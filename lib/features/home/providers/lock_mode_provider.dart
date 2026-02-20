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
  static const String _hashVersionPrefix = 'v1:';

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
    final hash = _hashPin(pin, salt);
    final stored =
        '$_hashVersionPrefix${base64Encode(salt)}:${base64Encode(hash)}';
    await _secureStorage.write(key: _pinKey, value: stored);
  }

  bool validatePin(String attemptedPin) {
    // This is now async internally but we need sync API for existing callers.
    // We'll use the async version instead.
    throw UnimplementedError('Use validatePinAsync instead');
  }

  Future<bool> validatePinAsync(String attemptedPin) async {
    final stored = await _secureStorage.read(key: _pinKey);
    if (stored == null) return false;

    if (stored.startsWith(_hashVersionPrefix)) {
      final parts = stored.substring(_hashVersionPrefix.length).split(':');
      if (parts.length != 2) return false;
      final salt = base64Decode(parts[0]);
      final storedHash = base64Decode(parts[1]);
      final computedHash = _hashPin(attemptedPin, salt);
      return _constantTimeEquals(storedHash, computedHash);
    }

    // Legacy plaintext - compare and upgrade
    if (stored == attemptedPin) {
      await _setHashedPin(attemptedPin);
      debugPrint('Traffic lock PIN auto-upgraded to hashed format');
      return true;
    }
    return false;
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

  Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
  }

  Uint8List _hashPin(String pin, Uint8List salt) {
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
