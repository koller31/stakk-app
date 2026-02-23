import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/card_category.dart';
import '../../../data/models/wallet_card_model.dart';
import '../../../data/services/card_category_service.dart';
import '../../../core/services/screen_pinning_service.dart';
import '../screens/expanded_category_screen.dart';
import '../../auth/screens/pin_entry_screen.dart';
import '../../card_scanner/screens/scan_card_screen.dart';
import '../../business/screens/add_business_connection_screen.dart';
import '../providers/home_provider.dart';
import '../providers/lock_mode_provider.dart';
import 'card_stack_widget.dart';
import 'home_search_bar.dart';
import 'recent_activity_widget.dart';

/// Category Carousel Widget - CashSwipe-style horizontal carousel
///
/// Layout:
/// - Spacer at top (blank space for future use)
/// - Fixed category title right above cards
/// - Constrained-height PageView for card stacks only
/// - Fixed Pin/Lock buttons at bottom
class CategoryCarouselWidget extends StatefulWidget {
  final List<WalletCardModel> walletCards;
  final Function(WalletCardModel)? onCardTap;
  final VoidCallback? onAddCard;
  final VoidCallback? onCardsChanged;
  final GlobalKey<RecentActivityWidgetState>? recentActivityKey;

  const CategoryCarouselWidget({
    super.key,
    required this.walletCards,
    this.onCardTap,
    this.onAddCard,
    this.onCardsChanged,
    this.recentActivityKey,
  });

  @override
  State<CategoryCarouselWidget> createState() =>
      _CategoryCarouselWidgetState();
}

class _CategoryCarouselWidgetState extends State<CategoryCarouselWidget> {
  final PageController _pageController = PageController();
  final CardCategoryService _categoryService = CardCategoryService();
  final ScreenPinningService _screenPinningService = ScreenPinningService();

  List<CardCategory> _sortedCategories = [];
  Map<CardCategory, List<WalletCardModel>> _groupedCards = {};
  int _currentPageIndex = 0;
  bool _isScreenPinned = false;

  // Cached - recomputed only when data changes, not on every build
  List<CardCategory> _nonEmptyCategories = [];
  int _totalItems = 1;

  void _recomputeCategories() {
    _nonEmptyCategories = _sortedCategories.where((cat) {
      final cards = _groupedCards[cat] ?? [];
      return cards.isNotEmpty;
    }).toList();
    _totalItems = _nonEmptyCategories.length + 1;
  }

