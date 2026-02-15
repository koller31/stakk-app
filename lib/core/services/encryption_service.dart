import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// Service for encryption operations - Hive database encryption and file encryption.
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._();
  factory EncryptionService() => _instance;
  EncryptionService._();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _hiveKeyStorageKey = 'hive_encryption_key';
  static const String _imageKeyStorageKey = 'image_encryption_key';

  /// Get or create the 32-byte AES key for Hive box encryption.
  /// Stored in FlutterSecureStorage (Android Keystore / iOS Keychain).
  Future<Uint8List> getOrCreateHiveKey() async {
    final existing = await _secureStorage.read(key: _hiveKeyStorageKey);
    if (existing != null) {
      return Uint8List.fromList(existing.codeUnits);
    }

    // Generate 32 random bytes for AES-256
    final key = _generateRandomBytes(32);
    await _secureStorage.write(
      key: _hiveKeyStorageKey,
      value: String.fromCharCodes(key),
    );
    return key;
  }

  /// Returns a HiveAesCipher for opening encrypted Hive boxes.
  Future<HiveAesCipher> getHiveCipher() async {
    final key = await getOrCreateHiveKey();
    return HiveAesCipher(key);
  }

  /// Get or create a separate AES-256 key for image file encryption.
  Future<enc.Key> getOrCreateImageKey() async {
    final existing = await _secureStorage.read(key: _imageKeyStorageKey);
    if (existing != null) {
      return enc.Key.fromBase64(existing);
    }

    final key = enc.Key.fromSecureRandom(32);
    await _secureStorage.write(
      key: _imageKeyStorageKey,
      value: key.base64,
    );
    return key;
  }

  /// Encrypt a file using AES-256-GCM.
  /// Output format: [12-byte IV][ciphertext+tag]
  Future<void> encryptFile(String sourcePath, String destPath) async {
    final key = await getOrCreateImageKey();
    final sourceFile = File(sourcePath);
    final plaintext = await sourceFile.readAsBytes();

    // Generate random 12-byte IV for GCM
    final iv = enc.IV.fromSecureRandom(12);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encryptBytes(plaintext, iv: iv);

    // Write IV + encrypted data
    final output = File(destPath);
    final builder = BytesBuilder();
    builder.add(iv.bytes);
    builder.add(encrypted.bytes);
    await output.writeAsBytes(builder.toBytes());
  }

  // Global in-memory cache for decrypted images (path -> bytes).
  // Avoids re-decrypting every time a widget rebuilds or scrolls into view.
  final Map<String, Uint8List> _imageCache = {};

  /// Decrypt a file and return raw bytes. Results are cached in memory.
  Future<Uint8List> decryptFileToBytes(String encryptedPath) async {
    // Return cached if available
    final cached = _imageCache[encryptedPath];
    if (cached != null) return cached;

    final key = await getOrCreateImageKey();
    final file = File(encryptedPath);
    final data = await file.readAsBytes();

    // First 12 bytes are the IV
    final iv = enc.IV(data.sublist(0, 12));
    final ciphertext = data.sublist(12);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final decrypted = encrypter.decryptBytes(
      enc.Encrypted(ciphertext),
      iv: iv,
    );

    final bytes = Uint8List.fromList(decrypted);
    _imageCache[encryptedPath] = bytes;
    return bytes;
  }

  /// Read a plain file with caching.
  Future<Uint8List> readFileWithCache(String path) async {
    final cached = _imageCache[path];
    if (cached != null) return cached;

    final bytes = await File(path).readAsBytes();
    _imageCache[path] = bytes;
    return bytes;
  }

  /// Remove a path from the image cache (call when a card is deleted).
  void evictFromCache(String path) {
    _imageCache.remove(path);
  }

  /// Securely delete a file by overwriting with random bytes, then zeros, then deleting.
  Future<void> secureDelete(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return;

      final length = await file.length();
      if (length > 0) {
        // Overwrite with random bytes
        final random = _generateRandomBytes(length);
        await file.writeAsBytes(random, flush: true);
        // Overwrite with zeros
        await file.writeAsBytes(Uint8List(length), flush: true);
      }
      await file.delete();
    } catch (e) {
      // Fall back to regular delete if secure delete fails
      debugPrint('Secure delete fallback: $e');
      try {
        final file = File(filePath);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}
