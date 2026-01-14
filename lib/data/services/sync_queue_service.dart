import 'dart:async';
import '../../utils/app_logger.dart';

/// Sync operation types
enum SyncOperation { backup, restore, sync }

/// Queued sync operation with error details
class QueuedOperation {
  final SyncOperation operation;
  final String error;
  final DateTime timestamp;

  QueuedOperation({
    required this.operation,
    required this.error,
    required this.timestamp,
  });

  @override
  String toString() =>
      'QueuedOperation(operation: $operation, error: $error, timestamp: $timestamp)';
}

/// Sync Queue Service
///
/// Manages failed sync operations with hybrid error handling:
/// - Queue errors for 1 hour
/// - Retry every 5 minutes
/// - Show user-facing error after 1 hour of failures
class SyncQueueService {
  final List<QueuedOperation> _queue = [];
  Timer? _retryTimer;

  static const Duration _retryInterval = Duration(minutes: 5);
  static const Duration _maxQueueTime = Duration(hours: 1);

  // Callbacks for retry and error display
  Function(SyncOperation)? onRetry;
  Function(String)? onError;

  SyncQueueService() {
    _startRetryTimer();
    AppLogger.backup.info('⏳ SyncQueueService initialized');
  }

  /// Enqueue a failed sync operation
  void enqueue(SyncOperation operation, String error) {
    _queue.add(QueuedOperation(
      operation: operation,
      error: error,
      timestamp: DateTime.now(),
    ));
    AppLogger.backup.warning(
        '⚠️ Sync queued: $operation (queue size: ${_queue.length})');
  }

  /// Start periodic retry timer
  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(_retryInterval, (_) {
      _processQueue();
    });
    AppLogger.backup.info(
        '🔄 Retry timer started (interval: ${_retryInterval.inMinutes} min)');
  }

  /// Process queued operations
  Future<void> _processQueue() async {
    if (_queue.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final expiredOperations = <QueuedOperation>[];
    final retryableOperations = <QueuedOperation>[];

    // Separate expired and retryable operations
    for (final op in _queue) {
      final age = now.difference(op.timestamp);
      if (age > _maxQueueTime) {
        expiredOperations.add(op);
      } else if (age >= const Duration(minutes: 5)) {
        retryableOperations.add(op);
      }
    }

    // Remove expired operations and show error
    for (final op in expiredOperations) {
      _queue.remove(op);
      if (onError != null) {
        onError!(
            'Sync failed for ${_maxQueueTime.inMinutes} minutes. Last error: ${op.error}');
      }
      AppLogger.backup.severe(
          '❌ Sync expired after ${_maxQueueTime.inMinutes} min: ${op.operation}');
    }

    // Retry operations older than 5 minutes
    for (final op in retryableOperations) {
      _queue.remove(op);
      if (onRetry != null) {
        onRetry!(op.operation);
        AppLogger.backup.info('🔄 Retrying: ${op.operation}');
      }
    }

    // Clear old errors (keep last 10)
    if (_queue.length > 10) {
      _queue.removeRange(0, _queue.length - 10);
    }
  }

  /// Get queue size
  int get queueSize => _queue.length;

  /// Check if queue has operations
  bool get hasPendingOperations => _queue.isNotEmpty;

  /// Clear all queued operations
  void clear() {
    _queue.clear();
    AppLogger.backup.info('🗑️ Sync queue cleared');
  }

  /// Dispose resources
  void dispose() {
    _retryTimer?.cancel();
    AppLogger.backup.info('⏸️ SyncQueueService disposed');
  }
}
