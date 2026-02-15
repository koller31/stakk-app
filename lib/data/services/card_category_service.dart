import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_category.dart';
import '../models/wallet_card_model.dart';

/// Service for managing card categories and user preferences
class CardCategoryService {
  static const String _prefsKey = 'card_category_preferences';

  /// Get all categories
  Future<List<CardCategory>> getCategories() async {
    return CardCategory.values.toList();
  }

  /// Check if a specific category is visible
  Future<bool> isCategoryVisible(CardCategory category) async {
    final prefs = await getPreferencesForCategory(category);
    return prefs.isVisible;
  }

  /// Get all category preferences (creates defaults if not found)
  Future<List<CategoryPreferences>> getAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_prefsKey);

    if (jsonString == null) {
      // Return default preferences for all categories
      return CardCategory.values
          .map((cat) => CategoryPreferences.defaultFor(cat))
          .toList();
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => CategoryPreferences.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading category preferences: $e');
      // Return defaults on error
      return CardCategory.values
          .map((cat) => CategoryPreferences.defaultFor(cat))
          .toList();
    }
  }

  /// Save category preferences
  Future<void> savePreferences(List<CategoryPreferences> preferences) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = preferences.map((pref) => pref.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await prefs.setString(_prefsKey, jsonString);
  }

  /// Get preferences for a specific category
  Future<CategoryPreferences> getPreferencesForCategory(CardCategory category) async {
    final allPrefs = await getAllPreferences();
    return allPrefs.firstWhere(
      (pref) => pref.category == category,
      orElse: () => CategoryPreferences.defaultFor(category),
    );
  }

  /// Update preferences for a specific category
  Future<void> updateCategoryPreferences(CategoryPreferences newPrefs) async {
    final allPrefs = await getAllPreferences();
    final index = allPrefs.indexWhere((pref) => pref.category == newPrefs.category);

    if (index != -1) {
      allPrefs[index] = newPrefs;
    } else {
      allPrefs.add(newPrefs);
    }

    await savePreferences(allPrefs);
  }

  /// Get sorted list of categories based on user preferences
  Future<List<CardCategory>> getSortedCategories({bool includeHidden = false}) async {
    final allPrefs = await getAllPreferences();

    // Filter out hidden categories if requested
    final visiblePrefs = includeHidden
        ? allPrefs
        : allPrefs.where((pref) => pref.isVisible).toList();

    // Sort by order
    visiblePrefs.sort((a, b) => a.order.compareTo(b.order));

    return visiblePrefs.map((pref) => pref.category).toList();
  }

  /// Group wallet cards by category
  Map<CardCategory, List<WalletCardModel>> groupCardsByCategory(
    List<WalletCardModel> cards,
  ) {
    final Map<CardCategory, List<WalletCardModel>> grouped = {};

    // Initialize all categories with empty lists
    for (final category in CardCategory.values) {
      grouped[category] = [];
    }

    // Group cards by their stored category (respects user's choice)
    for (final card in cards) {
      grouped[card.category]!.add(card);
    }

    return grouped;
  }

  /// Reset all category preferences to defaults
  Future<void> resetToDefaults() async {
    final defaults = CardCategory.values
        .map((cat) => CategoryPreferences.defaultFor(cat))
        .toList();
    await savePreferences(defaults);
  }

  /// Reorder categories
  Future<void> reorderCategories(List<CardCategory> newOrder) async {
    final allPrefs = await getAllPreferences();

    for (int i = 0; i < newOrder.length; i++) {
      final category = newOrder[i];
      final index = allPrefs.indexWhere((pref) => pref.category == category);

      if (index != -1) {
        allPrefs[index] = allPrefs[index].copyWith(order: i);
      }
    }

    await savePreferences(allPrefs);
  }

  /// Hide/show a category
  Future<void> setCategoryVisibility(CardCategory category, bool isVisible) async {
    final prefs = await getPreferencesForCategory(category);
    final updated = prefs.copyWith(isVisible: isVisible);
    await updateCategoryPreferences(updated);
  }

  /// Rename a category
  Future<void> renameCategory(CardCategory category, String newName) async {
    final prefs = await getPreferencesForCategory(category);
    final updated = prefs.copyWith(customName: newName);
    await updateCategoryPreferences(updated);
  }

  /// Save card order for a specific category
  /// Card IDs are stored in order, where index 0 is the top card
  Future<void> saveCardOrder(CardCategory category, List<String> cardIds) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'card_order_${category.toString()}';
    final jsonString = json.encode(cardIds);
    await prefs.setString(key, jsonString);
  }

  /// Get card order for a specific category
  /// Returns list of card IDs in order, or empty list if no order saved
  Future<List<String>> getCardOrder(CardCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'card_order_${category.toString()}';
    final jsonString = prefs.getString(key);

    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.cast<String>();
    } catch (e) {
      print('Error loading card order for $category: $e');
      return [];
    }
  }

  /// Sort cards by saved order
  /// Cards not in the saved order are placed at the end
  Future<List<WalletCardModel>> sortCardsByOrder(
    CardCategory category,
    List<WalletCardModel> cards,
  ) async {
    final order = await getCardOrder(category);
    if (order.isEmpty) return cards;

    // Create a map of card IDs to cards
    final Map<String, WalletCardModel> cardMap = {};
    for (final card in cards) {
      cardMap[card.id] = card;
    }

    // Sort cards based on saved order
    final List<WalletCardModel> sortedCards = [];
    final Set<String> addedIds = {};

    // Add cards in saved order
    for (final id in order) {
      if (cardMap.containsKey(id)) {
        sortedCards.add(cardMap[id]!);
        addedIds.add(id);
      }
    }

    // Add any remaining cards that weren't in the saved order
    for (final card in cards) {
      if (!addedIds.contains(card.id)) {
        sortedCards.add(card);
      }
    }

    return sortedCards;
  }
}
