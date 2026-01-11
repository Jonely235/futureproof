import 'dart:convert';
import '../models/app_error.dart';
import 'app_logger.dart';

/// Tracked error with metadata for debugging.
class TrackedError {
  /// The error that was tracked
  final AppError error;

  /// When the error occurred
  final DateTime timestamp;

  /// Where the error occurred (screen/component/service)
  final String context;

  /// Stack trace for debugging
  final StackTrace? stackTrace;

  TrackedError({
    required this.error,
    required this.timestamp,
    required this.context,
    this.stackTrace,
  });

  /// Converts tracked error to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'type': error.type.name,
      'message': error.message,
      'context': context,
      'technicalDetails': error.technicalDetails,
      'originalError': error.originalError?.toString(),
    };
  }
}

/// Centralized error tracking utility for debugging production issues.
///
/// Maintains in-memory history of errors with filtering and export capabilities.
/// Helps identify error patterns and diagnose issues in production.
///
/// Singleton pattern ensures single error history across app.
class ErrorTracker {
  // Private constructor for singleton
  ErrorTracker._internal();

  // Static instance
  static final ErrorTracker _instance = ErrorTracker._internal();

  // Factory constructor returning singleton instance
  factory ErrorTracker() => _instance;

  // Maximum history size to prevent unbounded growth
  static const int maxHistorySize = 100;

  // Error history (memory only - no persistence in this phase)
  final List<TrackedError> _errorHistory = [];

  /// Track an error in the error history.
  ///
  /// Logs the error and adds it to history.
  /// Removes oldest errors if history exceeds maxHistorySize.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await operation();
  /// } catch (e, st) {
  ///   final error = AppError.fromException(e, stackTrace: st);
  ///   ErrorTracker().trackError(error, 'MyScreen.loadData', stackTrace: st);
  ///   throw error;
  /// }
  /// ```
  void trackError(
    AppError error,
    String context, {
    StackTrace? stackTrace,
  }) {
    final trackedError = TrackedError(
      error: error,
      timestamp: DateTime.now(),
      context: context,
      stackTrace: stackTrace,
    );

    _errorHistory.add(trackedError);

    // Remove oldest errors if exceeding max size
    while (_errorHistory.length > maxHistorySize) {
      _errorHistory.removeAt(0);
    }

    // Log the error tracking
    AppLogger.general.severe(
      'Error tracked: [$context] ${error.message}',
      error.originalError,
      error.stackTrace,
    );
  }

  /// Get most recent N errors.
  ///
  /// Returns newest errors first (descending timestamp order).
  /// Default count is 20.
  ///
  /// Example:
  /// ```dart
  /// final recentErrors = ErrorTracker().getRecentErrors(count: 10);
  /// ```
  List<TrackedError> getRecentErrors({int count = 20}) {
    final sortedErrors = List<TrackedError>.from(_errorHistory)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedErrors.take(count).toList();
  }

  /// Get all errors of a specific type.
  ///
  /// Returns all errors matching the given AppErrorType.
  /// Sorted by timestamp (newest first).
  ///
  /// Example:
  /// ```dart
  /// final dbErrors = ErrorTracker().getErrorsByType(AppErrorType.database);
  /// ```
  List<TrackedError> getErrorsByType(AppErrorType type) {
    final filtered = _errorHistory
        .where((tracked) => tracked.error.type == type)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  /// Get all errors from a specific context.
  ///
  /// Returns all errors that occurred in the given screen/component/service.
  /// Sorted by timestamp (newest first).
  ///
  /// Example:
  /// ```dart
  /// final providerErrors = ErrorTracker().getErrorsByContext('TransactionProvider');
  /// ```
  List<TrackedError> getErrorsByContext(String context) {
    final filtered = _errorHistory
        .where((tracked) => tracked.context.contains(context))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  /// Clear all error history.
  ///
  /// Removes all tracked errors from memory.
  /// Logs the clear operation.
  ///
  /// Example:
  /// ```dart
  /// ErrorTracker().clearHistory();
  /// ```
  void clearHistory() {
    final count = _errorHistory.length;
    _errorHistory.clear();
    AppLogger.general.info('Cleared error history ($count errors)');
  }

  /// Get current error count.
  ///
  /// Returns number of errors currently in history.
  ///
  /// Example:
  /// ```dart
  /// final errorCount = ErrorTracker().getErrorCount();
  /// ```
  int getErrorCount() {
    return _errorHistory.length;
  }

  /// Export error log as JSON string.
  ///
  /// Returns JSON string of all tracked errors with full details.
  /// Useful for sharing error logs for debugging.
  ///
  /// Example:
  /// ```dart
  /// final errorLog = ErrorTracker().exportErrorLog();
  /// print(errorLog);
  /// ```
  String exportErrorLog() {
    final errorMaps = _errorHistory.map((e) => e.toMap()).toList();
    final logData = {
      'exportDate': DateTime.now().toIso8601String(),
      'errorCount': errorMaps.length,
      'errors': errorMaps,
    };
    return jsonEncode(logData);
  }
}
