import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_theme_model.dart';
import '../providers/theme_provider.dart';

class ThemeStoreScreen extends StatelessWidget {
  const ThemeStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final currentId = themeProvider.currentTheme.id;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.elevatedSurface,
        elevation: 0,
        title: Text(
          'Store',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.primaryText),
      ),
      body: ListView(
        padding: EdgeInsets.all(AppTheme.paddingMedium),
        children: [
          // Dark Themes section
          _SectionHeader(title: 'DARK THEMES'),
          _ThemeGrid(
            themes: AppThemeModel.darkThemes,
            currentId: currentId,
            onSelect: (id) => themeProvider.setTheme(id),
          ),

          const SizedBox(height: 24),

          // Light Themes section
          _SectionHeader(title: 'LIGHT THEMES'),
          _ThemeGrid(
            themes: AppThemeModel.lightThemes,
            currentId: currentId,
            onSelect: (id) => themeProvider.setTheme(id),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.paddingSmall,
        bottom: AppTheme.paddingSmall,
        top: AppTheme.paddingSmall,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.secondaryText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ThemeGrid extends StatelessWidget {
  final List<AppThemeModel> themes;
  final String currentId;
  final ValueChanged<String> onSelect;

  const _ThemeGrid({
    required this.themes,
    required this.currentId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final theme = themes[index];
        return _ThemeCard(
          theme: theme,
          isActive: theme.id == currentId,
          onTap: () => onSelect(theme.id),
        );
      },
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final AppThemeModel theme;
  final bool isActive;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Card border for the preview - use theme's own colors for contrast
    final previewBorderColor = theme.isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.elevatedSurface,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
          border: Border.all(
            color: isActive
                ? theme.primaryAccent
                : AppColors.subtleBorder,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Color preview area
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: previewBorderColor, width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mini preview mockup
                    Container(
                      width: 60,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.primaryText.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.secondaryText.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Color swatches
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Swatch(
                          color: theme.primaryAccent,
                          size: 24,
                          isDark: theme.isDark,
                        ),
                        const SizedBox(width: 6),
                        _Swatch(
                          color: theme.secondaryBackground,
                          size: 24,
                          isDark: theme.isDark,
                        ),
                        const SizedBox(width: 6),
                        _Swatch(
                          color: theme.elevatedSurface,
                          size: 24,
                          isDark: theme.isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Name + status
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          theme.name,
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          theme.description,
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Icon(
                      Icons.check_circle,
                      color: theme.primaryAccent,
                      size: 22,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final double size;
  final bool isDark;

  const _Swatch({
    required this.color,
    required this.size,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.15)
              : Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
    );
  }
}
