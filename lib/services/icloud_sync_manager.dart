import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../providers/transaction_provider.dart';
import '../providers/vault_provider.dart';
import '../utils/app_logger.dart';
import 'backup_service.dart';

/// iCloud Sync Manager
///
/// Manages debounced iCloud sync operations to prevent excessive writes.
/// Accumulates sync reasons and batches them into a single sync operation.
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
  ICloudSyncManager._internal();
  static final ICloudSyncManager instance = ICloudSyncManager._internal();

  final _log = Logger('ICloudSyncManager');

  // Debounce delay - wait 2 seconds after last change before syncing
  static const Duration _debounceDelay = Duration(seconds: 2);

  // Maximum time between syncs (force sync even if more changes come in)
  static const Duration _maxSyncInterval = Duration(minutes: 5);

  Timer? _debounceTimer;
  Timer? _maxSyncTimer;
  Timer? _statusResetTimer;
  DateTime? _lastSyncTime;

  // Track pending sync reasons for logging
  final Set<SyncReason> _pendingReasons = {};
  final List<String> _pendingDetails = [];

  // State tracking
  bool _isSyncing = false;
  SyncStatus _status = SyncStatus.idle;

  // Stream controller for status updates
  final _statusController = StreamController<SyncStatus>.broadcast();
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
      if (timeSinceLastSync > _maxSyncInterval) {
        _log.info('Max sync interval reached, forcing sync');
        _executeSync(vaultProvider, transactionProviders);
        return;
      }
    }

    // Cancel existing timers
    _debounceTimer?.cancel();
    _maxSyncTimer?.cancel();

    // Set debounce timer
    _debounceTimer = Timer(_debounceDelay, () {
      _executeSync(vaultProvider, transactionProviders);
    });

    // Set max sync timer as a safety net
    _maxSyncTimer = Timer(_maxSyncInterval, () {
      _log.info('Max sync timer fired, forcing sync');
      _executeSync(vaultProvider, transactionProviders);
    });

    _updateStatus(SyncStatus.scheduled);
  }

  /// Execute the sync operation
  Future<void> _executeSync(
    VaultProvider vaultProvider,
    Map<String, TransactionProvider> transactionProviders,
  ) async {
    if (_isSyncing) {
      _log.fine('Sync already in progress, skipping');
      return;
    }

    // Cancel timers
    _debounceTimer?.cancel();
    _maxSyncTimer?.cancel();

    _isSyncing = true;
    _updateStatus(SyncStatus.syncing);

    final reasons = _pendingReasons.toList();
    final details = List<String>.from(_pendingDetails);
    _pendingReasons.clear();
    _pendingDetails.clear();

    _log.info('Executing iCloud sync. Reasons: $reasons');

    try {
      final success = await BackupService.instance.triggeriCloudSync(
        vaultProvider: vaultProvider,
        transactionProviders: transactionProviders,
      );

      _lastSyncTime = DateTime.now();

      if (success) {
        _log.info('✅ iCloud sync completed successfully');
        _updateStatus(SyncStatus.success);
        // Reset to idle after a short delay
        _statusResetTimer?.cancel();
        _statusResetTimer = Timer(const Duration(seconds: 2), () {
          if (!_isSyncing) _updateStatus(SyncStatus.idle);
        });
      } else {
        _log.warning('⚠️ iCloud sync failed');
        _updateStatus(SyncStatus.error);
        // Reset to idle after a longer delay on error
        _statusResetTimer?.cancel();
        _statusResetTimer = Timer(const Duration(seconds: 5), () {
          if (!_isSyncing) _updateStatus(SyncStatus.idle);
        });
      }
    } catch (e, st) {
      _log.severe('iCloud sync error: $e', e, st);
      _updateStatus(SyncStatus.error);
      _statusResetTimer?.cancel();
      _statusResetTimer = Timer(const Duration(seconds: 5), () {
        if (!_isSyncing) _updateStatus(SyncStatus.idle);
      });
    } finally {
      _isSyncing = false;
    }
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
    _statusController.close();
  }
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
