import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/encryption_service.dart';

/// Widget that decrypts and displays an encrypted image file.
/// Uses a global in-memory cache so decryption only happens once per image.
class EncryptedImage extends StatefulWidget {
  final String path;
  final BoxFit fit;
  final int? quarterTurns;

  const EncryptedImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.quarterTurns,
  });

  @override
  State<EncryptedImage> createState() => _EncryptedImageState();
}

class _EncryptedImageState extends State<EncryptedImage> {
  Uint8List? _bytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(EncryptedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final encryption = EncryptionService();
      final Uint8List bytes;

      if (widget.path.endsWith('.enc')) {
        bytes = await encryption.decryptFileToBytes(widget.path);
      } else {
        bytes = await encryption.readFileWithCache(widget.path);
      }

      if (mounted) {
        setState(() {
          _bytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_hasError || _bytes == null) {
      return const Center(
        child: Icon(Icons.broken_image, color: Colors.white38, size: 48),
      );
    }

    Widget image = Image.memory(
      _bytes!,
      fit: widget.fit,
      gaplessPlayback: true,
    );

    if (widget.quarterTurns != null) {
      image = RotatedBox(quarterTurns: widget.quarterTurns!, child: image);
    }

    return image;
  }
}
