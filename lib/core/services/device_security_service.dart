import 'package:flutter/material.dart';
import 'package:safe_device/safe_device.dart';

/// Checks for rooted/jailbroken devices and warns the user.
/// Shows a one-time-per-session warning dialog (does NOT block access).
class DeviceSecurityService {
  static final DeviceSecurityService _instance = DeviceSecurityService._();
  factory DeviceSecurityService() => _instance;
  DeviceSecurityService._();

  bool _hasCheckedThisSession = false;

  /// Check if device is compromised and show warning if so.
  /// Call once after authentication succeeds.
  Future<void> checkAndWarn(BuildContext context) async {
    if (_hasCheckedThisSession) return;
    _hasCheckedThisSession = true;

    try {
      final isJailbroken = await SafeDevice.isJailBroken;
      if (isJailbroken && context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Security Warning'),
            content: const Text(
              'This device appears to be rooted or jailbroken. '
              'Your stored IDs and personal data may be at increased risk.\n\n'
              'For maximum security, use IDswipe on an unmodified device.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('I Understand'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Detection failed - don't block the user
      debugPrint('Device security check failed: $e');
    }
  }
}
