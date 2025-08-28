import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/age_verification.dart';

class FirestoreAgeVerificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'age_verifications';

  // Create age verification
  Future<void> createAgeVerification(AgeVerification verification) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(verification.id)
          .set(verification.toJson());
    } catch (e) {
      throw Exception('Failed to create age verification: $e');
    }
  }

  // Get age verification by user ID
  Future<AgeVerification?> getAgeVerificationByUserId(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final data = snapshot.docs.first.data();
      return AgeVerification.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get age verification: $e');
    }
  }

  // Update age verification status
  Future<void> updateAgeVerificationStatus(
    String verificationId,
    AgeVerificationStatus status,
    String verifiedBy, {
    String? rejectionReason,
  }) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'verifiedBy': verifiedBy,
        'verifiedAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      if (rejectionReason != null) {
        updateData['rejectionReason'] = rejectionReason;
      }

      await _firestore
          .collection(_collection)
          .doc(verificationId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update age verification status: $e');
    }
  }

  // Get pending verifications for review
  Future<List<AgeVerification>> getPendingVerifications({
    AgeVerificationMethod? method,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: false);

      if (method != null) {
        query =
            query.where('method', isEqualTo: method.toString().split('.').last);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AgeVerification.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get pending verifications: $e');
    }
  }

  // Get verifications requiring review
  Future<List<AgeVerification>> getVerificationsRequiringReview({
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'requiresReview')
          .orderBy('createdAt', descending: false)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AgeVerification.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get verifications requiring review: $e');
    }
  }

  // Get expired verifications
  Future<List<AgeVerification>> getExpiredVerifications({
    int limit = 100,
  }) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'verified')
          .where('expiresAt', isLessThan: now)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AgeVerification.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get expired verifications: $e');
    }
  }

  // Update parent consent
  Future<void> updateParentConsent(
    String verificationId,
    String parentEmail,
    String parentName,
    DateTime consentDate,
  ) async {
    try {
      await _firestore.collection(_collection).doc(verificationId).update({
        'parentEmail': parentEmail,
        'parentName': parentName,
        'parentConsentDate': consentDate,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to update parent consent: $e');
    }
  }

  // Delete age verification
  Future<void> deleteAgeVerification(String verificationId) async {
    try {
      await _firestore.collection(_collection).doc(verificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete age verification: $e');
    }
  }

  // Get verification statistics
  Future<Map<String, int>> getVerificationStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();

      Map<String, int> stats = {
        'total': 0,
        'pending': 0,
        'verified': 0,
        'rejected': 0,
        'expired': 0,
        'requiresReview': 0,
        'selfReported': 0,
        'parentalConfirmation': 0,
        'documentVerification': 0,
        'thirdPartyVerification': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        stats['total'] = (stats['total'] ?? 0) + 1;

        final status = data['status'] as String?;
        if (status != null) {
          stats[status] = (stats[status] ?? 0) + 1;
        }

        final method = data['method'] as String?;
        if (method != null) {
          stats[method] = (stats[method] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get verification statistics: $e');
    }
  }

  // Batch update verification statuses
  Future<void> batchUpdateVerificationStatuses(
    List<String> verificationIds,
    AgeVerificationStatus status,
    String verifiedBy,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final id in verificationIds) {
        final docRef = _firestore.collection(_collection).doc(id);
        batch.update(docRef, {
          'status': status.toString().split('.').last,
          'verifiedBy': verifiedBy,
          'verifiedAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update verification statuses: $e');
    }
  }

  // Get verification history for user
  Future<List<AgeVerification>> getVerificationHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AgeVerification.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get verification history: $e');
    }
  }
}
