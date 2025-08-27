import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../../../core/config.dart';
import '../../../core/exceptions.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FlutterSecureStorage _secureStorage;
  final DeviceInfoPlugin _deviceInfo;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FlutterSecureStorage? secureStorage,
    DeviceInfoPlugin? deviceInfo,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user's UserModel
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore
        .collection(AppConfig.usersCollection)
        .doc(user.uid)
        .get();
    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc);
  }

  // Sign in with Google
  Future<UserModel> signInWithGoogle() async {
    try {
      // Google sign in implementation
      throw UnimplementedError('Google Sign In not implemented yet');
    } catch (e) {
      throw AuthException('Failed to sign in with Google: ${e.toString()}');
    }
  }

  // Create new user profile
  Future<void> createUserProfile({
    required String uid,
    required String displayName,
    required String email,
    required String ageGroup,
    String? photoUrl,
  }) async {
    try {
      final deviceData = await _getDeviceInfo();
      final now = DateTime.now();

      final userDoc = UserModel(
        id: uid,
        displayName: displayName,
        email: email,
        photoUrl: photoUrl,
        role: AppConfig.roleUser,
        status: 'active',
        ageGroup: ageGroup,
        verificationStatus: 'none',
        stats: UserStats(
          totalLP: 0,
          totalEarnings: 0,
          totalWithdrawals: 0,
          remaining: 0,
          streakDays: 0,
          totalAER: 0,
        ),
        adStats: UserAdStats(
          impressionsByFormat: {},
          totalEngagementTime: 0,
        ),
        flags: UserFlags(
          suspicious: false,
          reasons: [],
        ),
        deviceInfo: UserDeviceInfo(
          fingerprint: deviceData['fingerprint'] ?? '',
          lastIP: deviceData['ip'] ?? '',
          registrationIP: deviceData['ip'] ?? '',
          deviceIds: [deviceData['id'] ?? ''],
        ),
        preferences: UserPreferences(
          theme: 'system',
          notifications: true,
          language: 'en',
          accessibility: {},
        ),
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(AppConfig.usersCollection)
          .doc(uid)
          .set(userDoc.toFirestore());
    } catch (e) {
      throw AuthException('Failed to create user profile: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Failed to sign out: ${e.toString()}');
    }
  }

  // Get device info
  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;

      return {
        'fingerprint': androidInfo.fingerprint,
        'id': androidInfo.id,
        'ip': 'Unknown', // TODO: Implement IP detection
      };
    } catch (e) {
      return {
        'fingerprint': 'unknown',
        'id': 'unknown',
        'ip': 'unknown',
      };
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
    Map<String, String>? preferences,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) updates['displayName'] = displayName;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (preferences != null) {
        updates['preferences'] = FieldValue.arrayUnion([preferences]);
      }

      await _firestore
          .collection(AppConfig.usersCollection)
          .doc(uid)
          .update(updates);
    } catch (e) {
      throw AuthException('Failed to update user profile: ${e.toString()}');
    }
  }

  // Change user status
  Future<void> changeUserStatus({
    required String uid,
    required String status,
    String? reason,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (reason != null) {
        updates['statusReason'] = reason;
      }

      await _firestore
          .collection(AppConfig.usersCollection)
          .doc(uid)
          .update(updates);
    } catch (e) {
      throw AuthException('Failed to change user status: ${e.toString()}');
    }
  }

  // Store sensitive data encrypted
  Future<void> storeSensitiveData({
    required String uid,
    required Map<String, String> data,
  }) async {
    try {
      // TODO: Implement AES encryption
      final encryptedData = data; // Placeholder for encryption

      await _firestore.collection(AppConfig.usersCollection).doc(uid).update({
        'profileEnc': encryptedData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AuthException('Failed to store sensitive data: ${e.toString()}');
    }
  }

  // Verify age and handle parental consent
  Future<void> verifyAgeAndConsent({
    required String uid,
    required DateTime dateOfBirth,
    String? parentEmail,
  }) async {
    try {
      final age = DateTime.now().difference(dateOfBirth).inDays ~/ 365;
      final ageGroup = age < 13
          ? AppConfig.ageGroupUnder13
          : age < 18
              ? AppConfig.ageGroup13To17
              : AppConfig.ageGroup18Plus;

      final updates = <String, dynamic>{
        'ageGroup': ageGroup,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (age < 13 && parentEmail != null) {
        updates['parentalConsent'] = {
          'parentEmail': parentEmail,
          'granted': false,
          'requestedAt': FieldValue.serverTimestamp(),
        };
      }

      await _firestore
          .collection(AppConfig.usersCollection)
          .doc(uid)
          .update(updates);
    } catch (e) {
      throw AuthException('Failed to verify age: ${e.toString()}');
    }
  }
}
