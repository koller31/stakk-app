import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LockModeProvider extends ChangeNotifier {
  bool _isLocked = false;
  bool _hasPin = false;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _pinKey = 'traffic_lock_pin';
  static const String _hashV1Prefix = 'v1:'; // Legacy SHA-256
  static const String _hashV2Prefix = 'v2:'; // PBKDF2-HMAC-SHA256

  // PBKDF2 parameters (match AuthService)
  static const int _pbkdf2Iterations = 100000;
  static const int _saltLength = 16;
  static const int _hashLength = 32;

  // Brute-force lockout
  static const String _failedAttemptsKey = 'traffic_lock_failed_attempts';
  static const String _lockoutUntilKey = 'traffic_lock_lockout_until';
  static const int _maxAttempts = 5;
  static const int _lockoutSeconds = 30;
  static const int _maxAttemptsExtended = 10;
  static const int _extendedLockoutSeconds = 300;

  bool get isLocked => _isLocked;
  bool get isLockModeActive => _isLocked;
  bool get hasPin => _hasPin;

  Future<void> initialize() async {
    // Migrate from SharedPreferences if needed
    await _migrateFromSharedPreferences();

    final stored = await _secureStorage.read(key: _pinKey);
    _hasPin = stored != null && stored.isNotEmpty;
    _isLocked = false;
    notifyListeners();
  }

  /// Migrate legacy plaintext PIN from SharedPreferences to FlutterSecureStorage.
  Future<void> _migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyPin = prefs.getString('traffic_lock_pin');
      if (legacyPin != null && legacyPin.isNotEmpty) {
        // Check if already migrated to secure storage
        final existing = await _secureStorage.read(key: _pinKey);
        if (existing == null) {
          // Hash and store in secure storage
          await _setHashedPin(legacyPin);
        }
        // Remove from SharedPreferences
        await prefs.remove('traffic_lock_pin');
        debugPrint('Traffic lock PIN migrated to secure storage');
      }
    } catch (e) {
      debugPrint('Error migrating traffic lock PIN: $e');
    }
  }

  Future<void> setPin(String newPin) async {
    await _setHashedPin(newPin);
    _hasPin = true;
    notifyListeners();
  }

  Future<void> _setHashedPin(String pin) async {
    final salt = _generateSalt();
    final hash = _pbkdf2(pin, salt);
    final stored =
        '$_hashV2Prefix${base64Encode(salt)}:${base64Encode(hash)}';
    await _secureStorage.write(key: _pinKey, value: stored);
  }

  bool validatePin(String attemptedPin) {
    // This is now async internally but we need sync API for existing callers.
    // We'll use the async version instead.
    throw UnimplementedError('Use validatePinAsync instead');
  }

  /// Check if traffic lock PIN is currently locked out.
  Future<int?> getLockoutRemainingSeconds() async {
    try {
      final lockoutStr = await _secureStorage.read(key: _lockoutUntilKey);
      if (lockoutStr == null) return null;
      final lockoutUntil = DateTime.tryParse(lockoutStr);
      if (lockoutUntil == null) return null;
      final remaining = lockoutUntil.difference(DateTime.now()).inSeconds;
      // Guard against clock manipulation: if lockout is more than 10 min in future, treat as expired
      if (remaining > _extendedLockoutSeconds + 60) {
        await _secureStorage.delete(key: _lockoutUntilKey);
        return null;
      }
      if (remaining <= 0) {
        await _secureStorage.delete(key: _lockoutUntilKey);
        return null;
      }
      return remaining;
    } catch (_) {
      return null;
    }
  }

  Future<bool> validatePinAsync(String attemptedPin) async {
    // Check lockout first
    final lockout = await getLockoutRemainingSeconds();
    if (lockout != null && lockout > 0) return false;

    final stored = await _secureStorage.read(key: _pinKey);
    if (stored == null) return false;

    bool isValid = false;

    if (stored.startsWith(_hashV2Prefix)) {
      // v2: PBKDF2
      final parts = stored.substring(_hashV2Prefix.length).split(':');
      if (parts.length != 2) return false;
      final salt = base64Decode(parts[0]);
      final storedHash = base64Decode(parts[1]);
      final computedHash = _pbkdf2(attemptedPin, salt);
      isValid = _constantTimeEquals(storedHash, computedHash);
    } else if (stored.startsWith(_hashV1Prefix)) {
      // v1: legacy SHA-256
      final parts = stored.substring(_hashV1Prefix.length).split(':');
      if (parts.length != 2) return false;
      final salt = base64Decode(parts[0]);
      final storedHash = base64Decode(parts[1]);
      final computedHash = _hashPinSha256(attemptedPin, salt);
      isValid = _constantTimeEquals(storedHash, computedHash);
    } else {
      // Legacy plaintext
      isValid = stored == attemptedPin;
    }

    if (isValid) {
      // Auto-upgrade to v2 if not already
      if (!stored.startsWith(_hashV2Prefix)) {
        await _setHashedPin(attemptedPin);
      }
      await _resetFailedAttempts();
    } else {
      await _recordFailedAttempt();
    }

    return isValid;
  }

  Future<bool> enableLockMode() async {
    if (!_hasPin) return false;
    _isLocked = true;
    notifyListeners();
    return true;
  }

  Future<bool> disableLockMode(String enteredPin) async {
    final valid = await validatePinAsync(enteredPin);
    if (!valid) return false;
    _isLocked = false;
    notifyListeners();
    return true;
  }

  Future<void> clearPin() async {
    _hasPin = false;
    _isLocked = false;
    await _secureStorage.delete(key: _pinKey);
    // Also clean up any legacy SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('traffic_lock_pin');
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _recordFailedAttempt() async {
    try {
      final str = await _secureStorage.read(key: _failedAttemptsKey);
      final count = (str != null ? (int.tryParse(str) ?? 0) : 0) + 1;
      await _secureStorage.write(key: _failedAttemptsKey, value: count.toString());

      if (count >= _maxAttemptsExtended) {
        final until = DateTime.now().add(const Duration(seconds: _extendedLockoutSeconds));
        await _secureStorage.write(key: _lockoutUntilKey, value: until.toIso8601String());
      } else if (count >= _maxAttempts) {
        final until = DateTime.now().add(const Duration(seconds: _lockoutSeconds));
        await _secureStorage.write(key: _lockoutUntilKey, value: until.toIso8601String());
      }
    } catch (_) {}
  }

  Future<void> _resetFailedAttempts() async {
    try {
      await _secureStorage.delete(key: _failedAttemptsKey);
      await _secureStorage.delete(key: _lockoutUntilKey);
    } catch (_) {}
  }

  Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_saltLength, (_) => random.nextInt(256)),
    );
  }

  /// PBKDF2-HMAC-SHA256 key derivation (matches AuthService).
  Uint8List _pbkdf2(String pin, Uint8List salt) {
    final pinBytes = utf8.encode(pin);
    final hmacSha256 = Hmac(sha256, pinBytes);

    final derivedKey = Uint8List(_hashLength);
    final blockCount = (_hashLength / 32).ceil();

    for (int block = 1; block <= blockCount; block++) {
      final saltBlock = Uint8List(salt.length + 4);
      saltBlock.setAll(0, salt);
      saltBlock[salt.length] = (block >> 24) & 0xFF;
      saltBlock[salt.length + 1] = (block >> 16) & 0xFF;
      saltBlock[salt.length + 2] = (block >> 8) & 0xFF;
      saltBlock[salt.length + 3] = block & 0xFF;

      var u = Uint8List.fromList(hmacSha256.convert(saltBlock).bytes);
      final result = Uint8List.fromList(u);

      for (int i = 1; i < _pbkdf2Iterations; i++) {
        u = Uint8List.fromList(hmacSha256.convert(u).bytes);
        for (int j = 0; j < result.length; j++) {
          result[j] ^= u[j];
        }
      }

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

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
