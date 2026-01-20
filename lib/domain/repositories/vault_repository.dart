import 'dart:async';
import '../entities/vault_entity.dart';

/// Vault repository interface - manages vault CRUD operations
///
/// This repository handles vault lifecycle: creation, deletion,
/// switching, and metadata management. Each vault is isolated
/// with its own database and settings.
abstract class VaultRepository {
  /// Get all vaults
  Future<List<VaultEntity>> getAllVaults();

  /// Get currently active vault
  Future<VaultEntity?> getActiveVault();

  /// Get vault by ID
  Future<VaultEntity?> getVaultById(String id);

  /// Create a new vault
  ///
  /// Creates vault directory, initializes database,
  /// and creates vault metadata file.
  Future<VaultEntity> createVault({
    required String name,
    required VaultType type,
    VaultSettings? settings,
  });

  /// Delete a vault and all its data
  ///
  /// Permanently deletes vault directory, database,
  /// and all transactions. This cannot be undone.
  Future<void> deleteVault(String id);

  /// Set a vault as active
  ///
  /// Switches the active vault context. All transaction
  /// operations will use the active vault's database.
  Future<void> setActiveVault(String id);

  /// Update vault metadata
  Future<void> updateVault(VaultEntity vault);

  /// Update vault transaction count
  Future<void> updateTransactionCount(String vaultId, int count);

  /// Reorder vaults (for drag-to-reorder functionality)
  Future<void> reorderVaults(List<VaultEntity> vaults);

  /// Archive a vault (soft delete, can be restored)
  Future<void> archiveVault(String vaultId);

  /// Restore an archived vault
  Future<void> restoreVault(String vaultId);

  /// Get all archived vaults
  Future<List<VaultEntity>> getArchivedVaults();

  /// Observe active vault changes
  Stream<VaultEntity?> observeActiveVault();

  /// Observe all vaults changes
  Stream<List<VaultEntity>> observeVaults();

  /// Get vault directory path
  Future<String> getVaultPath(String vaultId);

  /// Check if vault exists
  Future<bool> vaultExists(String id);
}
