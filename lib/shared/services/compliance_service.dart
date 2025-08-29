import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entities/age_verification.dart';
import '../domain/entities/user.dart';
import '../domain/entities/audit_log.dart';
import '../data/repositories/firestore_age_verification_repository.dart';
import '../data/repositories/firestore_user_repository.dart';
import '../data/repositories/firestore_audit_log_repository.dart';
import 'config_service.dart';

class ComplianceService {
  final FirestoreAgeVerificationRepository _ageVerificationRepository;
  final FirestoreUserRepository _userRepository;
  final FirestoreAuditLogRepository _auditLogRepository;
  final ConfigService _configService;

  ComplianceService({
    FirestoreAgeVerificationRepository? ageVerificationRepository,
    FirestoreUserRepository? userRepository,
    FirestoreAuditLogRepository? auditLogRepository,
    ConfigService? configService,
  })  : _ageVerificationRepository =
            ageVerificationRepository ?? FirestoreAgeVerificationRepository(),
        _userRepository = userRepository ?? FirestoreUserRepository(),
        _auditLogRepository =
            auditLogRepository ?? FirestoreAuditLogRepository(),
        _configService = configService ?? ConfigService();

  // Submit age verification
  Future<String> submitAgeVerification({
    required String userId,
    required DateTime dateOfBirth,
    required AgeVerificationMethod method,
    String? documentType,
    String? documentNumber,
    String? parentEmail,
    String? parentName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Calculate age group from date of birth
      final ageGroup = _calculateAgeGroup(dateOfBirth);

      // Determine expiration date based on age group
      final expiresAt = _calculateExpirationDate(ageGroup);

      final verification = AgeVerification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        method: method,
        status: AgeVerificationStatus.pending,
        verifiedAgeGroup: ageGroup,
        dateOfBirth: dateOfBirth,
        documentType: documentType,
        documentNumber: documentNumber,
        parentEmail: parentEmail,
        parentName: parentName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        expiresAt: expiresAt,
        metadata: metadata,
      );

      await _ageVerificationRepository.createAgeVerification(verification);

      // Create audit log
      final auditLog = AuditLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        action: AuditAction.create,
        entity: AuditEntity.user,
        entityId: verification.id,
        newValues: verification.toJson(),
        timestamp: DateTime.now(),
      );

      await _auditLogRepository.createAuditLog(auditLog);

