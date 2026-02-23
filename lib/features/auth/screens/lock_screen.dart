import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'pin_entry_screen.dart';

/// Splash / Lock Screen - Entry point every time the app opens.
///
/// Displays the Stakk app icon on a clean dark background.
/// Thumbprint auth triggers here; image pre-warming runs in the
/// background (driven by HomeProvider in main.dart).
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  bool _isInitialized = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Subtle fade-in for the icon
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _initialize();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check biometric availability
    _biometricAvailable = await authProvider.hasBiometrics();
    _biometricEnabled = await authProvider.isBiometricEnabled();

    if (!mounted) return;

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
      final lockoutRemaining = await authProvider.getLockoutRemainingSeconds();
      if (lockoutRemaining != null && lockoutRemaining > 0 && mounted) {
        _showError('Too many failed attempts. Try again in $lockoutRemaining seconds.');
        return;
      }

      final isValid = await authProvider.verifyPin(pin);

      if (isValid && mounted) {
        context.go('/home');
      } else if (mounted) {
        final failCount = await authProvider.getFailedAttemptCount();
        if (failCount >= 10) {
          _showError('Too many failed attempts. Locked for 5 minutes.');
        } else if (failCount >= 5) {
          _showError('Incorrect PIN. Locked for 30 seconds.');
        } else {
          _showError('Incorrect PIN. ${5 - failCount} attempts remaining.');
        }
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

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // App icon - always visible immediately (no spinner)
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/App Icon/stakk-icon-512.png',
                    width: 140,
                    height: 140,
                    filterQuality: FilterQuality.medium,
                  ),
                ),

                const SizedBox(height: 24),

                // App name
                Text(
                  'Stakk',
                  style: AppTheme.textTheme.displayMedium?.copyWith(
                    color: AppColors.primaryText,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle - only show once initialized
                if (_isInitialized && !authProvider.isLoading)
                  Text(
                    authProvider.isFirstLaunch
                        ? 'Set up your security PIN'
                        : 'Unlock to continue',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.secondaryText,
                    ),
                  ),

                const Spacer(flex: 2),

                // Auth controls - show once initialized
                if (_isInitialized && !authProvider.isLoading) ...[
                  // Biometric button (if available and not first launch)
                  if (!authProvider.isFirstLaunch && _biometricAvailable)
                    GestureDetector(
                      onTap: () => _tryBiometricAuth(force: true),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryAccent.withOpacity(0.4),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.fingerprint,
                              size: 40,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to unlock',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // PIN / Get Started button
                  TextButton(
                    onPressed: _handlePinEntry,
                    child: Text(
                      authProvider.isFirstLaunch ? 'Get Started' : 'Use PIN',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
