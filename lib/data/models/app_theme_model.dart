import 'package:flutter/material.dart';

class AppThemeModel {
  final String id;
  final String name;
  final String description;
  final bool isPremium;
  final double price;
  final bool isDark;

  final Color primaryBackground;
  final Color secondaryBackground;
  final Color elevatedSurface;
  final Color primaryAccent;
  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;

  const AppThemeModel({
    required this.id,
    required this.name,
    required this.description,
    this.isPremium = false,
    this.price = 0.0,
    this.isDark = true,
    required this.primaryBackground,
    required this.secondaryBackground,
    required this.elevatedSurface,
    required this.primaryAccent,
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
  });

  // ============================================================================
  // DARK THEMES
  // ============================================================================

  static const midnightTeal = AppThemeModel(
    id: 'midnight_teal',
    name: 'Midnight Teal',
    description: 'The classic Stakk look',
    primaryBackground: Color(0xFF0A0A0F),
    secondaryBackground: Color(0xFF14141F),
    elevatedSurface: Color(0xFF1E1E2D),
    primaryAccent: Color(0xFF14B8A6),
    primaryText: Color(0xFFFFFFFF),
    secondaryText: Color(0xFFA0A0B8),
    tertiaryText: Color(0xFF6B6B7F),
  );

  static const sunsetPurple = AppThemeModel(
    id: 'sunset_purple',
    name: 'Sunset Purple',
    description: 'Rich violet tones',
    primaryBackground: Color(0xFF120A1A),
    secondaryBackground: Color(0xFF1C1226),
    elevatedSurface: Color(0xFF271A35),
    primaryAccent: Color(0xFFA78BFA),
    primaryText: Color(0xFFFFFFFF),
    secondaryText: Color(0xFFB0A0C8),
    tertiaryText: Color(0xFF7F6B9F),
  );

  static const oceanBlue = AppThemeModel(
    id: 'ocean_blue',
    name: 'Ocean Blue',
    description: 'Cool deep-sea vibes',
    primaryBackground: Color(0xFF0A0F14),
    secondaryBackground: Color(0xFF12191F),
    elevatedSurface: Color(0xFF1A242D),
    primaryAccent: Color(0xFF0EA5E9),
    primaryText: Color(0xFFFFFFFF),
    secondaryText: Color(0xFFA0B0C0),
    tertiaryText: Color(0xFF6B7F8F),
  );

  // ============================================================================
  // LIGHT THEMES
  // ============================================================================

  static const cleanWhite = AppThemeModel(
    id: 'clean_white',
    name: 'Clean White',
    description: 'Crisp minimal light',
    isDark: false,
    primaryBackground: Color(0xFFF8F9FA),
    secondaryBackground: Color(0xFFFFFFFF),
    elevatedSurface: Color(0xFFFFFFFF),
    primaryAccent: Color(0xFF14B8A6),
    primaryText: Color(0xFF1A1A2E),
    secondaryText: Color(0xFF6B7280),
    tertiaryText: Color(0xFF9CA3AF),
  );

  static const softLavender = AppThemeModel(
    id: 'soft_lavender',
    name: 'Soft Lavender',
    description: 'Gentle purple tones',
    isDark: false,
    primaryBackground: Color(0xFFF5F3FF),
    secondaryBackground: Color(0xFFFFFFFF),
    elevatedSurface: Color(0xFFFAF8FF),
    primaryAccent: Color(0xFF8B5CF6),
    primaryText: Color(0xFF1E1B4B),
    secondaryText: Color(0xFF6B6B8F),
    tertiaryText: Color(0xFFA0A0B8),
  );

  static const skyBlue = AppThemeModel(
    id: 'sky_blue',
    name: 'Sky Blue',
    description: 'Fresh open-air feel',
    isDark: false,
    primaryBackground: Color(0xFFF0F9FF),
    secondaryBackground: Color(0xFFFFFFFF),
    elevatedSurface: Color(0xFFF8FCFF),
    primaryAccent: Color(0xFF0284C7),
    primaryText: Color(0xFF0C1929),
    secondaryText: Color(0xFF64748B),
    tertiaryText: Color(0xFF94A3B8),
  );

  // ============================================================================
  // ALL THEMES
  // ============================================================================

  static const List<AppThemeModel> builtInThemes = [
    midnightTeal,
    sunsetPurple,
    oceanBlue,
    cleanWhite,
    softLavender,
    skyBlue,
  ];

  static List<AppThemeModel> get darkThemes =>
      builtInThemes.where((t) => t.isDark).toList();

  static List<AppThemeModel> get lightThemes =>
      builtInThemes.where((t) => !t.isDark).toList();
}
