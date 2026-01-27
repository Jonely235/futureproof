import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../domain/entities/vault_entity.dart';
import '../domain/repositories/vault_repository.dart';
import '../models/app_error.dart';
import '../models/vault_sort_option.dart';
import '../models/vault_view_mode.dart';
import '../services/database_service.dart';
import '../utils/app_logger.dart';
import '../utils/error_tracker.dart';

/// Vault state management provider
///
/// Manages vault state, active vault switching, and vault CRUD operations.
/// Coordinates with DatabaseService to ensure the active vault's database
/// is used for all transaction operations.
///
/// Usage:
/// ```dart
/// // In main.dart
/// ChangeNotifierProvider(create: (_) => VaultProvider())
///
/// // In widgets
/// final vaultProvider = context.watch<VaultProvider>();
/// final activeVault = vaultProvider.activeVault;
/// ```
class VaultProvider extends ChangeNotifier {
  final VaultRepository _vaultRepository;
  final DatabaseService _databaseService = DatabaseService();

  // Private state
  List<VaultEntity> _vaults = [];
  VaultEntity? _activeVault;
  bool _isLoading = false;
  AppError? _error;
  bool _isInitialized = false;

  // UI State
  VaultViewMode _viewMode = VaultViewMode.auto;
  VaultSortOption _sortBy = VaultSortOption.custom;
  Set<VaultType> _filterTypes = {};
  String _searchQuery = '';
  List<VaultEntity> _filteredVaults = [];

  // Public getters
  List<VaultEntity> get vaults => _vaults;
  VaultEntity? get activeVault => _activeVault;
  bool get isLoading => _isLoading;
  AppError? get error => _error;
  bool get isInitialized => _isInitialized;

  // UI State getters
  VaultViewMode get viewMode => _viewMode;
  VaultSortOption get sortBy => _sortBy;
  Set<VaultType> get filterTypes => _filterTypes;
  String get searchQuery => _searchQuery;
  List<VaultEntity> get filteredVaults => _filteredVaults;
  bool get hasActiveFilters => _filterTypes.isNotEmpty || _searchQuery.isNotEmpty;

  /// Check if there are any vaults
  bool get hasVaults => _vaults.isNotEmpty;

  /// Get active vault ID
  String? get activeVaultId => _activeVault?.id;

  /// Check if an active vault is set
  bool get hasActiveVault => _activeVault != null;

  VaultProvider({
    required VaultRepository vaultRepository,
  }) : _vaultRepository = vaultRepository {
    _log = Logger('VaultProvider');
  }

  late final Logger _log;

