import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../design/design_tokens.dart';
import '../domain/entities/vault_entity.dart';
import '../models/vault_sort_option.dart';
import '../models/vault_view_mode.dart';
import '../providers/vault_provider.dart';
import '../widgets/vault_card_widget.dart';
import '../widgets/vault_grid_view.dart';
import '../widgets/vault_search_bar.dart';
import '../widgets/vault_type_filter.dart';
import 'vault_edit_screen.dart';

/// Sync state for iCloud operations
enum VaultSyncState {
  idle,
  syncing,
  success,
  error,
}

/// Vault management screen - advanced vault operations
///
/// Features: search, filter, sort, swipe-to-delete, edit vault, iCloud sync toggle.
class VaultManagementScreen extends StatefulWidget {
  const VaultManagementScreen({super.key});

  @override
  State<VaultManagementScreen> createState() => _VaultManagementScreenState();
}

class _VaultManagementScreenState extends State<VaultManagementScreen> {
  bool _isSearching = false;
  VaultSortOption _sortBy = VaultSortOption.nameAsc;

  // Track sync state for each vault
  final Map<String, VaultSyncState> _syncStates = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.scaffoldBackground,
      body: CustomScrollView(
        slivers: [
          // App bar with search and iCloud status
          SliverAppBar(
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.close, size: 24, color: AppColors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _isSearching ? '' : 'Manage Vaults',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            actions: [
              // iCloud status indicator
              _buildICloudStatusIndicator(),

              // Search button
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      context.read<VaultProvider>().setSearchQuery('');
                    }
                  });
                },
                tooltip: _isSearching ? 'Close search' : 'Search vaults',
              ),

              // Sort button
              PopupMenuButton<VaultSortOption>(
                icon: const Icon(Icons.sort),
                tooltip: 'Sort vaults',
                onSelected: (option) {
                  setState(() => _sortBy = option);
                  context.read<VaultProvider>().setSortOption(option);
                },
                itemBuilder: (context) => VaultSortOption.values.map((option) {
                  return PopupMenuItem<VaultSortOption>(
                    value: option,
                    child: Row(
                      children: [
                        if (_sortBy == option)
                          const Icon(Icons.check, size: 20, color: AppColors.fintechTeal),
                        if (_sortBy == option) const SizedBox(width: 12),
                        Text(
                          option.displayName,
                          style: GoogleFonts.spaceGrotesk(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              // View toggle
              Consumer<VaultProvider>(
                builder: (context, provider, _) {
                  return IconButton(
                    icon: Icon(
                      provider.effectiveViewMode == VaultViewMode.grid
                          ? Icons.view_list
                          : Icons.grid_view,
                    ),
                    onPressed: () {
                      final currentMode = provider.effectiveViewMode;
                      final newMode = currentMode == VaultViewMode.grid
                          ? VaultViewMode.list
                          : VaultViewMode.grid;
                      provider.setViewMode(newMode);
                    },
                    tooltip: 'Toggle view',
                  );
                },
              ),
            ],
          ),

          // Search bar (when searching)
          if (_isSearching)
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: VaultSearchBar(
                  query: context.watch<VaultProvider>().searchQuery,
                  onChanged: (query) {
                    context.read<VaultProvider>().setSearchQuery(query);
                  },
                  onClear: () {
                    context.read<VaultProvider>().setSearchQuery('');
                  },
                ),
              ),
            ),

          // Filter chips
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: VaultTypeFilter(
                selectedTypes: context.watch<VaultProvider>().filterTypes,
                onToggle: (type) {
                  context.read<VaultProvider>().toggleFilterType(type);
                },
                showLabel: true,
              ),
            ),
          ),

          // Results count
          Consumer<VaultProvider>(
            builder: (context, provider, _) {
              if (provider.hasActiveFilters) {
                return SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      '${provider.filteredVaults.length} of ${provider.vaults.length} vaults',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: AppColors.gray700,
                      ),
                    ),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),

          // Vault list with gestures
          Consumer<VaultProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final displayVaults = provider.hasActiveFilters
                  ? provider.filteredVaults
                  : provider.vaults;

              if (displayVaults.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(provider),
                );
              }

              // Use SliverList for vault display
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildVaultCard(displayVaults[index], provider, index);
                    },
                    childCount: displayVaults.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Build iCloud status indicator in app bar
  Widget _buildICloudStatusIndicator() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.fintechTeal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.fintechTeal.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_sync,
              size: 16,
              color: AppColors.fintechTeal,
            ),
            const SizedBox(width: 4),
            Text(
              'iCloud',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.fintechTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultCard(VaultEntity vault, VaultProvider provider, int index) {
    final syncState = _syncStates[vault.id] ?? VaultSyncState.idle;

    return Dismissible(
      key: ValueKey(vault.id),
      background: Container(
        color: AppColors.danger.withOpacity(0.1),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: AppColors.danger, size: 32),
            const SizedBox(height: 8),
            Text(
              'Delete Vault',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await _showDeleteDialog(context, vault, provider);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _showVaultOptions(context, vault, provider);
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              _showVaultOptions(context, vault, provider);
            },
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: name, active badge, sync status
                  Row(
                    children: [
                      // Vault icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: vault.isActive
                                ? [
                                    AppColors.fintechTeal,
                                    AppColors.fintechTeal.withOpacity(0.7),
                                  ]
                                : [
                                    AppColors.gray200,
                                    AppColors.gray300,
                                  ],
                          ),
                          borderRadius: DesignTokens.borderRadiusMd,
                        ),
                        child: Center(
                          child: Text(
                            vault.type.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Name and type
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    vault.name,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (vault.isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.fintechTeal,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'ACTIVE',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              vault.type.displayName,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                color: AppColors.gray700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Sync status
                      _buildSyncStatus(syncState, vault),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // iCloud toggle row
                  _buildICloudToggle(vault, provider),

                  const SizedBox(height: 8),

                  // Stats row
                  Row(
                    children: [
                      _buildStat(
                        Icons.receipt_long_outlined,
                        '${vault.transactionCount}',
                        'Transactions',
                      ),
                      const SizedBox(width: 24),
                      _buildStat(
                        Icons.cloud_outlined,
                        vault.cloudKitSyncEnabled ? 'On' : 'Off',
                        'iCloud Sync',
                      ),
                      const SizedBox(width: 24),
                      _buildStat(
                        Icons.schedule,
                        _formatLastSync(vault.lastCloudSync),
                        'Last Sync',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build sync status indicator
  Widget _buildSyncStatus(VaultSyncState syncState, VaultEntity vault) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (syncState) {
      case VaultSyncState.syncing:
        statusColor = AppColors.fintechTeal;
        statusIcon = Icons.sync;
        statusText = 'Syncing...';
        break;
      case VaultSyncState.success:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Synced';
        break;
      case VaultSyncState.error:
        statusColor = AppColors.danger;
        statusIcon = Icons.error;
        statusText = 'Failed';
        break;
      default:
        if (!vault.cloudKitSyncEnabled) {
          statusColor = AppColors.gray400;
          statusIcon = Icons.cloud_off;
          statusText = 'Off';
        } else {
          statusColor = AppColors.fintechTeal;
          statusIcon = Icons.cloud_done;
          statusText = 'On';
        }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (syncState == VaultSyncState.syncing)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          )
        else
          Icon(
            statusIcon,
            size: 18,
            color: statusColor,
          ),
        const SizedBox(width: 4),
        Text(
          statusText,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: statusColor,
          ),
        ),
      ],
    );
  }

  /// Build iCloud toggle switch
  Widget _buildICloudToggle(VaultEntity vault, VaultProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            vault.cloudKitSyncEnabled ? Icons.cloud_sync : Icons.cloud_off,
            size: 18,
            color: vault.cloudKitSyncEnabled
                ? AppColors.fintechTeal
                : AppColors.gray700,
          ),
          const SizedBox(width: 8),
          Text(
            'Store in iCloud',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
          ),
          const Spacer(),
          Switch(
            value: vault.cloudKitSyncEnabled,
            onChanged: (value) async {
              HapticFeedback.lightImpact();
              await _toggleICloudSync(vault, value, provider);
            },
            activeColor: AppColors.fintechTeal,
          ),
        ],
      ),
    );
  }

  /// Build stat item
  Widget _buildStat(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.gray700),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            color: AppColors.gray700,
          ),
        ),
      ],
    );
  }

  /// Format last sync time
  String _formatLastSync(DateTime? lastSync) {
    if (lastSync == null) return 'Never';

    final now = DateTime.now();
    final diff = now.difference(lastSync);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${lastSync.day}/${lastSync.month}/${lastSync.year}';
  }

  /// Toggle iCloud sync for a vault
  Future<void> _toggleICloudSync(
    VaultEntity vault,
    bool enabled,
    VaultProvider provider,
  ) async {
    // Update local state optimistically
    setState(() {
      _syncStates[vault.id] = VaultSyncState.syncing;
    });

    try {
      // Update vault entity
      final updatedVault = vault.copyWith(cloudKitSyncEnabled: enabled);
      final success = await provider.updateVault(updatedVault);

      if (success) {
        setState(() {
          _syncStates[vault.id] = VaultSyncState.success;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                enabled
                    ? 'iCloud sync enabled for "${vault.name}"'
                    : 'iCloud sync disabled for "${vault.name}"',
              ),
              backgroundColor: AppColors.fintechTeal,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Reset success state after delay
        Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _syncStates[vault.id] = VaultSyncState.idle;
            });
          }
        });
      } else {
        throw Exception('Failed to update vault');
      }
    } catch (e) {
      setState(() {
        _syncStates[vault.id] = VaultSyncState.error;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update iCloud sync: $e'),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Reset error state after delay
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _syncStates.remove(vault.id);
          });
        }
      });
    }
  }

  Widget _buildEmptyState(VaultProvider provider) {
    final hasFilters = provider.hasActiveFilters;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.filter_list_off : Icons.manage_search,
            size: 64,
            color: AppColors.gray400,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No vaults match your filters' : 'No vaults to manage',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: provider.clearFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.fintechTeal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showVaultOptions(BuildContext context, VaultEntity vault, VaultProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusXxl)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                ),
              ),

              // Vault header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      vault.type.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vault.name,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                          Text(
                            vault.type.displayName,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              color: AppColors.gray700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Quick sync button
                    if (vault.cloudKitSyncEnabled)
                      IconButton.filled(
                        onPressed: () => _manualSync(vault, provider),
                        icon: const Icon(Icons.cloud_sync, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.fintechTeal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 24),

              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(
                  'Edit Vault',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VaultEditScreen(vault: vault),
                    ),
                  );
                },
              ),

              ListTile(
                leading: Icon(
                  vault.cloudKitSyncEnabled ? Icons.cloud_off : Icons.cloud_sync,
                ),
                title: Text(
                  vault.cloudKitSyncEnabled ? 'Disable iCloud Sync' : 'Enable iCloud Sync',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleICloudSync(vault, !vault.cloudKitSyncEnabled, provider);
                },
              ),

              if (!vault.isActive)
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.danger),
                  title: Text(
                    'Delete Vault',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteDialog(context, vault, provider);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// Manual sync trigger
  Future<void> _manualSync(VaultEntity vault, VaultProvider provider) async {
    setState(() {
      _syncStates[vault.id] = VaultSyncState.syncing;
    });

    HapticFeedback.mediumImpact();

    // Simulate sync - in real implementation, call CloudKit service here
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _syncStates[vault.id] = VaultSyncState.success;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${vault.name}" synced to iCloud'),
          backgroundColor: AppColors.fintechTeal,
        ),
      );
    }

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _syncStates[vault.id] = VaultSyncState.idle;
        });
      }
    });
  }

  Future<void> _showDeleteDialog(BuildContext context, VaultEntity vault, VaultProvider provider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusLg,
          ),
          title: Text(
            'Delete Vault',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${vault.name}"?',
                style: GoogleFonts.spaceGrotesk(fontSize: 14),
              ),
              const SizedBox(height: 12),
              if (vault.cloudKitSyncEnabled)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.fintechTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppColors.fintechTeal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will also remove the vault from iCloud.',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            color: AppColors.fintechTeal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.spaceGrotesk(),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final success = await provider.deleteVault(vault.id);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vault "${vault.name}" deleted'),
            backgroundColor: AppColors.fintechTeal,
          ),
        );
      }
    }
  }
}
