import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/home_provider.dart';
import '../providers/lock_mode_provider.dart';
import '../widgets/category_carousel_widget.dart';
import '../widgets/recent_activity_widget.dart';
import '../../card_detail/screens/id_card_detail_screen.dart';
import '../../card_detail/screens/traffic_document_detail_screen.dart';
import '../../card_detail/screens/business_card_detail_screen.dart';
import '../../card_scanner/screens/scan_card_screen.dart';
import '../../../data/models/wallet_card_model.dart';
import '../../../data/models/card_category.dart';
import '../../../data/repositories/wallet_card_repository.dart';
import '../../../data/services/card_category_service.dart';
import '../../../core/services/recent_activity_service.dart';
import '../../settings/screens/settings_screen.dart';

/// Home Screen - CashSwipe-style layout with search, recent activity, and themes
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final WalletCardRepository _cardRepository = WalletCardRepository();
  final CardCategoryService _categoryService = CardCategoryService();
  final RecentActivityService _recentActivityService = RecentActivityService();
  final GlobalKey<RecentActivityWidgetState> _recentActivityKey = GlobalKey();

  List<WalletCardModel> _scannedCards = [];
  DateTime _lastRefresh = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadData();
      _loadScannedCards();
    });
  }

  Future<void> _loadScannedCards() async {
    await _cardRepository.init();
    setState(() {
      _scannedCards = _cardRepository.getAllCards();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _autoRefreshIfStale();
    }
  }

  void _autoRefreshIfStale() {
    final now = DateTime.now();
    if (now.difference(_lastRefresh).inSeconds > 5) {
      _lastRefresh = now;
      context.read<HomeProvider>().refreshData();
      _loadScannedCards();
    }
  }

  Future<void> _handleCardTap(WalletCardModel card) async {
    // Record in recent activity
    await _recentActivityService.addActivity(card.id);

    final category = card.category;

    // Get all cards in same category, sorted
    final categoryCards =
        _scannedCards.where((c) => c.category == category).toList();
    final sortedCards = await _categoryService.sortCardsByOrder(
      category,
      categoryCards,
    );

    final indexInSorted = sortedCards.indexWhere((c) => c.id == card.id);

    if (category == CardCategory.businessIds) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BusinessCardDetailScreen(
            cards: sortedCards,
            initialIndex: indexInSorted >= 0 ? indexInSorted : 0,
          ),
        ),
      );
    } else if (category == CardCategory.trafficDocuments ||
        card.displayFormat == DisplayFormat.document) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrafficDocumentDetailScreen(
            documents: sortedCards,
            initialIndex: indexInSorted >= 0 ? indexInSorted : 0,
          ),
        ),
      );
    } else {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IDCardDetailScreen(
            cards: sortedCards,
            initialIndex: indexInSorted >= 0 ? indexInSorted : 0,
          ),
        ),
      );
    }

    // Refresh recent activity after returning
    _recentActivityKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final lockProvider = Provider.of<LockModeProvider>(context);

    return PopScope(
      canPop: !lockProvider.isLocked,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (lockProvider.isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unlock Traffic Documents to navigate'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('IDswipe'),
          actions: [
            IconButton(
              icon: const Icon(Icons.palette_outlined),
              tooltip: 'Themes',
              onPressed: () => context.push('/theme-store'),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
        body: CategoryCarouselWidget(
          walletCards: _scannedCards,
          onCardsChanged: _loadScannedCards,
          recentActivityKey: _recentActivityKey,
          onCardTap: _handleCardTap,
          onAddCard: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ScanCardScreen(),
              ),
            );

            if (result == true) {
              _loadScannedCards();
            }
          },
        ),
      ),
    );
  }
}
