import 'user.dart';

enum AgeVerificationMethod {
  selfReported,
  parentalConfirmation,
  documentVerification,
  thirdPartyVerification,
}

enum AgeVerificationStatus {
  pending,
  verified,
  rejected,
  expired,
  requiresReview,
}

class AgeVerification {
  final String id;
  final String userId;
  final AgeVerificationMethod method;
  final AgeVerificationStatus status;
  final AgeGroup verifiedAgeGroup;
  final DateTime dateOfBirth;
  final String? documentType;
  final String? documentNumber;
  final String? parentEmail;
  final String? parentName;
  final DateTime? parentConsentDate;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic>? metadata;

  AgeVerification({
    required this.id,
    required this.userId,
    required this.method,
    required this.status,
    required this.verifiedAgeGroup,
    required this.dateOfBirth,
    this.documentType,
    this.documentNumber,
    this.parentEmail,
    this.parentName,
    this.parentConsentDate,
    this.verifiedBy,
    this.verifiedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    this.metadata,
  });

  factory AgeVerification.fromJson(Map<String, dynamic> json) {
    return AgeVerification(
      id: json['id'],
      userId: json['userId'],
      method: AgeVerificationMethod.values.firstWhere(
        (e) => e.toString().split('.').last == json['method'],
      ),
      status: AgeVerificationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      verifiedAgeGroup: AgeGroup.values.firstWhere(
        (e) => e.toString().split('.').last == json['verifiedAgeGroup'],
      ),
      dateOfBirth: json['dateOfBirth']?.toDate() ?? DateTime.now(),
      documentType: json['documentType'],
      documentNumber: json['documentNumber'],
      parentEmail: json['parentEmail'],
      parentName: json['parentName'],
      parentConsentDate: json['parentConsentDate']?.toDate(),
      verifiedBy: json['verifiedBy'],
      verifiedAt: json['verifiedAt']?.toDate(),
      rejectionReason: json['rejectionReason'],
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: json['updatedAt']?.toDate() ?? DateTime.now(),
      expiresAt: json['expiresAt']?.toDate(),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'method': method.toString().split('.').last,
      'status': status.toString().split('.').last,
      'verifiedAgeGroup': verifiedAgeGroup.toString().split('.').last,
      'dateOfBirth': dateOfBirth,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'parentEmail': parentEmail,
      'parentName': parentName,
      'parentConsentDate': parentConsentDate,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'expiresAt': expiresAt,
      'metadata': metadata,
    };
  }

  bool get isValid {
    if (status != AgeVerificationStatus.verified) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  int get currentAge {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  AgeGroup get currentAgeGroup {
    final age = currentAge;
    if (age < 13) return AgeGroup.under13;
    if (age >= 13 && age <= 17) return AgeGroup.thirteen_to_seventeen;
    return AgeGroup.eighteen_plus;
  }
}
