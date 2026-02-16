import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'encryption_service.dart';

/// Service for downloading remote images and encrypting them for local storage.
class ImageDownloadService {
  static final ImageDownloadService _instance = ImageDownloadService._();
  factory ImageDownloadService() => _instance;
  ImageDownloadService._();

  /// Downloads an image from a URL and encrypts it for secure storage.
  ///
  /// [url] - The remote image URL to download
  /// [cardId] - Unique identifier for the card
  /// [suffix] - Suffix to append to filename (e.g., 'front', 'back', 'card')
  ///
  /// Returns the path to the encrypted .enc file.
  ///
  /// Throws an [Exception] if:
  /// - The HTTP request fails
  /// - The response status is not 200
  /// - The download or encryption process fails
  Future<String> downloadAndEncrypt(
    String url,
    String cardId,
    String suffix,
  ) async {
    try {
      // Download the image
      final uri = Uri.parse(url);
      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // Check if response has content
        if (response.bodyBytes.isEmpty) {
          throw Exception('Downloaded image is empty from URL: $url');
        }

        // Set up storage directory
        final appDir = await getApplicationDocumentsDirectory();
        final walletDir = Directory('${appDir.path}/wallet_cards');
        if (!await walletDir.exists()) {
          await walletDir.create(recursive: true);
        }

        // Save to temp file
        final tempPath = '${walletDir.path}/${cardId}_${suffix}_temp';
        final tempFile = File(tempPath);
        await tempFile.writeAsBytes(response.bodyBytes);

        // Encrypt the file
        final encryptedPath = '${walletDir.path}/${cardId}_$suffix.enc';
        await EncryptionService().encryptFile(tempPath, encryptedPath);

        // Delete the unencrypted temp file
        await tempFile.delete();

        return encryptedPath;
      } else if (response.statusCode == 404) {
        throw Exception(
          'Image not found: HTTP 404 - $url',
        );
      } else if (response.statusCode == 403) {
        throw Exception(
          'Access forbidden: HTTP 403 - Check image URL permissions',
        );
      } else if (response.statusCode >= 500) {
        throw Exception(
          'Server error: HTTP ${response.statusCode} - ${response.reasonPhrase}',
        );
      } else {
        throw Exception(
          'Failed to download image: HTTP ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error while downloading image from $url: $e');
    }
  }
}
