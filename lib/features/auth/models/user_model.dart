import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../lib copy/features/auth/core/config.dart';

class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String role;
  final String status;
  final String ageGroup;
  final String verificationStatus;
  final UserProfileEnc? profileEnc;
  final UserKycData? kycData;
  final UserStats stats;
  final UserAdStats adStats;
  final UserFlags flags;
  final UserDeviceInfo deviceInfo;
  final ParentalConsent? parentalConsent;
  final UserPreferences preferences;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.role,
    required this.status,
    required this.ageGroup,
    required this.verificationStatus,
    this.profileEnc,
    this.kycData,
    required this.stats,
    required this.adStats,
    required this.flags,
    required this.deviceInfo,
    this.parentalConsent,
    required this.preferences,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  bool get isUnder13 => ageGroup == AppConfig.ageGroupUnder13;
  bool get isAdmin =>
      role == AppConfig.roleAdmin || role == AppConfig.roleSuperAdmin;
  bool get isActive => status == 'active';
  bool get requiresParentalConsent =>
      isUnder13 && (parentalConsent == null || !parentalConsent!.granted);

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      role: data['role'] ?? AppConfig.roleUser,
      status: data['status'] ?? 'active',
      ageGroup: data['ageGroup'] ?? AppConfig.ageGroup18Plus,
      verificationStatus: data['verificationStatus'] ?? 'none',
      profileEnc: data['profileEnc'] != null
          ? UserProfileEnc.fromMap(data['profileEnc'])
          : null,
      kycData:
          data['kycData'] != null ? UserKycData.fromMap(data['kycData']) : null,
      stats: UserStats.fromMap(data['stats'] ?? {}),
      adStats: UserAdStats.fromMap(data['adStats'] ?? {}),
      flags: UserFlags.fromMap(data['flags'] ?? {}),
      deviceInfo: UserDeviceInfo.fromMap(data['deviceInfo'] ?? {}),
      parentalConsent: data['parentalConsent'] != null
          ? ParentalConsent.fromMap(data['parentalConsent'])
          : null,
      preferences: UserPreferences.fromMap(data['preferences'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
      'status': status,
      'ageGroup': ageGroup,
      'verificationStatus': verificationStatus,
      'profileEnc': profileEnc?.toMap(),
      'kycData': kycData?.toMap(),
      'stats': stats.toMap(),
      'adStats': adStats.toMap(),
      'flags': flags.toMap(),
      'deviceInfo': deviceInfo.toMap(),
      'parentalConsent': parentalConsent?.toMap(),
      'preferences': preferences.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }
}

class UserProfileEnc {
  final String mobileEnc;
  final String addressEnc;
  final String pinEnc;
  final String? upiEnc;
  final String? paypalEnc;
  final String? parentalConsentEnc;

  UserProfileEnc({
    required this.mobileEnc,
    required this.addressEnc,
    required this.pinEnc,
    this.upiEnc,
    this.paypalEnc,
    this.parentalConsentEnc,
  });

  factory UserProfileEnc.fromMap(Map<String, dynamic> map) {
    return UserProfileEnc(
      mobileEnc: map['mobileEnc'] ?? '',
      addressEnc: map['addressEnc'] ?? '',
      pinEnc: map['pinEnc'] ?? '',
      upiEnc: map['upiEnc'],
      paypalEnc: map['paypalEnc'],
      parentalConsentEnc: map['parentalConsentEnc'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mobileEnc': mobileEnc,
      'addressEnc': addressEnc,
      'pinEnc': pinEnc,
      'upiEnc': upiEnc,
      'paypalEnc': paypalEnc,
      'parentalConsentEnc': parentalConsentEnc,
    };
  }
}

class UserKycData {
  final String verificationLevel;
  final List<String> documentHashes;
  final DateTime verifiedAt;

  UserKycData({
    required this.verificationLevel,
    required this.documentHashes,
    required this.verifiedAt,
  });