      return verification.id;
    } catch (e) {
      throw Exception('Failed to submit age verification: $e');
    }
  }

  // Calculate age group from date of birth
  AgeGroup _calculateAgeGroup(DateTime dateOfBirth) {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }

    if (age < 13) return AgeGroup.under13;
    if (age >= 13 && age <= 17) return AgeGroup.thirteenToSeventeen;
    return AgeGroup.eighteenPlus;
  }

  // Calculate expiration date based on age group
  DateTime? _calculateExpirationDate(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.under13:
        return DateTime.now().add(const Duration(days: 365)); // 1 year
      case AgeGroup.thirteenToSeventeen:
        return DateTime.now().add(const Duration(days: 365 * 2)); // 2 years
      case AgeGroup.eighteenPlus:
        return null; // No expiration for adults
    }
  }

  // Verify age verification
  Future<void> verifyAgeVerification(
    String verificationId,
    String verifiedBy,
    bool approved, {
    String? rejectionReason,
  }) async {
    try {
      final status = approved
          ? AgeVerificationStatus.verified
          : AgeVerificationStatus.rejected;

      await _ageVerificationRepository.updateAgeVerificationStatus(
        verificationId,
        status,
        verifiedBy,
        rejectionReason: rejectionReason,
      );

      // If approved, update user's age group and verification status
      if (approved) {
        final verification = await _ageVerificationRepository
            .getAgeVerificationByUserId(verificationId);
        if (verification != null) {
          final user = await _userRepository.getUser(verification.userId);
          if (user != null) {
            final updatedUser = User(
              uid: user.uid,
              displayName: user.displayName,
              email: user.email,
              photoUrl: user.photoUrl,
              role: user.role,
              status: user.status,
              ageGroup: verification.verifiedAgeGroup,
              verificationStatus: VerificationStatus.document,
            );
            await _userRepository.updateUser(updatedUser);
          }
        }
      }

      // Create audit log
      final auditLog = AuditLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: verifiedBy,
        adminId: verifiedBy,
        action: approved ? AuditAction.approve : AuditAction.reject,
        entity: AuditEntity.user,
        entityId: verificationId,
        reason: rejectionReason ??
            'Age verification ${approved ? 'approved' : 'rejected'}',
        timestamp: DateTime.now(),
      );

      await _auditLogRepository.createAuditLog(auditLog);
    } catch (e) {
      throw Exception('Failed to verify age verification: $e');
    }
  }

  // Check if user complies with age requirements
  Future<Map<String, dynamic>> checkAgeCompliance(String userId) async {
    try {
      final user = await _userRepository.getUser(userId);
      if (user == null) {
        return {
          'compliant': false,
          'reason': 'User not found',
        };
      }

      final verification =
          await _ageVerificationRepository.getAgeVerificationByUserId(userId);

      // Check if verification is required
      final requiresVerification = await _configService.getConfig(
        'compliance.parental_consent_required',
        defaultValue: true,
      );

      if (!requiresVerification) {
        return {'compliant': true};
      }

      // Check if user needs parental consent
      if (user.ageGroup == AgeGroup.under13) {
        if (user.parentalConsent == null || !user.parentalConsent!.granted) {
          return {
            'compliant': false,
            'reason': 'Missing parental consent',
            'required': 'Parental consent required for users under 13',
          };
        }
      }

      // Check verification status
      if (verification == null) {
        return {
          'compliant': false,
          'reason': 'No age verification submitted',
          'required': 'Age verification required',
        };
      }

      if (!verification.isValid) {
        return {
          'compliant': false,
          'reason': 'Age verification expired or invalid',
          'required': 'Valid age verification required',
        };
      }

      // Check if age group matches
      if (verification.currentAgeGroup != user.ageGroup) {
        return {
          'compliant': false,
          'reason': 'Age group mismatch',
          'required': 'Age group needs to be updated',
          'action': 'update_age_group',
        };
      }

      return {'compliant': true};
    } catch (e) {
      throw Exception('Failed to check age compliance: $e');
    }
  }

  // Handle parental consent
  Future<void> processParentalConsent(
    String userId,
    String parentEmail,
    String parentName,
    bool granted,
  ) async {
    try {
      final user = await _userRepository.getUser(userId);
      if (user != null) {
        // For now, we'll update directly to Firestore since the User entity doesn't have parental consent fields
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'parentalConsent': {
            'granted': granted,
            'parentEmail': parentEmail,
            'parentName': parentName,
            'consentTimestamp': DateTime.now(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update age verification if exists
      final verification =
          await _ageVerificationRepository.getAgeVerificationByUserId(userId);
      if (verification != null) {
        await _ageVerificationRepository.updateParentConsent(
          verification.id,
          parentEmail,
          parentName,
          DateTime.now(),
        );
      }

      // Create audit log
      final auditLog = AuditLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        action: granted ? AuditAction.approve : AuditAction.reject,
        entity: AuditEntity.user,
        entityId: userId,
        reason: 'Parental consent ${granted ? 'granted' : 'denied'}',
        metadata: {
          'parentEmail': parentEmail,
          'parentName': parentName,
        },
        timestamp: DateTime.now(),
      );

      await _auditLogRepository.createAuditLog(auditLog);
    } catch (e) {
      throw Exception('Failed to process parental consent: $e');
    }
  }

  // Get pending verifications for admin review
  Future<List<AgeVerification>> getPendingVerifications({
    AgeVerificationMethod? method,
    int limit = 50,
  }) async {
    try {
      return await _ageVerificationRepository.getPendingVerifications(
        method: method,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Failed to get pending verifications: $e');
    }
  }

  // Process expired verifications
  Future<void> processExpiredVerifications() async {
    try {
      final expiredVerifications =
          await _ageVerificationRepository.getExpiredVerifications();

      for (final verification in expiredVerifications) {
        // Update verification status
        await _ageVerificationRepository.updateAgeVerificationStatus(
          verification.id,
          AgeVerificationStatus.expired,
          'system',
        );

        // Update user status if needed
        final user = await _userRepository.getUser(verification.userId);
        if (user != null && user.status == UserStatus.active) {
          await _userRepository.updateUserStatus(
            verification.userId,
            UserStatus.pendingVerification,
            reason: 'Age verification expired',
          );
        }

        // Create audit log
        final auditLog = AuditLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: verification.userId,
          adminId: 'system',
          action: AuditAction.update,
          entity: AuditEntity.user,
          entityId: verification.id,
          reason: 'Age verification expired',
          timestamp: DateTime.now(),
        );

        await _auditLogRepository.createAuditLog(auditLog);
      }
    } catch (e) {
      throw Exception('Failed to process expired verifications: $e');
    }
  }

  // Get compliance dashboard data
  Future<Map<String, dynamic>> getComplianceDashboard({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final verificationStats =
          await _ageVerificationRepository.getVerificationStatistics(
        startDate: startDate,
        endDate: endDate,
      );

      final pendingVerifications =
          await _ageVerificationRepository.getPendingVerifications();
      final requiresReview =
          await _ageVerificationRepository.getVerificationsRequiringReview();

      return {
        'verificationStats': verificationStats,
        'pendingCount': pendingVerifications.length,
        'reviewCount': requiresReview.length,
        'recentPending': pendingVerifications.take(5).toList(),
        'recentReview': requiresReview.take(5).toList(),
      };
    } catch (e) {
      throw Exception('Failed to get compliance dashboard: $e');
    }
  }

  // Data retention compliance
  Future<void> enforceDataRetention() async {
    try {
      final retentionDays = await _configService.getConfig(
        'compliance.data_retention_days',
        defaultValue: 2555, // 7 years
      );

      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));

      // This would typically involve archiving or anonymizing old data
      // For now, we'll just log the action
      final auditLog = AuditLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'system',
        adminId: 'system',
        action: AuditAction.delete,
        entity: AuditEntity.system,
        reason:
            'Data retention enforcement for data older than $retentionDays days',
        metadata: {
          'cutoffDate': cutoffDate.toIso8601String(),
          'retentionDays': retentionDays,
        },
        timestamp: DateTime.now(),
      );

      await _auditLogRepository.createAuditLog(auditLog);
    } catch (e) {
      throw Exception('Failed to enforce data retention: $e');
    }
  }

  // Record parental consent for minors
  Future<void> recordParentalConsent({
    required String userId,
    required String parentEmail,
    required String parentName,
    required bool consentGranted,
    String? ipAddress,
  }) async {
    try {
      // Update user with parental consent information
      await _userRepository.updateUserFields(userId, {
        'parentalConsent': {
          'granted': consentGranted,
          'parentEmail': parentEmail,
          'parentName': parentName,
          'consentTimestamp': DateTime.now().toIso8601String(),
          'ipAddress': ipAddress ?? 'unknown',
        },
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Log the consent action
      final auditLog = AuditLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        adminId: 'system',
        action: AuditAction.create,
        entity: AuditEntity.user,
        reason: 'Parental consent recorded',
        metadata: {
          'parentEmail': parentEmail,
          'consentGranted': consentGranted,
          'ipAddress': ipAddress ?? 'unknown',
        },
        timestamp: DateTime.now(),
      );

      await _auditLogRepository.createAuditLog(auditLog);
    } catch (e) {
      throw Exception('Failed to record parental consent: $e');
    }
  }
}
