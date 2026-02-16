import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'encryption_service.dart';

/// Service for generating professional-looking business card images.
/// Creates encrypted card images when companies don't provide a card image URL.
class CardImageGenerator {
  static final CardImageGenerator _instance = CardImageGenerator._();
  factory CardImageGenerator() => _instance;
  CardImageGenerator._();

  static const double _cardWidth = 1012.0;
  static const double _cardHeight = 638.0;

  /// Generate a professional business card image and return encrypted file path.
  ///
  /// Creates a card with:
  /// - Dark gradient background
  /// - Company name and logo/initial
  /// - Employee name (centered)
  /// - Title and department
  /// - Employee ID
  /// - Colored accent strip at bottom
  ///
  /// Returns the path to the encrypted .enc file.
  Future<String> generateBusinessCard({
    required String employeeName,
    String? title,
    String? department,
    String? employeeId,
    required String companyName,
    String? companyLogoPath,
    required String cardId,
  }) async {
    // Create a recorder to build the canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, _cardWidth, _cardHeight),
    );

    // Draw gradient background
    await _drawBackground(canvas);

    // Draw company section (logo/initial + name)
    await _drawCompanySection(canvas, companyName, companyLogoPath);

    // Draw employee info (centered)
    _drawEmployeeInfo(canvas, employeeName, title, department);

    // Draw employee ID at bottom
    if (employeeId != null && employeeId.isNotEmpty) {
      _drawEmployeeId(canvas, employeeId);
    }

    // Draw accent strip at bottom
    _drawAccentStrip(canvas);

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      _cardWidth.toInt(),
      _cardHeight.toInt(),
    );

    // Convert to PNG bytes
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to generate card image bytes');
    }
    final pngBytes = byteData.buffer.asUint8List();

    // Save to temp file
    final appDir = await getApplicationDocumentsDirectory();
    final walletDir = Directory('${appDir.path}/wallet_cards');
    if (!await walletDir.exists()) {
      await walletDir.create(recursive: true);
    }

    final tempPath = '${walletDir.path}/$cardId.png';
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(pngBytes);

    // Encrypt the file
    final encryptedPath = '${walletDir.path}/$cardId.enc';
    await EncryptionService().encryptFile(tempPath, encryptedPath);

    // Delete the unencrypted temp file
    await tempFile.delete();

    return encryptedPath;
  }

  Future<void> _drawBackground(Canvas canvas) async {
    final rect = Rect.fromLTWH(0, 0, _cardWidth, _cardHeight);
    final gradient = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(0, _cardHeight),
      [
        const Color(0xFF1a1a2e),
        const Color(0xFF16213e),
      ],
    );

    final paint = Paint()..shader = gradient;
    canvas.drawRect(rect, paint);
  }

  Future<void> _drawCompanySection(
    Canvas canvas,
    String companyName,
    String? companyLogoPath,
  ) async {
    const double leftMargin = 40.0;
    const double topMargin = 40.0;

    // Draw company logo or initial circle
    if (companyLogoPath != null && companyLogoPath.isNotEmpty) {
      // Try to load and draw logo
      try {
        final logoFile = File(companyLogoPath);
        if (await logoFile.exists()) {
          final logoBytes = await logoFile.readAsBytes();
          final codec = await ui.instantiateImageCodec(
            logoBytes,
            targetWidth: 60,
            targetHeight: 60,
          );
          final frame = await codec.getNextFrame();
          canvas.drawImageRect(
            frame.image,
            Rect.fromLTWH(0, 0, frame.image.width.toDouble(), frame.image.height.toDouble()),
            const Rect.fromLTWH(leftMargin, topMargin, 60, 60),
            Paint(),
          );
        }
      } catch (e) {
        // Fall back to drawing initial if logo fails
        _drawCompanyInitial(canvas, companyName, leftMargin, topMargin);
      }
    } else {
      // Draw colored circle with first letter
      _drawCompanyInitial(canvas, companyName, leftMargin, topMargin);
    }

    // Draw company name
    final companyTextPainter = TextPainter(
      text: TextSpan(
        text: companyName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    companyTextPainter.layout();
    companyTextPainter.paint(
      canvas,
      const Offset(leftMargin + 70, topMargin + 18),
    );
  }

  void _drawCompanyInitial(
    Canvas canvas,
    String companyName,
    double x,
    double y,
  ) {
    const double circleSize = 60.0;

    // Draw circle background
    final circlePaint = Paint()
      ..color = const Color(0xFF0abde3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(x + circleSize / 2, y + circleSize / 2),
      circleSize / 2,
      circlePaint,
    );

    // Draw initial letter
    final initial = companyName.isNotEmpty ? companyName[0].toUpperCase() : '?';
    final initialPainter = TextPainter(
      text: TextSpan(
        text: initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    initialPainter.layout();
    initialPainter.paint(
      canvas,
      Offset(
        x + (circleSize - initialPainter.width) / 2,
        y + (circleSize - initialPainter.height) / 2,
      ),
    );
  }

  void _drawEmployeeInfo(
    Canvas canvas,
    String employeeName,
    String? title,
    String? department,
  ) {
    const double centerY = _cardHeight / 2;

    // Draw employee name (centered)
    final namePainter = TextPainter(
      text: TextSpan(
        text: employeeName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    namePainter.layout();
    namePainter.paint(
      canvas,
      Offset(
        (_cardWidth - namePainter.width) / 2,
        centerY - 50,
      ),
    );

    // Draw title if provided
    if (title != null && title.isNotEmpty) {
      final titlePainter = TextPainter(
        text: TextSpan(
          text: title,
          style: const TextStyle(
            color: Color(0xFFb8b8b8),
            fontSize: 18,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      titlePainter.layout();
      titlePainter.paint(
        canvas,
        Offset(
          (_cardWidth - titlePainter.width) / 2,
          centerY,
        ),
      );
    }

    // Draw department if provided
    if (department != null && department.isNotEmpty) {
      final deptPainter = TextPainter(
        text: TextSpan(
          text: department,
          style: const TextStyle(
            color: Color(0xFF8a8a8a),
            fontSize: 16,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      deptPainter.layout();
      deptPainter.paint(
        canvas,
        Offset(
          (_cardWidth - deptPainter.width) / 2,
          centerY + 30,
        ),
      );
    }
  }

  void _drawEmployeeId(Canvas canvas, String employeeId) {
    const double bottomMargin = 30.0;

    final idPainter = TextPainter(
      text: TextSpan(
        text: 'ID: $employeeId',
        style: const TextStyle(
          color: Color(0xFF6a6a6a),
          fontSize: 14,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    idPainter.layout();
    idPainter.paint(
      canvas,
      Offset(
        (_cardWidth - idPainter.width) / 2,
        _cardHeight - bottomMargin - idPainter.height - 10,
      ),
    );
  }

  void _drawAccentStrip(Canvas canvas) {
    const double stripHeight = 4.0;

    final stripPaint = Paint()
      ..color = const Color(0xFF0abde3)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        _cardHeight - stripHeight,
        _cardWidth,
        stripHeight,
      ),
      stripPaint,
    );
  }
}
