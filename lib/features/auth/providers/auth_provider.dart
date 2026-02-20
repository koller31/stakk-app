import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _sessionKey = 'active_session_ts';

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

      // Check if there's an active session (survives activity recreation)
      final sessionTs = await _storage.read(key: _sessionKey);
      if (sessionTs != null && _hasPin) {
        final sessionTime = DateTime.tryParse(sessionTs);
        if (sessionTime != null &&
            DateTime.now().difference(sessionTime).inSeconds < 30) {
          _isAuthenticated = true;
          _authStatus = AuthStatus.authenticated;
          // Refresh the session timestamp
          await _storage.write(
              key: _sessionKey, value: DateTime.now().toIso8601String());
          debugPrint('Auth restored from active session');
        } else {
          _isAuthenticated = false;
          _authStatus = AuthStatus.unauthenticated;
          await _storage.delete(key: _sessionKey);
        }
      } else {
        _isAuthenticated = false;
        _authStatus = AuthStatus.unauthenticated;
      }

      // Cache biometric state
      _biometricsAvailable = await _authService.hasBiometrics();
      _biometricsEnabled = await _authService.isBiometricEnabled();

      debugPrint('Auth initialized: hasPin=$_hasPin, isFirstLaunch=$_isFirstLaunch, restored=$_isAuthenticated');
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
        await _storage.write(
            key: _sessionKey, value: DateTime.now().toIso8601String());
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
      await _storage.write(
          key: _sessionKey, value: DateTime.now().toIso8601String());
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
        await _storage.write(
            key: _sessionKey, value: DateTime.now().toIso8601String());
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
  Future<void> lock() async {
    if (_isAuthenticated) {
      _isAuthenticated = false;
      _authStatus = AuthStatus.unauthenticated;
      await _storage.delete(key: _sessionKey);
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

  /// Check lockout status
  Future<int?> getLockoutRemainingSeconds() async {
    return await _authService.getLockoutRemainingSeconds();
  }

  /// Get failed attempt count
  Future<int> getFailedAttemptCount() async {
    return await _authService.getFailedAttemptCount();
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
