import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../domain/entities/vault_entity.dart';
import '../models/vault_sort_option.dart';
import '../models/vault_view_mode.dart';
import '../providers/vault_provider.dart';
import '../widgets/vault_card_widget.dart';
import '../widgets/vault_grid_view.dart';
import '../widgets/vault_search_bar.dart';
import '../widgets/vault_type_filter.dart';
import 'vault_creation_screen.dart';
import 'vault_edit_screen.dart';

/// Vault list screen - displays all vaults with adaptive layout
///
/// Shows all vaults in:
/// - Hero cards (1-3 vaults)
/// - List view (4-6 vaults)
/// - Grid view (7+ vaults)
///
/// Features:
/// - Adaptive layout based on vault count
/// - Search with debounce
/// - Filter by type
/// - Sort options
/// - Swipe-to-delete
/// - Drag-to-reorder
class VaultListScreen extends StatefulWidget {
  const VaultListScreen({super.key});

  @override
  State<VaultListScreen> createState() => _VaultListScreenState();
}

class _VaultListScreenState extends State<VaultListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Timer? _searchTimer;

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(
        slivers: [
          // App Bar with search and actions
          _buildSliverAppBar(),

          // Search and filter bar (when searching)
          if (_isSearching) _buildSearchAndFilterBar(),

          // Main vault content
          _buildVaultContent(),
        ],
      ),

      // Floating action button for creating new vaults
      floatingActionButton: Consumer<VaultProvider>(
        builder: (context, vaultProvider, child) {
          return vaultProvider.hasActiveFilters
              ? FloatingActionButton.extended(
                  onPressed: vaultProvider.clearFilters,
                  backgroundColor: AppColors.fintechTeal,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Filters'),
                )
              : FloatingActionButton(
                  onPressed: () => _showCreateVaultDialog(context),
                  backgroundColor: AppColors.fintechTeal,
                  child: const Icon(Icons.add),
                );
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return Consumer<VaultProvider>(
      builder: (context, vaultProvider, child) {
        return SliverAppBar(
          expandedHeight: _isSearching ? 80 : 140,
          floating: false,
          pinned: true,
          elevation: 0,
          backgroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
            title: Text(
              _isSearching ? '' : 'Vaults',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
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
                    _searchController.clear();
                  }
                });
              },
              tooltip: _isSearching ? 'Close search' : 'Search vaults',
            ),

            // View mode toggle (when vault count > 3)
            if (vaultProvider.vaultCount > 3)
              PopupMenuButton<VaultViewMode>(
                icon: const Icon(Icons.view_list),
                tooltip: 'Change view mode',
                onSelected: (mode) {
                  context.read<VaultProvider>().setViewMode(mode);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: VaultViewMode.auto,
                    child: Row(
                      children: [
                        const Icon(Icons.auto_mode, size: 20),
                        const SizedBox(width: 12),
                        Text('Auto', style: GoogleFonts.spaceGrotesk()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: VaultViewMode.list,
                    child: Row(
                      children: [
                        const Icon(Icons.view_list, size: 20),
                        const SizedBox(width: 12),
                        Text('List', style: GoogleFonts.spaceGrotesk()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: VaultViewMode.grid,
                    child: Row(
                      children: [
                        const Icon(Icons.grid_view, size: 20),
                        const SizedBox(width: 12),
                        Text('Grid', style: GoogleFonts.spaceGrotesk()),
                      ],
                    ),
                  ),
                ],
              ),

            // Sort button
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () => _showSortOptions(context, vaultProvider),
              tooltip: 'Sort vaults',
            ),

            // Create vault button
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateVaultDialog(context),
              tooltip: 'Create vault',
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Consumer<VaultProvider>(
      builder: (context, vaultProvider, child) {
        return SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                VaultSearchBar(
                  query: vaultProvider.searchQuery,
                  onChanged: (query) {
                    context.read<VaultProvider>().setSearchQuery(query);
                  },
                  onClear: () {
                    context.read<VaultProvider>().setSearchQuery('');
                  },
                ),
                const SizedBox(height: 16),

                // Type filter chips
                VaultTypeFilter(
                  selectedTypes: vaultProvider.filterTypes,
                  onToggle: (type) {
                    context.read<VaultProvider>().toggleFilterType(type);
                  },
                ),

                // Filter results count
                if (vaultProvider.hasActiveFilters)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      '${vaultProvider.filteredVaults.length} of ${vaultProvider.vaults.length} vaults',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: AppColors.gray700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVaultContent() {
    return Consumer<VaultProvider>(
      builder: (context, vaultProvider, child) {
        if (vaultProvider.isLoading) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Get vaults to display (filtered or all)
        final displayVaults = vaultProvider.hasActiveFilters
            ? vaultProvider.filteredVaults
            : vaultProvider.vaults;

        if (displayVaults.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(vaultProvider),
          );
        }

        // Determine layout mode
        final effectiveView = vaultProvider.effectiveViewMode;
        final screenWidth = MediaQuery.of(context).size.width;

        // Show hero cards for 1-3 vaults in list/auto mode
        if (effectiveView == VaultViewMode.list && displayVaults.length <= 3) {
          return _buildHeroCards(displayVaults, vaultProvider);
        }

        // Show grid view
        if (effectiveView == VaultViewMode.grid) {
          return _buildGridView(displayVaults, vaultProvider);
        }

        // Show list view
        return _buildListView(displayVaults, vaultProvider);
      },
    );
  }

  Widget _buildHeroCards(List<VaultEntity> vaults, VaultProvider provider) {
    return SliverPadding(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final vault = vaults[index];
            final isLast = index == vaults.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: _buildLargeVaultCard(vault, provider),
            );
          },
          childCount: vaults.length,
        ),
      ),
    );
  }

  Widget _buildLargeVaultCard(VaultEntity vault, VaultProvider provider) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: vault.isActive
            ? LinearGradient(
                colors: [
                  AppColors.fintechTeal.withOpacity(0.15),
                  AppColors.fintechTeal.withOpacity(0.05),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: vault.isActive
                ? AppColors.fintechTeal.withOpacity(0.2)
                : Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: vault.isActive
              ? BorderSide(color: AppColors.fintechTeal, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => _handleVaultTap(vault, provider),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _showVaultOptions(vault, provider);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      vault.type.icon,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vault.name,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (vault.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.fintechTeal,
                                    Color(0xFF00A896),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        vault.type.displayName,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          color: AppColors.gray700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            vault.transactionCount == 0
                                ? Icons.inventory_2_outlined
                                : Icons.receipt_long_outlined,
                            size: 16,
                            color: AppColors.gray700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            vault.transactionCount == 0
                                ? 'Empty vault'
                                : '${vault.transactionCount} transactions',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              color: AppColors.gray700,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.gray500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(vault.lastModified),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              color: AppColors.gray700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Delete button
                if (!vault.isActive)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.danger,
                    onPressed: () => _showDeleteDialog(vault, provider),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<VaultEntity> vaults, VaultProvider provider) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final vault = vaults[index];
          return VaultCardWidget(
            key: ValueKey(vault.id),
            vault: vault,
            isActive: vault.isActive,
            onTap: () => _handleVaultTap(vault, provider),
            onLongPress: () {
              _showVaultOptions(vault, provider);
            },
            onDelete: vault.isActive
                ? null
                : () => _showDeleteDialog(vault, provider),
          );
        },
        childCount: vaults.length,
      ),
    );
  }

  Widget _buildGridView(List<VaultEntity> vaults, VaultProvider provider) {
    return VaultGridView(
      vaults: vaults,
      activeVault: provider.activeVault,
      onTap: (vault) => _handleVaultTap(vault, provider),
      onLongPress: (vault) => _showVaultOptions(vault, provider),
      onDelete: !vaults.any((v) => v.isActive)
          ? (vault) => _showDeleteDialog(vault, provider)
          : null,
    );
  }

  Widget _buildEmptyState(VaultProvider provider) {
    final hasFilters = provider.hasActiveFilters;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.fintechTeal.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasFilters ? Icons.filter_list_off : Icons.folder_open,
                      size: 64,
                      color: AppColors.fintechTeal,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          Text(
            hasFilters ? 'No vaults match your filters' : 'No vaults yet',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),

          if (hasFilters) ...[
            Text(
              'Try adjusting your filters or search query',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: provider.clearFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.fintechTeal,
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Create your first vault to start tracking your finances',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: AppColors.gray700,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Pulsing CTA button
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 1.0 + (value % 1) * 0.05,
                  child: FilledButton.icon(
                    onPressed: () => _showCreateVaultDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your First Vault'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.fintechTeal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _handleVaultTap(VaultEntity vault, VaultProvider provider) async {
    if (!vault.isActive) {
      final success = await provider.setActiveVault(vault.id);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to "${vault.name}"'),
            backgroundColor: AppColors.fintechTeal,
          ),
        );
      }
    }
  }

  void _showVaultOptions(VaultEntity vault, VaultProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  borderRadius: BorderRadius.circular(2),
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
                  Navigator.push<VaultEntity>(
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
                    _showDeleteDialog(vault, provider);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(VaultEntity vault, VaultProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
            style: GoogleFonts.spaceGrotesk(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.spaceGrotesk(),
              ),
            ),
            FilledButton(
              onPressed: () async {
                final success = await provider.deleteVault(vault.id);
                if (success && mounted) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Vault "${vault.name}" deleted'),
                      backgroundColor: AppColors.fintechTeal,
                    ),
                  );
                }
              },
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
  }

  void _showSortOptions(BuildContext context, VaultProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Sort Vaults',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: VaultSortOption.values.map((option) {
              return RadioListTile<VaultSortOption>(
                title: Text(
                  option.displayName,
                  style: GoogleFonts.spaceGrotesk(fontSize: 14),
                ),
                value: option,
                groupValue: provider.sortBy,
                onChanged: (value) {
                  if (value != null) {
                    provider.setSortOption(value);
                    Navigator.pop(context);
                  }
                },
                activeColor: AppColors.fintechTeal,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showCreateVaultDialog(BuildContext context) {
    Navigator.push<VaultEntity>(
      context,
      MaterialPageRoute(
        builder: (context) => const VaultCreationScreen(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}