import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/badge_profile.dart';

/// Service for fetching badge profile data from business badge APIs.
class BadgeApiService {
  static final BadgeApiService _instance = BadgeApiService._();
  factory BadgeApiService() => _instance;
  BadgeApiService._();

  /// Fetches badge profile data from the specified API endpoint.
  /// Requires a valid OAuth access token for authentication.
  Future<BadgeProfile> fetchBadgeProfile(
    String badgeApiEndpoint,
    String accessToken,
  ) async {
    try {
      final uri = Uri.parse(badgeApiEndpoint);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return BadgeProfile.fromJson(json);
      } else if (response.statusCode == 401) {
        throw Exception(
          'Authentication failed: Access token may be expired or invalid',
        );
      } else if (response.statusCode == 403) {
        throw Exception(
          'Access forbidden: Insufficient permissions to access badge data',
        );
      } else if (response.statusCode == 404) {
        throw Exception(
          'Badge profile not found at endpoint: $badgeApiEndpoint',
        );
      } else {
        throw Exception(
          'Failed to fetch badge profile: HTTP ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error while fetching badge profile: $e');
    }
  }
}
