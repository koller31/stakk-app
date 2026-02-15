import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/app_theme_model.dart';
import '../../../core/theme/app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  static const _themeKey = 'selected_theme_id';

  AppThemeModel _currentTheme = AppThemeModel.midnightTeal;

  AppThemeModel get currentTheme => _currentTheme;

  List<AppThemeModel> get allThemes => AppThemeModel.builtInThemes;

  ThemeProvider() {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_themeKey) ?? 'midnight_teal';
    final theme = allThemes.firstWhere(
      (t) => t.id == savedId,
      orElse: () => AppThemeModel.midnightTeal,
    );
    _currentTheme = theme;
    AppColors.applyTheme(theme);
    notifyListeners();
  }

  Future<void> setTheme(String id) async {
    final theme = allThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => AppThemeModel.midnightTeal,
    );
    _currentTheme = theme;
    AppColors.applyTheme(theme);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, id);
    notifyListeners();
  }
}
