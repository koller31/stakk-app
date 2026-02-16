import 'package:hive/hive.dart';
import '../models/business_connection_model.dart';
import '../../core/services/encryption_service.dart';

/// Repository for managing business OAuth connections in encrypted Hive storage
class BusinessConnectionRepository {
  static const String _boxName = 'business_connections';
  Box<BusinessConnectionModel>? _box;

  /// Initialize the repository and open encrypted Hive box.
  Future<void> init({HiveAesCipher? cipher}) async {
    if (_box != null && _box!.isOpen) return;

    final encCipher = cipher ?? await EncryptionService().getHiveCipher();
    _box = await Hive.openBox<BusinessConnectionModel>(
      _boxName,
      encryptionCipher: encCipher,
    );
  }

  void _ensureInitialized() {
    if (_box == null || !_box!.isOpen) {
      throw Exception(
          'BusinessConnectionRepository not initialized. Call init() first.');
    }
  }

  /// Get all saved connections
  List<BusinessConnectionModel> getAllConnections() {
    _ensureInitialized();
    return _box!.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Get a connection by ID
  BusinessConnectionModel? getById(String id) {
    _ensureInitialized();
    return _box!.get(id);
  }

  /// Add a new connection
  Future<void> addConnection(BusinessConnectionModel connection) async {
    _ensureInitialized();
    await _box!.put(connection.id, connection);
  }

  /// Update an existing connection
  Future<void> updateConnection(BusinessConnectionModel connection) async {
    _ensureInitialized();
    await _box!.put(connection.id, connection);
  }

  /// Delete a connection by ID
  Future<void> deleteConnection(String id) async {
    _ensureInitialized();
    await _box!.delete(id);
  }

  /// Get count of connections
  int getConnectionCount() {
    _ensureInitialized();
    return _box!.length;
  }

  /// Close the repository
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
  }
}
