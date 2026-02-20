import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
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
  static const String _failedAttemptsKey = 'failed_pin_attempts';
  static const String _lockoutUntilKey = 'pin_lockout_until';

  // Hash version markers
  static const String _hashV1Prefix = 'v1:'; // Legacy SHA-256
  static const String _hashV2Prefix = 'v2:'; // PBKDF2-HMAC-SHA256

  // PBKDF2 parameters
  static const int _pbkdf2Iterations = 100000;
  static const int _saltLength = 16;
  static const int _hashLength = 32;

  // Brute-force lockout parameters
  static const int _maxAttemptsBeforeLockout = 5;
  static const int _lockoutDurationSeconds = 30;
  static const int _maxAttemptsBeforeExtendedLockout = 10;
  static const int _extendedLockoutDurationSeconds = 300; // 5 minutes

  /// Authenticate user using biometric prompt
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
      if (didAuthenticate) {
        await _resetFailedAttempts();
      }
      return didAuthenticate;
    } catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    }
  }

  /// Check if PIN entry is currently locked out due to too many failed attempts.
  /// Returns null if not locked out, or the remaining seconds if locked out.
  Future<int?> getLockoutRemainingSeconds() async {
    try {
      final lockoutStr = await _secureStorage.read(key: _lockoutUntilKey);
      if (lockoutStr == null) return null;
      final lockoutUntil = DateTime.tryParse(lockoutStr);
      if (lockoutUntil == null) return null;
      final remaining = lockoutUntil.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        await _secureStorage.delete(key: _lockoutUntilKey);
        return null;
      }
      return remaining;
    } catch (e) {
      return null;
    }
  }

  /// Get the current failed attempt count.
  Future<int> getFailedAttemptCount() async {
    try {
      final str = await _secureStorage.read(key: _failedAttemptsKey);
      return str != null ? (int.tryParse(str) ?? 0) : 0;
    } catch (e) {
      return 0;
    }
  }

  /// Record a failed PIN attempt and enforce lockout if threshold is reached.
  Future<void> recordFailedAttempt() async {
    try {
      final count = await getFailedAttemptCount() + 1;
      await _secureStorage.write(key: _failedAttemptsKey, value: count.toString());

      if (count >= _maxAttemptsBeforeExtendedLockout) {
        final lockoutUntil = DateTime.now().add(
          const Duration(seconds: _extendedLockoutDurationSeconds),
        );
        await _secureStorage.write(
          key: _lockoutUntilKey,
          value: lockoutUntil.toIso8601String(),
        );
      } else if (count >= _maxAttemptsBeforeLockout) {
        final lockoutUntil = DateTime.now().add(
          const Duration(seconds: _lockoutDurationSeconds),
        );
        await _secureStorage.write(
          key: _lockoutUntilKey,
          value: lockoutUntil.toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint('Error recording failed attempt: $e');
    }
  }

  /// Reset the failed attempt counter (called on successful auth).
  Future<void> _resetFailedAttempts() async {
    try {
      await _secureStorage.delete(key: _failedAttemptsKey);
      await _secureStorage.delete(key: _lockoutUntilKey);
    } catch (e) {
      debugPrint('Error resetting failed attempts: $e');
    }
  }

  /// Store PIN using PBKDF2-HMAC-SHA256 with 100k iterations.
  /// Format: "v2:base64(salt):base64(hash)"
  Future<void> setPin(String pin) async {
    try {
      final salt = _generateSalt();
      final hash = _pbkdf2(pin, salt);
      final stored = '$_hashV2Prefix${base64Encode(salt)}:${base64Encode(hash)}';
      await _secureStorage.write(key: _pinKey, value: stored);
    } catch (e) {
      debugPrint('Error storing PIN: $e');
      rethrow;
    }
  }

  /// Verify PIN against stored value.
  /// Supports legacy plaintext, v1 (SHA-256), and v2 (PBKDF2) formats.
  /// Auto-upgrades to v2 on successful verification.
  Future<bool> verifyPin(String pin) async {
    try {
      // Check lockout first
      final lockoutRemaining = await getLockoutRemainingSeconds();
      if (lockoutRemaining != null && lockoutRemaining > 0) {
        return false;
      }

      final storedPin = await _secureStorage.read(key: _pinKey);
      if (storedPin == null) return false;

      bool isValid = false;

      if (storedPin.startsWith(_hashV2Prefix)) {
        // v2: PBKDF2
        final parts = storedPin.substring(_hashV2Prefix.length).split(':');
        if (parts.length != 2) return false;
        final salt = base64Decode(parts[0]);
        final storedHash = base64Decode(parts[1]);
        final computedHash = _pbkdf2(pin, salt);
        isValid = _constantTimeEquals(storedHash, computedHash);
      } else if (storedPin.startsWith(_hashV1Prefix)) {
        // v1: legacy SHA-256
        final parts = storedPin.substring(_hashV1Prefix.length).split(':');
        if (parts.length != 2) return false;
        final salt = base64Decode(parts[0]);
        final storedHash = base64Decode(parts[1]);
        final computedHash = _hashPinSha256(pin, salt);
        isValid = _constantTimeEquals(storedHash, computedHash);
      } else {
        // Legacy plaintext
        isValid = storedPin == pin;
      }

      if (isValid) {
        // Auto-upgrade to v2 if not already
        if (!storedPin.startsWith(_hashV2Prefix)) {
          await setPin(pin);
          debugPrint('PIN auto-upgraded to PBKDF2 format');
        }
        await _resetFailedAttempts();
      } else {
        await recordFailedAttempt();
      }

      return isValid;
    } catch (e) {
      debugPrint('Error verifying PIN: $e');
      return false;
    }
  }

  /// Generate random salt bytes.
  Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_saltLength, (_) => random.nextInt(256)),
    );
  }

  /// PBKDF2-HMAC-SHA256 key derivation.
  Uint8List _pbkdf2(String pin, Uint8List salt) {
    final pinBytes = utf8.encode(pin);
    final hmacSha256 = Hmac(sha256, pinBytes);

    // PBKDF2 using HMAC-SHA256
    final derivedKey = Uint8List(_hashLength);
    final blockCount = (_hashLength / 32).ceil();

    for (int block = 1; block <= blockCount; block++) {
      // U1 = PRF(password, salt || INT_32_BE(block))
      final saltBlock = Uint8List(salt.length + 4);
      saltBlock.setAll(0, salt);
      saltBlock[salt.length] = (block >> 24) & 0xFF;
      saltBlock[salt.length + 1] = (block >> 16) & 0xFF;
      saltBlock[salt.length + 2] = (block >> 8) & 0xFF;
      saltBlock[salt.length + 3] = block & 0xFF;

      var u = Uint8List.fromList(hmacSha256.convert(saltBlock).bytes);
      final result = Uint8List.fromList(u);

      // U2..Uc
      for (int i = 1; i < _pbkdf2Iterations; i++) {
        u = Uint8List.fromList(hmacSha256.convert(u).bytes);
        for (int j = 0; j < result.length; j++) {
          result[j] ^= u[j];
        }
      }

      // Copy block result into derived key
      final offset = (block - 1) * 32;
      final copyLen = min(_hashLength - offset, 32);
      derivedKey.setRange(offset, offset + copyLen, result);
    }

    return derivedKey;
  }

  /// Legacy SHA-256 hash (for verifying v1 PINs before upgrade).
  Uint8List _hashPinSha256(String pin, Uint8List salt) {
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
      if (!canAuthenticate) return false;
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
      await _secureStorage.delete(key: _failedAttemptsKey);
      await _secureStorage.delete(key: _lockoutUntilKey);
    } catch (e) {
      debugPrint('Error clearing auth data: $e');
      rethrow;
    }
  }
}
