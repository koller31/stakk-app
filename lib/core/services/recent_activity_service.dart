import 'package:shared_preferences/shared_preferences.dart';

class RecentActivityService {
  static const _key = 'recent_card_ids';
  static const _maxItems = 5;

  Future<void> addActivity(String cardId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];

    // Remove if already present, then add to front
    ids.remove(cardId);
    ids.insert(0, cardId);

    // Trim to max
    if (ids.length > _maxItems) {
      ids.removeRange(_maxItems, ids.length);
    }

    await prefs.setStringList(_key, ids);
  }

  Future<List<String>> getRecentIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
