import 'package:flutter/material.dart';
import '../../../core/widgets/encrypted_image.dart';
import '../../../data/models/card_category.dart';
import '../../../data/models/wallet_card_model.dart';
import '../../../data/repositories/wallet_card_repository.dart';
import '../../../data/services/card_category_service.dart';
import '../../card_scanner/screens/scan_card_screen.dart';
import '../../card_scanner/screens/edit_card_screen.dart';

class ExpandedCategoryScreen extends StatefulWidget {
  final CardCategory category;
  final List<WalletCardModel> cards;
  final Function(WalletCardModel)? onCardTap;
  final VoidCallback? onCardsChanged;

  const ExpandedCategoryScreen({
    super.key,
    required this.category,
    required this.cards,
    this.onCardTap,
    this.onCardsChanged,
  });

  @override
  State<ExpandedCategoryScreen> createState() => _ExpandedCategoryScreenState();
}

class _ExpandedCategoryScreenState extends State<ExpandedCategoryScreen> {
  bool _isReordering = false;
  bool _isDismissing = false;
  late List<WalletCardModel> _reorderedCards;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _reorderedCards = List.from(widget.cards);
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(ExpandedCategoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isReordering) {
      _reorderedCards = List.from(widget.cards);
    }
  }

  void _toggleReorderMode() {
    setState(() {
      _isReordering = !_isReordering;
      if (!_isReordering) {
        _saveCardOrder();
      }
    });
  }

  Future<void> _saveCardOrder() async {
    final categoryService = CardCategoryService();
    final cardIds = _reorderedCards.map((card) => card.id).toList();
    await categoryService.saveCardOrder(widget.category, cardIds);
  }

  void _showCardOptions(BuildContext context, WalletCardModel card) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Card'),
              onTap: () {
                Navigator.pop(context);
                _editCard(card);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Card', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteCard(card);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCard(WalletCardModel card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: const Text('Are you sure you want to delete this card?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = WalletCardRepository();
      await repo.init();
      await repo.deleteCard(card.id);
      if (mounted) {
        setState(() {
          _reorderedCards.removeWhere((c) => c.id == card.id);
        });
        widget.onCardsChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card deleted')),
        );
        // If no cards left, go back to home
        if (_reorderedCards.isEmpty) {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Swipe-down dismiss: over-scroll detection (single mechanism, guarded)
  void _handleScroll() {
    if (!_isDismissing &&
        _scrollController.hasClients &&
        _scrollController.position.pixels < -100) {
      _isDismissing = true;
      Navigator.of(context).pop();
    }
  }

  void _editCard(WalletCardModel card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCardScreen(card: card),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = CardCategoryMetadata.getDisplayName(widget.category);
    final iconEmoji = CardCategoryMetadata.getIcon(widget.category);

    return Scaffold(
      body: SafeArea(
          child: Column(
            children: [
              // Custom header matching CashSwipe
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(iconEmoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      '${_reorderedCards.length} cards',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Card list
              Expanded(
                child: _reorderedCards.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(iconEmoji, style: const TextStyle(fontSize: 64)),
                            const SizedBox(height: 16),
                            Text(
                              'No cards in $displayName',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            const Text('Tap + to add a card'),
                          ],
                        ),
                      )
                    : _isReordering
                        ? _buildReorderableList()
                        : _buildCardList(),
              ),
            ],
          ),
        ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_reorderedCards.length > 1)
            FloatingActionButton(
              heroTag: 'reorder',
              onPressed: _toggleReorderMode,
              child: Icon(_isReordering ? Icons.check : Icons.reorder),
            ),
          if (_reorderedCards.length > 1) const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScanCardScreen(
                    initialCategory: widget.category,
                  ),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reorderedCards.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final card = _reorderedCards.removeAt(oldIndex);
          _reorderedCards.insert(newIndex, card);
        });
      },
      itemBuilder: (context, index) {
        final card = _reorderedCards[index];
        return Card(
          key: ValueKey(card.id),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.drag_handle),
            title: Text(card.name),
            subtitle: card.nickname != null && card.nickname!.isNotEmpty
                ? Text(card.nickname!)
                : null,
            trailing: _buildCardContent(card, isListTile: true),
          ),
        );
      },
    );
  }

  Widget _buildCardList() {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(16),
      itemCount: _reorderedCards.length,
      itemBuilder: (context, index) {
        final card = _reorderedCards[index];
        return GestureDetector(
          onTap: () {
            if (widget.onCardTap != null) {
              widget.onCardTap!(card);
            }
          },
          onLongPress: () => _showCardOptions(context, card),
          child: Container(
            height: 220,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildCardContent(card),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardContent(WalletCardModel card, {bool isListTile = false}) {
    if (isListTile) {
      return SizedBox(
        width: 60,
        height: 40,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: EncryptedImage(
            path: card.frontImagePath,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: EncryptedImage(
        path: card.frontImagePath,
        fit: BoxFit.cover,
      ),
    );
  }
}
