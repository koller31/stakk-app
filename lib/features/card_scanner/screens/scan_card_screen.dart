import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:edge_detection/edge_detection.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auto_lock_service.dart';
import '../../../data/models/card_category.dart';
import 'card_metadata_screen.dart';

/// Scan Card Screen - Captures and processes card images
class ScanCardScreen extends StatefulWidget {
  final CardCategory? initialCategory;

  const ScanCardScreen({super.key, this.initialCategory});

  @override
  State<ScanCardScreen> createState() => _ScanCardScreenState();
}

class _ScanCardScreenState extends State<ScanCardScreen> {
  String? _frontImagePath;
  String? _backImagePath;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Card'),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppTheme.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingLg),

              // Instructions
              Text(
                'Capture your card to add it to your digital wallet',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.spacingMd),

              Text(
                'Position the card on a flat surface with good lighting for best results.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // Front Image Card
              _buildImageCard(
                context,
                title: 'Front of Card',
                imagePath: _frontImagePath,
                onCapture: () => _captureCard(isBack: false),
                onRecrop: null,
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // Back Image Card
              _buildImageCard(
                context,
                title: 'Back of Card (Optional)',
                imagePath: _backImagePath,
                onCapture: () => _captureCard(isBack: true),
                onRecrop: null,
              ),

              const Spacer(),

              // Continue Button
              ElevatedButton(
                onPressed: _frontImagePath != null && !_isProcessing
                  ? _proceedToMetadata
                  : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                ),
                child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue'),
              ),

              const SizedBox(height: AppTheme.spacingMd),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(
    BuildContext context, {
    required String title,
    required String? imagePath,
    required VoidCallback onCapture,
    VoidCallback? onRecrop,
  }) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 2),
        borderRadius: AppTheme.borderRadiusLgAll,
      ),
      child: imagePath != null
        ? Stack(
            children: [
              ClipRRect(
                borderRadius: AppTheme.borderRadiusLgAll,
                child: Image.file(
                  File(imagePath),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    if (onRecrop != null)
                      IconButton(
                        onPressed: onRecrop,
                        icon: const Icon(Icons.crop),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: onCapture,
                      icon: const Icon(Icons.refresh),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        : InkWell(
            onTap: onCapture,
            borderRadius: AppTheme.borderRadiusLgAll,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'Tap to capture',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _captureCard({required bool isBack}) async {
    try {
      setState(() => _isProcessing = true);

      // Get temporary directory for image
      final Directory tempDir = await getTemporaryDirectory();
      final String imagePath = path.join(
        tempDir.path,
        '${const Uuid().v4()}.jpg',
      );

      // Suppress auto-lock while camera/gallery is open (2 min grace period)
      AutoLockService().suppressLockFor();

      // Use edge detection to capture and crop the card
      // This will open the camera with automatic edge detection
      bool success = await EdgeDetection.detectEdge(
        imagePath,
        canUseGallery: true,
        androidScanTitle: isBack ? 'Scan Back of Card' : 'Scan Front of Card',
        androidCropTitle: 'Crop Card',
        androidCropBlackWhiteTitle: 'Black White',
        androidCropReset: 'Reset',
      );

      if (success) {
        setState(() {
          if (isBack) {
            _backImagePath = imagePath;
          } else {
            _frontImagePath = imagePath;
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image capture cancelled')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing image: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }


  Future<void> _proceedToMetadata() async {
    if (_frontImagePath == null) return;

    // Navigate to metadata screen to enter card details with category
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CardMetadataScreen(
          frontImagePath: _frontImagePath!,
          backImagePath: _backImagePath,
          initialCategory: widget.initialCategory,
        ),
      ),
    );

    // If card was saved successfully, pop back to home
    if (result != null && result['saved'] == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    // Clean up temporary files if card wasn't saved
    _cleanupTempImages();
    super.dispose();
  }

  void _cleanupTempImages() {
    try {
      if (_frontImagePath != null) {
        final frontFile = File(_frontImagePath!);
        if (frontFile.existsSync()) frontFile.deleteSync();
      }
      if (_backImagePath != null) {
        final backFile = File(_backImagePath!);
        if (backFile.existsSync()) backFile.deleteSync();
      }
    } catch (e) {
      // Non-critical cleanup failure
    }
  }
}
