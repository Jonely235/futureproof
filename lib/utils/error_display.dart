import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../models/app_error.dart';
import 'app_logger.dart';

/// Centralized error display utility for consistent UI error messaging.
///
/// Provides standardized SnackBar and Dialog formatting for errors,
/// ensuring consistent user experience across all screens.
class ErrorDisplay {
  ErrorDisplay._(); // Private constructor to prevent instantiation

  /// Maps AppError type to appropriate icon for visual feedback.
  static IconData _getErrorIcon(AppErrorType type) {
    switch (type) {
      case AppErrorType.database:
        return Icons.storage;
      case AppErrorType.network:
        return Icons.wifi_off;
      case AppErrorType.validation:
        return Icons.error_outline;
      case AppErrorType.backup:
        return Icons.backup;
      case AppErrorType.unknown:
      default:
        return Icons.warning;
    }
  }

  /// Shows an error SnackBar with consistent styling.
  ///
  /// Maps AppError type to appropriate icon, uses user-friendly message,
  /// logs error before displaying. Duration: 4 seconds.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await operation();
  /// } catch (e, st) {
  ///   final error = AppError.fromException(e, stackTrace: st);
  ///   ErrorDisplay.showErrorSnackBar(context, error);
  /// }
  /// ```
  static void showErrorSnackBar(BuildContext context, AppError error) {
    // Log error with appropriate logger based on type
    final logger = _getLoggerForErrorType(error.type);
    logger.severe(
      'Displaying error to user: ${error.message}',
      error.originalError,
      error.stackTrace,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getErrorIcon(error.type), color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(error.message),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows a success SnackBar with consistent styling.
  ///
  /// Green background, white text, check icon, duration: 2 seconds.
  /// Logs success message with AppLogger.info.
  ///
  /// Example:
  /// ```dart
  /// ErrorDisplay.showSuccessSnackBar(context, 'Settings saved successfully');
  /// ```
  static void showSuccessSnackBar(BuildContext context, String message) {
    AppLogger.ui.info('Success: $message');

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows an error AlertDialog for critical errors.
  ///
  /// Displays technical details in collapsible section if available.
  /// Logs error with AppLogger.severe before showing.
  ///
  /// Use for critical errors that require user acknowledgment.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await criticalOperation();
  /// } catch (e, st) {
  ///   final error = AppError.fromException(e, stackTrace: st);
  ///   ErrorDisplay.showErrorDialog(context, error);
  /// }
  /// ```
  static Future<void> showErrorDialog(
    BuildContext context,
    AppError error,
  ) async {
    // Log critical error
    final logger = _getLoggerForErrorType(error.type);
    logger.severe(
      'Showing critical error dialog: ${error.message}',
      error.originalError,
      error.stackTrace,
    );

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(_getErrorIcon(error.type), size: 48, color: Colors.red),
        title: const Text('Error'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(error.message),
              if (error.technicalDetails != null) ...[
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text(
                    'Technical Details',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        error.technicalDetails!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Returns appropriate logger for error type.
  static Logger _getLoggerForErrorType(AppErrorType type) {
    switch (type) {
      case AppErrorType.database:
        return AppLogger.database;
      case AppErrorType.network:
        return AppLogger.services;
      case AppErrorType.validation:
        return AppLogger.ui;
      case AppErrorType.backup:
        return AppLogger.backup;
      case AppErrorType.unknown:
        return AppLogger.general;
    }
  }
}
