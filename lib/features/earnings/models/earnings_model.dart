import 'package:cloud_firestore/cloud_firestore.dart';

class LPEvent {
  final String id;
  final String userId;
  final int lp;
  final String reason;
  final String? activityRef;
  final String difficulty;
  final int timeTaken;
  final String deviceFingerprint;
  final String ipAddress;
  final DateTime createdAt;
  final bool serverValidated;

  LPEvent({
    required this.id,
    required this.userId,
    required this.lp,
    required this.reason,
    this.activityRef,
    required this.difficulty,
    required this.timeTaken,
    required this.deviceFingerprint,
    required this.ipAddress,
    required this.createdAt,
    required this.serverValidated,
  });

  factory LPEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LPEvent(
      id: doc.id,
      userId: data['userId'] ?? '',
      lp: data['lp'] ?? 0,
      reason: data['reason'] ?? '',
      activityRef: data['activityRef'],
      difficulty: data['difficulty'] ?? '',
      timeTaken: data['timeTaken'] ?? 0,
      deviceFingerprint: data['deviceFingerprint'] ?? '',
      ipAddress: data['ipAddress'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      serverValidated: data['serverValidated'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'lp': lp,
      'reason': reason,
      'activityRef': activityRef,
      'difficulty': difficulty,
      'timeTaken': timeTaken,
      'deviceFingerprint': deviceFingerprint,
      'ipAddress': ipAddress,
      'createdAt': Timestamp.fromDate(createdAt),
      'serverValidated': serverValidated,
    };
  }
}

class AdEvent {
  final String id;
  final String userId;
  final String format;
  final String adNetwork;
  final bool impression;
  final bool clicked;
  final String adUnitId;
  final String placementId;
  final double revenue;
  final Map<String, dynamic> deviceInfo;
  final String ipAddress;
  final String userAgent;
  final String consentStatus;
  final String ageGroup;
  final int engagementTime;
  final bool qualifiesForAER;
  final double aerAmount;
  final DateTime at;

  AdEvent({
    required this.id,
    required this.userId,
    required this.format,
    required this.adNetwork,
    required this.impression,
    required this.clicked,
    required this.adUnitId,
    required this.placementId,
    required this.revenue,
    required this.deviceInfo,
    required this.ipAddress,
    required this.userAgent,
    required this.consentStatus,
    required this.ageGroup,
    required this.engagementTime,
    required this.qualifiesForAER,
    required this.aerAmount,
    required this.at,
  });

  factory AdEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdEvent(
      id: doc.id,
      userId: data['userId'] ?? '',
      format: data['format'] ?? '',
      adNetwork: data['adNetwork'] ?? '',
      impression: data['impression'] ?? false,
      clicked: data['clicked'] ?? false,
      adUnitId: data['adUnitId'] ?? '',
      placementId: data['placementId'] ?? '',
      revenue: (data['revenue'] ?? 0.0).toDouble(),
      deviceInfo: Map<String, dynamic>.from(data['deviceInfo'] ?? {}),
      ipAddress: data['ipAddress'] ?? '',
      userAgent: data['userAgent'] ?? '',
      consentStatus: data['consentStatus'] ?? '',
      ageGroup: data['ageGroup'] ?? '',
      engagementTime: data['engagementTime'] ?? 0,
      qualifiesForAER: data['qualifiesForAER'] ?? false,
      aerAmount: (data['aerAmount'] ?? 0.0).toDouble(),
      at: (data['at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'format': format,
      'adNetwork': adNetwork,
      'impression': impression,
      'clicked': clicked,
      'adUnitId': adUnitId,
      'placementId': placementId,
      'revenue': revenue,
      'deviceInfo': deviceInfo,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'consentStatus': consentStatus,
      'ageGroup': ageGroup,
      'engagementTime': engagementTime,
      'qualifiesForAER': qualifiesForAER,
      'aerAmount': aerAmount,
      'at': Timestamp.fromDate(at),
    };
  }
}

class AEREvent {
  final String id;
  final String userId;
  final String adEventRef;
  final String format;
  final double aerAmount;
  final int engagementTime;
  final String qualificationReason;
  final String deviceFingerprint;
  final String ipAddress;
  final DateTime createdAt;
  final bool serverValidated;

  AEREvent({
    required this.id,
    required this.userId,
    required this.adEventRef,
    required this.format,
    required this.aerAmount,
    required this.engagementTime,
    required this.qualificationReason,
    required this.deviceFingerprint,
    required this.ipAddress,
    required this.createdAt,
    required this.serverValidated,
  });

  factory AEREvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AEREvent(
      id: doc.id,
      userId: data['userId'] ?? '',
      adEventRef: data['adEventRef'] ?? '',
      format: data['format'] ?? '',
      aerAmount: (data['aerAmount'] ?? 0.0).toDouble(),
      engagementTime: data['engagementTime'] ?? 0,
      qualificationReason: data['qualificationReason'] ?? '',
      deviceFingerprint: data['deviceFingerprint'] ?? '',
      ipAddress: data['ipAddress'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      serverValidated: data['serverValidated'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'adEventRef': adEventRef,
      'format': format,
      'aerAmount': aerAmount,
      'engagementTime': engagementTime,
      'qualificationReason': qualificationReason,
      'deviceFingerprint': deviceFingerprint,
      'ipAddress': ipAddress,
      'createdAt': Timestamp.fromDate(createdAt),
      'serverValidated': serverValidated,
    };
  }
}

class Withdrawal {
  final String id;
  final String userId;
  final String month;
  final double amount;
  final double platformFee;
  final String method;
  final String status;
  final bool kycRequired;
  final bool amlChecked;
  final DateTime? settledAt;
  final String? txRef;
  final String? notes;
  final String? reviewedBy;
  final String? complianceNotes;

  Withdrawal({
    required this.id,
    required this.userId,
    required this.month,
    required this.amount,
    required this.platformFee,
    required this.method,
    required this.status,
    required this.kycRequired,
    required this.amlChecked,
    this.settledAt,
    this.txRef,
    this.notes,
    this.reviewedBy,
    this.complianceNotes,
  });

  factory Withdrawal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Withdrawal(
      id: doc.id,
      userId: data['userId'] ?? '',
      month: data['month'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      platformFee: (data['platformFee'] ?? 0.0).toDouble(),
      method: data['method'] ?? '',
      status: data['status'] ?? '',
      kycRequired: data['kycRequired'] ?? false,
      amlChecked: data['amlChecked'] ?? false,
      settledAt: data['settledAt'] != null
          ? (data['settledAt'] as Timestamp).toDate()
          : null,
      txRef: data['txRef'],
      notes: data['notes'],
      reviewedBy: data['reviewedBy'],
      complianceNotes: data['complianceNotes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'month': month,
      'amount': amount,
      'platformFee': platformFee,
      'method': method,
      'status': status,
      'kycRequired': kycRequired,
      'amlChecked': amlChecked,
      'settledAt': settledAt != null ? Timestamp.fromDate(settledAt!) : null,
      'txRef': txRef,
      'notes': notes,
      'reviewedBy': reviewedBy,
      'complianceNotes': complianceNotes,
    };
  }
}
