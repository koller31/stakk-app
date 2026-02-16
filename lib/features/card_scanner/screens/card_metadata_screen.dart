import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/encryption_service.dart';
import '../../../data/models/wallet_card_model.dart';
import '../../../data/models/card_category.dart';
import '../../../data/repositories/wallet_card_repository.dart';

/// Card Metadata Screen - Enter card details and save
class CardMetadataScreen extends StatefulWidget {
  final String frontImagePath;
  final String? backImagePath;
  final CardCategory? initialCategory;

  const CardMetadataScreen({
    super.key,
    required this.frontImagePath,
    this.backImagePath,
    this.initialCategory,
  });

  @override
  State<CardMetadataScreen> createState() => _CardMetadataScreenState();
}

class _CardMetadataScreenState extends State<CardMetadataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _notesController = TextEditingController();

  CardType _selectedType = CardType.id;
  DisplayFormat _selectedFormat = DisplayFormat.card;
  bool _hasBarcode = WalletCardModel.defaultHasBarcodeForType(CardType.id);
  bool _isProcessing = false;
  bool _isExtractingText = false;
  Map<String, dynamic>? _extractedData;

  @override
  void initState() {
    super.initState();
    // Auto-extract text from card (optional feature)
    _extractTextFromCard();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Extract text from card using ML Kit OCR
  Future<void> _extractTextFromCard() async {
    setState(() => _isExtractingText = true);

    final textRecognizer = TextRecognizer();
    try {
      final inputImage = InputImage.fromFilePath(widget.frontImagePath);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      // Store all extracted text
      _extractedData = {
        'fullText': recognizedText.text,
        'blocks': recognizedText.blocks.map((block) => block.text).toList(),
      };

      // Try to auto-suggest card name from extracted text
      if (recognizedText.text.isNotEmpty && mounted) {
        // Take first line as suggestion
        final lines = recognizedText.text.split('\n');
        if (lines.isNotEmpty) {
          _nameController.text = lines.first.trim();
        }
      }
    } catch (e) {
      debugPrint('Error extracting text: $e');
      // OCR failure is non-critical, user can still enter details manually
    } finally {
      await textRecognizer.close();
      if (mounted) {
        setState(() => _isExtractingText = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Details'),
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

                // Card Preview
                _buildCardPreview(),

                const SizedBox(height: AppTheme.spacingXl),

                // OCR extraction indicator
                if (_isExtractingText)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Text(
                          'Reading card text...',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

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
                      setState(() {
                        _selectedType = value;
                        _hasBarcode = WalletCardModel.defaultHasBarcodeForType(value);
                      });
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

                // Has Barcode Toggle
                SwitchListTile(
                  title: const Text('Has scannable barcode'),
                  subtitle: const Text('Show brighten button when viewing card back'),
                  value: _hasBarcode,
                  onChanged: (value) {
                    setState(() => _hasBarcode = value);
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
                    : const Text('Save Card'),
                ),

                const SizedBox(height: AppTheme.spacingMd),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardPreview() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: AppTheme.borderRadiusLgAll,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppTheme.borderRadiusLgAll,
        child: Image.file(
          File(widget.frontImagePath),
          fit: BoxFit.cover,
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

      // Get permanent storage directory for card images
      final cardImagesDir = await repository.getCardImagesDirectory();

      // Generate unique ID for the card
      final cardId = const Uuid().v4();

      // Copy images to permanent storage and encrypt them
      final encryption = EncryptionService();
      final frontImageFile = File(widget.frontImagePath);
      final permanentFrontPath = path.join(
        cardImagesDir.path,
        '${cardId}_front.jpg.enc',
      );
      // Copy to temp location first, then encrypt to final .enc path
      final tempFrontPath = path.join(
        cardImagesDir.path,
        '${cardId}_front.jpg',
      );
      await frontImageFile.copy(tempFrontPath);
      await encryption.encryptFile(tempFrontPath, permanentFrontPath);
      await encryption.secureDelete(tempFrontPath);

      String? permanentBackPath;
      if (widget.backImagePath != null) {
        final backImageFile = File(widget.backImagePath!);
        permanentBackPath = path.join(
          cardImagesDir.path,
          '${cardId}_back.jpg.enc',
        );
        final tempBackPath = path.join(
          cardImagesDir.path,
          '${cardId}_back.jpg',
        );
        await backImageFile.copy(tempBackPath);
        await encryption.encryptFile(tempBackPath, permanentBackPath);
        await encryption.secureDelete(tempBackPath);
      }

      // Create card model with category
      final now = DateTime.now();

      final card = WalletCardModel(
        id: cardId,
        name: _nameController.text.trim(),
        nickname: _nicknameController.text.trim().isEmpty
          ? null
          : _nicknameController.text.trim(),
        cardTypeIndex: _selectedType.index,
        frontImagePath: permanentFrontPath,
        backImagePath: permanentBackPath,
        createdAt: now,
        updatedAt: now,
        extractedData: _extractedData,
        notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
        displayOrder: repository.getCardCount(), // Add at end
        categoryIndex: (widget.initialCategory ?? CardCategoryMetadata.getCategoryForCardType(_selectedType)).index,
        displayFormatIndex: _selectedFormat.index, // User-selected display format
        hasBarcode: _hasBarcode,
      );


      // Save to repository
      await repository.addCard(card);

      // Clean up temporary files
      await frontImageFile.delete();
      if (widget.backImagePath != null) {
        await File(widget.backImagePath!).delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card saved successfully!')),
        );

        // Return success
        Navigator.pop(context, {'saved': true});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving card: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
