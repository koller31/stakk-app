import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/nfc_badge_service.dart';
import 'nfc_scan_result_screen.dart';

/// NFC card scanning screen with three states: waiting, processing, error.
/// Auto-navigates to result screen on successful scan.
class NfcScanScreen extends StatefulWidget {
  const NfcScanScreen({super.key});

  @override
  State<NfcScanScreen> createState() => _NfcScanScreenState();
}

enum _ScanState { waiting, processing, error }

class _NfcScanScreenState extends State<NfcScanScreen>
    with SingleTickerProviderStateMixin {
  final _nfcService = NfcBadgeService();
  _ScanState _state = _ScanState.waiting;
  String _errorMessage = '';
  Timer? _timeoutTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startScan();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _pulseController.dispose();
    _nfcService.stopReading();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _state = _ScanState.waiting;
      _errorMessage = '';
    });

    // 30-second timeout
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && _state == _ScanState.waiting) {
        _nfcService.stopReading();
        setState(() {
          _state = _ScanState.error;
          _errorMessage = 'Scan timed out. No card detected.';
        });
      }
    });

    try {
      final result = await _nfcService.startReading();
      _timeoutTimer?.cancel();

      if (!mounted) return;

      setState(() => _state = _ScanState.processing);

      // Brief processing delay for visual feedback
      await Future.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;

      // Navigate to result screen
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => NfcScanResultScreen(scanResult: result),
        ),
      );

      if (saved == true && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        // User came back without saving -- reset to scan
        _startScan();
      }
    } on NfcScanCancelledException {
      // User cancelled or screen disposed -- do nothing
    } on PlatformException catch (e) {
      _timeoutTimer?.cancel();
      if (mounted) {
        setState(() {
          _state = _ScanState.error;
          _errorMessage = e.message ?? 'Failed to read NFC card';
        });
      }
    } catch (e) {
      _timeoutTimer?.cancel();
      if (mounted) {
        setState(() {
          _state = _ScanState.error;
          _errorMessage = 'Unexpected error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.elevatedSurface,
        title: Text(
          'Scan NFC Card',
          style: TextStyle(color: AppColors.primaryText),
        ),
        iconTheme: IconThemeData(color: AppColors.primaryText),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _buildStateContent(),
        ),
      ),
    );
  }

  Widget _buildStateContent() {
    switch (_state) {
      case _ScanState.waiting:
        return _buildWaitingState();
      case _ScanState.processing:
        return _buildProcessingState();
      case _ScanState.error:
        return _buildErrorState();
    }
  }

  Widget _buildWaitingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryAccent.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.primaryAccent.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.nfc,
              size: 56,
              color: AppColors.primaryAccent,
            ),
          ),
        ),
        const SizedBox(height: 40),
        Text(
          'Hold card to back of phone',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Place your NFC badge, card, or tag against\nthe back of your device',
          style: TextStyle(
            color: AppColors.secondaryText,
            fontSize: 15,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            backgroundColor: AppColors.subtleBorder,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.primaryAccent.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Waiting for card...',
          style: TextStyle(
            color: AppColors.tertiaryText,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Reading card data...',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.errorRed.withValues(alpha: 0.1),
          ),
          child: const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.errorRed,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Scan Failed',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage,
          style: TextStyle(
            color: AppColors.secondaryText,
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _startScan,
          icon: const Icon(Icons.refresh, size: 20),
          label: const Text(
            'Try Again',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            backgroundColor: AppColors.primaryAccent,
          ),
        ),
      ],
    );
  }
}
