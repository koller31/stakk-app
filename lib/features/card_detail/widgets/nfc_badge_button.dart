import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../../../core/services/nfc_badge_service.dart';

/// State of the NFC badge button
enum NfcBadgeState {
  unavailable, // iOS or no NFC hardware
  ready, // Ready to activate
  active, // Currently emitting NFC
  error, // Error state
}

/// Reusable NFC badge toggle button with countdown
class NfcBadgeButton extends StatefulWidget {
  final String? nfcAid;
  final String? nfcPayload;
  final int autoDeactivateSeconds;

  const NfcBadgeButton({
    super.key,
    this.nfcAid,
    this.nfcPayload,
    this.autoDeactivateSeconds = 60,
  });

  @override
  State<NfcBadgeButton> createState() => NfcBadgeButtonState();
}

class NfcBadgeButtonState extends State<NfcBadgeButton>
    with SingleTickerProviderStateMixin {
  final NfcBadgeService _nfcService = NfcBadgeService();

  NfcBadgeState _state = NfcBadgeState.unavailable;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _checkAvailability();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    // Deactivate badge when leaving screen
    if (_state == NfcBadgeState.active) {
      _nfcService.deactivateBadge();
    }
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    if (!Platform.isAndroid) {
      setState(() => _state = NfcBadgeState.unavailable);
      return;
    }

    if (widget.nfcAid == null || widget.nfcPayload == null) {
      setState(() => _state = NfcBadgeState.unavailable);
      return;
    }

    final nfcAvailable = await _nfcService.isNfcAvailable();
    final hceSupported = await _nfcService.isHceSupported();

    if (mounted) {
      setState(() {
        _state = (nfcAvailable && hceSupported)
            ? NfcBadgeState.ready
            : NfcBadgeState.unavailable;
      });
    }
  }

  Future<void> _toggleBadge() async {
    if (_state == NfcBadgeState.active) {
      await _deactivate();
    } else if (_state == NfcBadgeState.ready) {
      await _activate();
    }
  }

  Future<void> _activate() async {
    try {
      final success = await _nfcService.activateBadge(
        widget.nfcAid!,
        widget.nfcPayload!,
      );

      if (success && mounted) {
        setState(() {
          _state = NfcBadgeState.active;
          _remainingSeconds = widget.autoDeactivateSeconds;
        });

        // Haptic feedback
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 100);
        }

        // Start pulse animation
        _pulseController.repeat(reverse: true);

        // Start countdown
        _countdownTimer = Timer.periodic(
          const Duration(seconds: 1),
          (timer) {
            if (!mounted) {
              timer.cancel();
              return;
            }
            setState(() {
              _remainingSeconds--;
              if (_remainingSeconds <= 0) {
                _deactivate();
              }
            });
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _state = NfcBadgeState.error);
        // Reset to ready after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _state = NfcBadgeState.ready);
        });
      }
    }
  }

  Future<void> _deactivate() async {
    _countdownTimer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    await _nfcService.deactivateBadge();
    if (mounted) {
      setState(() {
        _state = NfcBadgeState.ready;
        _remainingSeconds = 0;
      });
    }
  }

  /// Sync state when app resumes (in case service was killed)
  Future<void> syncState() async {
    if (_state == NfcBadgeState.active) {
      // If we think we're active but service might have been killed,
      // just reset to ready
      await _deactivate();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == NfcBadgeState.unavailable) {
      if (Platform.isIOS) {
        return _buildVisualOnlyBanner();
      }
      return const SizedBox.shrink();
    }

    return _buildBadgeButton();
  }

  Widget _buildVisualOnlyBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.badge, color: Colors.grey, size: 18),
          SizedBox(width: 8),
          Text(
            'Visual Badge Only',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeButton() {
    final isActive = _state == NfcBadgeState.active;
    final isError = _state == NfcBadgeState.error;

    Color buttonColor;
    Color textColor;
    IconData icon;
    String label;

    if (isError) {
      buttonColor = Colors.red.shade700;
      textColor = Colors.white;
      icon = Icons.error_outline;
      label = 'Error';
    } else if (isActive) {
      buttonColor = Colors.green.shade700;
      textColor = Colors.white;
      icon = Icons.nfc;
      label = 'Active  $_remainingSeconds s';
    } else {
      buttonColor = Colors.blue.shade700;
      textColor = Colors.white;
      icon = Icons.nfc;
      label = 'Present Badge';
    }

    Widget button = GestureDetector(
      onTap: _toggleBadge,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    // Add pulse animation when active
    if (isActive) {
      button = AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_pulseController.value * 0.03),
            child: child,
          );
        },
        child: button,
      );
    }

    return button;
  }
}
