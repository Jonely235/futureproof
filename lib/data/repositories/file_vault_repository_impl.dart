import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';
import '../../domain/entities/vault_entity.dart';
import '../../domain/repositories/vault_repository.dart';
import '../../services/vault_file_service.dart';
import '../../utils/app_logger.dart';

/// File-based implementation of VaultRepository
///
/// Manages vaults using local file system. Each vault gets
/// its own directory with metadata, database, and settings.
class FileVaultRepositoryImpl implements VaultRepository {
  final VaultFileService _fileService;
  final _log = Logger('FileVaultRepository');

  // Cache and streams
  List<VaultEntity>? _cachedVaults;
  VaultEntity? _activeVault;
  final _vaultsController = StreamController<List<VaultEntity>>.broadcast();
  final _activeVaultController = StreamController<VaultEntity?>.broadcast();

  FileVaultRepositoryImpl({
    VaultFileService? fileService,
  }) : _fileService = fileService ?? VaultFileService();

  @override
  Future<List<VaultEntity>> getAllVaults() async {
    try {
      if (kIsWeb) {
        // Web platform: return empty list (use in-memory storage)
        return [];
      }

      if (_cachedVaults != null) {
        return _cachedVaults!;
      }

      final vaultIds = await _fileService.getVaultIds();
      final vaults = <VaultEntity>[];

      for (final vaultId in vaultIds) {
        final vault = await _fileService.loadVaultMetadata(vaultId);
        if (vault != null) {
          vaults.add(vault);
        }
      }

      _cachedVaults = vaults;
      _vaultsController.add(vaults);

      AppLogger.vaults.info('📊 Loaded ${vaults.length} vaults');
      return vaults;
    } catch (e, st) {
      AppLogger.vaults.severe('❌ Error getting all vaults', e, st);
      rethrow;
    }
  }

  @override
  Future<VaultEntity?> getActiveVault() async {
    try {
      if (_activeVault != null) {
        return _activeVault;
      }

      if (kIsWeb) {
        return null;
      }

      final activeVaultId = await _fileService.getActiveVaultId();
      if (activeVaultId == null) {
        return null;
      }

      final vault = await _fileService.loadVaultMetadata(activeVaultId);
      if (vault != null) {
        _activeVault = vault.copyWith(isActive: true);
        _activeVaultController.add(_activeVault);
      }

      return _activeVault;
    } catch (e, st) {
      AppLogger.vaults.severe('❌ Error getting active vault', e, st);
      return null;
    }
  }

  @override
  Future<VaultEntity?> getVaultById(String id) async {
    try {
      if (kIsWeb) return null;

      return await _fileService.loadVaultMetadata(id);
    } catch (e, st) {
      AppLogger.vaults.severe('❌ Error getting vault by ID: $id', e, st);
      return null;
    }
  }

  @override
  Future<VaultEntity> createVault({
    required String name,
    required VaultType type,
    VaultSettings? settings,
  }) async {
    try {
      if (kIsWeb) {
        throw UnsupportedError('Vault creation not supported on web');
      }

      final vaultId = _fileService.generateVaultId();
      final now = DateTime.now();

      // Create vault directory
      await _fileService.createVaultDirectory(vaultId);

      // Create vault entity
      final vault = VaultEntity(
        id: vaultId,
        name: name,
        type: type,
        createdAt: now,
        lastModified: now,
        settings: settings ?? VaultSettings(),
        isActive: false,
      );

      // Save vault metadata
      await _fileService.saveVaultMetadata(vault);

      // Add vault to index (CRITICAL: without this, vault won't appear in getAllVaults)
      await _fileService.addVaultToIndex(vault);

      // Invalidate cache
      _invalidateCache();

      AppLogger.vaults.info('✅ Created vault: $name ($vaultId)');
      return vault;
    } catch (e, st) {
      AppLogger.vaults.severe('❌ Error creating vault: $name', e, st);
      rethrow;
    }
  }

  @override
  Future<void> deleteVault(String id) async {
    try {
      if (kIsWeb) {
        throw UnsupportedError('Vault deletion not supported on web');
      }

      // Check if it's the active vault
      final activeVault = await getActiveVault();
      if (activeVault?.id == id) {
        await _fileService.clearActiveVaultId();
        _activeVault = null;
        _activeVaultController.add(null);
      }

      // Delete vault directory
      await _fileService.deleteVaultDirectory(id);

      // Invalidate cache
      _invalidateCache();

      AppLogger.vaults.info('🗑️ Deleted vault: $id');
    } catch (e, st) {
      AppLogger.vaults.severe('❌ Error deleting vault: $id', e, st);
      rethrow;
    }
  }

