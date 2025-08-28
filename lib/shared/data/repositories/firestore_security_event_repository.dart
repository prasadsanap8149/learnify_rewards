import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/security_event.dart';

class FirestoreSecurityEventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'security_events';

  // Create security event
  Future<void> createSecurityEvent(SecurityEvent event) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(event.id)
          .set(event.toJson());
    } catch (e) {
      throw Exception('Failed to create security event: $e');
    }
  }

  // Get security events for user
  Stream<List<SecurityEvent>> getSecurityEventsStream(
    String userId, {
    SecurityEventType? type,
    SecuritySeverity? severity,
    SecurityStatus? status,
    int limit = 50,
  }) {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }

      if (severity != null) {
        query = query.where('severity',
            isEqualTo: severity.toString().split('.').last);
      }

      if (status != null) {
        query =
            query.where('status', isEqualTo: status.toString().split('.').last);
      }

      return query.limit(limit).snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return SecurityEvent.fromJson(data);
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to get security events stream: $e');
    }
  }

  // Update security event status
  Future<void> updateSecurityEventStatus(
    String eventId,
    SecurityStatus status,
    String reviewedBy, {
    String? resolution,
  }) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'reviewedBy': reviewedBy,
        'reviewedAt': DateTime.now(),
      };

      if (resolution != null) {
        updateData['resolution'] = resolution;
      }

      await _firestore.collection(_collection).doc(eventId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update security event status: $e');
    }
  }

  // Get open security events by severity
  Future<List<SecurityEvent>> getOpenEventsBySeverity(
    SecuritySeverity severity, {
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'open')
          .where('severity', isEqualTo: severity.toString().split('.').last)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SecurityEvent.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get open events by severity: $e');
    }
  }

  // Get security events by type and date range
  Future<List<SecurityEvent>> getEventsByTypeAndDateRange(
    SecurityEventType type,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('type', isEqualTo: type.toString().split('.').last)
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SecurityEvent.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get events by type and date range: $e');
    }
  }

  // Add related event to existing security event
  Future<void> addRelatedEvent(String eventId, String relatedEventId) async {
    try {
      await _firestore.collection(_collection).doc(eventId).update({
        'relatedEvents': FieldValue.arrayUnion([relatedEventId]),
      });
    } catch (e) {
      throw Exception('Failed to add related event: $e');
    }
  }

  // Get security statistics for dashboard
  Future<Map<String, int>> getSecurityStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();

      Map<String, int> stats = {
        'total': 0,
        'open': 0,
        'resolved': 0,
        'critical': 0,
        'high': 0,
        'medium': 0,
        'low': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        stats['total'] = (stats['total'] ?? 0) + 1;

        final status = data['status'] as String?;
        if (status != null) {
          stats[status] = (stats[status] ?? 0) + 1;
        }

        final severity = data['severity'] as String?;
        if (severity != null) {
          stats[severity] = (stats[severity] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get security statistics: $e');
    }
  }

  // Delete security event (admin only)
  Future<void> deleteSecurityEvent(String eventId) async {
    try {
      await _firestore.collection(_collection).doc(eventId).delete();
    } catch (e) {
      throw Exception('Failed to delete security event: $e');
    }
  }

  // Get events for compliance review
  Future<List<SecurityEvent>> getEventsForCompliance({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 1000,
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

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SecurityEvent.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get events for compliance: $e');
    }
  }
}
