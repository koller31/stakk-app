import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../../../core/theme/app_theme.dart';

/// Overlay widget that shows a scannable PDF417 barcode
/// Used when user taps "Show Scannable Barcode" button on ID card
class ScannableBarcodeOverlay extends StatefulWidget {
  final String aamvaData;
  final VoidCallback onClose;

  const ScannableBarcodeOverlay({
    super.key,
    required this.aamvaData,
    required this.onClose,
  });

  @override
  State<ScannableBarcodeOverlay> createState() => _ScannableBarcodeOverlayState();
}

class _ScannableBarcodeOverlayState extends State<ScannableBarcodeOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  double? _previousBrightness;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _maxBrightness();
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

  @override
  void dispose() {
    _restoreBrightness();
    _controller.dispose();
    super.dispose();
  }

  void _handleClose() async {
    await _controller.reverse();
    await _restoreBrightness();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.black.withOpacity(0.95),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _handleClose,
                    ),
                    const Expanded(
                      child: Text(
                        'Scannable Barcode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the close button
                  ],
                ),
              ),

              const Spacer(),

              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.brightness_high, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Ready to Scan',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // Barcode container - white background for scanner contrast
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // PDF417 Barcode
                    // AAMVA Standard Size: Minimum 1.25" x 0.5"
                    // At 160 DPI (typical phone display): 200 x 80 pixels minimum
                    // Using larger size for better scanning: 350 x 140 pixels
                    BarcodeWidget(
                      barcode: Barcode.pdf417(
                        moduleHeight: 2.0, // Increase module height for better scanning
                        preferredRatio: 3.0, // Width:Height ratio
                      ),
                      data: widget.aamvaData,
                      width: 350,
                      height: 140,
                      color: Colors.black,
                      backgroundColor: Colors.white,
                      errorBuilder: (context, error) => Container(
                        width: 350,
                        height: 140,
                        color: Colors.grey[200],
                        child: Center(
                          child: Text(
                            'Barcode Error: $error',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Label with compliance info
                    Column(
                      children: [
                        const Text(
                          'PDF417 - AAMVA Version 8 (2016)',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Size: 350x140px (~1.4" x 0.6")',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // Instructions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
                child: Text(
                  'Hold your phone steady and let the scanner read the barcode. Screen brightness has been maximized for best results.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),

              // Close button
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Done Scanning',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
