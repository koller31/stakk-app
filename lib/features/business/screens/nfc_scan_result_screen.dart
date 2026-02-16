import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/card_image_generator.dart';
import '../../../core/services/nfc_badge_service.dart';
import '../../../data/models/nfc_scan_result.dart';
import '../../../data/models/wallet_card_model.dart';
import '../../../data/models/card_category.dart';
import '../../../data/repositories/wallet_card_repository.dart';

/// Result screen after successfully scanning an NFC card.
/// Shows captured data and allows saving as a wallet badge.
class NfcScanResultScreen extends StatefulWidget {
  final NfcScanResult scanResult;

  const NfcScanResultScreen({super.key, required this.scanResult});

  @override
  State<NfcScanResultScreen> createState() => _NfcScanResultScreenState();
}

class _NfcScanResultScreenState extends State<NfcScanResultScreen> {
  late TextEditingController _nameController;
  bool _isSaving = false;
  bool _nfcAvailable = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.scanResult.cardTypeDescription);
    _checkNfc();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _checkNfc() async {
    final available = await NfcBadgeService().isNfcAvailable();
    if (mounted) setState(() => _nfcAvailable = available);
  }

  Future<void> _saveBadge() async {
    if (_isSaving) return;
    final badgeName = _nameController.text.trim();
    if (badgeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a badge name'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final cardId = const Uuid().v4();
      final scan = widget.scanResult;

      // Generate a card image for this scanned badge
      final frontImagePath = await CardImageGenerator().generateBusinessCard(
        employeeName: badgeName,
        title: scan.cardTypeDescription,
        department: 'UID: ${_formatUid(scan.uid)}',
        employeeId: scan.techSummary,
        companyName: 'NFC Badge',
        cardId: cardId,
      );

      final repository = WalletCardRepository();
      await repository.init();

      final now = DateTime.now();
      final card = WalletCardModel(
        id: cardId,
        name: badgeName,
        cardTypeIndex: CardType.businessId.index,
        frontImagePath: frontImagePath,
        createdAt: now,
        updatedAt: now,
        displayOrder: repository.getCardCount(),
        categoryIndex: CardCategory.businessIds.index,
        hasBarcode: false,
        nfcAid: scan.hceAid,
        nfcPayload: scan.hcePayload,
        extractedData: scan.toExtractedData(),
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

  String _formatUid(String uid) {
    // Insert colons every 2 chars: "04A3B2C1" -> "04:A3:B2:C1"
    final buffer = StringBuffer();
    for (var i = 0; i < uid.length; i += 2) {
      if (i > 0) buffer.write(':');
      buffer.write(uid.substring(i, i + 2 > uid.length ? uid.length : i + 2));
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final scan = widget.scanResult;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.elevatedSurface,
        title: Text(
          'Scan Result',
          style: TextStyle(color: AppColors.primaryText),
        ),
        iconTheme: IconThemeData(color: AppColors.primaryText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card preview
            _buildCardPreview(scan),

            const SizedBox(height: 24),

            // Badge name field
            _buildNameField(),

            const SizedBox(height: 24),

            // Card Type section
            _buildInfoSection('Card Type', [
              _buildInfoRow('Type', scan.cardTypeDescription),
              _buildInfoRow('Technologies', scan.techSummary),
            ]),

            const SizedBox(height: 16),

            // UID section
            _buildInfoSection('Identification', [
              _buildInfoRow('UID', _formatUid(scan.uid)),
              if (scan.atqa != null) _buildInfoRow('ATQA', scan.atqa!),
              if (scan.sak != null)
                _buildInfoRow('SAK', '0x${scan.sak!.toRadixString(16).toUpperCase().padLeft(2, '0')}'),
            ]),

            // NDEF section
            if (scan.hasNdef) ...[
              const SizedBox(height: 16),
              _buildInfoSection('NDEF Data', [
                if (scan.ndefType != null)
                  _buildInfoRow('Type', scan.ndefType!),
                if (scan.ndefMaxSize != null)
                  _buildInfoRow('Max Size', '${scan.ndefMaxSize} bytes'),
                ...scan.ndefRecords!.asMap().entries.map((entry) {
                  final record = entry.value;
                  if (record.text != null) {
                    return _buildInfoRow('Text', record.text!);
                  } else if (record.uri != null) {
                    return _buildInfoRow('URI', record.uri!);
                  } else if (record.payload != null) {
                    return _buildInfoRow(
                      'Record ${entry.key}',
                      _truncateHex(record.payload!, 32),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ]),
            ],

            // MIFARE section
            if (scan.hasMifareData) ...[
              const SizedBox(height: 16),
              _buildInfoSection('MIFARE Data', [
                if (scan.mifareType != null)
                  _buildInfoRow('Type', scan.mifareType!),
                if (scan.mifareSize != null)
                  _buildInfoRow('Size', '${scan.mifareSize} bytes'),
                if (scan.mifareSectorCount != null)
                  _buildInfoRow('Total Sectors', '${scan.mifareSectorCount}'),
                _buildInfoRow(
                  'Readable Sectors',
                  '${scan.mifareSectors!.length}',
                ),
              ]),
            ],

            // Ultralight section
            if (scan.hasUltralightData) ...[
              const SizedBox(height: 16),
              _buildInfoSection('Ultralight Data', [
                if (scan.ultralightType != null)
                  _buildInfoRow('Type', scan.ultralightType!),
                _buildInfoRow(
                  'Readable Pages',
                  '${scan.ultralightPages!.length}',
                ),
              ]),
            ],

            // Historical bytes
            if (scan.historicalBytes != null) ...[
              const SizedBox(height: 16),
              _buildInfoSection('ISO-DEP', [
                _buildInfoRow(
                  'Historical Bytes',
                  _truncateHex(scan.historicalBytes!, 32),
                ),
              ]),
            ],

            const SizedBox(height: 16),

            // UID limitation warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningYellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppColors.warningYellow.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.warningYellow,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Android HCE uses a random UID each time -- the original card UID cannot be cloned. Emulation uses captured payload data instead.',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // NFC status
            _buildInfoSection('Emulation', [
              _buildInfoRow(
                'Device NFC',
                _nfcAvailable ? 'Available' : 'Not Available',
              ),
              _buildInfoRow('Generated AID', scan.hceAid),
              _buildInfoRow(
                'Payload Size',
                '${(scan.hcePayload.length / 2).round()} bytes',
              ),
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
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Badge to Wallet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPreview(NfcScanResult scan) {
    return Container(
      height: 200,
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
          // Card type label
          Text(
            'NFC BADGE',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          // Card type description
          Text(
            scan.cardTypeDescription,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'UID: ${_formatUid(scan.uid)}',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
          const Spacer(),
          // Bottom row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                scan.techSummary,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
              if (_nfcAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
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
                        style: TextStyle(color: Colors.teal, fontSize: 11),
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
    );
  }

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BADGE NAME',
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Enter badge name',
              hintStyle: TextStyle(
                color: AppColors.tertiaryText,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    final filtered = children.where((w) => w is! SizedBox).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

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
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _truncateHex(String hex, int maxChars) {
    if (hex.length <= maxChars) return hex;
    return '${hex.substring(0, maxChars)}...';
  }
}
