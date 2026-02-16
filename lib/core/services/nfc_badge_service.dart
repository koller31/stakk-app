import 'dart:io';
import 'package:flutter/services.dart';
import '../../data/models/nfc_scan_result.dart';

class NfcBadgeService {
  static final NfcBadgeService _instance = NfcBadgeService._internal();
  factory NfcBadgeService() => _instance;
  NfcBadgeService._internal();

  static const MethodChannel _channel = MethodChannel('com.idswipe/nfc_badge');

  /// Check if NFC is available and enabled on the device
  Future<bool> isNfcAvailable() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final bool? available = await _channel.invokeMethod('isNfcAvailable');
      return available ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if Host Card Emulation (HCE) is supported
  Future<bool> isHceSupported() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final bool? supported = await _channel.invokeMethod('isHceSupported');
      return supported ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Activate the NFC badge with specified AID and payload
  ///
  /// [aid] - Application ID in hex format (e.g., "F0010203040506")
  /// [payload] - Payload data in hex format
  Future<bool> activateBadge(String aid, String payload) async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final bool? result = await _channel.invokeMethod('activateBadge', {
        'aid': aid,
        'payload': payload,
      });
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Deactivate the NFC badge
  Future<bool> deactivateBadge() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final bool? result = await _channel.invokeMethod('deactivateBadge');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Start reading an NFC tag. Returns scan result when a tag is tapped.
  /// Throws [NfcScanCancelledException] if cancelled via [stopReading].
  /// Throws [PlatformException] on NFC errors.
  Future<NfcScanResult> startReading() async {
    if (!Platform.isAndroid) {
      throw PlatformException(
        code: 'UNSUPPORTED',
        message: 'NFC reading is only supported on Android',
      );
    }

    try {
      final result = await _channel.invokeMethod('startNfcReader');
      if (result == null) {
        throw PlatformException(
          code: 'NFC_READ_ERROR',
          message: 'No data returned from tag',
        );
      }
      return NfcScanResult.fromNativeMap(Map<dynamic, dynamic>.from(result));
    } on PlatformException catch (e) {
      if (e.code == 'NFC_CANCELLED') {
        throw NfcScanCancelledException();
      }
      rethrow;
    }
  }

  /// Cancel an active NFC read operation
  Future<void> stopReading() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('stopNfcReader');
    } catch (_) {}
  }
}

/// Thrown when an NFC scan is cancelled by the user or by calling stopReading()
class NfcScanCancelledException implements Exception {
  @override
  String toString() => 'NFC scan was cancelled';
}
