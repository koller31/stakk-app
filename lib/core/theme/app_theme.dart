import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// IDswipe App Theme
/// Complete ThemeData configuration based on UI/UX Specifications v1.0
/// Optimized for dark mode with Gen Z aesthetic

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // ============================================================================
  // TYPOGRAPHY
  // ============================================================================

  /// Font family - Inter (with system fallback)
  static const String fontFamily = 'Inter';

  /// Text theme configuration (dynamic - reads current theme colors)
  static TextTheme get textTheme => TextTheme(
    // Hero text - Account balance (48px / 3rem)
    displayLarge: TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: -0.96, // -0.02em
      color: AppColors.primaryAccent,
    ),

    // H1 - Screen titles (32px / 2rem)
    displayMedium: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.32, // -0.01em
      color: AppColors.primaryText,
    ),

    // H2 - Section headers (24px / 1.5rem)
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: AppColors.primaryText,
    ),

    // H3 - Card titles (18px / 1.125rem)
    headlineMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: AppColors.primaryText,
    ),

    // Body Large (16px / 1rem)
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.primaryText,
    ),

    // Body Regular (14px / 0.875rem)
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.primaryText,
    ),

    // Body Small - Labels, hints (12px / 0.75rem)
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: AppColors.secondaryText,
    ),

    // Caption - Metadata (10px / 0.625rem)
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      height: 1.3,
      letterSpacing: 0.5, // 0.05em
      color: AppColors.tertiaryText,
    ),
  );

  // ============================================================================
  // SPACING
  // ============================================================================

  /// Spacing scale based on 4px base unit
  static const double spacingXs = 4.0; // 0.25rem
  static const double spacingSm = 8.0; // 0.5rem
  static const double spacingMd = 16.0; // 1rem
  static const double spacingLg = 24.0; // 1.5rem
  static const double spacingXl = 32.0; // 2rem
  static const double spacing2xl = 48.0; // 3rem
  static const double spacing3xl = 64.0; // 4rem

  // Aliases for settings screen compatibility
  static const double paddingSmall = spacingSm;
  static const double paddingMedium = spacingMd;
  static const double paddingLarge = spacingLg;
  static const double radiusMedium = borderRadiusMd;

  /// Screen padding
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: 20.0);
  static const EdgeInsets screenPaddingVertical = EdgeInsets.symmetric(vertical: 16.0);
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0);

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================

  static const double borderRadiusSm = 8.0;
  static const double borderRadiusMd = 12.0;
  static const double borderRadiusLg = 16.0;
  static const double borderRadiusXl = 24.0;
  static const double borderRadiusRound = 9999.0;

  static const BorderRadius borderRadiusSmAll = BorderRadius.all(Radius.circular(borderRadiusSm));
  static const BorderRadius borderRadiusMdAll = BorderRadius.all(Radius.circular(borderRadiusMd));
  static const BorderRadius borderRadiusLgAll = BorderRadius.all(Radius.circular(borderRadiusLg));
  static const BorderRadius borderRadiusXlAll = BorderRadius.all(Radius.circular(borderRadiusXl));

  // ============================================================================
  // CARD GRADIENT COLORS
  // ============================================================================

  static const Color cardBackgroundStart = Color(0xFF1E1E2D);
  static const Color cardBackgroundEnd = Color(0xFF14141F);

  // ============================================================================
  // SHADOWS & ELEVATION
  // ============================================================================

  /// Level 1 - Subtle (small cards, floating buttons)
  static List<BoxShadow> get shadowLevel1 => [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          offset: const Offset(0, 2),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ];

  /// Level 2 - Standard (bills in carousel, contact cards)
  static List<BoxShadow> get shadowLevel2 => [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          offset: const Offset(0, 4),
          blurRadius: 16,
          spreadRadius: 0,
        ),
      ];

  /// Level 3 - Prominent (modals, active bill selection)
  static List<BoxShadow> get shadowLevel3 => [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          offset: const Offset(0, 8),
          blurRadius: 32,
          spreadRadius: 0,
        ),
      ];

  /// Level 4 - Dramatic (bill during swipe animation)
  static List<BoxShadow> get shadowLevel4 => [
        BoxShadow(
          color: Colors.black.withOpacity(0.6),
          offset: const Offset(0, 16),
          blurRadius: 48,
          spreadRadius: 0,
        ),
      ];

  /// Button shadow (accent colored)
  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: AppColors.primaryAccent.withOpacity(0.3),
          offset: const Offset(0, 4),
          blurRadius: 16,
          spreadRadius: 0,
        ),
      ];

  // ============================================================================
  // DARK THEME CONFIGURATION
  // ============================================================================

  static ThemeData get darkTheme {
    return ThemeData(
      // Brightness
      brightness: Brightness.dark,
      useMaterial3: true,

      // Font family
      fontFamily: fontFamily,

      // Color scheme
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryAccent,
        secondary: AppColors.brandPrimary,
        surface: AppColors.secondaryBackground,
        error: AppColors.errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.primaryText,
        onError: Colors.white,
        brightness: Brightness.dark,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.primaryBackground,

      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
          fontFamily: fontFamily,
        ),
        iconTheme: IconThemeData(
          color: AppColors.primaryText,
          size: 24,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // Text theme
      textTheme: textTheme,

      // Button themes
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,

      // Card theme
      cardTheme: _cardTheme,

      // Input decoration
      inputDecorationTheme: _inputDecorationTheme,

      // Icon theme
      iconTheme: IconThemeData(
        color: AppColors.primaryText,
        size: 24,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.elevatedSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(borderRadiusXl),
          ),
        ),
        elevation: 0,
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusLg),
        ),
        elevation: 0,
      ),

      // Chip theme
      chipTheme: _chipTheme,

      // Switch theme
      switchTheme: _switchTheme,

      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primaryAccent,
      ),
    );
  }

  // ============================================================================
  // BUTTON THEMES
  // ============================================================================

  static ElevatedButtonThemeData get _elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: AppColors.primaryAccent.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData get _outlinedButtonTheme {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryText,
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        side: const BorderSide(
          color: AppColors.subtleBorder,
          width: 1,
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
      ),
    );
  }

  static TextButtonThemeData get _textButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.secondaryText,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          fontFamily: fontFamily,
        ),
      ),
    );
  }

  // ============================================================================
  // CARD THEME
  // ============================================================================

  static CardThemeData get _cardTheme {
    return CardThemeData(
      color: AppColors.secondaryBackground,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
        side: const BorderSide(
          color: AppColors.subtleBorder,
          width: 1,
        ),
      ),
      margin: const EdgeInsets.all(0),
    );
  }

  // ============================================================================
  // INPUT DECORATION THEME
  // ============================================================================

  static InputDecorationTheme get _inputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.secondaryBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
        borderSide: const BorderSide(
          color: AppColors.subtleBorder,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
        borderSide: const BorderSide(
          color: AppColors.subtleBorder,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
        borderSide: BorderSide(
          color: AppColors.focusBorder,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
        borderSide: const BorderSide(
          color: AppColors.errorRed,
          width: 2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
        borderSide: const BorderSide(
          color: AppColors.errorRed,
          width: 2,
        ),
      ),
      hintStyle: TextStyle(
        color: AppColors.tertiaryText,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: TextStyle(
        color: AppColors.secondaryText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      errorStyle: const TextStyle(
        color: AppColors.errorRed,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  // ============================================================================
  // CHIP THEME
  // ============================================================================

  static ChipThemeData get _chipTheme {
    return ChipThemeData(
      backgroundColor: AppColors.hoverOverlay,
      deleteIconColor: AppColors.secondaryText,
      disabledColor: AppColors.hoverOverlay.withOpacity(0.5),
      selectedColor: AppColors.selectedOverlay,
      secondarySelectedColor: AppColors.selectedOverlay,
      labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      labelStyle: TextStyle(
        color: AppColors.primaryText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: TextStyle(
        color: AppColors.primaryText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      brightness: Brightness.dark,
    );
  }

  // ============================================================================
  // SWITCH THEME
  // ============================================================================

  static SwitchThemeData get _switchTheme {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return AppColors.tertiaryText;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryAccent;
        }
        return AppColors.hoverOverlay;
      }),
    );
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get text style with custom color
  static TextStyle getTextStyle(TextStyle baseStyle, {Color? color}) {
    return baseStyle.copyWith(color: color);
  }

  /// Create a gradient decoration
  static BoxDecoration createGradientDecoration({
    required Gradient gradient,
    BorderRadius? borderRadius,
    Border? border,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: borderRadius,
      border: border,
      boxShadow: boxShadow,
    );
  }

  /// Create a standard card decoration
  static BoxDecoration createCardDecoration({
    Color? color,
    BorderRadius? borderRadius,
    Border? border,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.secondaryBackground,
      borderRadius: borderRadius ?? borderRadiusMdAll,
      border: border ?? Border.all(color: AppColors.subtleBorder, width: 1),
      boxShadow: boxShadow ?? shadowLevel1,
    );
  }
}