  factory UserKycData.fromMap(Map<String, dynamic> map) {
    return UserKycData(
      verificationLevel: map['verificationLevel'] ?? 'none',
      documentHashes: List<String>.from(map['documentHashes'] ?? []),
      verifiedAt: (map['verifiedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'verificationLevel': verificationLevel,
      'documentHashes': documentHashes,
      'verifiedAt': Timestamp.fromDate(verifiedAt),
    };
  }
}

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

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      totalLP: map['totalLP'] ?? 0,
      totalEarnings: (map['totalEarnings'] ?? 0.0).toDouble(),
      totalWithdrawals: (map['totalWithdrawals'] ?? 0.0).toDouble(),
      remaining: (map['remaining'] ?? 0.0).toDouble(),
      streakDays: map['streakDays'] ?? 0,
      totalAER: (map['totalAER'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
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

class UserAdStats {
  final Map<String, int> impressionsByFormat;
  final DateTime? lastAdAt;
  final String? consentString;
  final int totalEngagementTime;

  UserAdStats({
    required this.impressionsByFormat,
    this.lastAdAt,
    this.consentString,
    required this.totalEngagementTime,
  });

  factory UserAdStats.fromMap(Map<String, dynamic> map) {
    return UserAdStats(
      impressionsByFormat:
          Map<String, int>.from(map['impressionsByFormat'] ?? {}),
      lastAdAt: map['lastAdAt'] != null
          ? (map['lastAdAt'] as Timestamp).toDate()
          : null,
      consentString: map['consentString'],
      totalEngagementTime: map['totalEngagementTime'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'impressionsByFormat': impressionsByFormat,
      'lastAdAt': lastAdAt != null ? Timestamp.fromDate(lastAdAt!) : null,
      'consentString': consentString,
      'totalEngagementTime': totalEngagementTime,
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

  factory UserFlags.fromMap(Map<String, dynamic> map) {
    return UserFlags(
      suspicious: map['suspicious'] ?? false,
      reasons: List<String>.from(map['reasons'] ?? []),
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: map['reviewedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'suspicious': suspicious,
      'reasons': reasons,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
    };
  }
}

class UserDeviceInfo {
  final String fingerprint;
  final String lastIP;
  final String registrationIP;
  final List<String> deviceIds;

  UserDeviceInfo({
    required this.fingerprint,
    required this.lastIP,
    required this.registrationIP,
    required this.deviceIds,
  });

  factory UserDeviceInfo.fromMap(Map<String, dynamic> map) {
    return UserDeviceInfo(
      fingerprint: map['fingerprint'] ?? '',
      lastIP: map['lastIP'] ?? '',
      registrationIP: map['registrationIP'] ?? '',
      deviceIds: List<String>.from(map['deviceIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
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
  final String parentEmail;
  final DateTime consentTimestamp;
  final String ipAddress;

  ParentalConsent({
    required this.granted,
    required this.parentEmail,
    required this.consentTimestamp,
    required this.ipAddress,
  });

  factory ParentalConsent.fromMap(Map<String, dynamic> map) {
    return ParentalConsent(
      granted: map['granted'] ?? false,
      parentEmail: map['parentEmail'] ?? '',
      consentTimestamp: (map['consentTimestamp'] as Timestamp).toDate(),
      ipAddress: map['ipAddress'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'granted': granted,
      'parentEmail': parentEmail,
      'consentTimestamp': Timestamp.fromDate(consentTimestamp),
      'ipAddress': ipAddress,
    };
  }
}

class UserPreferences {
  final String theme;
  final bool notifications;
  final String language;
  final Map<String, dynamic> accessibility;

  UserPreferences({
    required this.theme,
    required this.notifications,
    required this.language,
    required this.accessibility,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      theme: map['theme'] ?? 'system',
      notifications: map['notifications'] ?? true,
      language: map['language'] ?? 'en',
      accessibility: Map<String, dynamic>.from(map['accessibility'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'notifications': notifications,
      'language': language,
      'accessibility': accessibility,
    };
  }
}
