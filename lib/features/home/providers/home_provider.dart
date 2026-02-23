import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import '../../../core/services/encryption_service.dart';
import '../../../data/models/card_category.dart';
import '../../../data/models/wallet_card_model.dart';
import '../../../data/repositories/wallet_card_repository.dart';
import '../../../data/services/card_category_service.dart';

/// HomeProvider manages the state for the home screen
///
/// Responsibilities:
/// - Load and manage wallet cards
/// - Handle loading states
/// - Handle errors
/// - Support pull-to-refresh
/// - Add/delete cards
class HomeProvider extends ChangeNotifier {
  final WalletCardRepository _cardRepository = WalletCardRepository();
  final CardCategoryService _categoryService = CardCategoryService();

  // State
  List<WalletCardModel> _cards = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Pre-computed category data for instant carousel rendering
  List<CardCategory> _sortedCategories = [];
  Map<CardCategory, List<WalletCardModel>> _groupedCards = {};

  // Getters
  List<WalletCardModel> get cards => _cards;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  int get cardCount => _cards.length;
  List<CardCategory> get sortedCategories => _sortedCategories;
  Map<CardCategory, List<WalletCardModel>> get groupedCards => _groupedCards;

  /// Load initial data
  /// This should be called when the home screen is first displayed
  Future<void> loadData() async {
    if (_isLoading) return;

    debugPrint('HomeProvider: Starting loadData');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Initialize repository
      await _cardRepository.init();

      // Load all cards
      _cards = _cardRepository.getAllCards();
      debugPrint('HomeProvider: Loaded ${_cards.length} cards');

      // Pre-compute categories so carousel renders instantly
      await _preComputeCategories();

      _errorMessage = null;
    } catch (e) {
      debugPrint('HomeProvider: Error loading data: $e');
      _errorMessage = 'Failed to load cards: $e';
      _cards = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Pre-warm image cache in background after UI renders.
    // Cards appear immediately; cache fills for smooth swipe/flip.
    _preWarmImageCache();
  }

  /// Refresh data (for pull-to-refresh)
  Future<void> refreshData() async {
    debugPrint('HomeProvider: Starting refresh');
    _errorMessage = null;
    notifyListeners();

    try {
      // Ensure repository is initialized
      await _cardRepository.init();

      // Reload all cards
      _cards = _cardRepository.getAllCards();
      debugPrint('HomeProvider: Refreshed ${_cards.length} cards');

      _errorMessage = null;
    } catch (e) {
      debugPrint('HomeProvider: Error refreshing data: $e');
      _errorMessage = 'Failed to refresh cards: $e';
    } finally {
      notifyListeners();
    }
  }

  /// Add a new card
  Future<void> addCard(WalletCardModel card) async {
    try {
      await _cardRepository.init();
      await _cardRepository.addCard(card);
      _cards = _cardRepository.getAllCards();
      _errorMessage = null;
      notifyListeners();
      debugPrint('HomeProvider: Card added successfully');
    } catch (e) {
      debugPrint('HomeProvider: Error adding card: $e');
      _errorMessage = 'Failed to add card: $e';
      notifyListeners();
    }
  }

  /// Delete a card by ID
  Future<void> deleteCard(String id) async {
    try {
      await _cardRepository.init();
      await _cardRepository.deleteCard(id);
      _cards = _cardRepository.getAllCards();
      _errorMessage = null;
      notifyListeners();
      debugPrint('HomeProvider: Card deleted successfully');
    } catch (e) {
      debugPrint('HomeProvider: Error deleting card: $e');
      _errorMessage = 'Failed to delete card: $e';
      notifyListeners();
    }
  }

  /// Pre-compute sorted categories and grouped cards so the carousel
  /// can render on its first frame without any async delay.
  Future<void> _preComputeCategories() async {
    _sortedCategories = await _categoryService.getSortedCategories();
    final grouped = _categoryService.groupCardsByCategory(_cards);

    final Map<CardCategory, List<WalletCardModel>> sortedGrouped = {};
    for (final entry in grouped.entries) {
      sortedGrouped[entry.key] =
          await _categoryService.sortCardsByOrder(entry.key, entry.value);
    }
    _groupedCards = sortedGrouped;
  }

  /// Pre-warm the full image pipeline for all cards:
  /// 1. Decrypt bytes into EncryptionService's LRU cache
  /// 2. Decode PNG/JPEG into Flutter's ImageCache (pixel data ready to paint)
  /// This eliminates both decryption jank AND codec-decode jank.
  Future<void> _preWarmImageCache() async {
    final encryption = EncryptionService();
    final futures = <Future>[];

    for (final card in _cards) {
      futures.add(_preWarmImage(encryption, card.frontImagePath));
      if (card.backImagePath != null) {
        futures.add(_preWarmImage(encryption, card.backImagePath!));
      }
    }

    await Future.wait(futures);
    debugPrint('HomeProvider: Pre-warmed ${futures.length} images');
  }

  /// Decrypt a single image and pre-decode it into Flutter's ImageCache.
  Future<void> _preWarmImage(EncryptionService encryption, String path) async {
    try {
      final bytes = await encryption.decryptFileToBytes(path);
      // Resolve the MemoryImage to trigger codec decode into Flutter's ImageCache.
      // Uses the same bytes reference that EncryptedImage will use, so cache hits.
      final completer = Completer<void>();
      final provider = MemoryImage(bytes);
      final stream = provider.resolve(const ImageConfiguration());
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, sync) {
          if (!completer.isCompleted) completer.complete();
          stream.removeListener(listener);
        },
        onError: (e, st) {
          if (!completer.isCompleted) completer.complete();
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
      await completer.future;
    } catch (e) {
      debugPrint('HomeProvider: Pre-warm failed for $path: $e');
    }
  }

  /// Re-warm the image cache on app resume to prevent first-swipe jank.
  Future<void> reWarmImageCache() async {
    if (_cards.isEmpty) return;
    await _preWarmImageCache();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _cards = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
    debugPrint('HomeProvider: State reset');
  }
}
