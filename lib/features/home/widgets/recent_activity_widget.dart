import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/recent_activity_service.dart';
import '../../../data/models/wallet_card_model.dart';

class RecentActivityWidget extends StatefulWidget {
  final List<WalletCardModel> allCards;
  final Function(WalletCardModel)? onCardTap;

  const RecentActivityWidget({
    super.key,
    required this.allCards,
    this.onCardTap,
  });

  @override
  State<RecentActivityWidget> createState() => RecentActivityWidgetState();
}

class RecentActivityWidgetState extends State<RecentActivityWidget> {
  final RecentActivityService _service = RecentActivityService();
  List<WalletCardModel> _recentCards = [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void didUpdateWidget(RecentActivityWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allCards != widget.allCards) {
      _loadRecent();
    }
  }

  Future<void> _loadRecent() async {
    final ids = await _service.getRecentIds();
    final cards = <WalletCardModel>[];
    for (final id in ids) {
      final match = widget.allCards.where((c) => c.id == id);
      if (match.isNotEmpty) {
        cards.add(match.first);
      }
    }
    if (mounted) {
      setState(() => _recentCards = cards);
    }
  }

  void refresh() => _loadRecent();

  @override
  Widget build(BuildContext context) {
    if (_recentCards.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'No recent activity',
          style: TextStyle(
            color: AppColors.tertiaryText,
            fontSize: 12,
          ),
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _recentCards.length > 5 ? 5 : _recentCards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final card = _recentCards[index];
          return GestureDetector(
            onTap: () => widget.onCardTap?.call(card),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.subtleBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    size: 14,
                    color: AppColors.primaryAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    card.name.length > 15
                        ? '${card.name.substring(0, 15)}...'
                        : card.name,
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