  @override
  void initState() {
    super.initState();

    // Use HomeProvider's pre-computed categories for instant first render
    final homeProvider = context.read<HomeProvider>();
    if (homeProvider.sortedCategories.isNotEmpty) {
      _sortedCategories = homeProvider.sortedCategories;
      _groupedCards = homeProvider.groupedCards;
      _recomputeCategories();
    }

    _loadCategories();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_nonEmptyCategories.isNotEmpty) {
        final initialPage = 10000 * _totalItems;
        _pageController.jumpToPage(initialPage);
      }
    });
  }

  @override
  void didUpdateWidget(CategoryCarouselWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.walletCards != widget.walletCards) {
      _loadCategories();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await _categoryService.getSortedCategories();
    final grouped = _categoryService.groupCardsByCategory(widget.walletCards);

    final Map<CardCategory, List<WalletCardModel>> sortedGrouped = {};
    for (final entry in grouped.entries) {
      final category = entry.key;
      final cards = entry.value;
      final sortedCards =
          await _categoryService.sortCardsByOrder(category, cards);
      sortedGrouped[category] = sortedCards;
    }

    setState(() {
      _sortedCategories = categories;
      _groupedCards = sortedGrouped;
      _recomputeCategories();
    });
  }

  void _onPageChanged(int rawIndex) {
    final newIndex = rawIndex % _totalItems;
    // Only rebuild if the actual category changed
    if (newIndex != _currentPageIndex) {
      setState(() {
        _currentPageIndex = newIndex;
      });
    }
  }

  Future<void> _handleScreenPinToggle(BuildContext context) async {
    if (_isScreenPinned) {
      final success = await _screenPinningService.stopScreenPinning();
      if (success && context.mounted) {
        setState(() => _isScreenPinned = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Screen unpinned'), backgroundColor: Colors.green),
        );
      }
    } else {
      final success = await _screenPinningService.startScreenPinning();
      if (success && context.mounted) {
        setState(() => _isScreenPinned = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Screen pinned - Device locked to this app'),
              backgroundColor: Colors.orange),
        );
      }
    }
  }

  Future<void> _handleLockToggle(
      BuildContext context, LockModeProvider lockProvider) async {
    if (lockProvider.isLocked) {
      final enteredPin = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => const PinEntryScreen(
            mode: PinEntryMode.unlock,
            title: 'Unlock Traffic Documents',
            subtitle: 'Enter your PIN to unlock',
          ),
        ),
      );

      if (enteredPin != null) {
        final success = await lockProvider.disableLockMode(enteredPin);
        if (context.mounted && !success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Incorrect PIN'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      if (!lockProvider.hasPin) {
        final newPin = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (context) => const PinEntryScreen(
              mode: PinEntryMode.set,
              title: 'Set Lock PIN',
              subtitle: 'Create a PIN to lock Traffic Documents',
            ),
          ),
        );

        if (newPin != null) {
          await lockProvider.setPin(newPin);
          await lockProvider.enableLockMode();
        }
      } else {
        await lockProvider.enableLockMode();
      }
    }
  }

  Future<void> _showCategorySelectionDialog(BuildContext context) async {
    final selectedCategory = await showDialog<CardCategory>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Card Type'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: CardCategory.values.map((category) {
                final displayName =
                    CardCategoryMetadata.getDisplayName(category);
                final icon = CardCategoryMetadata.getIcon(category);
                return ListTile(
                  leading: Text(icon, style: const TextStyle(fontSize: 24)),
                  title: Text(displayName),
                  onTap: () => Navigator.of(context).pop(category),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedCategory != null && context.mounted) {
      // Business IDs feature hidden until NFC badge OAuth workflow is validated.
      // To re-enable, replace this block with navigation to AddBusinessConnectionScreen.
      if (selectedCategory == CardCategory.businessIds) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Business badge feature coming soon')),
          );
        }
        return;
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ScanCardScreen(initialCategory: selectedCategory),
        ),
      );

      if (result == true) {
        _loadCategories();
        widget.onCardsChanged?.call();
      }
    }
  }

  void _handleExpandCategory(BuildContext context, CardCategory category,
      List<WalletCardModel> cards) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExpandedCategoryScreen(
          category: category,
          cards: cards,
          onCardTap: widget.onCardTap,
          onCardsChanged: widget.onCardsChanged,
        ),
      ),
    );
  }

  /// Open bottom sheet to reorder category types
  void _showReorderCategoriesSheet(BuildContext context) {
    // Start with all categories that have cards (the ones visible in carousel)
    final reorderList = List<CardCategory>.from(_nonEmptyCategories);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.elevatedSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  // Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Text(
                          'Reorder Categories',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            // Save the new order
                            await _categoryService.reorderCategories(reorderList);
                            if (context.mounted) {
                              Navigator.pop(sheetContext);
                              _loadCategories();
                            }
                          },
                          child: Text(
                            'Done',
                            style: TextStyle(
                              color: AppColors.primaryAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Drag to reorder how card types appear in your carousel',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Reorderable list
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      itemCount: reorderList.length,
                      onReorder: (oldIndex, newIndex) {
                        setSheetState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final item = reorderList.removeAt(oldIndex);
                          reorderList.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final cat = reorderList[index];
                        final icon = CardCategoryMetadata.getIcon(cat);
                        final name = CardCategoryMetadata.getDisplayName(cat);
                        final count = (_groupedCards[cat] ?? []).length;

                        return Card(
                          key: ValueKey(cat),
                          color: AppColors.secondaryBackground,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              Icons.drag_handle,
                              color: AppColors.tertiaryText,
                            ),
                            title: Row(
                              children: [
                                Text(icon, style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 10),
                                Text(
                                  name,
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              '$count cards',
                              style: TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Build the fixed category title row
  Widget _buildCategoryTitle(BuildContext context) {
    // On the "Add Card" page, show no title
    if (_currentPageIndex >= _nonEmptyCategories.length) {
      return const SizedBox(height: 32);
    }

    final category = _nonEmptyCategories[_currentPageIndex];
    final categoryName = CardCategoryMetadata.getDisplayName(category);
    final categoryIcon = CardCategoryMetadata.getIcon(category);
    final cardCount = (_groupedCards[category] ?? []).length;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppTheme.spacingSm,
        left: AppTheme.spacingMd,
        right: AppTheme.spacingSm,
        bottom: 4,
      ),
      child: Row(
        children: [
          Text(categoryIcon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            categoryName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 6),
          Text(
            '($cardCount)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.tertiaryText,
                ),
          ),
          const Spacer(),
          // Reorder categories button
          if (_nonEmptyCategories.length > 1)
            GestureDetector(
              onTap: () => _showReorderCategoriesSheet(context),
              child: Icon(
                Icons.swap_vert,
                size: 22,
                color: AppColors.secondaryText,
              ),
            ),
        ],
      ),
    );
  }

  /// Build the fixed Pin/Lock button bar
  Widget _buildButtonBar(
      BuildContext context, LockModeProvider lockProvider, bool hasCards) {
    if (!hasCards) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Screen Pin button
          Material(
            color: _isScreenPinned
                ? Colors.blue.shade100
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(24),
            elevation: 4,
            child: InkWell(
              onTap: () => _handleScreenPinToggle(context),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isScreenPinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      size: 20,
                      color: _isScreenPinned
                          ? Colors.blue.shade700
                          : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isScreenPinned ? 'Pinned' : 'Pin App',
                      style: TextStyle(
                        color: _isScreenPinned
                            ? Colors.blue.shade700
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Lock button
          Material(
            color: lockProvider.isLocked
                ? Colors.orange.shade100
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(24),
            elevation: 4,
            child: InkWell(
              onTap: () => _handleLockToggle(context, lockProvider),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      lockProvider.isLocked ? Icons.lock : Icons.lock_open,
                      size: 20,
                      color: lockProvider.isLocked
                          ? Colors.orange.shade700
                          : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      lockProvider.isLocked ? 'Locked' : 'Lock',
                      style: TextStyle(
                        color: lockProvider.isLocked
                            ? Colors.orange.shade700
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_sortedCategories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Count total cards
    int totalCards = 0;
    for (var cards in _groupedCards.values) {
      totalCards += cards.length;
    }

    // Show spinner while data is still loading (don't flash "Add Card")
    final homeProvider = context.watch<HomeProvider>();
    if (totalCards == 0 && (homeProvider.isLoading || homeProvider.cards.isNotEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }

    // No cards - show single add button
    if (totalCards == 0) {
      return Center(
        child: GestureDetector(
          onTap: () => _showCategorySelectionDialog(context),
          child: Container(
            width: 300,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: AppTheme.borderRadiusLgAll,
              border: Border.all(color: Colors.grey[400]!, width: 2),
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
                    Icon(Icons.add_circle_outline,
                        size: 48, color: Colors.grey[600]),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'Add Card',
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
        ),
      );
    }

    final nonEmpty = _nonEmptyCategories;

    return Consumer<LockModeProvider>(
      builder: (context, lockProvider, child) {
        return Column(
          children: [
            // Content area above cards
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Search bar
                    HomeSearchBar(
                      walletCards: widget.walletCards,
                      onCardSelected: widget.onCardTap,
                    ),
                    const SizedBox(height: 16),
                    // Recent activity label
                    Text(
                      'Recent',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Recent activity chips
                    RecentActivityWidget(
                      key: widget.recentActivityKey,
                      allCards: widget.walletCards,
                      onCardTap: widget.onCardTap,
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),

            // FIXED: Category title (right above cards)
            _buildCategoryTitle(context),

            // CONSTRAINED: Card carousel (just the card stack area)
            SizedBox(
              height: 296,
              child: PageView.builder(
                controller: _pageController,
                physics:
                    lockProvider.isLocked
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(),
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final actualIndex = index % _totalItems;

                  // Last item is "Add Card"
                  if (actualIndex == nonEmpty.length) {
                    return Center(
                      child: GestureDetector(
                        onTap: () => _showCategorySelectionDialog(context),
                        child: Container(
                          width: 300,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: AppTheme.borderRadiusLgAll,
                            border: Border.all(
                                color: Colors.grey[400]!, width: 2),
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
                                  Icon(Icons.add_circle_outline,
                                      size: 48, color: Colors.grey[600]),
                                  const SizedBox(height: AppTheme.spacingSm),
                                  Text(
                                    'Add Card',
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
                      ),
                    );
                  }

                  // Regular category pages - just the card stack
                  final category = nonEmpty[actualIndex];
                  final cards = _groupedCards[category] ?? [];

                  return _CategoryPage(
                    category: category,
                    cards: List<WalletCardModel>.from(cards),
                    onCardTap: widget.onCardTap,
                    onAddCard: () => _showCategorySelectionDialog(context),
                    onCardsChanged: widget.onCardsChanged,
                    isLocked: lockProvider.isLocked,
                    onExpand: () => _handleExpandCategory(
                        context, category, List.from(cards)),
                  );
                },
              ),
            ),

            // FIXED: Pin/Lock buttons (outside carousel)
            _buildButtonBar(context, lockProvider, totalCards > 0),

            // Bottom safe area padding
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        );
      },
    );
  }
}

/// Dashed border painter
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(12),
        ),
      );

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final dashPaint = Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..style = PaintingStyle.stroke;

    double distance = 0.0;
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        final start = metric.getTangentForOffset(distance);
        final end = metric.getTangentForOffset(distance + dashWidth);
        if (start != null && end != null) {
          canvas.drawLine(start.position, end.position, dashPaint);
        }
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Individual category page - card stack with swipe-up detection via Listener
/// Uses Listener instead of GestureDetector to avoid competing with
/// PageView's horizontal drag in the gesture arena.
class _CategoryPage extends StatefulWidget {
  final CardCategory category;
  final List<WalletCardModel> cards;
  final Function(WalletCardModel)? onCardTap;
  final VoidCallback? onAddCard;
  final VoidCallback? onCardsChanged;
  final bool isLocked;
  final VoidCallback? onExpand;

  const _CategoryPage({
    required this.category,
    required this.cards,
    this.onCardTap,
    this.onAddCard,
    this.onCardsChanged,
    this.isLocked = false,
    this.onExpand,
  });

  @override
  State<_CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<_CategoryPage> {
  Offset? _pointerStart;

  @override
  Widget build(BuildContext context) {
    // Listener doesn't enter the gesture arena, so it won't
    // compete with PageView's horizontal scrolling
    return Listener(
      onPointerDown: (event) {
        _pointerStart = event.position;
      },
      onPointerUp: (event) {
        if (_pointerStart != null) {
          final delta = event.position - _pointerStart!;
          // Detect a clear upward swipe: moved up >80px and more vertical than horizontal
          if (delta.dy < -80 && delta.dy.abs() > delta.dx.abs()) {
            widget.onExpand?.call();
          }
          _pointerStart = null;
        }
      },
      child: Center(
        child: CardStackWidget(
          category: widget.category,
          cards: widget.cards,
          onCardTap: widget.onCardTap,
          onAddCard: widget.onAddCard,
          isLocked: widget.isLocked,
        ),
      ),
    );
  }
}
