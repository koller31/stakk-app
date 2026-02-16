import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/encrypted_image.dart';
import '../../../data/models/card_category.dart';
import '../../../data/models/wallet_card_model.dart';
import '../../card_detail/screens/id_card_detail_screen.dart';
import '../../card_detail/screens/traffic_document_detail_screen.dart';
import '../../card_detail/screens/business_card_detail_screen.dart';
import 'category_carousel_widget.dart' show DashedBorderPainter;

/// Card Stack Widget - Displays collapsed stacked cards (CashSwipe pattern)
///
/// Features:
/// - Shows up to 3 stacked cards with visible edges
/// - Double-tap on top card opens detail viewer
/// - Tap navigates to card detail
class CardStackWidget extends StatefulWidget {
  final CardCategory category;
  final List<WalletCardModel> cards;
  final VoidCallback? onAddCard;
  final Function(WalletCardModel)? onCardTap;
  final bool isLocked;

  const CardStackWidget({
    super.key,
    required this.category,
    required this.cards,
    this.onAddCard,
    this.onCardTap,
    this.isLocked = false,
  });

  @override
  State<CardStackWidget> createState() => _CardStackWidgetState();
}

class _CardStackWidgetState extends State<CardStackWidget> {
  // Stack display settings - matching CashSwipe
  static const int _maxVisibleCards = 3;
  static const double _cardOffset = 16.0;
  static const double _cardScaleFactor = 0.97;

  void _handleDoubleTap(WalletCardModel card, int cardIndex) {
    // Double-tap on top card opens the detail viewer
    final category = card.category;

    if (category == CardCategory.businessIds) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BusinessCardDetailScreen(
            cards: widget.cards,
            initialIndex: cardIndex,
          ),
        ),
      );
    } else if (category == CardCategory.trafficDocuments ||
        card.displayFormat == DisplayFormat.document) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrafficDocumentDetailScreen(
            documents: widget.cards,
            initialIndex: cardIndex,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IDCardDetailScreen(
            cards: widget.cards,
            initialIndex: cardIndex,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return _buildEmptyState();
    }

    final displayCards = widget.cards.take(_maxVisibleCards).toList();

    return Container(
      height: 260,
      padding: const EdgeInsets.only(top: _cardOffset * 2),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // Render cards in reverse order so bottom card shows at top
          for (int i = displayCards.length - 1; i >= 0; i--)
            Positioned(
              bottom: i * _cardOffset,
              child: Transform.scale(
                scale: 1 - (i * (1 - _cardScaleFactor)),
                child: _buildCard(displayCards[i], i),
              ),
            ),

          // Card count indicator if more than visible
          if (widget.cards.length > _maxVisibleCards)
            Positioned(
              top: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${widget.cards.length - _maxVisibleCards} more',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(WalletCardModel card, int index) {
    Widget cardWidget = GestureDetector(
      onTap: () => widget.onCardTap?.call(card),
      // Double-tap only on top card (index 0)
      onDoubleTap: index == 0 ? () => _handleDoubleTap(card, 0) : null,
      child: Container(
        width: 340,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: AppTheme.borderRadiusLgAll,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppTheme.borderRadiusLgAll,
          child: _buildWalletCard(card),
        ),
      ),
    );

    return cardWidget;
  }

  Widget _buildWalletCard(WalletCardModel card) {
    return SizedBox(
      width: 340,
      height: 220,
      child: EncryptedImage(
        path: card.frontImagePath,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildEmptyState() {
    final displayName = CardCategoryMetadata.getDisplayName(widget.category);

    return GestureDetector(
      onTap: widget.onAddCard,
      child: Container(
        width: 300,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: AppTheme.borderRadiusLgAll,
          border: Border.all(
            color: Colors.grey[400]!,
            width: 2,
          ),
        ),
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: Colors.grey[400]!,
            strokeWidth: 2,
            dashWidth: 8,
            dashSpace: 4,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 48,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'Add $displayName',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
