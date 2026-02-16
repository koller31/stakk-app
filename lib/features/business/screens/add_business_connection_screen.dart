import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/nfc_badge_service.dart';
import '../../../data/models/business_connection_config.dart';
import '../../../data/models/badge_profile.dart';
import '../providers/business_connection_provider.dart';
import 'business_badge_preview_screen.dart';
import 'nfc_scan_screen.dart';

/// Screen for adding a new business connection via QR code or manual entry
class AddBusinessConnectionScreen extends StatefulWidget {
  const AddBusinessConnectionScreen({super.key});

  @override
  State<AddBusinessConnectionScreen> createState() =>
      _AddBusinessConnectionScreenState();
}

class _AddBusinessConnectionScreenState
    extends State<AddBusinessConnectionScreen> {
  bool _isManualMode = false;
  bool _isConnecting = false;

  // Manual form controllers
  final _formKey = GlobalKey<FormState>();
  final _providerNameController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _discoveryUrlController = TextEditingController();
  final _badgeApiController = TextEditingController();
  final _scopesController = TextEditingController(text: 'openid profile');
  final _logoUrlController = TextEditingController();

  @override
  void dispose() {
    _providerNameController.dispose();
    _clientIdController.dispose();
    _discoveryUrlController.dispose();
    _badgeApiController.dispose();
    _scopesController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleQrCode(String data) async {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final config = BusinessConnectionConfig.fromJson(json);
      await _connectWithConfig(config);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid QR code: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _handleManualSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final config = BusinessConnectionConfig(
      providerName: _providerNameController.text.trim(),
      clientId: _clientIdController.text.trim(),
      discoveryUrl: _discoveryUrlController.text.trim().isEmpty
          ? null
          : _discoveryUrlController.text.trim(),
      badgeApiEndpoint: _badgeApiController.text.trim(),
      scopes: _scopesController.text.trim().split(' '),
      logoUrl: _logoUrlController.text.trim().isEmpty
          ? null
          : _logoUrlController.text.trim(),
    );

    await _connectWithConfig(config);
  }

  Future<void> _handleDemoMode() async {
    if (_isConnecting) return;
    setState(() => _isConnecting = true);

    try {
      final provider = context.read<BusinessConnectionProvider>();
      final connection = await provider.addDemoConnection();

      if (connection != null && mounted) {
        final badge = BadgeProfile(
          employeeName: 'Josep Martinez',
          title: 'Software Engineer',
          department: 'Engineering',
          employeeId: 'EMP-2024-0042',
          companyName: 'IDswipe Demo Corp',
          nfcAid: 'F049445357495045',
          nfcPayload: '454D502D323032342D30303432',
        );

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BusinessBadgePreviewScreen(
              connection: connection,
              badge: badge,
            ),
          ),
        );

        if (result == true && mounted) {
          Navigator.pop(context, true);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Demo setup failed'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _connectWithConfig(BusinessConnectionConfig config) async {
    if (_isConnecting) return;

    setState(() => _isConnecting = true);

    try {
      final provider = context.read<BusinessConnectionProvider>();
      final connection = await provider.addConnection(config);

      if (connection != null && mounted) {
        // Fetch badge data
        final badge = await provider.fetchBadge(connection.id);

        if (mounted) {
          // Navigate to badge preview
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BusinessBadgePreviewScreen(
                connection: connection,
                badge: badge,
              ),
            ),
          );

          if (result == true && mounted) {
            Navigator.pop(context, true);
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Connection failed'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.elevatedSurface,
        title: Text(
          'Add Business Badge',
          style: TextStyle(color: AppColors.primaryText),
        ),
        iconTheme: IconThemeData(color: AppColors.primaryText),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _isManualMode = !_isManualMode);
            },
            child: Text(
              _isManualMode ? 'Scan QR' : 'Manual',
              style: TextStyle(color: AppColors.primaryAccent),
            ),
          ),
        ],
      ),
      body: _isConnecting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Connecting...',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ],
              ),
            )
          : _isManualMode
              ? _buildManualForm()
              : _buildQrScanner(),
    );
  }

  Widget _buildQrScanner() {
    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleQrCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          color: AppColors.elevatedSurface,
          child: Column(
            children: [
              Text(
                'Scan your employer\'s badge QR code',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your IT department should provide a QR code containing the connection details.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildDemoSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter Connection Details',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get these details from your IT department.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _providerNameController,
              label: 'Company Name',
              hint: 'e.g., Acme Corp',
              icon: Icons.business,
              required: true,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _buildTextField(
              controller: _clientIdController,
              label: 'Client ID',
              hint: 'OAuth client identifier',
              icon: Icons.key,
              required: true,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _buildTextField(
              controller: _discoveryUrlController,
              label: 'Discovery URL (Optional)',
              hint: 'https://login.company.com/.well-known/openid-configuration',
              icon: Icons.link,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _buildTextField(
              controller: _badgeApiController,
              label: 'Badge API URL',
              hint: 'https://api.company.com/badge/profile',
              icon: Icons.api,
              required: true,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _buildTextField(
              controller: _scopesController,
              label: 'Scopes',
              hint: 'openid profile badge',
              icon: Icons.security,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _buildTextField(
              controller: _logoUrlController,
              label: 'Logo URL (Optional)',
              hint: 'https://company.com/logo.png',
              icon: Icons.image,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _handleManualSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primaryAccent,
              ),
              child: const Text(
                'Connect',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildDemoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.subtleBorder)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.subtleBorder)),
          ],
        ),
        const SizedBox(height: 16),
        // NFC Scan button -- only shown on Android with NFC
        if (Platform.isAndroid)
          FutureBuilder<bool>(
            future: NfcBadgeService().isNfcAvailable(),
            builder: (context, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
              return Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _handleNfcScan,
                    icon: const Icon(Icons.nfc, size: 20),
                    label: const Text(
                      'Scan NFC Card',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Read a physical NFC badge or tag',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        OutlinedButton.icon(
          onPressed: _handleDemoMode,
          icon: const Icon(Icons.play_circle_outline, size: 20),
          label: const Text(
            'Try Demo Badge',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            foregroundColor: Colors.teal,
            side: const BorderSide(color: Colors.teal, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Creates a sample badge so you can test the full flow',
          style: TextStyle(
            color: AppColors.secondaryText,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _handleNfcScan() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const NfcScanScreen(),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primaryAccent),
        labelStyle: TextStyle(color: AppColors.secondaryText),
        hintStyle: TextStyle(color: AppColors.secondaryText.withValues(alpha: 0.5)),
      ),
      style: TextStyle(color: AppColors.primaryText),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }
              return null;
            }
          : null,
    );
  }
}
