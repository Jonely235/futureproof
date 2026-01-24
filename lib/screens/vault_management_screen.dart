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

/// Vault management screen - advanced vault operations
///
/// Features: search, filter, sort, swipe-to-delete, edit vault.
class VaultManagementScreen extends StatefulWidget {
  const VaultManagementScreen({super.key});

  @override
  State<VaultManagementScreen> createState() => _VaultManagementScreenState();
}

class _VaultManagementScreenState extends State<VaultManagementScreen> {
  bool _isSearching = false;
  VaultSortOption _sortBy = VaultSortOption.nameAsc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.scaffoldBackground,
      body: CustomScrollView(
        slivers: [
          // App bar with search
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

  Widget _buildVaultCard(VaultEntity vault, VaultProvider provider, int index) {
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
      child: VaultCardWidget(
        vault: vault,
        isActive: vault.isActive,
        enableGestures: true,
        reorderKey: ValueKey(vault.id),
        onTap: () {
          HapticFeedback.lightImpact();
          // Just a tap, don't activate (go to edit instead)
          _showVaultOptions(context, vault, provider);
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showVaultOptions(context, vault, provider);
        },
        onDelete: vault.isActive
            ? null
            : () => _showDeleteDialog(context, vault, provider),
      ),
    );
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
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(
                  'Edit Vault',
                  style: GoogleFonts.spaceGrotesk(),
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
              if (!vault.isActive)
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.danger),
                  title: Text(
                    'Delete Vault',
                    style: GoogleFonts.spaceGrotesk(),
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
          content: Text(
            'Are you sure you want to delete "${vault.name}"? This will permanently delete all transactions in this vault.',
            style: GoogleFonts.spaceGrotesk(fontSize: 14),
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
