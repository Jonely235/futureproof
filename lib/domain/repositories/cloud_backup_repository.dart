/// Cloud backup repository - manages cloud backup and sync
abstract class CloudBackupRepository {
  /// Authenticate with cloud service
  Future<void> authenticate();

  /// Sign out from cloud service
  Future<void> signOut();

  /// Check if authenticated
  Future<bool> isAuthenticated();

  /// Backup data to cloud
  Future<void> backupData();

  /// Restore data from cloud
  Future<void> restoreData();

  /// Get last backup timestamp
  Future<DateTime?> getLastBackupTime();

  /// Enable auto-sync
  Future<void> enableAutoSync();

  /// Disable auto-sync
  Future<void> disableAutoSync();

  /// Check if auto-sync is enabled
  Future<bool> isAutoSyncEnabled();

  /// Observe backup status
  Stream<BackupStatus> get backupStatusStream;

  /// Perform sync (upload or download based on timestamps)
  Future<SyncResult> performSync();
}

/// Backup status - represents current backup state
class BackupStatus {
  final bool isBackingUp;
  final bool isRestoring;
  final DateTime? lastBackupTime;
  final String? errorMessage;
  final double progress;

  const BackupStatus({
    this.isBackingUp = false,
    this.isRestoring = false,
    this.lastBackupTime,
    this.errorMessage,
    this.progress = 0.0,
  });

  /// Business rule: Is operation in progress?
  bool get isOperationInProgress => isBackingUp || isRestoring;

  /// Business rule: Has error occurred?
  bool get hasError => errorMessage != null;
}

/// Sync result - result of sync operation
class SyncResult {
  final bool success;
  final SyncType type;
  final DateTime syncTime;
  final String? errorMessage;

  const SyncResult({
    required this.success,
    required this.type,
    required this.syncTime,
    this.errorMessage,
  });

  /// Create success result
  factory SyncResult.uploaded(DateTime time) {
    return SyncResult(
      success: true,
      type: SyncType.upload,
      syncTime: time,
    );
  }

  /// Create download result
  factory SyncResult.downloaded(DateTime time) {
    return SyncResult(
      success: true,
      type: SyncType.download,
      syncTime: time,
    );
  }

  /// Create error result
  factory SyncResult.error(String error) {
    return SyncResult(
      success: false,
      type: SyncType.none,
      syncTime: DateTime.now(),
      errorMessage: error,
    );
  }
}

/// Sync type - direction of sync operation
enum SyncType {
  upload,
  download,
  none,
}
