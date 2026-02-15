import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages auto-lock on app background/inactivity.
/// Records when the app goes to background and checks elapsed time on resume.
class AutoLockService {
  static final AutoLockService _instance = AutoLockService._();
  factory AutoLockService() => _instance;
  AutoLockService._();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _timeoutKey = 'auto_lock_timeout_seconds';

  DateTime? _pausedAt;
  int _timeoutSeconds = 60; // Default: 1 minute

  /// Available timeout options (in seconds).
  static const Map<int, String> timeoutOptions = {
    30: '30 seconds',
    60: '1 minute',
    300: '5 minutes',
    900: '15 minutes',
    -1: 'Never',
  };

  /// Initialize - load saved timeout preference.
  Future<void> init() async {
    try {
      final stored = await _secureStorage.read(key: _timeoutKey);
      if (stored != null) {
        _timeoutSeconds = int.tryParse(stored) ?? 60;
      }
    } catch (e) {
      debugPrint('AutoLockService init error: $e');
    }
  }

  /// Record the time when app goes to background.
  void recordPause() {
    _pausedAt = DateTime.now();
  }

  /// Check if the app should lock on resume.
  Future<bool> shouldLockOnResume() async {
    if (_timeoutSeconds == -1) return false; // "Never" setting
    if (_pausedAt == null) return false;

    final elapsed = DateTime.now().difference(_pausedAt!).inSeconds;
    _pausedAt = null;
    return elapsed >= _timeoutSeconds;
  }

  /// Get current timeout in seconds.
  int get timeoutSeconds => _timeoutSeconds;

  /// Set the auto-lock timeout.
  Future<void> setTimeout(int seconds) async {
    _timeoutSeconds = seconds;
    await _secureStorage.write(
      key: _timeoutKey,
      value: seconds.toString(),
    );
  }
}
