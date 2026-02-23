import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/card_category.dart';
import '../../data/models/wallet_card_model.dart';
import '../../data/repositories/wallet_card_repository.dart';
import 'encryption_service.dart';

/// Seeds mock cards for the S2 demo build.
/// Runs once on first launch when the card count is 0.
class DemoCardSeeder {
  final WalletCardRepository _repo = WalletCardRepository();
  final EncryptionService _encryption = EncryptionService();
  final Uuid _uuid = const Uuid();

  /// Card definitions: asset paths, metadata, and display order.
  static const List<_DemoCard> _cards = [
    _DemoCard(
      frontAsset: 'assets/demo_cards/MockIDFront.png',
      backAsset: 'assets/demo_cards/MockIDBack.png',
      name: 'Driver License',
      cardType: CardType.driversLicense,
      displayFormat: DisplayFormat.card,
      hasFrontBarcode: false,
      hasBackBarcode: true,
      displayOrder: 0,
    ),
    _DemoCard(
      frontAsset: 'assets/demo_cards/InstitueID.png',
      backAsset: 'assets/demo_cards/InstituteIDback.png',
      name: 'Institute ID',
      cardType: CardType.id,
      displayFormat: DisplayFormat.card,
      hasFrontBarcode: false,
      hasBackBarcode: false,
      displayOrder: 1,
    ),
    _DemoCard(
      frontAsset: 'assets/demo_cards/mock health insurance.png',
      backAsset: null,
      name: 'Health Insurance',
      cardType: CardType.healthInsurance,
      displayFormat: DisplayFormat.card,
      hasFrontBarcode: false,
      hasBackBarcode: false,
      displayOrder: 2,
    ),
    _DemoCard(
      frontAsset: 'assets/demo_cards/mock-up-of-driver-insurance-card.png',
      backAsset: null,
      name: 'Auto Insurance',
      cardType: CardType.insurance,
      displayFormat: DisplayFormat.card,
      hasFrontBarcode: false,
      hasBackBarcode: false,
      displayOrder: 3,
    ),
    _DemoCard(
      frontAsset: 'assets/demo_cards/mock gym front.png',
      backAsset: 'assets/demo_cards/mock gym back.png',
      name: 'Gym Membership',
      cardType: CardType.membership,
      displayFormat: DisplayFormat.card,
      hasFrontBarcode: false,
      hasBackBarcode: false,
      displayOrder: 4,
    ),
    _DemoCard(
      frontAsset: 'assets/demo_cards/mock vehicle registration certificate full size document.png',
      backAsset: null,
      name: 'Vehicle Registration',
      cardType: CardType.vehicleRegistration,
      displayFormat: DisplayFormat.document,
      hasFrontBarcode: false,
      hasBackBarcode: false,
      displayOrder: 5,
    ),
  ];

  /// Seed demo cards if the wallet is empty.
  Future<void> seedIfEmpty() async {
    try {
      await _repo.init();
      if (_repo.getCardCount() > 0) {
        debugPrint('DemoCardSeeder: Cards already exist, skipping seed');
        return;
      }

      debugPrint('DemoCardSeeder: Seeding ${_cards.length} demo cards...');
      final imagesDir = await _repo.getCardImagesDirectory();

      for (final card in _cards) {
        await _seedCard(card, imagesDir);
      }

      debugPrint('DemoCardSeeder: Done! ${_cards.length} cards seeded');
    } catch (e) {
      debugPrint('DemoCardSeeder: Error seeding cards: $e');
    }
  }

  Future<void> _seedCard(_DemoCard card, Directory imagesDir) async {
    final cardId = _uuid.v4();
    final now = DateTime.now();

    // Process front image
    final frontEncPath = '${imagesDir.path}/${cardId}_front.jpg.enc';
    await _processAndEncryptAsset(card.frontAsset, frontEncPath);

    // Process back image if present
    String? backEncPath;
    if (card.backAsset != null) {
      backEncPath = '${imagesDir.path}/${cardId}_back.jpg.enc';
      await _processAndEncryptAsset(card.backAsset!, backEncPath);
    }

    final category = CardCategoryMetadata.getCategoryForCardType(card.cardType);

    final model = WalletCardModel(
      id: cardId,
      name: card.name,
      cardTypeIndex: card.cardType.index,
      frontImagePath: frontEncPath,
      backImagePath: backEncPath,
      createdAt: now,
      updatedAt: now,
      displayOrder: card.displayOrder,
      categoryIndex: category.index,
      displayFormatIndex: card.displayFormat.index,
      hasFrontBarcode: card.hasFrontBarcode,
      hasBackBarcode: card.hasBackBarcode,
    );

    await _repo.addCard(model);
    debugPrint('DemoCardSeeder: Seeded "${card.name}" (${cardId.substring(0, 8)})');
  }

  /// Load asset as-is (no rotation), write to temp file, encrypt.
  Future<void> _processAndEncryptAsset(String assetPath, String encryptedDestPath) async {
    final bytes = await rootBundle.load(assetPath);
    final imageBytes = bytes.buffer.asUint8List();

    // Store images as-is - demo mockups are already correctly oriented
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/demo_seed_${DateTime.now().millisecondsSinceEpoch}.png');
    await tempFile.writeAsBytes(imageBytes);

    await _encryption.encryptFile(tempFile.path, encryptedDestPath);

    // Clean up temp file
    await tempFile.delete();
  }

}

class _DemoCard {
  final String frontAsset;
  final String? backAsset;
  final String name;
  final CardType cardType;
  final DisplayFormat displayFormat;
  final bool hasFrontBarcode;
  final bool hasBackBarcode;
  final int displayOrder;

  const _DemoCard({
    required this.frontAsset,
    this.backAsset,
    required this.name,
    required this.cardType,
    required this.displayFormat,
    required this.hasFrontBarcode,
    required this.hasBackBarcode,
    required this.displayOrder,
  });
}
