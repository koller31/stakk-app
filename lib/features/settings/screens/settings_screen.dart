import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auto_lock_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/pin_entry_screen.dart';
import '../../theme/providers/theme_provider.dart';
import '../../../data/models/card_category.dart';
import '../../../data/repositories/wallet_card_repository.dart';
import '../../../data/services/card_category_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late CardCategoryService _categoryService;
  List<CardCategory> _categories = [];
  Map<CardCategory, bool> _categoryVisibility = {};
  final AutoLockService _autoLockService = AutoLockService();
  int _currentTimeout = 60;

  @override
  void initState() {
    super.initState();
    _categoryService = CardCategoryService();
    _loadCategories();
    _loadAutoLockTimeout();
  }

  Future<void> _loadAutoLockTimeout() async {
    await _autoLockService.init();
    if (mounted) {
      setState(() {
        _currentTimeout = _autoLockService.timeoutSeconds;
      });
    }
  }

  Future<void> _loadCategories() async {
    final categories = await _categoryService.getCategories();
    final visibility = <CardCategory, bool>{};
    for (final category in categories) {
      visibility[category] = await _categoryService.isCategoryVisible(category);
    }
    setState(() {
      _categories = categories;
      _categoryVisibility = visibility;
    });
  }

  Future<void> _toggleCategoryVisibility(CardCategory category, bool value) async {
    await _categoryService.setCategoryVisibility(category, value);
    setState(() {
      _categoryVisibility[category] = value;
    });
  }

  Future<void> _changePIN() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PinEntryScreen(
          mode: PinEntryMode.set,
        ),
      ),
    );
  }

  Future<void> _showAutoLockPicker() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevatedSurface,
        title: Text(
          'Auto-lock Timeout',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AutoLockService.timeoutOptions.entries.map((entry) {
            return RadioListTile<int>(
              title: Text(
                entry.value,
                style: TextStyle(color: AppColors.primaryText),
              ),
              value: entry.key,
              groupValue: _currentTimeout,
              activeColor: AppColors.primaryAccent,
              onChanged: (value) => Navigator.pop(context, value),
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null && mounted) {
      await _autoLockService.setTimeout(selected);
      setState(() {
        _currentTimeout = selected;
      });
    }
  }

  Future<void> _clearExtractedText() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevatedSurface,
        title: Text(
          'Clear Extracted Text',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: Text(
          'This will remove all OCR-extracted text data (names, addresses, etc.) from your cards. Card images will not be affected.',
          style: TextStyle(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Clear Text',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repository = WalletCardRepository();
      await repository.init();
      final cards = repository.getAllCards();
      for (final card in cards) {
        if (card.extractedData != null) {
          final updated = card.copyWith(
            extractedData: null,
            updatedAt: DateTime.now(),
          );
          await repository.updateCard(updated);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Extracted text data cleared'),
            backgroundColor: AppColors.elevatedSurface,
          ),
        );
      }
    }
  }

  Future<void> _clearAllCards() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevatedSurface,
        title: Text(
          'Clear All Cards',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: Text(
          'Are you sure you want to delete all cards? This action cannot be undone.',
          style: TextStyle(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Clear All',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repository = WalletCardRepository();
      await repository.init();
      await repository.clearAllCards();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All cards have been cleared'),
            backgroundColor: AppColors.elevatedSurface,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final biometricsAvailable = authProvider.biometricsAvailable;
    final biometricsEnabled = authProvider.biometricsEnabled;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.elevatedSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
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
          _buildSectionHeader('Security'),
          _buildCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.lock, color: AppColors.primaryAccent),
                  title: Text(
                    'Change PIN',
                    style: TextStyle(color: AppColors.primaryText),
                  ),
                  trailing: Icon(Icons.chevron_right, color: AppColors.secondaryText),
                  onTap: _changePIN,
                ),
                Divider(
                  color: AppColors.subtleBorder,
                  height: 1,
                  indent: 56,
                ),
                ListTile(
                  leading: Icon(Icons.fingerprint, color: AppColors.primaryAccent),
                  title: Text(
                    'Biometric Authentication',
                    style: TextStyle(color: AppColors.primaryText),
                  ),
                  subtitle: Text(
                    biometricsAvailable
                        ? 'Use fingerprint or face to unlock'
                        : 'Not available on this device',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Switch(
                    value: biometricsEnabled,
                    onChanged: biometricsAvailable
                        ? (value) => authProvider.setBiometricsEnabled(value)
                        : null,
                    activeColor: AppColors.primaryAccent,
                  ),
                ),
                Divider(
                  color: AppColors.subtleBorder,
                  height: 1,
                  indent: 56,
                ),
                ListTile(
                  leading: Icon(Icons.timer, color: AppColors.primaryAccent),
                  title: Text(
                    'Auto-lock timeout',
                    style: TextStyle(color: AppColors.primaryText),
                  ),
                  subtitle: Text(
                    AutoLockService.timeoutOptions[_currentTimeout] ?? '1 minute',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right, color: AppColors.secondaryText),
                  onTap: _showAutoLockPicker,
                ),
              ],
            ),
          ),
          SizedBox(height: AppTheme.paddingLarge),
          _buildSectionHeader('Appearance'),
          _buildCard(
            child: ListTile(
              leading: Icon(Icons.palette, color: AppColors.primaryAccent),
              title: Text(
                'Theme',
                style: TextStyle(color: AppColors.primaryText),
              ),
              subtitle: Text(
                context.watch<ThemeProvider>().currentTheme.name,
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
              trailing: Icon(Icons.chevron_right, color: AppColors.secondaryText),
              onTap: () => context.push('/theme-store'),
            ),
          ),
          SizedBox(height: AppTheme.paddingLarge),
          _buildSectionHeader('Categories'),
          _buildCard(
            child: Column(
              children: [
                ..._categories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  final isVisible = _categoryVisibility[category] ?? true;

                  return Column(
                    children: [
                      if (index > 0)
                        Divider(
                          color: AppColors.subtleBorder,
                          height: 1,
                          indent: 56,
                        ),
                      ListTile(
                        leading: Icon(
                          _getCategoryIcon(category),
                          color: AppColors.primaryAccent,
                        ),
                        title: Text(
                          _getCategoryLabel(category),
                          style: TextStyle(color: AppColors.primaryText),
                        ),
                        trailing: Switch(
                          value: isVisible,
                          onChanged: (value) => _toggleCategoryVisibility(category, value),
                          activeColor: AppColors.primaryAccent,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
          SizedBox(height: AppTheme.paddingLarge),
          _buildSectionHeader('Data'),
          _buildCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.text_fields, color: AppColors.primaryAccent),
                  title: Text(
                    'Clear Extracted Text',
                    style: TextStyle(color: AppColors.primaryText),
                  ),
                  subtitle: Text(
                    'Remove OCR data from all cards',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right, color: AppColors.secondaryText),
                  onTap: _clearExtractedText,
                ),
                Divider(
                  color: AppColors.subtleBorder,
                  height: 1,
                  indent: 56,
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: AppColors.errorRed),
                  title: Text(
                    'Clear All Cards',
                    style: TextStyle(color: AppColors.errorRed),
                  ),
                  trailing: Icon(Icons.chevron_right, color: AppColors.secondaryText),
                  onTap: _clearAllCards,
                ),
                Divider(
                  color: AppColors.subtleBorder,
                  height: 1,
                  indent: 56,
                ),
                ListTile(
                  leading: Icon(Icons.file_download, color: AppColors.secondaryText),
                  title: Text(
                    'Export Data',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                  subtitle: Text(
                    'Coming soon',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  enabled: false,
                ),
              ],
            ),
          ),
          SizedBox(height: AppTheme.paddingLarge),
          _buildSectionHeader('About'),
          _buildCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline, color: AppColors.primaryAccent),
                  title: Text(
                    'IDswipe',
                    style: TextStyle(color: AppColors.primaryText),
                  ),
                  subtitle: Text(
                    'Digital ID Wallet',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ),
                Divider(
                  color: AppColors.subtleBorder,
                  height: 1,
                  indent: 56,
                ),
                ListTile(
                  leading: Icon(Icons.tag, color: AppColors.primaryAccent),
                  title: Text(
                    'Version',
                    style: TextStyle(color: AppColors.primaryText),
                  ),
                  trailing: Text(
                    '1.0.0',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.paddingSmall,
        bottom: AppTheme.paddingSmall,
        top: AppTheme.paddingSmall,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.secondaryText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppColors.subtleBorder,
          width: 1,
        ),
      ),
      child: child,
    );
  }

  IconData _getCategoryIcon(CardCategory category) {
    switch (category) {
      case CardCategory.idCards:
        return Icons.badge;
      case CardCategory.memberships:
        return Icons.card_membership;
      case CardCategory.insurance:
        return Icons.health_and_safety;
      case CardCategory.giftCards:
        return Icons.card_giftcard;
      case CardCategory.trafficDocuments:
        return Icons.drive_eta;
      case CardCategory.other:
        return Icons.credit_card;
    }
  }

  String _getCategoryLabel(CardCategory category) {
    return CardCategoryMetadata.getDisplayName(category);
  }
}
