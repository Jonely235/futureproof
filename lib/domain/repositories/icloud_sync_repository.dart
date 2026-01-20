/// iCloud sync repository - manages vault sync via CloudKit
///
/// This is a refactored version of CloudBackupRepository,
/// specifically designed for vault-level synchronization.
abstract class ICloudSyncRepository {
  /// Check if CloudKit is available (iOS only)
  Future<bool> isAvailable();

  /// Authenticate with iCloud (automatic on iOS)
  Future<void> authenticate();

  /// Sign out from iCloud (system-level on iOS)
  Future<void> signOut();

  /// Check if authenticated
  Future<bool> isAuthenticated();

  /// Sync vault metadata to iCloud
  Future<void> syncVaultMetadata(String vaultId, Map<String, dynamic> metadata);

  /// Delete vault metadata from iCloud
  Future<void> deleteVaultMetadata(String vaultId);

  /// Fetch vault index from iCloud
  Future<Map<String, dynamic>?> fetchVaultIndex();

  /// Enable auto-sync for a vault
  Future<void> enableAutoSync(String vaultId);

  /// Disable auto-sync for a vault
  Future<void> disableAutoSync(String vaultId);

  /// Check if auto-sync is enabled for a vault
  Future<bool> isAutoSyncEnabled(String vaultId);

  /// Observe sync status
  Stream<SyncStatus> get syncStatusStream;

  /// Perform full vault sync
  Future<SyncResult> performSync(String vaultId);
}

/// Sync status - represents current sync state
class SyncStatus {
  final bool isSyncing;
  final bool isUploading;
  final bool isDownloading;
  final DateTime? lastSyncTime;
  final String? errorMessage;
  final double progress;
  final String? vaultId;

  const SyncStatus({
    this.isSyncing = false,
    this.isUploading = false,
    this.isDownloading = false,
    this.lastSyncTime,
    this.errorMessage,
    this.progress = 0.0,
    this.vaultId,
  });

  /// Business rule: Is operation in progress?
  bool get isOperationInProgress => isSyncing;

  /// Business rule: Has error occurred?
  bool get hasError => errorMessage != null;

  /// Create syncing status
  SyncStatus copyWith({
    bool? isSyncing,
    bool? isUploading,
    bool? isDownloading,
    DateTime? lastSyncTime,
    String? errorMessage,
    double? progress,
    String? vaultId,
  }) {
    return SyncStatus(
      isSyncing: isSyncing ?? this.isSyncing,
      isUploading: isUploading ?? this.isUploading,
      isDownloading: isDownloading ?? this.isDownloading,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
      vaultId: vaultId ?? this.vaultId,
    );
  }
}

/// Sync result - result of sync operation
class SyncResult {
  final bool success;
  final SyncType type;
  final DateTime syncTime;
  final String? errorMessage;
  final String? vaultId;

  const SyncResult({
    required this.success,
    required this.type,
    required this.syncTime,
    this.errorMessage,
    this.vaultId,
  });

  /// Create upload success result
  factory SyncResult.uploaded(DateTime time, String vaultId) {
    return SyncResult(
      success: true,
      type: SyncType.upload,
      syncTime: time,
      vaultId: vaultId,
    );
  }

  /// Create download success result
  factory SyncResult.downloaded(DateTime time, String vaultId) {
    return SyncResult(
      success: true,
      type: SyncType.download,
      syncTime: time,
      vaultId: vaultId,
    );
  }

  /// Create error result
  factory SyncResult.error(String error, {String? vaultId}) {
    return SyncResult(
      success: false,
      type: SyncType.none,
      syncTime: DateTime.now(),
      errorMessage: error,
      vaultId: vaultId,
    );
  }
}

/// Sync type - direction of sync operation
enum SyncType {
  upload,
  download,
  none,
}
