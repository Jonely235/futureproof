import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import '../../domain/entities/vault_entity.dart';
import '../../domain/repositories/icloud_sync_repository.dart';
import '../../domain/repositories/vault_repository.dart';
import '../../services/cloudkit_service.dart';
import '../../utils/app_logger.dart';

/// iCloud implementation of SyncRepository
///
/// Uses CloudKit for iOS vault synchronization.
/// Falls back to local-only mode on non-iOS platforms.
class ICloudSyncRepositoryImpl implements ICloudSyncRepository {
  final VaultRepository _vaultRepository;
  final CloudKitService _cloudKitService;
  final _statusController = StreamController<SyncStatus>.broadcast();

  static const String _autoSyncPrefix = 'icloud_auto_sync_';
  static const String _lastSyncPrefix = 'icloud_last_sync_';

  ICloudSyncRepositoryImpl({
    required VaultRepository vaultRepository,
    CloudKitService? cloudKitService,
  })  : _vaultRepository = vaultRepository,
        _cloudKitService = cloudKitService ?? CloudKitService();

  @override
  Stream<SyncStatus> get syncStatusStream => _statusController.stream;

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb || !Platform.isIOS) {
      return false;
    }
    return await _cloudKitService.isAvailable();
  }

  @override
  Future<void> authenticate() async {
    // iCloud authentication is automatic on iOS
    // Just check availability
    final available = await isAvailable();
    if (!available) {
      throw Exception('CloudKit is not available');
    }
    AppLogger.vaults.info('✅ iCloud authenticated (automatic)');
  }

  @override
  Future<void> signOut() async {
    // iCloud sign-out is system-level on iOS
    // Users sign out through iOS Settings
    AppLogger.vaults.info('ℹ️ iCloud sign-out: Use iOS Settings app');
  }

  @override
  Future<bool> isAuthenticated() async {
    // On iOS, if CloudKit is available, user is effectively authenticated
    return await isAvailable();
  }

  @override
  Future<void> syncVaultMetadata(String vaultId, Map<String, dynamic> metadata) async {
    if (!await isAvailable()) {
      throw Exception('CloudKit not available');
    }

    _statusController.add(SyncStatus(
      isSyncing: true,
      isUploading: true,
      vaultId: vaultId,
      progress: 0.5,
    ));

    try {
      final success = await _cloudKitService.uploadVaultMetadata(
        vaultId: vaultId,
        metadata: metadata,
      );

      if (!success) {
        throw Exception('Failed to upload vault metadata');
      }

      // Update last sync time
      await _setLastSyncTime(vaultId, DateTime.now());

      _statusController.add(SyncStatus(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
        vaultId: vaultId,
        progress: 1.0,
      ));

      AppLogger.vaults.info('✅ Synced vault metadata: $vaultId');
    } catch (e) {
      _statusController.add(SyncStatus(
        isSyncing: false,
        errorMessage: e.toString(),
        vaultId: vaultId,
      ));
      rethrow;
    }
  }

  @override
  Future<void> deleteVaultMetadata(String vaultId) async {
    if (!await isAvailable()) {
      AppLogger.vaults.warning('CloudKit not available, skipping delete');
      return;
    }

    final success = await _cloudKitService.deleteVaultMetadata(vaultId);
    if (!success) {
      throw Exception('Failed to delete vault metadata');
    }

    AppLogger.vaults.info('🗑️ Deleted vault metadata from iCloud: $vaultId');
  }

  @override
  Future<Map<String, dynamic>?> fetchVaultIndex() async {
    if (!await isAvailable()) {
      AppLogger.vaults.warning('CloudKit not available, cannot fetch index');
      return null;
    }

    return await _cloudKitService.fetchVaultIndex();
  }

  @override
  Future<void> enableAutoSync(String vaultId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_autoSyncPrefix$vaultId', true);
    AppLogger.vaults.info('✅ Auto-sync enabled for vault: $vaultId');
  }

  @override
  Future<void> disableAutoSync(String vaultId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_autoSyncPrefix$vaultId', false);
    AppLogger.vaults.info('⏸️ Auto-sync disabled for vault: $vaultId');
  }

  @override
  Future<bool> isAutoSyncEnabled(String vaultId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_autoSyncPrefix$vaultId') ?? false;
  }

  @override
  Future<SyncResult> performSync(String vaultId) async {
    try {
      AppLogger.vaults.info('🔄 Starting sync for vault: $vaultId');

      // Get local vault
      final localVault = await _vaultRepository.getVaultById(vaultId);
      if (localVault == null) {
        return SyncResult.error('Vault not found: $vaultId', vaultId: vaultId);
      }

      // Get last sync time
      final lastSync = await _getLastSyncTime(vaultId);

      // Fetch cloud vault index
      final cloudIndex = await fetchVaultIndex();

      if (cloudIndex == null) {
        // No cloud data, upload local vault
        await syncVaultMetadata(vaultId, localVault.toJson());
        return SyncResult.uploaded(DateTime.now(), vaultId);
      }

      // Simple sync strategy: last-write-wins based on lastModified
      // In production, you'd implement proper conflict resolution
      final cloudVaults = cloudIndex['vaults'] as List?;
      if (cloudVaults != null) {
        for (final cloudVaultData in cloudVaults) {
          final cloudVault = cloudVaultData as Map<String, dynamic>;
          if (cloudVault['id'] == vaultId) {
            final cloudLastModified = DateTime.parse(cloudVault['lastModified'] as String);

            if (lastSync == null || localVault.lastModified.isAfter(cloudLastModified)) {
              // Local is newer, upload
              await syncVaultMetadata(vaultId, localVault.toJson());
              return SyncResult.uploaded(DateTime.now(), vaultId);
            } else {
              // Cloud is newer or same, no action needed
              AppLogger.vaults.info('✅ Vault already in sync');
              return SyncResult.downloaded(DateTime.now(), vaultId);
            }
          }
        }
      }

      // Vault not in cloud, upload
      await syncVaultMetadata(vaultId, localVault.toJson());
      return SyncResult.uploaded(DateTime.now(), vaultId);
    } catch (e, st) {
      AppLogger.vaults.severe('❌ Sync failed for vault: $vaultId', e, st);
      return SyncResult.error(e.toString(), vaultId: vaultId);
    }
  }

  Future<DateTime?> _getLastSyncTime(String vaultId) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('$_lastSyncPrefix$vaultId');
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  Future<void> _setLastSyncTime(String vaultId, DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_lastSyncPrefix$vaultId', time.millisecondsSinceEpoch);
  }

  void dispose() {
    _statusController.close();
  }
}
