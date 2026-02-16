import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/wallet_card_model.dart';
import '../../core/services/encryption_service.dart';

/// Repository for managing wallet cards in local storage
class WalletCardRepository {
  static const String _boxName = 'wallet_cards';
  Box<WalletCardModel>? _box;

  /// Initialize the repository and open encrypted Hive box.
  Future<void> init({HiveAesCipher? cipher}) async {
    if (_box != null && _box!.isOpen) return;

    // Use provided cipher, or get one from EncryptionService
    final encCipher = cipher ?? await EncryptionService().getHiveCipher();
    _box = await Hive.openBox<WalletCardModel>(
      _boxName,
      encryptionCipher: encCipher,
    );
  }

  /// Ensure box is initialized
  void _ensureInitialized() {
    if (_box == null || !_box!.isOpen) {
      throw Exception('WalletCardRepository not initialized. Call init() first.');
    }
  }

  /// Get all wallet cards sorted by display order
  List<WalletCardModel> getAllCards() {
    _ensureInitialized();
    final cards = _box!.values.toList();
    cards.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return cards;
  }

  /// Get a single card by ID
  WalletCardModel? getCardById(String id) {
    _ensureInitialized();
    return _box!.get(id);
  }

  /// Add a new wallet card
  Future<void> addCard(WalletCardModel card) async {
    _ensureInitialized();
    await _box!.put(card.id, card);
  }

  /// Update an existing card
  Future<void> updateCard(WalletCardModel card) async {
    _ensureInitialized();
    await _box!.put(card.id, card);
  }

  /// Delete a card by ID
  Future<void> deleteCard(String id) async {
    _ensureInitialized();
    final card = _box!.get(id);
    if (card != null) {
      // Delete associated image files
      await _deleteImageFile(card.frontImagePath);
      if (card.backImagePath != null) {
        await _deleteImageFile(card.backImagePath!);
      }
      await _box!.delete(id);
    }
  }

  /// Securely delete image file from storage
  Future<void> _deleteImageFile(String path) async {
    try {
      await EncryptionService().secureDelete(path);
    } catch (e) {
      debugPrint('Error deleting image file: $e');
    }
  }

  /// Update display order for cards
  Future<void> reorderCards(List<String> cardIds) async {
    _ensureInitialized();
    for (int i = 0; i < cardIds.length; i++) {
      final card = _box!.get(cardIds[i]);
      if (card != null) {
        final updatedCard = card.copyWith(
          displayOrder: i,
          updatedAt: DateTime.now(),
        );
        await _box!.put(cardIds[i], updatedCard);
      }
    }
  }

  /// Get cards by type
  List<WalletCardModel> getCardsByType(CardType type) {
    _ensureInitialized();
    return _box!.values.where((card) => card.cardType == type).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  /// Get cards by business connection ID
  List<WalletCardModel> getCardsByConnection(String connectionId) {
    _ensureInitialized();
    return _box!.values
        .where((card) => card.businessConnectionId == connectionId)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  /// Search cards by name or nickname
  List<WalletCardModel> searchCards(String query) {
    _ensureInitialized();
    final lowerQuery = query.toLowerCase();
    return _box!.values.where((card) {
      return card.name.toLowerCase().contains(lowerQuery) ||
          (card.nickname?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  /// Get directory for storing card images
  Future<Directory> getCardImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cardImagesDir = Directory('${appDir.path}/wallet_cards');
    if (!await cardImagesDir.exists()) {
      await cardImagesDir.create(recursive: true);
    }
    return cardImagesDir;
  }

  /// Get count of all cards
  int getCardCount() {
    _ensureInitialized();
    return _box!.length;
  }

  /// Clear all cards (use with caution!)
  Future<void> clearAllCards() async {
    _ensureInitialized();
    // Delete all image files
    for (final card in _box!.values) {
      await _deleteImageFile(card.frontImagePath);
      if (card.backImagePath != null) {
        await _deleteImageFile(card.backImagePath!);
      }
    }
    await _box!.clear();
  }

  /// Close the repository
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
  }
}
