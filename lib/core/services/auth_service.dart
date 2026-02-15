import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for handling biometric and PIN authentication
class AuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Storage keys
  static const String _pinKey = 'user_pin';
  static const String _biometricEnabledKey = 'biometric_enabled';

  // Hash version marker prefix - hashed PINs start with "v1:"
  static const String _hashVersionPrefix = 'v1:';

  /// Authenticate user using biometric prompt
  /// When [force] is true, skips the preference check (for explicit button taps)
  /// Returns true if authentication succeeds
  Future<bool> authenticate({bool force = false}) async {
    try {
      if (!await hasBiometrics()) return false;
      if (!force && !await isBiometricEnabled()) return false;

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your IDs',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    }
  }

  /// Store PIN as salted SHA-256 hash.
  /// Format: "v1:base64(salt):base64(hash)"
  Future<void> setPin(String pin) async {
    try {
      final salt = _generateSalt();
      final hash = _hashPin(pin, salt);
      final stored = '$_hashVersionPrefix${base64Encode(salt)}:${base64Encode(hash)}';
      await _secureStorage.write(key: _pinKey, value: stored);
    } catch (e) {
      debugPrint('Error storing PIN: $e');
      rethrow;
    }
  }

  /// Verify PIN against stored value.
  /// Supports both legacy plaintext PINs and new hashed PINs.
  /// Legacy PINs are auto-upgraded to hashed format on successful verify.
  Future<bool> verifyPin(String pin) async {
    try {
      final storedPin = await _secureStorage.read(key: _pinKey);
      if (storedPin == null) return false;

      // Check if this is a hashed PIN (v1: prefix)
      if (storedPin.startsWith(_hashVersionPrefix)) {
        final parts = storedPin.substring(_hashVersionPrefix.length).split(':');
        if (parts.length != 2) return false;
        final salt = base64Decode(parts[0]);
        final storedHash = base64Decode(parts[1]);
        final computedHash = _hashPin(pin, salt);
        return _constantTimeEquals(storedHash, computedHash);
      }

      // Legacy plaintext PIN - compare directly
      if (storedPin == pin) {
        // Auto-upgrade to hashed format
        await setPin(pin);
        debugPrint('PIN auto-upgraded to hashed format');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error verifying PIN: $e');
      return false;
    }
  }

  /// Generate 16 random bytes for PIN salt.
  Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
  }

  /// Compute SHA-256(salt + pin).
  Uint8List _hashPin(String pin, Uint8List salt) {
    final pinBytes = utf8.encode(pin);
    final combined = Uint8List(salt.length + pinBytes.length);
    combined.setAll(0, salt);
    combined.setAll(salt.length, pinBytes);
    final digest = sha256.convert(combined);
    return Uint8List.fromList(digest.bytes);
  }

  /// Constant-time comparison to prevent timing attacks.
  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Check if user has set a PIN
  Future<bool> hasPin() async {
    try {
      final pin = await _secureStorage.read(key: _pinKey);
      return pin != null && pin.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking PIN: $e');
      return false;
    }
  }

  /// Check if device supports biometric authentication
  Future<bool> hasBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        return false;
      }

      // Check if any biometrics are enrolled
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
      return false;
    }
  }

  /// Check if user has enabled biometric authentication
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _secureStorage.read(key: _biometricEnabledKey);
      return value == 'true';
    } catch (e) {
      debugPrint('Error reading biometric preference: $e');
      return false;
    }
  }

  /// Toggle biometric authentication preference
  Future<void> toggleBiometric(bool enabled) async {
    try {
      await _secureStorage.write(
        key: _biometricEnabledKey,
        value: enabled.toString(),
      );
    } catch (e) {
      debugPrint('Error saving biometric preference: $e');
      rethrow;
    }
  }

  /// Clear all authentication data (for logout/reset)
  Future<void> clearAuthData() async {
    try {
      await _secureStorage.delete(key: _pinKey);
      await _secureStorage.delete(key: _biometricEnabledKey);
    } catch (e) {
      debugPrint('Error clearing auth data: $e');
      rethrow;
    }
  }
}
