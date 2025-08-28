import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_config.dart';

class FirestoreConfigRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'app_configs';

  // Create or update config
  Future<void> setConfig(AppConfig config) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(config.id)
          .set(config.toJson());
    } catch (e) {
      throw Exception('Failed to set config: $e');
    }
  }

  // Get config by key
  Future<AppConfig?> getConfig(String key) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('key', isEqualTo: key)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final data = snapshot.docs.first.data();
      final config = AppConfig.fromJson(data);

      return config.isActive ? config : null;
    } catch (e) {
      throw Exception('Failed to get config: $e');
    }
  }

  // Get configs by type
  Future<List<AppConfig>> getConfigsByType(ConfigType type) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('type', isEqualTo: type.toString().split('.').last)
          .where('status', isEqualTo: 'active')
          .get();

      return snapshot.docs
          .map((doc) => AppConfig.fromJson(doc.data()))
          .where((config) => config.isActive)
          .toList();
    } catch (e) {
      throw Exception('Failed to get configs by type: $e');
    }
  }

  // Get all active configs
  Stream<List<AppConfig>> getActiveConfigsStream() {
    try {
      return _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'active')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => AppConfig.fromJson(doc.data()))
            .where((config) => config.isActive)
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get active configs stream: $e');
    }
  }

  // Update config value
  Future<void> updateConfigValue(
    String key,
    dynamic value,
    String updatedBy,
  ) async {
    try {
      final existingConfig = await getConfig(key);
      if (existingConfig == null) {
        throw Exception('Config not found: $key');
      }

      final updatedConfig = AppConfig(
        id: existingConfig.id,
        key: existingConfig.key,
        type: existingConfig.type,
        value: value,
        status: existingConfig.status,
        description: existingConfig.description,
        metadata: existingConfig.metadata,
        createdAt: existingConfig.createdAt,
        updatedAt: DateTime.now(),
        updatedBy: updatedBy,
        effectiveFrom: existingConfig.effectiveFrom,
        effectiveUntil: existingConfig.effectiveUntil,
      );

      await setConfig(updatedConfig);
    } catch (e) {
      throw Exception('Failed to update config value: $e');
    }
  }

  // Delete config
  Future<void> deleteConfig(String configId) async {
    try {
      await _firestore.collection(_collection).doc(configId).delete();
    } catch (e) {
      throw Exception('Failed to delete config: $e');
    }
  }

  // Archive config
  Future<void> archiveConfig(String key, String updatedBy) async {
    try {
      final existingConfig = await getConfig(key);
      if (existingConfig == null) {
        throw Exception('Config not found: $key');
      }

      final archivedConfig = AppConfig(
        id: existingConfig.id,
        key: existingConfig.key,
        type: existingConfig.type,
        value: existingConfig.value,
        status: ConfigStatus.archived,
        description: existingConfig.description,
        metadata: existingConfig.metadata,
        createdAt: existingConfig.createdAt,
        updatedAt: DateTime.now(),
        updatedBy: updatedBy,
        effectiveFrom: existingConfig.effectiveFrom,
        effectiveUntil: existingConfig.effectiveUntil,
      );

      await setConfig(archivedConfig);
    } catch (e) {
      throw Exception('Failed to archive config: $e');
    }
  }

  // Get config history
  Future<List<AppConfig>> getConfigHistory(String key) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('key', isEqualTo: key)
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AppConfig.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get config history: $e');
    }
  }

  // Batch update configs
  Future<void> batchUpdateConfigs(List<AppConfig> configs) async {
    try {
      final batch = _firestore.batch();

      for (final config in configs) {
        final docRef = _firestore.collection(_collection).doc(config.id);
        batch.set(docRef, config.toJson());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update configs: $e');
    }
  }
}
