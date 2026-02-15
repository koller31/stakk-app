import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'pin_entry_screen.dart';

/// Lock Screen - Main entry point for authentication
///
/// Displays on:
/// - App startup
/// - Resume from background
///
/// Handles:
/// - First-time PIN setup
/// - Biometric authentication
/// - PIN entry for unlock
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _isInitialized = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check biometric availability
    _biometricAvailable = await authProvider.hasBiometrics();
    _biometricEnabled = await authProvider.isBiometricEnabled();

    setState(() {
      _isInitialized = true;
    });

    // Auto-trigger biometric if enabled and available
    if (_biometricEnabled && _biometricAvailable && !authProvider.isFirstLaunch) {
      _tryBiometricAuth();
    }
  }

  Future<void> _tryBiometricAuth({bool force = false}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.authenticate(force: force);

    if (success && mounted) {
      context.go('/home');
    }
  }

  Future<void> _handlePinEntry() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Determine mode based on first launch
    final mode = authProvider.isFirstLaunch ? PinEntryMode.set : PinEntryMode.unlock;

    final pin = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => PinEntryScreen(
          mode: mode,
          biometricAvailable: !authProvider.isFirstLaunch && _biometricAvailable,
          onBiometricRequested: () {
            Navigator.of(context).pop(); // Close PIN screen
            _tryBiometricAuth(force: true); // Try biometric (explicit tap)
          },
        ),
      ),
    );

    if (pin == null || !mounted) return;

    if (mode == PinEntryMode.set) {
      // First launch - set PIN
      try {
        await authProvider.setPin(pin);

        // Ask if user wants to enable biometrics
        if (_biometricAvailable && mounted) {
          await _offerBiometricSetup();
        }

        if (mounted) {
          context.go('/home');
        }
      } catch (e) {
        if (mounted) {
          _showError('Failed to set PIN. Please try again.');
        }
      }
    } else {
      // Unlock mode - verify PIN
      final isValid = await authProvider.verifyPin(pin);

      if (isValid && mounted) {
        context.go('/home');
      } else if (mounted) {
        _showError('Incorrect PIN. Please try again.');
        // Automatically show PIN entry again
        _handlePinEntry();
      }
    }
  }

  Future<void> _offerBiometricSetup() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevatedSurface,
        title: Text(
          'Enable Biometric Authentication?',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: Text(
          'Use fingerprint or face recognition to unlock the app quickly.',
          style: TextStyle(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Not Now',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Enable',
              style: TextStyle(color: AppColors.primaryAccent),
            ),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        await authProvider.toggleBiometric(true);
      } catch (e) {
        debugPrint('Failed to enable biometric: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!_isInitialized || authProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryAccent,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // App logo and lock icon
              Icon(
                Icons.lock_outline,
                size: 80,
                color: AppColors.primaryAccent,
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // App name
              Text(
                'IDswipe',
                style: AppTheme.textTheme.displayMedium?.copyWith(
                  color: AppColors.primaryText,
                  fontSize: 36,
                ),
              ),

              const SizedBox(height: AppTheme.spacingSm),

              // Subtitle
              Text(
                authProvider.isFirstLaunch
                    ? 'Welcome! Set up your security PIN'
                    : 'Unlock to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // Unlock button
              ElevatedButton(
                onPressed: _handlePinEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  authProvider.isFirstLaunch ? 'Get Started' : 'Unlock',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // Biometric button (if available and not first launch)
              if (!authProvider.isFirstLaunch && _biometricAvailable)
                IconButton(
                  onPressed: () => _tryBiometricAuth(force: true),
                  icon: Icon(
                    Icons.fingerprint,
                    size: 48,
                    color: AppColors.primaryAccent,
                  ),
                  tooltip: 'Use biometric authentication',
                ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
