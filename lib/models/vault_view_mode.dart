/// Vault view mode enum
///
/// Determines how vaults are displayed in the UI.
enum VaultViewMode {
  /// Automatically switch between hero, list, and grid based on vault count
  auto,

  /// Force list view
  list,

  /// Force grid view
  grid,
}

/// Vault view mode extension for display names
extension VaultViewModeExtension on VaultViewMode {
  String get displayName {
    switch (this) {
      case VaultViewMode.auto:
        return 'Auto';
      case VaultViewMode.list:
        return 'List';
      case VaultViewMode.grid:
        return 'Grid';
    }
  }

  String get description {
    switch (this) {
      case VaultViewMode.auto:
        return 'Automatically switch based on vault count';
      case VaultViewMode.list:
        return 'Show vaults in a vertical list';
      case VaultViewMode.grid:
        return 'Show vaults in a grid layout';
    }
  }
}