  @override
  Future<void> setActiveVault(String id) async {
    try {
      if (kIsWeb) {
        throw UnsupportedError('Setting active vault not supported on web');
      }

      // Deactivate currently active vault
      if (_activeVault != null) {
        final updated = _activeVault!.copyWith(isActive: false);
        await _fileService.saveVaultMetadata(updated);
      }

      // Load and activate new vault
      final vault = await _fileService.loadVaultMetadata(id);
      if (vault == null) {
        throw Exception('Vault not found: $id');
      }

      final activeVault = vault.copyWith(isActive: true);
      await _fileService.saveVaultMetadata(activeVault);
      await _fileService.setActiveVaultId(id);

      _activeVault = activeVault;
      _activeVaultController.add(activeVault);

      AppLogger.vaults.info('✅ Set active vault: ${vault.name} ($id)');
    } catch (e, st) {
      AppLogger.vaults.severe('❌ Error setting active vault: $id', e, st);
      rethrow;
    }
  }

  @override
  Future<void> updateVault(VaultEntity vault) async {
    try {
      if (kIsWeb) {
        throw UnsupportedError('Updating vault not supported on web');
      }

      final updated = vault.copyWith(lastModified: DateTime.now());
      await _fileService.saveVaultMetadata(updated);

      // Update cache if present
      if (_cachedVaults != null) {
        final index = _cachedVaults!.indexWhere((v) => v.id == vault.id);
        if (index >= 0) {
          _cachedVaults![index] = updated;
        }
      }

      // Update active vault cache
      if (_activeVault?.id == vault.id) {
        _activeVault = updated;
        _activeVaultController.add(updated);
      }

      AppLogger.vaults.info('✅ Updated vault: ${vault.name} (${vault.id})');
    } catch (e, st) {
      AppLogger.vaults.severe('❌ Error updating vault: ${vault.id}', e, st);
      rethrow;
    }
  }

  @override
  Future<void> updateTransactionCount(String vaultId, int count) async {
    try {
      final vault = await getVaultById(vaultId);
      if (vault == null) {
        throw Exception('Vault not found: $vaultId');
      }

      final updated = vault.copyWith(
        transactionCount: count,
        lastModified: DateTime.now(),
      );

      await updateVault(updated);
    } catch (e, st) {
      AppLogger.vaults.severe(
          '❌ Error updating transaction count: $vaultId', e, st);
      rethrow;
    }
  }

  @override
  Stream<VaultEntity?> observeActiveVault() {
    // Load initial value
    getActiveVault();
    return _activeVaultController.stream;
  }

  @override
  Stream<List<VaultEntity>> observeVaults() {
    // Load initial value
    getAllVaults();
    return _vaultsController.stream;
  }

  @override
  Future<String> getVaultPath(String vaultId) async {
    if (kIsWeb) {
      throw UnsupportedError('Vault path not available on web');
    }

    final vaultDir = await _fileService.getVaultDirectory(vaultId);
    return vaultDir.path;
  }

  @override
  Future<bool> vaultExists(String id) async {
    if (kIsWeb) return false;

    return await _fileService.vaultDirectoryExists(id);
  }

  @override
  Future<void> reorderVaults(List<VaultEntity> vaults) async {
    try {
      if (kIsWeb) {
        // On web, just return silently
        return;
      }

      // Save each vault's metadata to persist the new order
      // The order is implicit in how vaults are loaded from the filesystem
      for (final vault in vaults) {
        await _fileService.saveVaultMetadata(vault);
      }

      // Update cache
      _cachedVaults = vaults;
      _vaultsController.add(vaults);

      AppLogger.vaults.info('✅ Reordered ${vaults.length} vaults');
    } catch (e, st) {
      AppLogger.vaults.severe('❌ Error reordering vaults', e, st);
      rethrow;
    }
  }

  @override
  Future<void> archiveVault(String vaultId) async {
    try {
      if (kIsWeb) {
        throw UnsupportedError('Vault archiving not supported on web');
      }

      // For now, archiveVault works the same as deleteVault
      // In a full implementation, you would move the vault to an "archived" directory
      await deleteVault(vaultId);

      AppLogger.vaults.info('📦 Archived vault: $vaultId');
    } catch (e, st) {
      AppLogger.vaults.severe('❌ Error archiving vault: $vaultId', e, st);
      rethrow;
    }
  }

  @override
  Future<void> restoreVault(String vaultId) async {
    try {
      if (kIsWeb) {
        throw UnsupportedError('Vault restoration not supported on web');
      }

      // In a full implementation, you would move the vault from "archived" back to main list
      // For now, this is a placeholder that throws an error
      throw UnimplementedError('Restore vault not yet implemented - vaults are permanently deleted');
    } catch (e, st) {
      AppLogger.vaults.severe('❌ Error restoring vault: $vaultId', e, st);
      rethrow;
    }
  }

  @override
  Future<List<VaultEntity>> getArchivedVaults() async {
    try {
      if (kIsWeb) {
        return [];
      }

      // In a full implementation, you would scan the "archived" directory
      // For now, return empty list as archiving is not fully implemented
      return [];
    } catch (e, st) {
      AppLogger.vaults.severe('❌ Error getting archived vaults', e, st);
      return [];
    }
  }

  void _invalidateCache() {
    _cachedVaults = null;
  }

  void dispose() {
    _vaultsController.close();
    _activeVaultController.close();
  }
}
