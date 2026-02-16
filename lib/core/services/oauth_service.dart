import 'package:flutter_appauth/flutter_appauth.dart';
import '../../data/models/business_connection_model.dart';
import '../../data/models/business_connection_config.dart';
import '../../data/models/oauth_result.dart';
import 'auto_lock_service.dart';

/// Service for handling OAuth2 authorization flows with business identity providers.
class OAuthService {
  static final OAuthService _instance = OAuthService._();
  factory OAuthService() => _instance;
  OAuthService._();

  final FlutterAppAuth _appAuth = const FlutterAppAuth();

  static const String _redirectUri = 'com.idswipe.idswipe://oauth/callback';

  /// Initiates OAuth2 authorization flow with PKCE.
  /// Uses discovery URL if available, otherwise falls back to explicit endpoints.
  Future<OAuthResult> authorize(BusinessConnectionConfig config) async {
    // Suppress auto-lock while OAuth browser is open (2 min grace period)
    AutoLockService().suppressLockFor();

    try {
      final AuthorizationTokenResponse result;

      if (config.discoveryUrl != null) {
        // Use OpenID Connect discovery
        result = await _appAuth.authorizeAndExchangeCode(
          AuthorizationTokenRequest(
            config.clientId,
            _redirectUri,
            discoveryUrl: config.discoveryUrl,
            scopes: config.scopes,
            promptValues: ['consent'],
          ),
        );
      } else {
        // Use explicit endpoints
        if (config.authEndpoint == null || config.tokenEndpoint == null) {
          throw Exception(
            'Either discoveryUrl or both authEndpoint and tokenEndpoint must be provided',
          );
        }

        result = await _appAuth.authorizeAndExchangeCode(
          AuthorizationTokenRequest(
            config.clientId,
            _redirectUri,
            serviceConfiguration: AuthorizationServiceConfiguration(
              authorizationEndpoint: config.authEndpoint!,
              tokenEndpoint: config.tokenEndpoint!,
            ),
            scopes: config.scopes,
            promptValues: ['consent'],
          ),
        );
      }

      if (result.accessToken == null) {
        throw Exception('OAuth provider did not return an access token');
      }

      return OAuthResult(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken,
        idToken: result.idToken,
        expiresAt: result.accessTokenExpirationDateTime,
        scopes: config.scopes,
      );
    } catch (e) {
      throw Exception('OAuth authorization failed: $e');
    }
  }

  /// Refreshes an access token using a refresh token.
  /// Returns null if no refresh token is available.
  Future<OAuthResult?> refreshToken(BusinessConnectionModel connection) async {
    if (connection.refreshToken == null) {
      return null;
    }

    try {
      final TokenResponse result;

      if (connection.discoveryUrl != null) {
        result = await _appAuth.token(
          TokenRequest(
            connection.clientId,
            _redirectUri,
            discoveryUrl: connection.discoveryUrl,
            refreshToken: connection.refreshToken,
            scopes: connection.scopes,
          ),
        );
      } else {
        if (connection.tokenEndpoint == null) {
          throw Exception('Token endpoint is required for token refresh');
        }

        result = await _appAuth.token(
          TokenRequest(
            connection.clientId,
            _redirectUri,
            serviceConfiguration: AuthorizationServiceConfiguration(
              authorizationEndpoint: connection.authEndpoint ?? '',
              tokenEndpoint: connection.tokenEndpoint!,
            ),
            refreshToken: connection.refreshToken,
            scopes: connection.scopes,
          ),
        );
      }

      if (result.accessToken == null) {
        throw Exception('Token refresh did not return an access token');
      }

      return OAuthResult(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken ?? connection.refreshToken,
        idToken: result.idToken,
        expiresAt: result.accessTokenExpirationDateTime,
        scopes: connection.scopes,
      );
    } catch (e) {
      throw Exception('Token refresh failed: $e');
    }
  }

  /// Gets a valid access token for the connection.
  /// If the current token is expired, attempts to refresh it.
  /// Throws an exception if both the current token and refresh fail.
  Future<String> getValidAccessToken(BusinessConnectionModel connection) async {
    if (!isTokenExpired(connection)) {
      return connection.accessToken!;
    }

    final refreshedResult = await refreshToken(connection);
    if (refreshedResult == null) {
      throw Exception(
        'Access token is expired and no refresh token is available',
      );
    }

    return refreshedResult.accessToken;
  }

  /// Checks if the connection's access token is expired.
  bool isTokenExpired(BusinessConnectionModel connection) {
    return connection.isTokenExpired;
  }
}
