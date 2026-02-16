import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/encrypted_image.dart';
import '../../../data/models/wallet_card_model.dart';
import '../widgets/nfc_badge_button.dart';

/// Full-screen detail view for business ID cards with NFC badge activation
class BusinessCardDetailScreen extends StatefulWidget {
  final List<WalletCardModel> cards;
  final int initialIndex;

  const BusinessCardDetailScreen({
    super.key,
    required this.cards,
    this.initialIndex = 0,
  });

  @override
  State<BusinessCardDetailScreen> createState() =>
      _BusinessCardDetailScreenState();
}

class _BusinessCardDetailScreenState extends State<BusinessCardDetailScreen>
    with WidgetsBindingObserver {
  late PageController _pageController;
  int _currentCardIndex = 0;
  double? _originalBrightness;
  final GlobalKey<NfcBadgeButtonState> _nfcButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentCardIndex = widget.initialIndex;
    final cardCount = widget.cards.length;
    final initialPage = (10000 ~/ cardCount) * cardCount + widget.initialIndex;
    _pageController = PageController(initialPage: initialPage);
    _boostBrightness();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restoreBrightness();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Sync NFC badge state on app resume
      _nfcButtonKey.currentState?.syncState();
    }
  }

  Future<void> _boostBrightness() async {
    try {
      _originalBrightness = await ScreenBrightness().current;
      await ScreenBrightness().setScreenBrightness(1.0);
    } catch (_) {}
  }

  Future<void> _restoreBrightness() async {
    try {
      if (_originalBrightness != null) {
        await ScreenBrightness().setScreenBrightness(_originalBrightness!);
      } else {
        await ScreenBrightness().resetScreenBrightness();
      }
    } catch (_) {}
  }

  WalletCardModel get _currentCard => widget.cards[_currentCardIndex];

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
          _currentCard.nickname ?? _currentCard.name,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (widget.cards.length > 1)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_currentCardIndex + 1}/${widget.cards.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            Navigator.pop(context);
          }
        },
        child: Column(
          children: [
            // Card display area
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentCardIndex = index % widget.cards.length;
                  });
                },
                itemBuilder: (context, index) {
                  final actualIndex = index % widget.cards.length;
                  return _buildCardPage(widget.cards[actualIndex]);
                },
              ),
            ),

            // Bottom bar with NFC button
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // NFC Badge Button
                  NfcBadgeButton(
                    key: _nfcButtonKey,
                    nfcAid: _currentCard.nfcAid,
                    nfcPayload: _currentCard.nfcPayload,
                  ),
                  const SizedBox(height: 12),
                  // Employee info
                  if (_currentCard.nickname != null)
                    Text(
                      _currentCard.name,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  if (widget.cards.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Swipe for more badges',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPage(WalletCardModel card) {
    return Center(
      child: Container(
        width: 320,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: AppTheme.borderRadiusLgAll,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppTheme.borderRadiusLgAll,
          child: EncryptedImage(
            path: card.frontImagePath,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
