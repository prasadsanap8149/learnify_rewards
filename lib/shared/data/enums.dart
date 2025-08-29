/// Core enums for Learnify Rewards app
/// Centralized enum definitions for consistent data types

// =============================================================================
// WITHDRAWAL RELATED ENUMS
// =============================================================================

/// Withdrawal payment methods available to users
enum WithdrawalMethod {
  paypal,
  bankTransfer,
  giftCard,
  check,
  cryptocurrency,
}

/// Withdrawal request status lifecycle
enum WithdrawalStatus {
  pending, // Request submitted, awaiting admin review
  pendingReview, // Under review by admin
  pendingSettlement, // Approved and awaiting manual settlement
  approved, // Approved for processing
  processing, // Admin is processing the payment
  completed, // Payment sent successfully
  rejected, // Request rejected by admin
  cancelled, // Cancelled by user
  failed, // Payment attempt failed
}

// =============================================================================
// USER RELATED ENUMS
// =============================================================================

/// User account status
enum UserStatus {
  active,
  suspended,
  banned,
  pending,
  inactive,
}

/// User verification levels
enum VerificationLevel {
  none,
  email,
  phone,
  identity,
  full,
}

/// User age groups for COPPA compliance
enum AgeGroup {
  under13,
  thirteenToSeventeen,
  eighteenPlus,
}

/// User roles for access control
enum UserRole {
  user,
  moderator,
  admin,
  superAdmin,
}

// =============================================================================
// ACTIVITY RELATED ENUMS
// =============================================================================

/// Types of activities users can complete
enum ActivityType {
  quiz,
  video,
  reading,
  game,
  survey,
  challenge,
}

/// Activity difficulty levels
enum ActivityDifficulty {
  beginner,
  intermediate,
  advanced,
  expert,
}

/// Activity completion status
enum ActivityStatus {
  available,
  inProgress,
  completed,
  locked,
  expired,
}

// =============================================================================
// EARNINGS RELATED ENUMS
// =============================================================================

/// Types of earnings/rewards
enum EarningType {
  activityCompletion,
  dailyBonus,
  streakBonus,
  referralBonus,
  specialPromotion,
  adminAward,
}

/// LP (Learning Points) transaction types
enum LPTransactionType {
  earned,
  spent,
  bonus,
  penalty,
  refund,
  withdrawal,
}

// =============================================================================
// AD RELATED ENUMS
// =============================================================================

/// Ad types supported by the app
enum AdType {
  banner,
  interstitial,
  rewarded,
  native,
  video,
}

/// Ad engagement tracking
enum AdEngagement {
  viewed,
  clicked,
  completed,
  skipped,
  failed,
}

// =============================================================================
// NOTIFICATION RELATED ENUMS
// =============================================================================

/// Notification types
enum NotificationType {
  system,
  achievement,
  reminder,
  promotion,
  withdrawal,
  security,
}

/// Notification priority levels
enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

// =============================================================================
// SECURITY RELATED ENUMS
// =============================================================================

/// Security event types for audit logging
enum SecurityEventType {
  login,
  logout,
  passwordChange,
  emailChange,
  withdrawalRequest,
  suspiciousActivity,
  dataExport,
}

/// Fraud detection levels
enum FraudRiskLevel {
  low,
  medium,
  high,
  critical,
}

// =============================================================================
// ANALYTICS RELATED ENUMS
// =============================================================================

/// Event types for analytics tracking
enum AnalyticsEventType {
  userAction,
  systemEvent,
  error,
  performance,
  business,
}

/// User engagement levels
enum EngagementLevel {
  newUser,
  casual,
  regular,
  power,
  champion,
}

// =============================================================================
// HELPER EXTENSIONS
// =============================================================================

/// Extension methods for enum display and utility functions
extension WithdrawalMethodExtension on WithdrawalMethod {
  String get displayName {
    switch (this) {
      case WithdrawalMethod.paypal:
        return 'PayPal';
      case WithdrawalMethod.bankTransfer:
        return 'Bank Transfer';
      case WithdrawalMethod.giftCard:
        return 'Gift Card';
      case WithdrawalMethod.check:
        return 'Check';
      case WithdrawalMethod.cryptocurrency:
        return 'Cryptocurrency';
    }
  }

  String get icon {
    switch (this) {
      case WithdrawalMethod.paypal:
        return '💙';
      case WithdrawalMethod.bankTransfer:
        return '🏦';
      case WithdrawalMethod.giftCard:
        return '🎁';
      case WithdrawalMethod.check:
        return '📄';
      case WithdrawalMethod.cryptocurrency:
        return '₿';
    }
  }
}

extension WithdrawalStatusExtension on WithdrawalStatus {
  String get displayName {
    switch (this) {
      case WithdrawalStatus.pending:
        return 'Pending Review';
      case WithdrawalStatus.pendingReview:
        return 'Under Review';
      case WithdrawalStatus.pendingSettlement:
        return 'Pending Settlement';
      case WithdrawalStatus.approved:
        return 'Approved';
      case WithdrawalStatus.processing:
        return 'Processing Payment';
      case WithdrawalStatus.completed:
        return 'Completed';
      case WithdrawalStatus.rejected:
        return 'Rejected';
      case WithdrawalStatus.cancelled:
        return 'Cancelled';
      case WithdrawalStatus.failed:
        return 'Failed';
    }
  }

  String get icon {
    switch (this) {
      case WithdrawalStatus.pending:
        return '⏳';
      case WithdrawalStatus.pendingReview:
        return '👁️';
      case WithdrawalStatus.pendingSettlement:
        return '💰';
      case WithdrawalStatus.approved:
        return '✅';
      case WithdrawalStatus.processing:
        return '⚡';
      case WithdrawalStatus.completed:
        return '✅';
      case WithdrawalStatus.rejected:
        return '❌';
      case WithdrawalStatus.cancelled:
        return '🚫';
      case WithdrawalStatus.failed:
        return '⚠️';
    }
  }

  bool get isComplete {
    return this == WithdrawalStatus.completed;
  }

  bool get isFinal {
    return [
      WithdrawalStatus.completed,
      WithdrawalStatus.rejected,
      WithdrawalStatus.cancelled,
      WithdrawalStatus.failed,
    ].contains(this);
  }
}

extension AgeGroupExtension on AgeGroup {
  String get displayName {
    switch (this) {
      case AgeGroup.under13:
        return 'Under 13';
      case AgeGroup.thirteenToSeventeen:
        return '13-17';
      case AgeGroup.eighteenPlus:
        return '18+';
    }
  }

  bool get requiresParentalConsent {
    return this != AgeGroup.eighteenPlus;
  }

  bool get isCoppaCompliant {
    return this == AgeGroup.under13;
  }
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.moderator:
        return 'Moderator';
      case UserRole.admin:
        return 'Admin';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }

  bool get canAccessAdminPanel {
    return [UserRole.admin, UserRole.superAdmin].contains(this);
  }

  bool get canProcessWithdrawals {
    return [UserRole.admin, UserRole.superAdmin].contains(this);
  }

  bool get canManageUsers {
    return [UserRole.moderator, UserRole.admin, UserRole.superAdmin]
        .contains(this);
  }
}
