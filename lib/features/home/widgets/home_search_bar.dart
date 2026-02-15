import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/wallet_card_model.dart';

class HomeSearchBar extends StatelessWidget {
  final List<WalletCardModel> walletCards;
  final Function(WalletCardModel)? onCardSelected;

  const HomeSearchBar({
    super.key,
    required this.walletCards,
    this.onCardSelected,
  });

  void _openSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.elevatedSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SearchSheet(
        walletCards: walletCards,
        onCardSelected: (card) {
          Navigator.pop(context);
          onCardSelected?.call(card);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openSearch(context),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.subtleBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.tertiaryText, size: 20),
            const SizedBox(width: 10),
            Text(
              'Search cards...',
              style: TextStyle(
                color: AppColors.tertiaryText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchSheet extends StatefulWidget {
  final List<WalletCardModel> walletCards;
  final Function(WalletCardModel)? onCardSelected;

  const _SearchSheet({
    required this.walletCards,
    this.onCardSelected,
  });

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _controller = TextEditingController();
  List<WalletCardModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.walletCards;
  }

  void _onChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.walletCards;
      } else {
        final lower = query.toLowerCase();
        _filtered = widget.walletCards
            .where((c) => c.name.toLowerCase().contains(lower))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.tertiaryText,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                style: TextStyle(color: AppColors.primaryText),
                decoration: InputDecoration(
                  hintText: 'Search by card name...',
                  prefixIcon: Icon(Icons.search, color: AppColors.tertiaryText),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, color: AppColors.tertiaryText),
                          onPressed: () {
                            _controller.clear();
                            _onChanged('');
                          },
                        )
                      : null,
                ),
              ),
            ),
            // Results
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No cards found',
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final card = _filtered[index];
                        return ListTile(
                          leading: Icon(
                            Icons.credit_card,
                            color: AppColors.primaryAccent,
                          ),
                          title: Text(
                            card.name,
                            style: TextStyle(color: AppColors.primaryText),
                          ),
                          subtitle: Text(
                            card.category.name,
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () => widget.onCardSelected?.call(card),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppTheme.borderRadiusSm),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
