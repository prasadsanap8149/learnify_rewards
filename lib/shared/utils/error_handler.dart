import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Centralized error handling utility for the app
class ErrorHandler {
  /// Show a snackbar with error message
  static void showError(BuildContext context, dynamic error) {
    String message = _getErrorMessage(error);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  /// Show success message
  static void showSuccess(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Show info message
  static void showInfo(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Get user-friendly error message
  static String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return _getAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      return _getFirestoreErrorMessage(error);
    } else if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    } else {
      return error.toString();
    }
  }

  /// Get Firebase Auth error message
  static String _getAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'requires-recent-login':
        return 'Please log in again to perform this action.';
      default:
        return error.message ?? 'Authentication error occurred.';
    }
  }

  /// Get Firestore error message
  static String _getFirestoreErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You don\'t have permission to perform this action.';
      case 'unavailable':
        return 'Service is currently unavailable. Please try again.';
      case 'deadline-exceeded':
        return 'Request timeout. Please try again.';
      case 'not-found':
        return 'The requested data was not found.';
      case 'already-exists':
        return 'This data already exists.';
      case 'resource-exhausted':
        return 'Resource limit exceeded. Please try again later.';
      case 'failed-precondition':
        return 'Operation failed. Please check your data.';
      case 'aborted':
        return 'Operation was aborted. Please try again.';
      case 'out-of-range':
        return 'Invalid data range provided.';
      case 'unimplemented':
        return 'This feature is not yet implemented.';
      case 'internal':
        return 'Internal error occurred. Please try again.';
      case 'unauthenticated':
        return 'Please sign in to continue.';
      case 'invalid-argument':
        return 'Invalid data provided.';
      case 'cancelled':
        return 'Operation was cancelled.';
      default:
        return error.message ?? 'An error occurred. Please try again.';
    }
  }

  /// Log error for debugging
  static void logError(dynamic error, [StackTrace? stackTrace]) {
    debugPrint('❌ Error: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Show error dialog
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onAction();
              },
              child: Text(actionLabel),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show confirmation dialog
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDangerous
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Show loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Dismiss loading dialog
  static void dismissLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Handle async operation with loading and error handling
  static Future<T?> handleAsync<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? loadingMessage,
    String? successMessage,
    bool showLoading = true,
  }) async {
    try {
      if (showLoading && context.mounted) {
        showLoadingDialog(context, message: loadingMessage);
      }

      final result = await operation();

      if (showLoading && context.mounted) {
        dismissLoadingDialog(context);
      }

      if (successMessage != null && context.mounted) {
        showSuccess(context, successMessage);
      }

      return result;
    } catch (error, stackTrace) {
      logError(error, stackTrace);
      
      if (showLoading && context.mounted) {
        dismissLoadingDialog(context);
      }

      if (context.mounted) {
        showError(context, error);
      }

      return null;
    }
  }
}

/// Validation utility class
class Validator {
  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validate number
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (double.tryParse(value) == null) {
      return '$fieldName must be a valid number';
    }
    return null;
  }

  /// Validate positive number
  static String? validatePositiveNumber(String? value, String fieldName) {
    final error = validateNumber(value, fieldName);
    if (error != null) return error;
    
    final number = double.parse(value!);
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  /// Validate length
  static String? validateLength(
    String? value,
    String fieldName, {
    int? min,
    int? max,
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (min != null && value.length < min) {
      return '$fieldName must be at least $min characters';
    }
    if (max != null && value.length > max) {
      return '$fieldName must be at most $max characters';
    }
    return null;
  }

  /// Validate URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional
    }
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  /// Validate date of birth (minimum age)
  static String? validateDateOfBirth(DateTime? value, {int minimumAge = 13}) {
    if (value == null) {
      return 'Date of birth is required';
    }
    final age = DateTime.now().difference(value).inDays ~/ 365;
    if (age < minimumAge) {
      return 'You must be at least $minimumAge years old';
    }
    return null;
  }
}
