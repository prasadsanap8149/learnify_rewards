class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() =>
      'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

class AuthException extends AppException {
  AuthException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

class NetworkException extends AppException {
  NetworkException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

class ValidationException extends AppException {
  ValidationException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

class ComplianceException extends AppException {
  ComplianceException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

class FraudException extends AppException {
  FraudException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

class WithdrawalException extends AppException {
  WithdrawalException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

class AgeRestrictionException extends AppException {
  AgeRestrictionException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

class ActivityException extends AppException {
  ActivityException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

class AERException extends AppException {
  AERException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}
