import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';

/// PIN Entry Screen - For setting or validating PIN
///
/// Usage:
/// - Set mode: Create a new PIN (requires confirmation)
/// - Unlock mode: Enter PIN to unlock
class PinEntryScreen extends StatefulWidget {
  final PinEntryMode mode;
  final String? title;
  final String? subtitle;
  final bool biometricAvailable;
  final VoidCallback? onBiometricRequested;

  const PinEntryScreen({
    super.key,
    required this.mode,
    this.title,
    this.subtitle,
    this.biometricAvailable = false,
    this.onBiometricRequested,
  });

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  String _pin = '';
  String? _firstPin; // For confirmation in set mode
  bool _isConfirming = false;
  String? _errorMessage;

  void _onNumberPressed(String number) {
    if (_pin.length >= 4) return;

    setState(() {
      _pin += number;
      _errorMessage = null;
    });

    // Auto-submit when 4 digits entered
    if (_pin.length == 4) {
      _handlePinComplete();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;

    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorMessage = null;
    });
  }

  void _handlePinComplete() {
    if (widget.mode == PinEntryMode.set) {
      if (!_isConfirming) {
        // First entry - ask for confirmation
        setState(() {
          _firstPin = _pin;
          _pin = '';
          _isConfirming = true;
        });
      } else {
        // Second entry - check if they match
        if (_pin == _firstPin) {
          // PINs match - return the PIN
          Navigator.of(context).pop(_pin);
        } else {
          // PINs don't match - reset
          setState(() {
            _errorMessage = 'PINs do not match. Try again.';
            _pin = '';
            _firstPin = null;
            _isConfirming = false;
          });
        }
      }
    } else {
      // Unlock mode - return the entered PIN for validation
      Navigator.of(context).pop(_pin);
    }
  }

  void _onCancel() {
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    String displayTitle = widget.title ??
        (_isConfirming ? 'Confirm PIN' :
         widget.mode == PinEntryMode.set ? 'Set PIN' : 'Enter PIN');

    String displaySubtitle = widget.subtitle ??
        (_isConfirming ? 'Enter your PIN again' :
         widget.mode == PinEntryMode.set ? 'Create a 4-digit PIN' : 'Enter your PIN to unlock');

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.primaryText),
          onPressed: _onCancel,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            children: [
              const Spacer(),

              // Lock icon
              Icon(
                widget.mode == PinEntryMode.unlock
                    ? Icons.lock_outline
                    : Icons.lock_open_outlined,
                size: 64,
                color: AppColors.primaryAccent,
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // Title
              Text(
                displayTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),

              const SizedBox(height: AppTheme.spacingSm),

              // Subtitle
              Text(
                displaySubtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _pin.length
                          ? AppColors.primaryAccent
                          : AppColors.tertiaryText.withOpacity(0.3),
                    ),
                  );
                }),
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // Error message
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.errorRed,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),

              const Spacer(),

              // Number pad
              _buildNumberPad(),

              const SizedBox(height: AppTheme.spacingMd),

              // Biometric button (if available)
              if (widget.biometricAvailable && widget.onBiometricRequested != null)
                IconButton(
                  onPressed: widget.onBiometricRequested,
                  icon: Icon(
                    Icons.fingerprint,
                    size: 48,
                    color: AppColors.primaryAccent,
                  ),
                  tooltip: 'Use biometric authentication',
                ),

              const SizedBox(height: AppTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        _buildNumberRow(['1', '2', '3']),
        const SizedBox(height: AppTheme.spacingMd),
        _buildNumberRow(['4', '5', '6']),
        const SizedBox(height: AppTheme.spacingMd),
        _buildNumberRow(['7', '8', '9']),
        const SizedBox(height: AppTheme.spacingMd),
        _buildNumberRow(['', '0', 'back']),
      ],
    );
  }

  Widget _buildNumberRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: numbers.map((number) {
        if (number.isEmpty) {
          return const SizedBox(width: 80, height: 80);
        }

        if (number == 'back') {
          return _buildButton(
            onPressed: _onBackspace,
            child: Icon(
              Icons.backspace_outlined,
              size: 28,
              color: AppColors.primaryText,
            ),
          );
        }

        return _buildButton(
          onPressed: () => _onNumberPressed(number),
          child: Text(
            number,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryText,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildButton({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 80,
      height: 80,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.subtleBorder,
                width: 1,
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

enum PinEntryMode {
  set,    // Setting a new PIN
  unlock, // Unlocking with existing PIN
}
