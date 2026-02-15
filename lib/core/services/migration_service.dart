import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import '../services/encryption_service.dart';
import '../../data/models/wallet_card_model.dart';

/// Handles data migration for existing users when security features are added.
/// Manages versioned migrations with crash safety.
class MigrationService {
  static final MigrationService _instance = MigrationService._();
  factory MigrationService() => _instance;
  MigrationService._();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final EncryptionService _encryptionService = EncryptionService();

  static const String _migrationVersionKey = 'migration_version';
  static const String _migrationInProgressKey = 'migration_in_progress';
  static const String _boxName = 'wallet_cards';

  /// Run pending migrations. Call before opening Hive boxes normally.
  Future<void> runMigrations() async {
    final versionStr = await _secureStorage.read(key: _migrationVersionKey);
    final currentVersion = int.tryParse(versionStr ?? '') ?? 0;

    // Check for interrupted migration
    final inProgress = await _secureStorage.read(key: _migrationInProgressKey);
    if (inProgress == 'true') {
      debugPrint('MigrationService: Recovering from interrupted migration');
      // Reset and re-run from same version
      await _secureStorage.delete(key: _migrationInProgressKey);
    }

    if (currentVersion < 1) {
      await _migrateV0ToV1();
    }
  }

  /// Version 0 -> 1: Encrypt Hive box and encrypt card images.
  Future<void> _migrateV0ToV1() async {
    debugPrint('MigrationService: Starting v0 -> v1 migration');
    await _secureStorage.write(key: _migrationInProgressKey, value: 'true');

    try {
      // Step 1: Read all cards from unencrypted box
      List<Map<String, dynamic>> cardJsonList = [];

      // Check if old unencrypted box exists
      final bool boxExists = await Hive.boxExists(_boxName);
      if (boxExists) {
        final Box<WalletCardModel> oldBox =
            await Hive.openBox<WalletCardModel>(_boxName);
        for (final card in oldBox.values) {
          cardJsonList.add(card.toJson());
        }
        await oldBox.close();

        if (cardJsonList.isNotEmpty) {
          // Step 2: Encrypt card images
          for (int i = 0; i < cardJsonList.length; i++) {
            final cardJson = cardJsonList[i];

            // Encrypt front image
            final frontPath = cardJson['frontImagePath'] as String;
            if (await File(frontPath).exists() && !frontPath.endsWith('.enc')) {
              final encPath = '$frontPath.enc';
              await _encryptionService.encryptFile(frontPath, encPath);
              await _encryptionService.secureDelete(frontPath);
              cardJson['frontImagePath'] = encPath;
            }

            // Encrypt back image
            final backPath = cardJson['backImagePath'] as String?;
            if (backPath != null &&
                await File(backPath).exists() &&
                !backPath.endsWith('.enc')) {
              final encPath = '$backPath.enc';
              await _encryptionService.encryptFile(backPath, encPath);
              await _encryptionService.secureDelete(backPath);
              cardJson['backImagePath'] = encPath;
            }
          }

          // Step 3: Delete old unencrypted box
          await Hive.deleteBoxFromDisk(_boxName);

          // Step 4: Open new encrypted box and write cards back
          final cipher = await _encryptionService.getHiveCipher();
          final Box<WalletCardModel> newBox =
              await Hive.openBox<WalletCardModel>(
            _boxName,
            encryptionCipher: cipher,
          );

          for (final cardJson in cardJsonList) {
            final card = WalletCardModel.fromJson(cardJson);
            await newBox.put(card.id, card);
          }
          await newBox.close();
        } else {
          // No cards - just delete old box and we'll open encrypted on next init
          await Hive.deleteBoxFromDisk(_boxName);
        }
      }

      // Mark migration complete
      await _secureStorage.write(key: _migrationVersionKey, value: '1');
      await _secureStorage.delete(key: _migrationInProgressKey);
      debugPrint('MigrationService: v0 -> v1 migration complete');
    } catch (e) {
      debugPrint('MigrationService: Migration failed: $e');
      await _secureStorage.delete(key: _migrationInProgressKey);
      // Don't rethrow - allow app to continue even if migration fails
      // The app will retry on next launch since version wasn't updated
    }
  }
}
