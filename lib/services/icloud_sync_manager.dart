import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../config/icloud_config.dart';
import '../providers/transaction_provider.dart';
import '../providers/vault_provider.dart';
import '../utils/app_logger.dart';
import 'backup_service.dart';

/// iCloud Sync Manager
///
/// Manages debounced iCloud sync operations to prevent excessive writes.
/// Accumulates sync reasons and batches them into a single sync operation.
/// Implements exponential backoff retry logic for failed syncs.
///
/// Usage:
/// ```dart
/// ICloudSyncManager.instance.scheduleSync(
///   reason: SyncReason.vaultCreated,
///   vaultProvider: vaultProvider,
///   transactionProviders: transactionProviders,
/// );
/// ```
class ICloudSyncManager {
  ICloudSyncManager._internal(this._statusController);
  static final ICloudSyncManager instance = ICloudSyncManager._internal(
    StreamController<SyncStatus>.broadcast(
      onListen: () => 0,
      onCancel: () => 0,
    ),
  );

  final _log = Logger('ICloudSyncManager');

  Timer? _debounceTimer;
  Timer? _maxSyncTimer;
  Timer? _statusResetTimer;
  DateTime? _lastSyncTime;

  // Track pending sync reasons for logging
  final Set<SyncReason> _pendingReasons = {};
  final List<String> _pendingDetails = [];

  // Retry tracking
  int _retryCount = 0;
  DateTime? _lastFailedSyncTime;

  // State tracking
  bool _isSyncing = false;
  SyncStatus _status = SyncStatus.idle;

  // Stream controller for status updates - initialized via factory constructor
  final StreamController<SyncStatus> _statusController;

  Stream<SyncStatus> get statusStream => _statusController.stream;

  SyncStatus get currentStatus => _status;

  /// Schedule a sync with the given reason
  ///
  /// If a sync is already scheduled, it will be debounced.
  /// If the maximum interval has passed since last sync, sync will run immediately.
  void scheduleSync({
    required SyncReason reason,
    required VaultProvider vaultProvider,
    required Map<String, TransactionProvider> transactionProviders,
    String? detail,
  }) {
    _pendingReasons.add(reason);
    if (detail != null) {
      _pendingDetails.add(detail);
    }

    _log.fine('Sync scheduled: $reason ${detail != null ? "- $detail" : ""}');

    // Check if we need to force sync due to max interval
    if (_lastSyncTime != null) {
      final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
      if (timeSinceLastSync > ICloudConfig.maxSyncInterval) {
        _log.info('Max sync interval reached, forcing sync');
        _executeSync(vaultProvider, transactionProviders);
        return;
      }
    }

    // Cancel existing timers before creating new ones
    _debounceTimer?.cancel();
    _maxSyncTimer?.cancel();

    // Set debounce timer
    _debounceTimer = Timer(ICloudConfig.syncDebounceDelay, () {
      _executeSync(vaultProvider, transactionProviders);
    });

    // Set max sync timer as a safety net (only if not already syncing)
    if (!_isSyncing) {
      _maxSyncTimer = Timer(ICloudConfig.maxSyncInterval, () {
        _log.info('Max sync timer fired, forcing sync');
        _executeSync(vaultProvider, transactionProviders);
      });
    }

    _updateStatus(SyncStatus.scheduled);
  }