  /// Initialize vault system
  ///
  /// Loads all vaults and sets the active vault.
  /// Should be called on app startup.
  Future<void> initialize() async {
    if (_isInitialized) {
      _log.info('VaultProvider already initialized');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.vaults.info('🔧 Initializing vault system...');

      // Load all vaults
      _vaults = await _vaultRepository.getAllVaults();

      // Load active vault
      _activeVault = await _vaultRepository.getActiveVault();

      // Set active vault in database service
      if (_activeVault != null) {
        _databaseService.setActiveVault(_activeVault!.id);
        AppLogger.vaults.info('✅ Active vault set: ${_activeVault!.name}');
      } else if (_vaults.isNotEmpty) {
        // If no active vault but vaults exist, set first as active
        await setActiveVault(_vaults.first.id);
      }

      _isInitialized = true;
      AppLogger.vaults.info('✅ Vault system initialized: ${_vaults.length} vault(s)');
    } catch (e, st) {
      _error = e is AppError
          ? e
          : AppError.fromException(
              e,
              type: AppErrorType.database,
              stackTrace: st,
            );
      AppLogger.vaults.severe('Failed to initialize vault system', _error);
      ErrorTracker().trackError(_error!, 'VaultProvider.initialize',
          stackTrace: st);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new vault
  ///
  /// Returns the created vault if successful, null otherwise.
  /// [onCreated] optional callback called after successful vault creation (before return).
  /// This can be used to trigger side effects like iCloud sync.
  Future<VaultEntity?> createVault({
    required String name,
    required VaultType type,
    VaultSettings? settings,
    void Function(VaultEntity)? onCreated,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.vaults.info('➕ Creating vault: $name');

      final vault = await _vaultRepository.createVault(
        name: name,
        type: type,
        settings: settings,
      );

      // Reload vaults list
      _vaults = await _vaultRepository.getAllVaults();

      // If this is the first vault, make it active
      if (_vaults.length == 1) {
        await setActiveVault(vault.id);
      } else {
        notifyListeners();
      }

      AppLogger.vaults.info('✅ Created vault: ${vault.name} (${vault.id})');

      // Call the onCreated callback for side effects (e.g., iCloud sync)
      onCreated?.call(vault);

      return vault;
    } catch (e, st) {
      _error = e is AppError
          ? e
          : AppError.fromException(
              e,
              type: AppErrorType.validation,
              stackTrace: st,
            );
      AppLogger.vaults.severe('Failed to create vault', _error);
      ErrorTracker().trackError(_error!, 'VaultProvider.createVault',
          stackTrace: st);
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a vault
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> deleteVault(String vaultId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.vaults.info('🗑️ Deleting vault: $vaultId');

      await _vaultRepository.deleteVault(vaultId);

      // Reload vaults list
      _vaults = await _vaultRepository.getAllVaults();

      // If we deleted the active vault, clear it
      if (_activeVault?.id == vaultId) {
        _activeVault = null;
        _databaseService.setActiveVault(null);

        // Set new active vault if available
        if (_vaults.isNotEmpty) {
          await setActiveVault(_vaults.first.id);
        }
      } else {
        notifyListeners();
      }

      AppLogger.vaults.info('✅ Deleted vault: $vaultId');
      return true;
    } catch (e, st) {
      _error = e is AppError
          ? e
          : AppError.fromException(
              e,
              type: AppErrorType.database,
              stackTrace: st,
            );
      AppLogger.vaults.severe('Failed to delete vault', _error);
      ErrorTracker().trackError(_error!, 'VaultProvider.deleteVault',
          stackTrace: st);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set active vault
  ///
  /// Switches the active vault and updates the database service.
  Future<bool> setActiveVault(String vaultId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.vaults.info('🔑 Switching to vault: $vaultId');

      await _vaultRepository.setActiveVault(vaultId);

      // Update active vault
      _activeVault = await _vaultRepository.getVaultById(vaultId);

      // Update database service
      _databaseService.setActiveVault(vaultId);

      // Reload vaults to update isActive flags
      _vaults = await _vaultRepository.getAllVaults();

      AppLogger.vaults.info('✅ Active vault: ${_activeVault?.name}');
      return true;
    } catch (e, st) {
      _error = e is AppError
          ? e
          : AppError.fromException(
              e,
              type: AppErrorType.database,
              stackTrace: st,
            );
      AppLogger.vaults.severe('Failed to set active vault', _error);
      ErrorTracker().trackError(_error!, 'VaultProvider.setActiveVault',
          stackTrace: st);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update vault metadata
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> updateVault(VaultEntity vault) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.vaults.info('✏️ Updating vault: ${vault.id}');

      await _vaultRepository.updateVault(vault);

      // Reload vaults
      _vaults = await _vaultRepository.getAllVaults();

      // Update active vault if needed
      if (_activeVault?.id == vault.id) {
        _activeVault = vault;
      }

      AppLogger.vaults.info('✅ Updated vault: ${vault.name}');
      return true;
    } catch (e, st) {
      _error = e is AppError
          ? e
          : AppError.fromException(
              e,
              type: AppErrorType.database,
              stackTrace: st,
            );
      AppLogger.vaults.severe('Failed to update vault', _error);
      ErrorTracker().trackError(_error!, 'VaultProvider.updateVault',
          stackTrace: st);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update vault transaction count
  Future<void> updateTransactionCount(String vaultId, int count) async {
    try {
      await _vaultRepository.updateTransactionCount(vaultId, count);

      // Update local cache
      final index = _vaults.indexWhere((v) => v.id == vaultId);
      if (index >= 0) {
        _vaults[index] = _vaults[index].copyWith(transactionCount: count);
        notifyListeners();
      }

      // Update active vault if needed
      if (_activeVault?.id == vaultId) {
        _activeVault = _activeVault!.copyWith(transactionCount: count);
        notifyListeners();
      }
    } catch (e, st) {
      _log.warning('Failed to update transaction count: $e');
      // Non-critical error, just log it
    }
  }

  /// Get vault by ID
  VaultEntity? getVaultById(String id) {
    final index = _vaults.indexWhere((v) => v.id == id);
    return index >= 0 ? _vaults[index] : null;
  }

  /// Reload vaults from repository
  Future<void> reloadVaults() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vaults = await _vaultRepository.getAllVaults();
      _activeVault = await _vaultRepository.getActiveVault();
      AppLogger.vaults.info('🔄 Reloaded ${_vaults.length} vault(s)');
    } catch (e, st) {
      _error = e is AppError
          ? e
          : AppError.fromException(
              e,
              type: AppErrorType.database,
              stackTrace: st,
            );
      AppLogger.vaults.severe('Failed to reload vaults', _error);
      ErrorTracker().trackError(_error!, 'VaultProvider.reloadVaults',
          stackTrace: st);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear any error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh vault state
  ///
  /// Alias for reloadVaults() for semantic clarity.
  Future<void> refresh() async {
    await reloadVaults();
  }

  // ==================== UI State Methods ====================

  /// Set the view mode for displaying vaults
  void setViewMode(VaultViewMode mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      notifyListeners();
      AppLogger.vaults.info('View mode changed to: ${mode.displayName}');
    }
  }

  /// Set the sort option for vaults
  void setSortOption(VaultSortOption option) {
    if (_sortBy != option) {
      _sortBy = option;
      _applyFiltersAndSort();
      notifyListeners();
      AppLogger.vaults.info('Sort option changed to: ${option.displayName}');
    }
  }

  /// Set filter types for vaults
  void setFilterTypes(Set<VaultType> types) {
    if (_filterTypes != types) {
      _filterTypes = types;
      _applyFiltersAndSort();
      notifyListeners();
      AppLogger.vaults.info('Filter types changed: ${types.length} types');
    }
  }

  /// Toggle a single vault type filter
  void toggleFilterType(VaultType type) {
    final newFilters = Set<VaultType>.from(_filterTypes);
    if (newFilters.contains(type)) {
      newFilters.remove(type);
    } else {
      newFilters.add(type);
    }
    setFilterTypes(newFilters);
  }

  /// Set the search query for filtering vaults
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applyFiltersAndSort();
      notifyListeners();
    }
  }

  /// Clear all filters and search
  void clearFilters() {
    _filterTypes.clear();
    _searchQuery = '';
    _applyFiltersAndSort();
    notifyListeners();
    AppLogger.vaults.info('Filters cleared');
  }

  /// Apply filters and sorting to vaults
  void _applyFiltersAndSort() {
    _filteredVaults = _vaults.toList();

    // Apply type filter
    if (_filterTypes.isNotEmpty) {
      _filteredVaults = _filteredVaults
          .where((vault) => _filterTypes.contains(vault.type))
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      _filteredVaults = _filteredVaults
          .where((vault) =>
              vault.name.toLowerCase().contains(query) ||
              vault.type.displayName.toLowerCase().contains(query))
          .toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case VaultSortOption.nameAsc:
        _filteredVaults.sort((a, b) => a.name.compareTo(b.name));
        break;
      case VaultSortOption.nameDesc:
        _filteredVaults.sort((a, b) => b.name.compareTo(a.name));
        break;
      case VaultSortOption.createdDesc:
        _filteredVaults.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case VaultSortOption.createdAsc:
        _filteredVaults.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case VaultSortOption.modifiedDesc:
        _filteredVaults.sort((a, b) => b.lastModified.compareTo(a.lastModified));
        break;
      case VaultSortOption.modifiedAsc:
        _filteredVaults.sort((a, b) => a.lastModified.compareTo(b.lastModified));
        break;
      case VaultSortOption.transactionsDesc:
        _filteredVaults
            .sort((a, b) => b.transactionCount.compareTo(a.transactionCount));
        break;
      case VaultSortOption.transactionsAsc:
        _filteredVaults
            .sort((a, b) => a.transactionCount.compareTo(b.transactionCount));
        break;
      case VaultSortOption.custom:
        // Keep current order (for drag-to-reorder)
        break;
    }
  }

  /// Get the effective view mode (resolves 'auto' based on vault count)
  VaultViewMode get effectiveViewMode {
    if (_viewMode != VaultViewMode.auto) {
      return _viewMode;
    }

    final count = _filteredVaults.isEmpty ? _vaults.length : _filteredVaults.length;
    if (count <= 3) {
      return VaultViewMode.list; // Will use hero cards
    } else if (count <= 6) {
      return VaultViewMode.list;
    } else {
      return VaultViewMode.grid;
    }
  }

  /// Reorder vaults (optimistic update)
  Future<bool> reorderVaults(int oldIndex, int newIndex) async {
    try {
      // Optimistic update
      final vault = _vaults.removeAt(oldIndex);
      _vaults.insert(newIndex, vault);
      _applyFiltersAndSort();
      notifyListeners();

      // Persist the new order
      await _vaultRepository.reorderVaults(_vaults);

      AppLogger.vaults.info('✅ Reordered vaults: $oldIndex -> $newIndex');
      return true;
    } catch (e, st) {
      // Rollback on failure
      _error = e is AppError
          ? e
          : AppError.fromException(
              e,
              type: AppErrorType.database,
              stackTrace: st,
            );
      AppLogger.vaults.severe('Failed to reorder vaults', _error);
      ErrorTracker().trackError(_error!, 'VaultProvider.reorderVaults',
          stackTrace: st);

      // Reload original order
      await reloadVaults();
      return false;
    }
  }

  /// Archive a vault (new feature)
  ///
  /// Archives a vault instead of deleting it. The vault is hidden
  /// from the main list but can be restored later.
  Future<bool> archiveVault(String vaultId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.vaults.info('📦 Archiving vault: $vaultId');

      await _vaultRepository.archiveVault(vaultId);

      // Reload vaults list
      _vaults = await _vaultRepository.getAllVaults();
      _applyFiltersAndSort();

      // If we archived the active vault, clear it
      if (_activeVault?.id == vaultId) {
        _activeVault = null;
        _databaseService.setActiveVault(null);

        // Set new active vault if available
        if (_vaults.isNotEmpty) {
          await setActiveVault(_vaults.first.id);
        }
      } else {
        notifyListeners();
      }

      AppLogger.vaults.info('✅ Archived vault: $vaultId');
      return true;
    } catch (e, st) {
      _error = e is AppError
          ? e
          : AppError.fromException(
              e,
              type: AppErrorType.database,
              stackTrace: st,
            );
      AppLogger.vaults.severe('Failed to archive vault', _error);
      ErrorTracker().trackError(_error!, 'VaultProvider.archiveVault',
          stackTrace: st);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get vault count for determining layout
  int get vaultCount => _filteredVaults.isEmpty ? _vaults.length : _filteredVaults.length;

  /// Check if we should show hero cards (1-3 vaults in auto mode)
  bool get showHeroCards => effectiveViewMode == VaultViewMode.list && vaultCount <= 3;

  /// Check if we should show grid view
  bool get showGridView => effectiveViewMode == VaultViewMode.grid;

  /// Get cross axis count for grid view based on screen size
  int getGridCrossAxisCount(double screenWidth) {
    if (screenWidth < 600) {
      return 2; // Mobile
    } else if (screenWidth < 900) {
      return 3; // Tablet
    } else {
      return 4; // Desktop
    }
  }

  @override
  void dispose() {
    _log.info('Disposing VaultProvider');
    super.dispose();
  }
}
