import 'package:flutter/foundation.dart';
import '../../../core/services/auth_service.dart';

/// Authentication status enum for routing
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
}

/// Provider for managing authentication state
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  bool _isAuthenticated = false;
  bool _isFirstLaunch = true;
  bool _hasPin = false;
  bool _isLoading = false;
  AuthStatus _authStatus = AuthStatus.initial;

  // Cached sync properties for settings screen
  bool _biometricsAvailable = false;
  bool _biometricsEnabled = false;

  AuthProvider([AuthService? authService])
      : _authService = authService ?? AuthService();

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get hasPin => _hasPin;
  bool get isLoading => _isLoading;
  AuthStatus get authStatus => _authStatus;
  bool get biometricsAvailable => _biometricsAvailable;
  bool get biometricsEnabled => _biometricsEnabled;

  /// Initialize auth state on app startup
  Future<void> init() async {
    _authStatus = AuthStatus.loading;
    _isLoading = true;
    notifyListeners();

    try {
      _hasPin = await _authService.hasPin();
      _isFirstLaunch = !_hasPin;
      _isAuthenticated = false;

      // Cache biometric state
      _biometricsAvailable = await _authService.hasBiometrics();
      _biometricsEnabled = await _authService.isBiometricEnabled();

      _authStatus = AuthStatus.unauthenticated;
      debugPrint('Auth initialized: hasPin=$_hasPin, isFirstLaunch=$_isFirstLaunch');
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      _hasPin = false;
      _isFirstLaunch = true;
      _isAuthenticated = false;
      _authStatus = AuthStatus.unauthenticated;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Authenticate user using biometric
  /// When [force] is true, bypasses the enabled preference (for explicit taps)
  Future<bool> authenticate({bool force = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _authService.authenticate(force: force);

      if (success) {
        _isAuthenticated = true;
        _authStatus = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set user's PIN (for first launch or PIN change)
  Future<void> setPin(String pin) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.setPin(pin);
      _hasPin = true;
      _isFirstLaunch = false;
      _isAuthenticated = true;
      _authStatus = AuthStatus.authenticated;
      debugPrint('PIN set successfully');
    } catch (e) {
      debugPrint('Error setting PIN: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verify PIN entered by user
  Future<bool> verifyPin(String pin) async {
    _isLoading = true;
    notifyListeners();

    try {
      final isValid = await _authService.verifyPin(pin);

      if (isValid) {
        _isAuthenticated = true;
        _authStatus = AuthStatus.authenticated;
        debugPrint('PIN verified successfully');
      } else {
        debugPrint('PIN verification failed');
      }

      return isValid;
    } catch (e) {
      debugPrint('Error verifying PIN: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lock the app
  void lock() {
    if (_isAuthenticated) {
      _isAuthenticated = false;
      _authStatus = AuthStatus.unauthenticated;
      debugPrint('App locked');
      notifyListeners();
    }
  }

  /// Check if biometrics are available (async)
  Future<bool> hasBiometrics() async {
    return await _authService.hasBiometrics();
  }

  /// Check if biometric authentication is enabled (async)
  Future<bool> isBiometricEnabled() async {
    return await _authService.isBiometricEnabled();
  }

  /// Toggle biometric authentication
  Future<void> toggleBiometric(bool enabled) async {
    try {
      await _authService.toggleBiometric(enabled);
      _biometricsEnabled = enabled;
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling biometric: $e');
      rethrow;
    }
  }

  /// Set biometrics enabled (alias for toggleBiometric)
  Future<void> setBiometricsEnabled(bool enabled) async {
    await toggleBiometric(enabled);
  }

  /// Clear all auth data
  Future<void> clearAuthData() async {
    try {
      await _authService.clearAuthData();
      _isAuthenticated = false;
      _hasPin = false;
      _isFirstLaunch = true;
      _biometricsEnabled = false;
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing auth data: $e');
      rethrow;
    }
  }
}