  /// Execute the sync operation with retry logic
  Future<void> _executeSync(
    VaultProvider vaultProvider,
    Map<String, TransactionProvider> transactionProviders,
  ) async {
    if (_isSyncing) {
      _log.fine('Sync already in progress, skipping');
      return;
    }

    // Cancel timers to prevent duplicate syncs
    _debounceTimer?.cancel();
    _maxSyncTimer?.cancel();

    _isSyncing = true;
    _updateStatus(SyncStatus.syncing);

    // Capture pending reasons before clearing
    final reasons = List<SyncReason>.from(_pendingReasons);
    final details = List<String>.from(_pendingDetails);
    _pendingReasons.clear();
    _pendingDetails.clear();

    _log.info('Executing iCloud sync. Reasons: $reasons');

    bool success = false;

    try {
      // Attempt sync with retry logic
      success = await _attemptSyncWithRetry(
        vaultProvider: vaultProvider,
        transactionProviders: transactionProviders,
      );

      if (success) {
        _lastSyncTime = DateTime.now();
        _retryCount = 0; // Reset retry count on success
        _log.info('iCloud sync completed successfully');
        _updateStatus(SyncStatus.success);
        // Reset to idle after a short delay
        _statusResetTimer?.cancel();
        _statusResetTimer = Timer(ICloudConfig.successStatusResetDelay, () {
          if (!_isSyncing) _updateStatus(SyncStatus.idle);
        });
      } else {
        _handleSyncFailure(reasons, details, vaultProvider, transactionProviders);
      }
    } catch (e, st) {
      _log.severe('iCloud sync error: $e', e, st);
      _handleSyncFailure(reasons, details, vaultProvider, transactionProviders);
    } finally {
      _isSyncing = false;
    }
  }

  /// Attempt sync with exponential backoff retry
  Future<bool> _attemptSyncWithRetry({
    required VaultProvider vaultProvider,
    required Map<String, TransactionProvider> transactionProviders,
  }) async {
    for (int attempt = 0; attempt < ICloudConfig.maxSyncRetries; attempt++) {
      try {
        final success = await BackupService.instance.triggeriCloudSync(
          vaultProvider: vaultProvider,
          transactionProviders: transactionProviders,
        );

        if (success) {
          if (attempt > 0) {
            _log.info('Sync succeeded on attempt ${attempt + 1}');
          }
          return true;
        }

        // If not successful and not the last attempt, wait before retrying
        if (attempt < ICloudConfig.maxSyncRetries - 1) {
          _retryCount = attempt + 1;
          final delay = _calculateRetryDelay(attempt);
          _log.warning('Sync failed, retrying in ${delay.inSeconds}s (attempt ${attempt + 1}/${ICloudConfig.maxSyncRetries})');
          await Future.delayed(delay);
        }
      } catch (e) {
        _log.warning('Sync attempt ${attempt + 1} failed: $e');

        // If this is the last attempt, rethrow the exception
        if (attempt == ICloudConfig.maxSyncRetries - 1) {
          rethrow;
        }

        // Wait before retrying
        final delay = _calculateRetryDelay(attempt);
        await Future.delayed(delay);
      }
    }

    return false;
  }

  /// Calculate exponential backoff delay for retries
  Duration _calculateRetryDelay(int attempt) {
    final baseDelay = ICloudConfig.baseRetryDelay;
    final exponentialDelay = baseDelay * (1 << attempt); // 2^attempt multiplier
    final jitter = Duration(milliseconds: (exponentialDelay.inMilliseconds * 0.1).round());
    return exponentialDelay + jitter;
  }

  /// Handle sync failure with appropriate actions
  void _handleSyncFailure(
    List<SyncReason> reasons,
    List<String> details,
    VaultProvider vaultProvider,
    Map<String, TransactionProvider> transactionProviders,
  ) {
    _lastFailedSyncTime = DateTime.now();
    _log.warning('iCloud sync failed after ${ICloudConfig.maxSyncRetries} attempts');
    _updateStatus(SyncStatus.error);

    // Restore pending reasons for potential manual retry
    _pendingReasons.addAll(reasons);
    _pendingDetails.addAll(details);

    // Schedule a retry after a longer delay
    _statusResetTimer?.cancel();
    _statusResetTimer = Timer(ICloudConfig.errorStatusResetDelay, () {
      if (!_isSyncing) _updateStatus(SyncStatus.idle);
    });

    // Note: Automatic retry is handled by _attemptSyncWithRetry
    // which uses exponential backoff. If all retries fail,
    // the user can manually trigger sync via the UI.
  }

