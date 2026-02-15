import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';

/// Mixin that provides screen brightness boost functionality for barcode scanning.
///
/// Use with any StatefulWidget that needs a "brighten for scanning" feature.
/// The mixin manages brightness state, toggle logic, and image color filtering.
///
/// Usage:
///   class _MyScreenState extends State<MyScreen> with BrightnessBoostMixin {
///     @override
///     void dispose() {
///       disposeBrightness();
///       super.dispose();
///     }
///   }
mixin BrightnessBoostMixin<T extends StatefulWidget> on State<T> {
  bool _brightnessBoostActive = false;
  double? _previousBrightness;

  bool get brightnessBoostActive => _brightnessBoostActive;

  Future<void> toggleBrightnessBoost() async {
    if (_brightnessBoostActive) {
      await _restoreBrightness();
    } else {
      await _maxBrightness();
    }
    setState(() {
      _brightnessBoostActive = !_brightnessBoostActive;
    });
  }

  Future<void> _maxBrightness() async {
    try {
      _previousBrightness = await ScreenBrightness().current;
      await ScreenBrightness().setScreenBrightness(1.0);
    } catch (e) {
      debugPrint('Could not set brightness: $e');
    }
  }

  Future<void> _restoreBrightness() async {
    try {
      if (_previousBrightness != null) {
        await ScreenBrightness().setScreenBrightness(_previousBrightness!);
      } else {
        await ScreenBrightness().resetScreenBrightness();
      }
    } catch (e) {
      debugPrint('Could not restore brightness: $e');
    }
  }

  /// Call this in your State's dispose() method.
  void disposeBrightness() {
    _restoreBrightness();
  }

  /// Wraps a widget with a brightness-boosting color filter when active.
  Widget applyBrightnessFilter(Widget child) {
    if (!_brightnessBoostActive) return child;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        1.5, 0, 0, 0, 50, // Red
        0, 1.5, 0, 0, 50, // Green
        0, 0, 1.5, 0, 50, // Blue
        0, 0, 0, 1, 0,    // Alpha
      ]),
      child: child,
    );
  }

  /// Builds the "Brighten for Scanning" button.
  Widget buildBrightenButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: toggleBrightnessBoost,
        style: ElevatedButton.styleFrom(
          backgroundColor: _brightnessBoostActive
              ? Colors.green
              : Colors.white.withOpacity(0.9),
          foregroundColor: _brightnessBoostActive
              ? Colors.white
              : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(
          _brightnessBoostActive
              ? Icons.brightness_high
              : Icons.brightness_6,
          size: 20,
        ),
        label: Text(
          _brightnessBoostActive
              ? 'Ready to Scan (Brightness 100%)'
              : 'Brighten for Scanning',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
