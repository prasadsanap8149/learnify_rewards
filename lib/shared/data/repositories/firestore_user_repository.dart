import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnify_rewards/shared/data/models/user_model.dart';
import 'package:learnify_rewards/shared/domain/entities/user.dart';
import 'package:learnify_rewards/shared/domain/repositories/user_repository.dart';

class FirestoreUserRepository implements UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'users';

  @override
  Future<User?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson({...doc.data()!, 'uid': uid});
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  @override
  Future<void> createUser(User user) async {
    try {
      final userModel = UserModel(
        uid: user.uid,
        displayName: user.displayName,
        email: user.email,
        photoUrl: user.photoUrl,
        role: user.role,
        status: user.status,
        ageGroup: user.ageGroup,
        verificationStatus: user.verificationStatus,
      );

      final data = userModel.toJson();
      data.addAll({
        'stats': {
          'totalLP': 0,
          'totalEarnings': 0.0,
          'totalWithdrawals': 0.0,
          'remaining': 0.0,
          'streakDays': 0,
          'totalAER': 0.0,
        },
        'adStats': {
          'impressionsByFormat': {
            'banner': 0,
            'interstitial': 0,
            'rewarded': 0,
            'rewardedInterstitial': 0,
          },
          'lastAdAt': null,
          'consentString': '',
          'totalEngagementTime': 0,
        },
        'flags': {
          'suspicious': false,
          'reasons': [],
          'reviewedAt': null,
          'reviewedBy': null,
        },
        'preferences': {
          'theme': 'system',
          'notifications': true,
          'language': 'en',
          'accessibility': false,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection(_collection).doc(user.uid).set(data);
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  @override
  Future<void> updateUser(User user) async {
    try {
      final userModel = UserModel(
        uid: user.uid,
        displayName: user.displayName,
        email: user.email,
        photoUrl: user.photoUrl,
        role: user.role,
        status: user.status,
        ageGroup: user.ageGroup,
        verificationStatus: user.verificationStatus,
      );

      final data = userModel.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();
      data['lastLoginAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_collection).doc(user.uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Future<void> updateUserStats(String uid, Map<String, dynamic> stats) async {
    try {
      await _firestore.collection(_collection).doc(uid).update({
        'stats': stats,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user stats: $e');
    }
  }

  Future<void> flagUser(
      String uid, List<String> reasons, String reviewedBy) async {
    try {
      await _firestore.collection(_collection).doc(uid).update({
        'flags.suspicious': true,
        'flags.reasons': reasons,
        'flags.reviewedAt': FieldValue.serverTimestamp(),
        'flags.reviewedBy': reviewedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to flag user: $e');
    }
  }

  Stream<User?> getUserStream(String uid) {
    return _firestore.collection(_collection).doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson({...doc.data()!, 'uid': uid});
      }
      return null;
    });
  }

  /// Update user status (for admin/security operations)
  Future<void> updateUserStatus(String uid, UserStatus status,
      {String? reason}) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (reason != null) {
        updateData['statusChangeReason'] = reason;
      }

      await _firestore.collection(_collection).doc(uid).update(updateData);
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }

  /// Update user role (for admin operations)
  Future<void> updateUserRole(String uid, UserRole role,
      {String? updatedBy}) async {
    try {
      final updateData = {
        'role': role.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (updatedBy != null) {
        updateData['roleUpdatedBy'] = updatedBy;
      }

      await _firestore.collection(_collection).doc(uid).update(updateData);
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  // Update user fields with custom data
  Future<void> updateUserFields(String uid, Map<String, dynamic> fields) async {
    try {
      await _firestore.collection(_collection).doc(uid).update(fields);
    } catch (e) {
      throw Exception('Failed to update user fields: $e');
    }
  }
}
