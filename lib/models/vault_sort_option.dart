/// Vault sort option enum
///
/// Determines how vaults are sorted in the UI.
enum VaultSortOption {
  /// Sort by vault name (A-Z)
  nameAsc,

  /// Sort by vault name (Z-A)
  nameDesc,

  /// Sort by creation date (newest first)
  createdDesc,

  /// Sort by creation date (oldest first)
  createdAsc,

  /// Sort by last modified date (newest first)
  modifiedDesc,

  /// Sort by last modified date (oldest first)
  modifiedAsc,

  /// Sort by transaction count (highest first)
  transactionsDesc,

  /// Sort by transaction count (lowest first)
  transactionsAsc,

  /// Custom order (drag-to-reorder)
  custom,
}

/// Vault sort option extension for display names
extension VaultSortOptionExtension on VaultSortOption {
  String get displayName {
    switch (this) {
      case VaultSortOption.nameAsc:
        return 'Name (A-Z)';
      case VaultSortOption.nameDesc:
        return 'Name (Z-A)';
      case VaultSortOption.createdDesc:
        return 'Newest';
      case VaultSortOption.createdAsc:
        return 'Oldest';
      case VaultSortOption.modifiedDesc:
        return 'Recently Modified';
      case VaultSortOption.modifiedAsc:
        return 'Least Recently Modified';
      case VaultSortOption.transactionsDesc:
        return 'Most Transactions';
      case VaultSortOption.transactionsAsc:
        return 'Fewest Transactions';
      case VaultSortOption.custom:
        return 'Custom Order';
    }
  }

  bool get isCustom => this == VaultSortOption.custom;

  bool get isAscending {
    switch (this) {
      case VaultSortOption.nameAsc:
      case VaultSortOption.createdAsc:
      case VaultSortOption.modifiedAsc:
      case VaultSortOption.transactionsAsc:
        return true;
      default:
        return false;
    }
  }
}
