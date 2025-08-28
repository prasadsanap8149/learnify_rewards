import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/audit_log.dart';

class FirestoreAuditLogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'audit_logs';

  // Create audit log
  Future<void> createAuditLog(AuditLog log) async {
    try {
      await _firestore.collection(_collection).doc(log.id).set(log.toJson());
    } catch (e) {
      throw Exception('Failed to create audit log: $e');
    }
  }

  // Get audit logs for user
  Stream<List<AuditLog>> getAuditLogsStream(
    String userId, {
    AuditAction? action,
    AuditEntity? entity,
    int limit = 50,
  }) {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      if (action != null) {
        query =
            query.where('action', isEqualTo: action.toString().split('.').last);
      }

      if (entity != null) {
        query =
            query.where('entity', isEqualTo: entity.toString().split('.').last);
      }

      return query.limit(limit).snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return AuditLog.fromJson(data);
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to get audit logs stream: $e');
    }
  }

  // Get audit logs by admin
  Future<List<AuditLog>> getAuditLogsByAdmin(
    String adminId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('adminId', isEqualTo: adminId)
          .orderBy('timestamp', descending: true);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AuditLog.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get audit logs by admin: $e');
    }
  }

  // Get audit logs by entity
  Future<List<AuditLog>> getAuditLogsByEntity(
    AuditEntity entity,
    String entityId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('entity', isEqualTo: entity.toString().split('.').last)
          .where('entityId', isEqualTo: entityId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AuditLog.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get audit logs by entity: $e');
    }
  }

  // Get audit logs by action and date range
  Future<List<AuditLog>> getAuditLogsByActionAndDateRange(
    AuditAction action,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('action', isEqualTo: action.toString().split('.').last)
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AuditLog.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get audit logs by action and date range: $e');
    }
  }

  // Get audit statistics
  Future<Map<String, int>> getAuditStatistics({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? adminId,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      if (adminId != null) {
        query = query.where('adminId', isEqualTo: adminId);
      }

      final snapshot = await query.get();

      Map<String, int> stats = {
        'total': 0,
        'userActions': 0,
        'adminActions': 0,
      };

      // Initialize action counters
      for (final action in AuditAction.values) {
        stats[action.toString().split('.').last] = 0;
      }

      // Initialize entity counters
      for (final entity in AuditEntity.values) {
        stats['${entity.toString().split('.').last}Actions'] = 0;
      }

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        stats['total'] = (stats['total'] ?? 0) + 1;

        if (data['adminId'] != null) {
          stats['adminActions'] = (stats['adminActions'] ?? 0) + 1;
        } else {
          stats['userActions'] = (stats['userActions'] ?? 0) + 1;
        }

        final action = data['action'] as String?;
        if (action != null) {
          stats[action] = (stats[action] ?? 0) + 1;
        }

        final entity = data['entity'] as String?;
        if (entity != null) {
          final key = '${entity}Actions';
          stats[key] = (stats[key] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get audit statistics: $e');
    }
  }

  // Delete old audit logs (for cleanup)
  Future<int> deleteOldAuditLogs(DateTime beforeDate) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('timestamp', isLessThan: beforeDate)
          .get();

      final batch = _firestore.batch();
      int deleteCount = 0;

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        deleteCount++;
      }

      await batch.commit();
      return deleteCount;
    } catch (e) {
      throw Exception('Failed to delete old audit logs: $e');
    }
  }

  // Get compliance report
  Future<List<AuditLog>> getComplianceReport({
    DateTime? startDate,
    DateTime? endDate,
    List<AuditAction>? actions,
    List<AuditEntity>? entities,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .orderBy('timestamp', descending: true);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      List<AuditLog> logs = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AuditLog.fromJson(data);
      }).toList();

      // Filter by actions if specified
      if (actions != null && actions.isNotEmpty) {
        logs = logs.where((log) => actions.contains(log.action)).toList();
      }

      // Filter by entities if specified
      if (entities != null && entities.isNotEmpty) {
        logs = logs.where((log) => entities.contains(log.entity)).toList();
      }

      return logs;
    } catch (e) {
      throw Exception('Failed to get compliance report: $e');
    }
  }
}
