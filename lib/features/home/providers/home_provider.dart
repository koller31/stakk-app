import 'package:flutter/foundation.dart';
import '../../../data/models/wallet_card_model.dart';
import '../../../data/repositories/wallet_card_repository.dart';

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

  // State
  List<WalletCardModel> _cards = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<WalletCardModel> get cards => _cards;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  int get cardCount => _cards.length;

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

      _errorMessage = null;
    } catch (e) {
      debugPrint('HomeProvider: Error loading data: $e');
      _errorMessage = 'Failed to load cards: $e';
      _cards = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
