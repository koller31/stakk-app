import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/wallet_card_model.dart';
import '../../../data/repositories/wallet_card_repository.dart';

/// Edit Card Screen - Edit existing wallet card details
class EditCardScreen extends StatefulWidget {
  final WalletCardModel card;

  const EditCardScreen({
    super.key,
    required this.card,
  });

  @override
  State<EditCardScreen> createState() => _EditCardScreenState();
}

class _EditCardScreenState extends State<EditCardScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _notesController;
  late CardType _selectedType;
  late DisplayFormat _selectedFormat;
  late bool _frontHasBarcode;
  late bool _backHasBarcode;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.card.name);
    _nicknameController = TextEditingController(text: widget.card.nickname ?? '');
    _notesController = TextEditingController(text: widget.card.notes ?? '');
    _selectedType = widget.card.cardType;
    _selectedFormat = widget.card.displayFormat;
    _frontHasBarcode = widget.card.hasFrontBarcode;
    _backHasBarcode = widget.card.hasBackBarcode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Card'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTheme.spacingMd),

                // Card Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Card Name',
                    hintText: 'e.g., Arkansas Driver\'s License',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a card name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // Nickname Field (Optional)
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    labelText: 'Nickname (Optional)',
                    hintText: 'e.g., My DL',
                    prefixIcon: Icon(Icons.label),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // Card Type Dropdown
                DropdownButtonFormField<CardType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Card Type',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: CardType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getCardTypeLabel(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // Display Format Selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Display Format',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<DisplayFormat>(
                            title: const Text('Card'),
                            subtitle: const Text('Wallet-sized, double-tap to flip'),
                            value: DisplayFormat.card,
                            groupValue: _selectedFormat,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedFormat = value);
                              }
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<DisplayFormat>(
                            title: const Text('Document'),
                            subtitle: const Text('Full-size, pinch to zoom'),
                            value: DisplayFormat.document,
                            groupValue: _selectedFormat,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedFormat = value);
                              }
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // Per-side barcode toggles
                SwitchListTile(
                  title: const Text('Front has barcode'),
                  subtitle: const Text('Show brighten button on front side'),
                  value: _frontHasBarcode,
                  onChanged: (value) {
                    setState(() => _frontHasBarcode = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                if (widget.card.backImagePath != null)
                  SwitchListTile(
                    title: const Text('Back has barcode'),
                    subtitle: const Text('Show brighten button on back side'),
                    value: _backHasBarcode,
                    onChanged: (value) {
                      setState(() => _backHasBarcode = value);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),

                const SizedBox(height: AppTheme.spacingMd),

                // Notes Field (Optional)
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Additional information',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: AppTheme.spacingXl),

                // Save Button
                ElevatedButton(
                  onPressed: _isProcessing ? null : _saveCard,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                  ),
                  child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
                ),

                const SizedBox(height: AppTheme.spacingMd),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCardTypeLabel(CardType type) {
    switch (type) {
      case CardType.id:
        return 'ID Card';
      case CardType.driversLicense:
        return 'Driver\'s License';
      case CardType.giftCard:
        return 'Gift Card';
      case CardType.membership:
        return 'Membership Card';
      case CardType.insurance:
        return 'Vehicle Insurance';
      case CardType.healthInsurance:
        return 'Health Insurance';
      case CardType.vehicleRegistration:
        return 'Vehicle Registration';
      case CardType.other:
        return 'Other';
      case CardType.businessId:
        return 'Business ID';
    }
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final repository = WalletCardRepository();
      await repository.init();

      // Create updated card with modified fields
      final updatedCard = widget.card.copyWith(
        name: _nameController.text.trim(),
        nickname: _nicknameController.text.trim().isEmpty
          ? null
          : _nicknameController.text.trim(),
        cardTypeIndex: _selectedType.index,
        displayFormatIndex: _selectedFormat.index,
        notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
        hasBarcode: _frontHasBarcode || _backHasBarcode,
        hasFrontBarcode: _frontHasBarcode,
        hasBackBarcode: _backHasBarcode,
        updatedAt: DateTime.now(),
      );

      // Update card in repository
      await repository.updateCard(updatedCard);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card updated successfully!')),
        );

        // Return success
        Navigator.pop(context, {'updated': true});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating card: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
