import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/oauth_service.dart';
import '../../../core/services/badge_api_service.dart';
import '../../../data/models/business_connection_model.dart';
import '../../../data/models/business_connection_config.dart';
import '../../../data/models/badge_profile.dart';
import '../../../data/repositories/business_connection_repository.dart';

/// Provider managing business OAuth connections and badge data
class BusinessConnectionProvider extends ChangeNotifier {
  final BusinessConnectionRepository _repository =
      BusinessConnectionRepository();
  final OAuthService _oauthService = OAuthService();
  final BadgeApiService _badgeApiService = BadgeApiService();

  List<BusinessConnectionModel> _connections = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BusinessConnectionModel> get connections => _connections;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Initialize and load connections
  Future<void> init() async {
    await _repository.init();
    _connections = _repository.getAllConnections();
    notifyListeners();
  }

  /// Add a new business connection via OAuth flow
  /// Returns the new connection on success, null on failure
  Future<BusinessConnectionModel?> addConnection(
      BusinessConnectionConfig config) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Trigger OAuth flow
      final oauthResult = await _oauthService.authorize(config);

      // Create connection model
      final now = DateTime.now();
      final connection = BusinessConnectionModel(
        id: const Uuid().v4(),
        providerName: config.providerName,
        issuerUrl: config.issuerUrl,
        clientId: config.clientId,
        discoveryUrl: config.discoveryUrl,
        authEndpoint: config.authEndpoint,
        tokenEndpoint: config.tokenEndpoint,
        badgeApiEndpoint: config.badgeApiEndpoint,
        accessToken: oauthResult.accessToken,
        refreshToken: oauthResult.refreshToken,
        tokenExpiry: oauthResult.expiresAt,
        createdAt: now,
        updatedAt: now,
        logoUrl: config.logoUrl,
        scopes: config.scopes,
      );

      // Save to repository
      await _repository.addConnection(connection);
      _connections = _repository.getAllConnections();
      _errorMessage = null;
      notifyListeners();

      debugPrint(
          'BusinessConnectionProvider: Connection added for ${config.providerName}');
      return connection;
    } catch (e) {
      debugPrint('BusinessConnectionProvider: Error adding connection: $e');
      _errorMessage = 'Failed to connect: $e';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh tokens for a connection
  Future<bool> refreshConnection(String connectionId) async {
    try {
      final connection = _repository.getById(connectionId);
      if (connection == null) return false;

      final oauthResult = await _oauthService.refreshToken(connection);
      if (oauthResult == null) {
        _errorMessage = 'No refresh token available. Please reconnect.';
        notifyListeners();
        return false;
      }

      final updated = connection.copyWith(
        accessToken: oauthResult.accessToken,
        refreshToken: oauthResult.refreshToken ?? connection.refreshToken,
        tokenExpiry: oauthResult.expiresAt,
        updatedAt: DateTime.now(),
      );

      await _repository.updateConnection(updated);
      _connections = _repository.getAllConnections();
      notifyListeners();

      debugPrint(
          'BusinessConnectionProvider: Refreshed connection $connectionId');
      return true;
    } catch (e) {
      debugPrint('BusinessConnectionProvider: Error refreshing: $e');
      _errorMessage = 'Failed to refresh: $e';
      notifyListeners();
      return false;
    }
  }

  /// Remove a connection and disconnect
  Future<void> removeConnection(String connectionId) async {
    try {
      await _repository.deleteConnection(connectionId);
      _connections = _repository.getAllConnections();
      _errorMessage = null;
      notifyListeners();
      debugPrint(
          'BusinessConnectionProvider: Removed connection $connectionId');
    } catch (e) {
      debugPrint('BusinessConnectionProvider: Error removing: $e');
      _errorMessage = 'Failed to disconnect: $e';
      notifyListeners();
    }
  }

  /// Fetch badge profile from business API
  Future<BadgeProfile?> fetchBadge(String connectionId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final connection = _repository.getById(connectionId);
      if (connection == null) {
        throw Exception('Connection not found');
      }

      // Get valid access token (auto-refresh if needed)
      final accessToken =
          await _oauthService.getValidAccessToken(connection);

      // Fetch badge profile
      final badge = await _badgeApiService.fetchBadgeProfile(
        connection.badgeApiEndpoint,
        accessToken,
      );

      // Update connection's last-used timestamp
      final updated = connection.copyWith(updatedAt: DateTime.now());
      await _repository.updateConnection(updated);
      _connections = _repository.getAllConnections();

      debugPrint(
          'BusinessConnectionProvider: Fetched badge for ${badge.employeeName}');
      return badge;
    } catch (e) {
      debugPrint('BusinessConnectionProvider: Error fetching badge: $e');
      _errorMessage = 'Failed to fetch badge: $e';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get a specific connection by ID
  BusinessConnectionModel? getConnection(String id) {
    return _repository.getById(id);
  }

  /// Add a demo connection (bypasses OAuth entirely)
  /// Returns the connection so the UI can proceed to badge preview
  Future<BusinessConnectionModel?> addDemoConnection() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final connection = BusinessConnectionModel(
        id: const Uuid().v4(),
        providerName: 'IDswipe Demo Corp',
        clientId: 'demo-client-id',
        badgeApiEndpoint: 'https://demo.idswipe.local/api/badge',
        accessToken: 'demo-access-token',
        refreshToken: 'demo-refresh-token',
        tokenExpiry: now.add(const Duration(days: 365)),
        createdAt: now,
        updatedAt: now,
        scopes: const ['openid', 'profile', 'badge'],
      );

      await _repository.addConnection(connection);
      _connections = _repository.getAllConnections();
      _errorMessage = null;
      notifyListeners();

      debugPrint(
          'BusinessConnectionProvider: Demo connection added');
      return connection;
    } catch (e) {
      debugPrint('BusinessConnectionProvider: Error adding demo connection: $e');
      _errorMessage = 'Failed to create demo connection: $e';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
