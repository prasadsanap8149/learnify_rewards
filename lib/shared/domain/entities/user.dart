enum UserRole {
  user,
  moderator,
  finance,
  admin,
  superadmin,
  compliance,
  security
}

enum UserStatus { active, deactivated, suspended, pending_verification }

enum AgeGroup { under13, thirteen_to_seventeen, eighteen_plus }

enum VerificationStatus { none, email, phone, document, full }

class UserStats {
  final int totalLP;
  final double totalEarnings;
  final double totalWithdrawals;
  final double remaining;
  final int streakDays;
  final double totalAER;

  UserStats({
    required this.totalLP,
    required this.totalEarnings,
    required this.totalWithdrawals,
    required this.remaining,
    required this.streakDays,
    required this.totalAER,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalLP: json['totalLP'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      totalWithdrawals: (json['totalWithdrawals'] ?? 0).toDouble(),
      remaining: (json['remaining'] ?? 0).toDouble(),
      streakDays: json['streakDays'] ?? 0,
      totalAER: (json['totalAER'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalLP': totalLP,
      'totalEarnings': totalEarnings,
      'totalWithdrawals': totalWithdrawals,
      'remaining': remaining,
      'streakDays': streakDays,
      'totalAER': totalAER,
    };
  }
}

class UserFlags {
  final bool suspicious;
  final List<String> reasons;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  UserFlags({
    required this.suspicious,
    required this.reasons,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory UserFlags.fromJson(Map<String, dynamic> json) {
    return UserFlags(
      suspicious: json['suspicious'] ?? false,
      reasons: List<String>.from(json['reasons'] ?? []),
      reviewedAt: json['reviewedAt']?.toDate(),
      reviewedBy: json['reviewedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suspicious': suspicious,
      'reasons': reasons,
      'reviewedAt': reviewedAt,
      'reviewedBy': reviewedBy,
    };
  }
}

class DeviceInfo {
  final String fingerprint;
  final String lastIP;
  final String registrationIP;
  final List<String> deviceIds;

  DeviceInfo({
    required this.fingerprint,
    required this.lastIP,
    required this.registrationIP,
    required this.deviceIds,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      fingerprint: json['fingerprint'] ?? '',
      lastIP: json['lastIP'] ?? '',
      registrationIP: json['registrationIP'] ?? '',
      deviceIds: List<String>.from(json['deviceIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fingerprint': fingerprint,
      'lastIP': lastIP,
      'registrationIP': registrationIP,
      'deviceIds': deviceIds,
    };
  }
}

class ParentalConsent {
  final bool granted;
  final String? parentEmail;
  final DateTime? consentTimestamp;
  final String? ipAddress;

  ParentalConsent({
    required this.granted,
    this.parentEmail,
    this.consentTimestamp,
    this.ipAddress,
  });

  factory ParentalConsent.fromJson(Map<String, dynamic> json) {
    return ParentalConsent(
      granted: json['granted'] ?? false,
      parentEmail: json['parentEmail'],
      consentTimestamp: json['consentTimestamp']?.toDate(),
      ipAddress: json['ipAddress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'granted': granted,
      'parentEmail': parentEmail,
      'consentTimestamp': consentTimestamp,
      'ipAddress': ipAddress,
    };
  }
}

class User {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final UserRole role;
  final UserStatus status;
  final AgeGroup ageGroup;
  final VerificationStatus verificationStatus;
  final UserStats? stats;
  final UserFlags? flags;
  final DeviceInfo? deviceInfo;
  final ParentalConsent? parentalConsent;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  User({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    required this.role,
    required this.status,
    required this.ageGroup,
    required this.verificationStatus,
    this.stats,
    this.flags,
    this.deviceInfo,
    this.parentalConsent,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });
}