  /// Force an immediate sync (bypasses debounce)
  Future<void> forceSync({
    required VaultProvider vaultProvider,
    required Map<String, TransactionProvider> transactionProviders,
  }) async {
    _log.info('Force sync requested');
    _pendingReasons.add(SyncReason.manual);
    _executeSync(vaultProvider, transactionProviders);
  }

  /// Cancel any pending sync
  void cancelPendingSync() {
    _debounceTimer?.cancel();
    _maxSyncTimer?.cancel();
    _pendingReasons.clear();
    _pendingDetails.clear();
    _updateStatus(SyncStatus.idle);
    _log.fine('Pending sync cancelled');
  }

  /// Check if a sync is currently scheduled
  bool get isSyncScheduled => _debounceTimer?.isActive ?? false;

  /// Check if a sync is currently in progress
  bool get isSyncing => _isSyncing;

  /// Get the time since last sync
  Duration? get timeSinceLastSync {
    if (_lastSyncTime == null) return null;
    return DateTime.now().difference(_lastSyncTime!);
  }

  void _updateStatus(SyncStatus status) {
    if (_status != status) {
      _status = status;
      _statusController.add(status);
      _log.fine('Sync status: $status');
    }
  }

  /// Dispose resources
  ///
  /// NOTE: This is a singleton that lives for the app's lifetime.
  /// Call dispose() when shutting down the app or in tests.
  /// Stream listeners should cancel their subscriptions to avoid leaks.
  void dispose() {
    _debounceTimer?.cancel();
    _maxSyncTimer?.cancel();
    _statusResetTimer?.cancel();

    if (!_statusController.isClosed) {
      _statusController.close();
    }
  }

  /// Check if the manager has been disposed
  bool get isDisposed => _statusController.isClosed;
}

/// Reasons for triggering a sync
enum SyncReason {
  /// User manually triggered sync
  manual,

  /// A new vault was created
  vaultCreated,

  /// A vault was deleted
  vaultDeleted,

  /// A vault was updated (name, settings, etc.)
  vaultUpdated,

  /// A transaction was added
  transactionAdded,

  /// A transaction was updated
  transactionUpdated,

  /// A transaction was deleted
  transactionDeleted,

  /// Multiple changes occurred
  batchChanges,
}

extension SyncReasonExtension on SyncReason {
  String get displayName {
    switch (this) {
      case SyncReason.manual:
        return 'Manual sync';
      case SyncReason.vaultCreated:
        return 'Vault created';
      case SyncReason.vaultDeleted:
        return 'Vault deleted';
      case SyncReason.vaultUpdated:
        return 'Vault updated';
      case SyncReason.transactionAdded:
        return 'Transaction added';
      case SyncReason.transactionUpdated:
        return 'Transaction updated';
      case SyncReason.transactionDeleted:
        return 'Transaction deleted';
      case SyncReason.batchChanges:
        return 'Multiple changes';
    }
  }
}

/// Current sync status
enum SyncStatus {
  /// No sync activity
  idle,

  /// A sync is scheduled (debouncing)
  scheduled,

  /// Currently syncing
  syncing,

  /// Last sync completed successfully
  success,

  /// Last sync failed
  error,
}

extension SyncStatusExtension on SyncStatus {
  String get displayName {
    switch (this) {
      case SyncStatus.idle:
        return '';
      case SyncStatus.scheduled:
        return 'Sync scheduled...';
      case SyncStatus.syncing:
        return 'Syncing to iCloud...';
      case SyncStatus.success:
        return 'Synced to iCloud';
      case SyncStatus.error:
        return 'Sync failed';
    }
  }

  bool get isIdle => this == SyncStatus.idle;
  bool get isActive => this == SyncStatus.scheduled || this == SyncStatus.syncing;
  bool get isTerminal => this == SyncStatus.success || this == SyncStatus.error;
}
