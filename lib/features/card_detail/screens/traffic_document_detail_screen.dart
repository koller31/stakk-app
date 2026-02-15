import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../../../core/mixins/brightness_boost_mixin.dart';
import '../../../core/widgets/encrypted_image.dart';
import '../../../data/models/wallet_card_model.dart';

/// Traffic Document Detail Screen - Full screen view with zoom/pan for large documents
///
/// Features:
/// - Full screen document display with PageView for multiple documents
/// - InteractiveViewer for zoom and pan on large documents (vehicle registrations)
/// - Double tap to flip between front and back for standard-sized cards
/// - Horizontal swipe to navigate between documents
/// - Vertical swipe down to dismiss
/// - "Lock & Share" button for Android screen pinning (future implementation)
/// - Supports different viewing modes for different document types
class TrafficDocumentDetailScreen extends StatefulWidget {
  final List<WalletCardModel> documents;
  final int initialIndex;

  const TrafficDocumentDetailScreen({
    super.key,
    required this.documents,
    this.initialIndex = 0,
  });

  @override
  State<TrafficDocumentDetailScreen> createState() =>
      _TrafficDocumentDetailScreenState();
}

class _TrafficDocumentDetailScreenState
    extends State<TrafficDocumentDetailScreen> with TickerProviderStateMixin, BrightnessBoostMixin {
  late PageController _pageController;
  int _currentDocumentIndex = 0;

  // Track flip state for each document (only applies to card-sized documents)
  late List<bool> _showFrontList;
  late List<AnimationController> _flipControllers;
  late List<Animation<double>> _flipAnimations;

  // Track zoom state for each document
  late List<TransformationController> _transformControllers;

  @override
  void initState() {
    super.initState();

    _currentDocumentIndex = widget.initialIndex;
    // Start at a high page number to allow bidirectional infinite scrolling
    final documentCount = widget.documents.length;
    final initialPage =
        (10000 ~/ documentCount) * documentCount + widget.initialIndex;
    _pageController = PageController(initialPage: initialPage);

    // Initialize flip states and controllers for all documents
    _showFrontList = List<bool>.filled(documentCount, true);
    _flipControllers = List.generate(
      documentCount,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );
    _flipAnimations = _flipControllers.map((controller) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Initialize transformation controllers for zoom/pan
    _transformControllers = List.generate(
      documentCount,
      (index) => TransformationController(),
    );
  }

  @override
  void dispose() {
    for (var controller in _flipControllers) {
      controller.dispose();
    }
    for (var controller in _transformControllers) {
      controller.dispose();
    }
    _pageController.dispose();
    disposeBrightness();
    super.dispose();
  }

  void _flipCard(int index) {
    if (_showFrontList[index]) {
      _flipControllers[index].forward();
    } else {
      _flipControllers[index].reverse();
    }
    setState(() {
      _showFrontList[index] = !_showFrontList[index];
    });
  }

  bool _isDocumentFormat(WalletCardModel document) {
    return document.displayFormat == DisplayFormat.document;
  }

  bool _isZoomed(int index) {
    final controller = _transformControllers[index];
    return controller.value.getMaxScaleOnAxis() > 1.0;
  }

  String _getDocumentTitle(int index) {
    final document = widget.documents[index];
    final side = _showFrontList[index] ? 'Front' : 'Back';
    return '${document.nickname ?? document.name} - $side';
  }

  void _resetZoom(int index) {
    _transformControllers[index].value = Matrix4.identity();
  }

  bool _currentDocHasBarcode() {
    return widget.documents[_currentDocumentIndex].hasBarcode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getDocumentTitle(_currentDocumentIndex),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          // Reset zoom button for document format
          if (_isDocumentFormat(widget.documents[_currentDocumentIndex]))
            IconButton(
              icon: const Icon(Icons.zoom_out_map, color: Colors.white),
              onPressed: () => _resetZoom(_currentDocumentIndex),
              tooltip: 'Reset Zoom',
            ),
          // Card counter indicator if more than one document
          if (widget.documents.length > 1)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_currentDocumentIndex + 1}/${widget.documents.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: _isZoomed(_currentDocumentIndex)
            ? const NeverScrollableScrollPhysics() // Disable swipe when zoomed
            : const PageScrollPhysics(), // Enable swipe when not zoomed
        onPageChanged: (index) {
          setState(() {
            _currentDocumentIndex = index % widget.documents.length;
          });
        },
        itemBuilder: (context, index) {
          // Use modulo to create infinite loop
          final actualIndex = index % widget.documents.length;
          return _buildDocumentPage(actualIndex);
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Brightness boost button - show when viewing back of a document with barcode
            if (!_showFrontList[_currentDocumentIndex] && _currentDocHasBarcode())
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                child: buildBrightenButton(),
              ),
            // Instructions based on format
            if (_isDocumentFormat(widget.documents[_currentDocumentIndex]))
              Text(
                'Pinch to zoom • Double tap to flip • Drag to pan',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              )
            else
              Text(
                'Double tap to flip card',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            if (widget.documents.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Swipe left/right for next document',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentPage(int index) {
    final document = widget.documents[index];
    final isDocument = _isDocumentFormat(document);

    if (isDocument) {
      // Use InteractiveViewer with flip for documents (zoom + pan + flip)
      return Center(
        child: InteractiveViewer(
          transformationController: _transformControllers[index],
          minScale: 0.5,
          maxScale: 4.0,
          boundaryMargin: const EdgeInsets.all(100),
          panEnabled: true,
          scaleEnabled: true,
          onInteractionStart: (details) {
            // Improve gesture recognition by updating state
            setState(() {});
          },
          onInteractionEnd: (details) {
            // Rebuild to update swipe physics based on zoom
            setState(() {});
          },
          child: GestureDetector(
            onDoubleTap: () => _flipCard(index),
            child: AnimatedBuilder(
              animation: _flipAnimations[index],
              builder: (context, child) {
                // Calculate the rotation angle for flip
                final angle = _flipAnimations[index].value * math.pi;

                // Determine which side to show based on rotation
                final showFront = angle < math.pi / 2;

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // Perspective
                    ..rotateY(angle), // Apply flip animation
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..rotateY(showFront ? 0 : math.pi), // Flip back image
                      child: _buildDocImage(document, showFront),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    } else {
      // Use flip animation for card-sized items (driver's license, credit card)
      return Center(
        child: GestureDetector(
          onDoubleTap: () => _flipCard(index),
          child: AnimatedBuilder(
            animation: _flipAnimations[index],
            builder: (context, child) {
              // Calculate the rotation angle for flip
              final angle = _flipAnimations[index].value * math.pi;

              // Determine which side to show based on rotation
              final showFront = angle < math.pi / 2;

              // Physical credit card size ratio
              final cardWidth = 280.0;
              final cardHeight = cardWidth * (85.60 / 53.98);

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Perspective
                  ..rotateY(angle), // Apply flip animation
                child: Container(
                  width: cardWidth,
                  height: cardHeight,
                  decoration: BoxDecoration(
                    borderRadius: AppTheme.borderRadiusLgAll,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: AppTheme.borderRadiusLgAll,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..rotateY(showFront ? 0 : math.pi), // Flip back image
                      child: _buildCardContent(index, showFront),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  Widget _buildDocImage(WalletCardModel document, bool showFront) {
    final imagePath = showFront
        ? document.frontImagePath
        : (document.backImagePath ?? document.frontImagePath);
    final image = EncryptedImage(
      path: imagePath,
      fit: BoxFit.contain,
    );
    if (!showFront) return applyBrightnessFilter(image);
    return image;
  }

  Widget _buildCardContent(int index, bool showFront) {
    final document = widget.documents[index];
    final imagePath = showFront
        ? document.frontImagePath
        : (document.backImagePath ?? document.frontImagePath);
    final image = EncryptedImage(
      path: imagePath,
      fit: BoxFit.cover,
      quarterTurns: 1,
    );
    if (!showFront) return applyBrightnessFilter(image);
    return image;
  }
}
