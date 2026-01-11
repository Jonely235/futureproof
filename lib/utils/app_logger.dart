import 'package:logging/logging.dart';

/// Centralized logging utility for FutureProof application.
///
/// Provides static logger instances for different components and helper methods
/// for consistent logging patterns across the application.
class AppLogger {
  // Logger instances for different components
  static final _ui = Logger('UI');
  static final _database = Logger('Database');
  static final _analytics = Logger('Analytics');
  static final _services = Logger('Services');
  static final _general = Logger('General');
  static final _backup = Logger('Backup');

  /// Get UI logger for screen/widget related logs
  static Logger get ui => _ui;

  /// Get Database logger for storage operations
  static Logger get database => _database;

  /// Get Analytics logger for tracking events
  static Logger get analytics => _analytics;

  /// Get Services logger for business logic services
  static Logger get services => _services;

  /// Get General logger for uncategorized logs
  static Logger get general => _general;

  /// Get Backup logger for data export/import operations
  static Logger get backup => _backup;

  /// Log an informational message.
  ///
  /// Use for normal operations and expected application flow.
  /// Example: User actions, successful operations, state changes
  static void logInfo(Logger logger, String message) {
    logger.info(message);
  }

  /// Log a warning message.
  ///
  /// Use for recoverable issues and unexpected but non-fatal situations.
  /// Example: Missing data that can be defaulted, API retries, fallback behavior
  static void logWarning(Logger logger, String message, [Object? error, StackTrace? stackTrace]) {
    logger.warning(message, error, stackTrace);
  }

  /// Log a severe error message.
  ///
  /// Use for errors that impact functionality or require attention.
  /// Example: Failed operations, exceptions, data corruption
  static void logError(Logger logger, String message, [Object? error, StackTrace? stackTrace]) {
    logger.severe(message, error, stackTrace);
  }

  /// Log with context prefix for better traceability.
  ///
  /// Example: AppLogger.logWithContext(AppLogger.services, 'Transaction', 'Saved successfully')
  static void logWithContext(Logger logger, String context, String message) {
    logger.info('[$context] $message');
  }
}
