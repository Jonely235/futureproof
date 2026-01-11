/// Standardized error class for FutureProof app error handling.
///
/// Provides consistent error structure across all services and UI layers.
/// Includes user-friendly messages, technical details, and original error context.
class AppError {
  /// User-friendly error message suitable for display
  final String message;

  /// Technical details for debugging (not shown to users)
  final String? technicalDetails;

  /// The original exception that caused this error
  final Object? originalError;

  /// Stack trace for debugging
  final StackTrace? stackTrace;

  /// Type of error for categorization
  final AppErrorType type;

  /// Creates a new AppError with full context
  const AppError({
    required this.type,
    required this.message,
    this.technicalDetails,
    this.originalError,
    this.stackTrace,
  });

  /// Factory constructor that converts any exception to AppError
  factory AppError.fromException(
    Object? error, {
    AppErrorType? type,
    StackTrace? stackTrace,
  }) {
    if (error is AppError) {
      return error;
    }

    String message;
    String? technicalDetails;

    if (error is Exception) {
      message = error.toString().replaceFirst('Exception: ', '');
      technicalDetails = error.toString();
    } else if (error != null) {
      message = error.toString();
      technicalDetails = error.toString();
    } else {
      message = 'An unknown error occurred';
      technicalDetails = 'Null error object';
    }

    return AppError(
      type: type ?? AppErrorType.unknown,
      message: message,
      technicalDetails: technicalDetails,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('AppError[$type]: $message');

    if (technicalDetails != null) {
      buffer.write(' | Details: $technicalDetails');
    }

    if (originalError != null) {
      buffer.write(' | Original: $originalError');
    }

    return buffer.toString();
  }

  /// Converts error to a map for serialization (e.g., for error tracking export)
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'message': message,
      'technicalDetails': technicalDetails,
      'originalError': originalError?.toString(),
    };
  }
}

/// Categories of errors that can occur in the app
enum AppErrorType {
  /// SQLite database operations
  database,

  /// Network API calls (future use for cloud sync)
  network,

  /// Input validation failures
  validation,

  /// Import/export backup operations
  backup,

  /// Catch-all for unexpected errors
  unknown,
}
