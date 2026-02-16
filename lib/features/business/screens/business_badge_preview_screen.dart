import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/card_image_generator.dart';
import '../../../core/services/image_download_service.dart';
import '../../../core/services/nfc_badge_service.dart';
import '../../../data/models/wallet_card_model.dart';
import '../../../data/models/card_category.dart';
import '../../../data/models/business_connection_model.dart';
import '../../../data/models/badge_profile.dart';
import '../../../data/repositories/wallet_card_repository.dart';

/// Preview screen after successful OAuth + badge fetch
class BusinessBadgePreviewScreen extends StatefulWidget {
  final BusinessConnectionModel connection;
  final BadgeProfile? badge;

  const BusinessBadgePreviewScreen({
    super.key,
    required this.connection,
    this.badge,
  });

  @override
  State<BusinessBadgePreviewScreen> createState() =>
      _BusinessBadgePreviewScreenState();
}

class _BusinessBadgePreviewScreenState
    extends State<BusinessBadgePreviewScreen> {
  bool _isSaving = false;
  bool _nfcAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkNfc();
  }

  Future<void> _checkNfc() async {
    final available = await NfcBadgeService().isNfcAvailable();
    if (mounted) {
      setState(() => _nfcAvailable = available);
    }
  }

  Future<void> _saveBadge() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final badge = widget.badge;
      final cardId = const Uuid().v4();
      String frontImagePath;

      // Use company-provided image or generate one
      if (badge?.cardImageUrl != null && badge!.cardImageUrl!.isNotEmpty) {
        frontImagePath = await ImageDownloadService()
            .downloadAndEncrypt(badge.cardImageUrl!, cardId, 'front');
      } else {
        frontImagePath = await CardImageGenerator().generateBusinessCard(
          employeeName: badge?.employeeName ?? 'Employee',
          title: badge?.title,
          department: badge?.department,
          employeeId: badge?.employeeId,
          companyName: badge?.companyName ?? widget.connection.providerName,
          cardId: cardId,
        );
      }

      final repository = WalletCardRepository();
      await repository.init();

      final now = DateTime.now();
      final card = WalletCardModel(
        id: cardId,
        name: badge?.companyName ?? widget.connection.providerName,
        nickname: badge?.employeeName,
        cardTypeIndex: CardType.businessId.index,
        frontImagePath: frontImagePath,
        createdAt: now,
        updatedAt: now,
        displayOrder: repository.getCardCount(),
        categoryIndex: CardCategory.businessIds.index,
        hasBarcode: false,
        businessConnectionId: widget.connection.id,
        nfcAid: badge?.nfcAid,
        nfcPayload: badge?.nfcPayload,
        isBusinessCard: true,
      );

      await repository.addCard(card);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Badge saved to wallet!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving badge: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.elevatedSurface,
        title: Text(
          'Badge Preview',
          style: TextStyle(color: AppColors.primaryText),
        ),
        iconTheme: IconThemeData(color: AppColors.primaryText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Badge card preview
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: AppTheme.borderRadiusLgAll,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company name
                  Text(
                    badge?.companyName ?? widget.connection.providerName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  // Employee name
                  Text(
                    badge?.employeeName ?? 'Employee',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (badge?.title != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      badge!.title!,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 16,
                      ),
                    ),
                  ],
                  if (badge?.department != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      badge!.department!,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Bottom row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (badge?.employeeId != null)
                        Text(
                          'ID: ${badge!.employeeId}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      if (_nfcAvailable && badge?.nfcAid != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.nfc, color: Colors.teal, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'NFC',
                                style: TextStyle(
                                    color: Colors.teal, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  // Accent strip
                  const SizedBox(height: 8),
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0abde3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Badge info
            _buildInfoSection('Employee Information', [
              if (badge?.employeeName != null)
                _buildInfoRow('Name', badge!.employeeName),
              if (badge?.title != null) _buildInfoRow('Title', badge!.title!),
              if (badge?.department != null)
                _buildInfoRow('Department', badge!.department!),
              if (badge?.employeeId != null)
                _buildInfoRow('Employee ID', badge!.employeeId!),
            ]),

            const SizedBox(height: 16),

            _buildInfoSection('Connection', [
              _buildInfoRow('Provider', widget.connection.providerName),
              _buildInfoRow(
                  'Status',
                  widget.connection.hasValidToken
                      ? 'Connected'
                      : 'Token Expired'),
            ]),

            const SizedBox(height: 16),

            _buildInfoSection('NFC Badge', [
              _buildInfoRow(
                'Device NFC',
                _nfcAvailable ? 'Available' : 'Not Available',
              ),
              _buildInfoRow(
                'Badge NFC',
                badge?.nfcAid != null ? 'Configured' : 'Not Configured',
              ),
              if (!_nfcAvailable && Platform.isIOS)
                _buildInfoRow('Note', 'NFC badge emulation is Android-only'),
            ]),

            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveBadge,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primaryAccent,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Save Badge to Wallet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.secondaryText)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
