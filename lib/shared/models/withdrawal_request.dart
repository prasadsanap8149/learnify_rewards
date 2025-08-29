import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/enums.dart';

class WithdrawalRequest {
  final String id;
  final String userId;
  final double amount;
  final WithdrawalMethod method;
  final Map<String, dynamic> paymentDetails;
  final WithdrawalStatus status;
  final DateTime requestedAt;
  final DateTime? completedAt;
  final DateTime? failedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? note;
  final String? error;
  final String? transactionId;
  final String? approvedBy;
  final String? rejectedBy;
  final String? rejectionReason;
  final int fraudScore;
  final bool requiresManualReview;

  WithdrawalRequest({
    required this.id,
    required this.userId,
    required this.amount,
    required this.method,
    required this.paymentDetails,
    required this.status,
    required this.requestedAt,
    this.completedAt,
    this.failedAt,
    this.approvedAt,
    this.rejectedAt,
    this.note,
    this.error,
    this.transactionId,
    this.approvedBy,
    this.rejectedBy,
    this.rejectionReason,
    this.fraudScore = 0,
    this.requiresManualReview = false,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequest(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      method: WithdrawalMethod.values.firstWhere(
        (e) => e.toString() == json['method'],
        orElse: () => WithdrawalMethod.paypal,
      ),
      paymentDetails: Map<String, dynamic>.from(json['paymentDetails'] ?? {}),
      status: WithdrawalStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => WithdrawalStatus.pending,
      ),
      requestedAt: _parseTimestamp(json['requestedAt']),
      completedAt: json['completedAt'] != null
          ? _parseTimestamp(json['completedAt'])
          : null,
      failedAt:
          json['failedAt'] != null ? _parseTimestamp(json['failedAt']) : null,
      approvedAt: json['approvedAt'] != null
          ? _parseTimestamp(json['approvedAt'])
          : null,
      rejectedAt: json['rejectedAt'] != null
          ? _parseTimestamp(json['rejectedAt'])
          : null,
      note: json['note'] as String?,
      error: json['error'] as String?,
      transactionId: json['transactionId'] as String?,
      approvedBy: json['approvedBy'] as String?,
      rejectedBy: json['rejectedBy'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      fraudScore: json['fraudScore'] as int? ?? 0,
      requiresManualReview: json['requiresManualReview'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'method': method.toString(),
      'paymentDetails': paymentDetails,
      'status': status.toString(),
      'requestedAt': Timestamp.fromDate(requestedAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'failedAt': failedAt != null ? Timestamp.fromDate(failedAt!) : null,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'note': note,
      'error': error,
      'transactionId': transactionId,
      'approvedBy': approvedBy,
      'rejectedBy': rejectedBy,
      'rejectionReason': rejectionReason,
      'fraudScore': fraudScore,
      'requiresManualReview': requiresManualReview,
    };
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is DateTime) {
      return timestamp;
    }
    return DateTime.now();
  }

  WithdrawalRequest copyWith({
    String? id,
    String? userId,
    double? amount,
    WithdrawalMethod? method,
    Map<String, dynamic>? paymentDetails,
    WithdrawalStatus? status,
    DateTime? requestedAt,
    DateTime? completedAt,
    DateTime? failedAt,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    String? note,
    String? error,
    String? transactionId,
    String? approvedBy,
    String? rejectedBy,
    String? rejectionReason,
    int? fraudScore,
    bool? requiresManualReview,
  }) {
    return WithdrawalRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      completedAt: completedAt ?? this.completedAt,
      failedAt: failedAt ?? this.failedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      note: note ?? this.note,
      error: error ?? this.error,
      transactionId: transactionId ?? this.transactionId,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      fraudScore: fraudScore ?? this.fraudScore,
      requiresManualReview: requiresManualReview ?? this.requiresManualReview,
    );
  }

  /// Get formatted amount
  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case WithdrawalStatus.pending:
        return 'Pending';
      case WithdrawalStatus.pendingReview:
        return 'Pending Review';
      case WithdrawalStatus.pendingSettlement:
        return 'Pending Settlement';
      case WithdrawalStatus.approved:
        return 'Approved';
      case WithdrawalStatus.processing:
        return 'Processing';
      case WithdrawalStatus.completed:
        return 'Completed';
      case WithdrawalStatus.failed:
        return 'Failed';
      case WithdrawalStatus.rejected:
        return 'Rejected';
      case WithdrawalStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get method display text
  String get methodDisplayText {
    switch (method) {
      case WithdrawalMethod.paypal:
        return 'PayPal';
      case WithdrawalMethod.bankTransfer:
        return 'Bank Transfer';
      case WithdrawalMethod.cryptocurrency:
        return 'Cryptocurrency';
      case WithdrawalMethod.giftCard:
        return 'Gift Card';
      case WithdrawalMethod.check:
        return 'Check';
    }
  }

  /// Check if withdrawal is completed
  bool get isCompleted => status == WithdrawalStatus.completed;

  /// Check if withdrawal is pending
  bool get isPending =>
      status == WithdrawalStatus.pending ||
      status == WithdrawalStatus.pendingReview ||
      status == WithdrawalStatus.pendingSettlement ||
      status == WithdrawalStatus.approved ||
      status == WithdrawalStatus.processing;

  /// Check if withdrawal failed
  bool get isFailed =>
      status == WithdrawalStatus.failed || status == WithdrawalStatus.rejected;

  /// Check if withdrawal can be cancelled
  bool get canBeCancelled =>
      status == WithdrawalStatus.pending ||
      status == WithdrawalStatus.pendingReview;

  /// Get processing time (if completed)
  Duration? get processingTime {
    if (completedAt != null) {
      return completedAt!.difference(requestedAt);
    }
    return null;
  }

  /// Get formatted processing time
  String? get formattedProcessingTime {
    final duration = processingTime;
    if (duration == null) return null;

    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  /// Get masked payment details for display
  Map<String, dynamic> get maskedPaymentDetails {
    final masked = Map<String, dynamic>.from(paymentDetails);

    switch (method) {
      case WithdrawalMethod.paypal:
        if (masked.containsKey('email')) {
          final email = masked['email'] as String;
          final atIndex = email.indexOf('@');
          if (atIndex > 2) {
            masked['email'] =
                '${email.substring(0, 2)}***${email.substring(atIndex)}';
          }
        }
        break;

      case WithdrawalMethod.bankTransfer:
        if (masked.containsKey('accountNumber')) {
          final accountNumber = masked['accountNumber'] as String;
          if (accountNumber.length > 4) {
            masked['accountNumber'] =
                '****${accountNumber.substring(accountNumber.length - 4)}';
          }
        }
        if (masked.containsKey('routingNumber')) {
          masked['routingNumber'] = '****';
        }
        break;

      case WithdrawalMethod.cryptocurrency:
        if (masked.containsKey('address')) {
          final address = masked['address'] as String;
          if (address.length > 8) {
            masked['address'] =
                '${address.substring(0, 4)}...${address.substring(address.length - 4)}';
          }
        }
        break;

      case WithdrawalMethod.giftCard:
        // Gift cards don't have sensitive details to mask
        break;
      case WithdrawalMethod.check:
        if (masked.containsKey('routingNumber')) {
          masked['routingNumber'] = '****';
        }
        if (masked.containsKey('accountNumber')) {
          final accountNumber = masked['accountNumber'] as String;
          if (accountNumber.length > 4) {
            masked['accountNumber'] =
                '****${accountNumber.substring(accountNumber.length - 4)}';
          }
        }
        break;
    }

    return masked;
  }

  /// Get risk level based on fraud score
  String get riskLevel {
    if (fraudScore >= 80) return 'High';
    if (fraudScore >= 60) return 'Medium';
    if (fraudScore >= 30) return 'Low';
    return 'Minimal';
  }

  /// Get risk level color
  String get riskLevelColor {
    if (fraudScore >= 80) return 'red';
    if (fraudScore >= 60) return 'orange';
    if (fraudScore >= 30) return 'yellow';
    return 'green';
  }

  @override
  String toString() {
    return 'WithdrawalRequest(id: $id, userId: $userId, amount: $amount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WithdrawalRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
