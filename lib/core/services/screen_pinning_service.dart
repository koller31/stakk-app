import 'package:flutter/services.dart';

/// Screen Pinning Service - Integrates with Android Lock Task Mode
///
/// This service provides screen pinning functionality for traffic document viewing
/// Communicates with native Android code via MethodChannel
class ScreenPinningService {
  static const MethodChannel _channel =
      MethodChannel('com.idswipe/screen_pinning');

  /// Start screen pinning mode (Android Lock Task Mode)
  ///
  /// This locks the screen to the current app, preventing users from
  /// navigating away or accessing other app functions
  ///
  /// Returns true if successfully started, false otherwise
  Future<bool> startScreenPinning() async {
    try {
      final result = await _channel.invokeMethod('startLockTask');
      return result == true;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Stop screen pinning mode
  ///
  /// Exits lock task mode and returns the app to normal operation
  ///
  /// Returns true if successfully stopped, false otherwise
  Future<bool> stopScreenPinning() async {
    try {
      final result = await _channel.invokeMethod('stopLockTask');
      return result == true;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  // Static convenience methods
  static final ScreenPinningService _instance = ScreenPinningService();
  static Future<bool> startPinning() => _instance.startScreenPinning();
  static Future<bool> stopPinning() => _instance.stopScreenPinning();

  /// Check if currently in screen pinning mode
  ///
  /// Returns true if in lock task mode, false otherwise
  Future<bool> isInScreenPinningMode() async {
    try {
      final result = await _channel.invokeMethod('isInLockTaskMode');
      return result == true;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
