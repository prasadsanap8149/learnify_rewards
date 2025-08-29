enum UserRole {
  user,
  moderator,
  finance,
  admin,
  superadmin,
  compliance,
  security
}

enum UserStatus { active, deactivated, suspended, pendingVerification }

enum AgeGroup { under13, thirteenToSeventeen, eighteenPlus }

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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      displayName: json['displayName'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == json['role'],
        orElse: () => UserRole.user,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => UserStatus.active,
      ),
      ageGroup: AgeGroup.values.firstWhere(
        (e) => e.toString() == json['ageGroup'],
        orElse: () => AgeGroup.eighteenPlus,
      ),
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.toString() == json['verificationStatus'],
        orElse: () => VerificationStatus.none,
      ),
      stats: json['stats'] != null ? UserStats.fromJson(json['stats']) : null,
      flags: json['flags'] != null ? UserFlags.fromJson(json['flags']) : null,
      deviceInfo: json['deviceInfo'] != null
          ? DeviceInfo.fromJson(json['deviceInfo'])
          : null,
      parentalConsent: json['parentalConsent'] != null
          ? ParentalConsent.fromJson(json['parentalConsent'])
          : null,
      createdAt: json['createdAt']?.toDate(),
      updatedAt: json['updatedAt']?.toDate(),
      lastLoginAt: json['lastLoginAt']?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'role': role.toString(),
      'status': status.toString(),
      'ageGroup': ageGroup.toString(),
      'verificationStatus': verificationStatus.toString(),
      'stats': stats?.toJson(),
      'flags': flags?.toJson(),
      'deviceInfo': deviceInfo?.toJson(),
      'parentalConsent': parentalConsent?.toJson(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastLoginAt': lastLoginAt,
    };
  }

  User copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    UserRole? role,
    UserStatus? status,
    AgeGroup? ageGroup,
    VerificationStatus? verificationStatus,
    UserStats? stats,
    UserFlags? flags,
    DeviceInfo? deviceInfo,
    ParentalConsent? parentalConsent,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      ageGroup: ageGroup ?? this.ageGroup,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      stats: stats ?? this.stats,
      flags: flags ?? this.flags,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      parentalConsent: parentalConsent ?? this.parentalConsent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  /// Check if user requires parental consent
  bool get requiresParentalConsent {
    return ageGroup == AgeGroup.under13 ||
        ageGroup == AgeGroup.thirteenToSeventeen;
  }

  /// Check if user is verified
  bool get isVerified {
    return verificationStatus != VerificationStatus.none;
  }

  /// Check if user is active
  bool get isActive {
    return status == UserStatus.active;
  }

  /// Check if user can withdraw funds
  bool get canWithdraw {
    return isActive &&
        isVerified &&
        (flags?.suspicious != true) &&
        (!requiresParentalConsent || parentalConsent?.granted == true);
  }

  /// Get display name or fallback
  String get displayNameOrEmail {
    return displayName ?? email ?? 'User $uid';
  }

  /// Check if user has admin privileges
  bool get isAdmin {
    return [UserRole.admin, UserRole.superadmin, UserRole.finance]
        .contains(role);
  }

  @override
  String toString() {
    return 'User(uid: $uid, email: $email, role: $role, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
