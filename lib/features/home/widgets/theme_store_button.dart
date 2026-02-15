import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../theme/providers/theme_provider.dart';

class ThemeStoreButton extends StatelessWidget {
  const ThemeStoreButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final themeName = themeProvider.currentTheme.name;

    return GestureDetector(
      onTap: () => context.push('/theme-store'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryAccent.withOpacity(0.3),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryAccent.withOpacity(0.08),
              AppColors.secondaryBackground,
            ],
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.palette_outlined,
              color: AppColors.primaryAccent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Themes',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    themeName,
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.tertiaryText,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
