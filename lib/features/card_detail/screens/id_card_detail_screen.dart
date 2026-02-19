import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/mixins/brightness_boost_mixin.dart';
import '../../../core/widgets/encrypted_image.dart';
import '../../../data/models/wallet_card_model.dart';

/// ID Card Detail Screen - Full screen view of ID cards with flip animation and swipe navigation
///
/// Features:
/// - Full screen ID card display with PageView for multiple cards
/// - Double tap to flip between front and back
/// - Horizontal swipe to navigate between cards
/// - 3D flip animation
/// - Per-side barcode brighten button (user-controlled)
/// - Supports both mock ID cards (asset images) and scanned cards (file images)
/// - Backward compatible with single card usage
class IDCardDetailScreen extends StatefulWidget {
  // Legacy single card support
  final String? frontImagePath;
  final String? backImagePath;
  final bool isMockCard;

  // New multi-card support
  final List<WalletCardModel>? cards;
  final int initialIndex;

  const IDCardDetailScreen({
    super.key,
    this.frontImagePath,
    this.backImagePath,
    this.isMockCard = true,
    this.cards,
    this.initialIndex = 0,
  });

  @override
  State<IDCardDetailScreen> createState() => _IDCardDetailScreenState();
}

class _IDCardDetailScreenState extends State<IDCardDetailScreen>
    with TickerProviderStateMixin, BrightnessBoostMixin {
  late PageController _pageController;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  int _currentCardIndex = 0;
  // Track flip state for each card
  late List<bool> _showFrontList;
  late List<AnimationController> _flipControllers;
  late List<Animation<double>> _flipAnimations;

  double _targetRotation = 0.0; // 0 for portrait, pi/2 or -pi/2 for landscape

  @override
  void initState() {
    super.initState();

    _currentCardIndex = widget.initialIndex;
    // Start at a high page number to allow bidirectional infinite scrolling
    // Must ensure (initialPage % cardCount) == initialIndex
    final cardCount = _getCardCount();
    final initialPage = (10000 ~/ cardCount) * cardCount + widget.initialIndex;
    _pageController = PageController(initialPage: initialPage);

    // Initialize flip states and controllers for all cards
    _showFrontList = List<bool>.filled(cardCount, true);
    _flipControllers = List.generate(
      cardCount,
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

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    _startOrientationListener();
  }

  int _getCardCount() {
    if (widget.cards != null) {
      return widget.cards!.length;
    }
    return 1; // Single card mode
  }

  void _startOrientationListener() {
    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      // Determine device orientation based on accelerometer
      const double sensitivityThreshold = 4.0;
      double newRotation = 0.0;

      if (event.x.abs() > event.y.abs() && event.x.abs() > sensitivityThreshold) {
        if (event.x < 0) {
          newRotation = math.pi;
        } else {
          newRotation = 0.0;
        }
      } else {
        newRotation = 0.0;
      }

      if (newRotation != _targetRotation) {
        setState(() {
          _targetRotation = newRotation;
          _rotationAnimation = Tween<double>(
            begin: _rotationAnimation.value,
            end: _targetRotation,
          ).animate(
            CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
          );
          _rotationController.forward(from: 0.0);
        });
      }
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    for (var controller in _flipControllers) {
      controller.dispose();
    }
    _rotationController.dispose();
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

  String _getCardTitle(int index) {
    if (widget.cards != null && widget.cards!.isNotEmpty) {
      final card = widget.cards![index];
      return '${card.nickname ?? card.name} - ${_showFrontList[index] ? 'Front' : 'Back'}';
    }
    return 'ID Card - ${_showFrontList[index] ? 'Front' : 'Back'}';
  }

  /// Whether the current side should show the brighten button.
  /// Uses per-side fields if set, otherwise falls back to legacy hasBarcode on back.
  bool _shouldShowBrighten(int index) {
    final showingFront = _showFrontList[index];
    if (widget.cards != null && widget.cards!.isNotEmpty) {
      final card = widget.cards![index];
      // If per-side flags are explicitly set, use them
      if (card.hasFrontBarcode || card.hasBackBarcode) {
        return showingFront ? card.hasFrontBarcode : card.hasBackBarcode;
      }
      // Legacy: use hasBarcode field on back only
      return !showingFront && card.hasBarcode;
    }
    // Single card legacy mode: show on back
    return !showingFront;
  }

  /// Whether to apply brightness filter on a specific side.
  bool _shouldApplyBrightness(int index, bool showFront) {
    if (widget.cards != null && widget.cards!.isNotEmpty) {
      final card = widget.cards![index];
      if (card.hasFrontBarcode || card.hasBackBarcode) {
        return showFront ? card.hasFrontBarcode : card.hasBackBarcode;
      }
      return !showFront && card.hasBarcode;
    }
    return !showFront;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getCardTitle(_currentCardIndex),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          // Card counter indicator
          if (widget.cards != null && widget.cards!.length > 1)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_currentCardIndex + 1}/${widget.cards!.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          // Detect downward swipe to exit
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            Navigator.pop(context);
          }
        },
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentCardIndex = index % _getCardCount();
            });
          },
          itemBuilder: (context, index) {
            final actualIndex = index % _getCardCount();
            return _buildCardPage(actualIndex);
          },
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Brightness boost button - show when current side has a barcode
            if (_shouldShowBrighten(_currentCardIndex))
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                child: buildBrightenButton(),
              ),
            Text(
              'Double tap to flip card',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            if (widget.cards != null && widget.cards!.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Swipe left/right for next card',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      ),
                ),
              ),
          ],
        ),
      ),
        ),
      ],
    );
  }

  Widget _buildCardPage(int index) {
    return Center(
      child: GestureDetector(
        onDoubleTap: () => _flipCard(index),
        child: AnimatedBuilder(
          animation: Listenable.merge([_flipAnimations[index], _rotationAnimation]),
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
                ..rotateZ(_rotationAnimation.value) // Apply device orientation rotation
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
                      ..rotateY(showFront ? 0 : math.pi), // Flip the back image
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

  Widget _buildCardContent(int index, bool showFront) {
    Widget cardImage;

    // Multi-card mode
    if (widget.cards != null && widget.cards!.isNotEmpty) {
      final card = widget.cards![index];
      final imagePath = showFront
          ? card.frontImagePath
          : (card.backImagePath ?? card.frontImagePath);
      cardImage = EncryptedImage(
        path: imagePath,
        fit: BoxFit.cover,
        quarterTurns: 1,
      );
    }
    // Legacy single card mode
    else if (widget.isMockCard) {
      cardImage = Image.asset(
        showFront
            ? 'assets/images/MockIDFront90.png'
            : 'assets/images/MockIDBack90.png',
        fit: BoxFit.cover,
      );
    } else {
      final imagePath = showFront
          ? widget.frontImagePath!
          : (widget.backImagePath ?? widget.backImagePath!);
      cardImage = EncryptedImage(
        path: imagePath,
        fit: BoxFit.cover,
        quarterTurns: 1,
      );
    }

    // Apply brightness filter on the side that has a barcode
    if (_shouldApplyBrightness(index, showFront)) {
      return applyBrightnessFilter(cardImage);
    }

    return cardImage;
  }
}
