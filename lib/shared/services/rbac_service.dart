import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../utils/constants.dart';

/// Role-Based Access Control Service
class RBACService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if current user has a specific role
  static Future<bool> hasRole(String role) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      final userRole = userData?['role'] as String?;

      return userRole == role;
    } catch (e) {
      debugPrint('Error checking role: $e');
      return false;
    }
  }

  /// Check if current user has any of the specified roles
  static Future<bool> hasAnyRole(List<String> roles) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      final userRole = userData?['role'] as String?;

      return userRole != null && roles.contains(userRole);
    } catch (e) {
      debugPrint('Error checking roles: $e');
      return false;
    }
  }

  /// Check if current user is an admin (admin or superadmin)
  static Future<bool> isAdmin() async {
    return hasAnyRole([
      AppConstants.roleAdmin,
      AppConstants.roleSuperAdmin,
    ]);
  }

  /// Check if current user is a moderator or higher
  static Future<bool> isModerator() async {
    return hasAnyRole([
      AppConstants.roleModerator,
      AppConstants.roleAdmin,
      AppConstants.roleSuperAdmin,
    ]);
  }

  /// Check if current user is in compliance team or higher
  static Future<bool> isCompliance() async {
    return hasAnyRole([
      AppConstants.roleCompliance,
      AppConstants.roleAdmin,
      AppConstants.roleSuperAdmin,
    ]);
  }

  /// Check if current user is in security team or higher
  static Future<bool> isSecurity() async {
    return hasAnyRole([
      AppConstants.roleSecurity,
      AppConstants.roleAdmin,
      AppConstants.roleSuperAdmin,
    ]);
  }

  /// Check if current user is in finance team or higher
  static Future<bool> isFinance() async {
    return hasAnyRole([
      AppConstants.roleFinance,
      AppConstants.roleAdmin,
      AppConstants.roleSuperAdmin,
    ]);
  }

  /// Check if current user is a super admin
  static Future<bool> isSuperAdmin() async {
    return hasRole(AppConstants.roleSuperAdmin);
  }

  /// Get current user's role
  static Future<String?> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return null;

      final userData = userDoc.data();
      return userData?['role'] as String?;
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }

  /// Check if user can access a specific resource
  static Future<bool> canAccess(String resourceType, String action) async {
    final role = await getCurrentUserRole();
    if (role == null) return false;

    return _getPermissions(role, resourceType).contains(action);
  }

  /// Get permissions for a role and resource type
  static List<String> _getPermissions(String role, String resourceType) {
    final permissions = _rolePermissions[role]?[resourceType] ?? [];
    return permissions;
  }

  /// Role permissions mapping
  static final Map<String, Map<String, List<String>>> _rolePermissions = {
    AppConstants.roleUser: {
      'activity': ['read', 'start', 'complete'],
      'reward': ['read', 'redeem'],
      'profile': ['read', 'update'],
      'withdrawal': ['create', 'read'],
      'notification': ['read', 'update', 'delete'],
    },
    AppConstants.roleModerator: {
      'activity': ['read', 'create', 'update', 'delete'],
      'reward': ['read', 'create', 'update'],
      'user': ['read', 'update'],
      'profile': ['read', 'update'],
      'report': ['read', 'create', 'update'],
      'notification': ['read', 'create', 'update', 'delete'],
    },
    AppConstants.roleFinance: {
      'withdrawal': ['read', 'update', 'approve', 'reject'],
      'user': ['read'],
      'lpEvent': ['read'],
      'report': ['read', 'create'],
    },
    AppConstants.roleCompliance: {
      'ageVerification': ['read', 'approve', 'reject'],
      'auditLog': ['read'],
      'user': ['read', 'update'],
      'report': ['read', 'create'],
    },
    AppConstants.roleSecurity: {
      'securityEvent': ['read', 'update'],
      'user': ['read', 'suspend', 'activate'],
      'auditLog': ['read'],
      'report': ['read', 'create'],
    },
    AppConstants.roleAdmin: {
      'activity': ['read', 'create', 'update', 'delete'],
      'reward': ['read', 'create', 'update', 'delete'],
      'user': ['read', 'create', 'update', 'delete'],
      'withdrawal': ['read', 'create', 'update', 'approve', 'reject', 'delete'],
      'lpEvent': ['read', 'create'],
      'adEvent': ['read'],
      'securityEvent': ['read', 'update', 'delete'],
      'auditLog': ['read'],
      'appConfig': ['read', 'update'],
      'ageVerification': ['read', 'approve', 'reject'],
      'referral': ['read', 'update', 'delete'],
      'notification': ['read', 'create', 'update', 'delete'],
      'report': ['read', 'create', 'update', 'delete'],
    },
    AppConstants.roleSuperAdmin: {
      'activity': ['read', 'create', 'update', 'delete'],
      'reward': ['read', 'create', 'update', 'delete'],
      'user': ['read', 'create', 'update', 'delete'],
      'withdrawal': ['read', 'create', 'update', 'approve', 'reject', 'delete'],
      'lpEvent': ['read', 'create', 'delete'],
      'adEvent': ['read', 'delete'],
      'securityEvent': ['read', 'update', 'delete'],
      'auditLog': ['read', 'delete'],
      'appConfig': ['read', 'update', 'delete'],
      'ageVerification': ['read', 'approve', 'reject', 'delete'],
      'referral': ['read', 'update', 'delete'],
      'notification': ['read', 'create', 'update', 'delete'],
      'report': ['read', 'create', 'update', 'delete'],
      'system': ['read', 'update', 'delete', 'manage'],
    },
  };

  /// Check if user account is active
  static Future<bool> isAccountActive() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      final status = userData?['status'] as String?;

      return status == AppConstants.statusActive;
    } catch (e) {
      debugPrint('Error checking account status: $e');
      return false;
    }
  }

  /// Check if user is verified
  static Future<bool> isVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      final verificationStatus = userData?['verificationStatus'] as String?;

      return verificationStatus == AppConstants.verificationFull ||
          verificationStatus == AppConstants.verificationEmail;
    } catch (e) {
      debugPrint('Error checking verification status: $e');
      return false;
    }
  }

  /// Get user's age group
  static Future<String?> getAgeGroup() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return null;

      final userData = userDoc.data();
      return userData?['ageGroup'] as String?;
    } catch (e) {
      debugPrint('Error getting age group: $e');
      return null;
    }
  }

  /// Check if content is appropriate for user's age group
  static Future<bool> isContentAppropriate(String contentAgeGroup) async {
    final userAgeGroup = await getAgeGroup();
    if (userAgeGroup == null) return false;

    // Age group hierarchy: under13 < thirteenToSeventeen < eighteenPlus
    final ageGroupHierarchy = {
      AppConstants.ageGroupUnder13: 0,
      AppConstants.ageGroup13To17: 1,
      AppConstants.ageGroup18Plus: 2,
    };

    final userLevel = ageGroupHierarchy[userAgeGroup] ?? 0;
    final contentLevel = ageGroupHierarchy[contentAgeGroup] ?? 2;

    return userLevel >= contentLevel;
  }

  /// Log access attempt for audit
  static Future<void> logAccessAttempt({
    required String resource,
    required String action,
    required bool granted,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection(AppConstants.auditLogsCollection).add({
        'userId': user.uid,
        'type': 'access',
        'resource': resource,
        'action': action,
        'granted': granted,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
      });
    } catch (e) {
      debugPrint('Error logging access attempt: $e');
    }
  }

  /// Require specific role or throw error
  static Future<void> requireRole(String role, {String? errorMessage}) async {
    final hasRequiredRole = await hasRole(role);
    if (!hasRequiredRole) {
      throw UnauthorizedException(
        errorMessage ?? 'You do not have permission to perform this action.',
      );
    }
  }

  /// Require any of the specified roles or throw error
  static Future<void> requireAnyRole(
    List<String> roles, {
    String? errorMessage,
  }) async {
    final hasRequiredRole = await hasAnyRole(roles);
    if (!hasRequiredRole) {
      throw UnauthorizedException(
        errorMessage ?? 'You do not have permission to perform this action.',
      );
    }
  }

  /// Require admin role or throw error
  static Future<void> requireAdmin({String? errorMessage}) async {
    final isAdminUser = await isAdmin();
    if (!isAdminUser) {
      throw UnauthorizedException(
        errorMessage ?? 'Admin access required.',
      );
    }
  }

  /// Require active account or throw error
  static Future<void> requireActiveAccount({String? errorMessage}) async {
    final isActive = await isAccountActive();
    if (!isActive) {
      throw AccountInactiveException(
        errorMessage ?? 'Your account is not active. Please contact support.',
      );
    }
  }

  /// Require verified account or throw error
  static Future<void> requireVerification({String? errorMessage}) async {
    final verified = await isVerified();
    if (!verified) {
      throw VerificationRequiredException(
        errorMessage ?? 'Account verification required.',
      );
    }
  }
}

/// Custom exceptions for RBAC
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => message;
}

class AccountInactiveException implements Exception {
  final String message;
  AccountInactiveException(this.message);

  @override
  String toString() => message;
}

class VerificationRequiredException implements Exception {
  final String message;
  VerificationRequiredException(this.message);

  @override
  String toString() => message;
}

class AgeRestrictionException implements Exception {
  final String message;
  AgeRestrictionException(this.message);

  @override
  String toString() => message;
}
