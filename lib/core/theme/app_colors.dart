import 'package:flutter/material.dart';
import '../../data/models/app_theme_model.dart';

/// IDswipe Color System
/// Supports dynamic theming via applyTheme()
/// Dark and light mode support

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ============================================================================
  // DYNAMIC THEME STATE
  // ============================================================================

  static AppThemeModel _current = AppThemeModel.midnightTeal;

  /// Apply a theme - all dynamic getters will reflect the new colors
  static void applyTheme(AppThemeModel theme) {
    _current = theme;
  }

  /// Whether the current theme is dark
  static bool get isDark => _current.isDark;

  // ============================================================================
  // DYNAMIC BACKGROUND COLORS
  // ============================================================================

  /// Primary background - main screen backgrounds
  static Color get primaryBackground => _current.primaryBackground;

  /// Secondary background - cards, containers, elevated elements
  static Color get secondaryBackground => _current.secondaryBackground;

  /// Elevated surface - modals, bottom sheets, prominent overlays
  static Color get elevatedSurface => _current.elevatedSurface;

  // ============================================================================
  // DYNAMIC TEXT COLORS
  // ============================================================================

  /// Primary text - main headings and important text
  static Color get primaryText => _current.primaryText;

  /// Secondary text - secondary information and labels
  static Color get secondaryText => _current.secondaryText;

  /// Tertiary text - hints, disabled text, subtle information
  static Color get tertiaryText => _current.tertiaryText;

  // ============================================================================
  // DYNAMIC ACCENT COLOR
  // ============================================================================

  /// Primary accent - CTAs, important amounts, primary actions
  static Color get primaryAccent => _current.primaryAccent;

  // ============================================================================
  // STATIC ACCENT COLORS (theme-independent)
  // ============================================================================

  /// Success green (#00D68F)
  static const Color successGreen = Color(0xFF00D68F);

  /// Warning yellow (#FFB800)
  static const Color warningYellow = Color(0xFFFFB800);

  /// Error red (#EF4444)
  static const Color errorRed = Color(0xFFEF4444);

  // ============================================================================
  // BRAND COLORS (static)
  // ============================================================================

  /// Brand primary color - Purple (#A78BFA)
  static const Color brandPrimary = Color(0xFFA78BFA);

  /// Brand secondary color - Blue (#0EA5E9)
  static const Color brandSecondary = Color(0xFF0EA5E9);

  // ============================================================================
  // BORDER & DIVIDER COLORS (brightness-aware)
  // ============================================================================

  /// Subtle border - adapts to theme brightness
  static Color get subtleBorder =>
      isDark ? const Color(0x1AFFFFFF) : const Color(0x1A000000);

  /// Divider color - Very subtle separator
  static Color get divider =>
      isDark ? const Color(0x0DFFFFFF) : const Color(0x0D000000);

  /// Focus border - Primary accent
  static Color get focusBorder => primaryAccent;

  // ============================================================================
  // OVERLAY COLORS (brightness-aware)
  // ============================================================================

  /// Modal backdrop
  static const Color modalBackdrop = Color(0x99000000);

  /// Pressed state overlay
  static Color get pressedOverlay => primaryAccent.withOpacity(0.05);

  /// Selected state overlay
  static Color get selectedOverlay => primaryAccent.withOpacity(0.1);

  /// Hover state overlay
  static Color get hoverOverlay =>
      isDark ? const Color(0x0DFFFFFF) : const Color(0x0D000000);

  // ============================================================================
  // GRADIENT COLORS (derived from dynamic accent)
  // ============================================================================

  /// Accent gradient start
  static Color get accentGradientStart => primaryAccent.withOpacity(0.1);

  /// Accent gradient end
  static Color get accentGradientEnd => primaryAccent.withOpacity(0.02);

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Create a linear gradient for cards
  static LinearGradient createCardGradient({
    Color? startColor,
    Color? endColor,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [
        startColor ?? accentGradientStart,
        endColor ?? accentGradientEnd,
      ],
    );
  }

  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Get contrast color (white or black) based on background
  static Color getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
