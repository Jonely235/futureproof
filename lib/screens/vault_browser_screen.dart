import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../domain/entities/vault_entity.dart';
import '../providers/vault_provider.dart';
import '../widgets/vault_card_widget.dart';
import '../widgets/vault_grid_view.dart';
import 'vault_creation_screen.dart';
import 'vault_management_screen.dart';

/// Vault browser screen - clean, focused vault selection
///
/// Simple vault list with no advanced features.
/// Primary action: tap to activate vault.
/// Secondary actions: create new vault, manage vaults.
class VaultBrowserScreen extends StatefulWidget {
  const VaultBrowserScreen({super.key});

  @override
  State<VaultBrowserScreen> createState() => _VaultBrowserScreenState();
}

class _VaultBrowserScreenState extends State<VaultBrowserScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(
        slivers: [
          // Clean app bar - just title and back button
          SliverAppBar(
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Vaults',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            actions: const [],
          ),

          // Vault content
          Consumer<VaultProvider>(
            builder: (context, vaultProvider, child) {
              if (vaultProvider.isLoading) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (!vaultProvider.hasVaults) {
                return SliverFillRemaining(
                  child: _buildEmptyState(context),
                );
              }

              // Adaptive layout based on vault count
              final vaultCount = vaultProvider.vaults.length;
              if (vaultCount <= 3) {
                return _buildHeroCards(context, vaultProvider);
              } else if (vaultCount <= 6) {
                return _buildListView(context, vaultProvider);
              } else {
                return _buildGridView(context, vaultProvider);
              }
            },
          ),
        ],
      ),

      // Bottom action buttons
      bottomNavigationBar: Consumer<VaultProvider>(
        builder: (context, vaultProvider, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Create button - prominent
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _showCreateVaultModal(context),
                      icon: const Icon(Icons.add),
                      label: Text(
                        'Create New Vault',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.fintechTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Manage button - secondary
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VaultManagementScreen(),
                            fullscreenDialog: true,
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings_outlined),
                      label: Text(
                        'Manage Vaults',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.fintechTeal,
                        side: BorderSide(color: AppColors.fintechTeal),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
                    child: const Icon(
                      Icons.folder_open,
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
            'No Vaults Yet',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
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

          // Pulsing CTA
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 1.0 + (value % 1) * 0.05,
                child: FilledButton.icon(
                  onPressed: () => _showCreateVaultModal(context),
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Create Your First Vault',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.fintechTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Hero cards for 1-3 vaults
  Widget _buildHeroCards(BuildContext context, VaultProvider provider) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final vault = provider.vaults[index];
            final isLast = index == provider.vaults.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 100 : 16),
              child: _buildHeroCard(context, vault, provider),
            );
          },
          childCount: provider.vaults.length,
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, VaultEntity vault, VaultProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      height: isMobile ? 140 : 160,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleVaultTap(context, vault, provider),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            // Navigate to management screen on long press
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VaultManagementScreen(),
                fullscreenDialog: true,
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon
                Container(
                  width: isMobile ? 80 : 90,
                  height: isMobile ? 80 : 90,
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
                      style: TextStyle(fontSize: isMobile ? 40 : 48),
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
                      // Name + Active badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vault.name,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: isMobile ? 20 : 22,
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

                      // Type
                      Text(
                        vault.type.displayName,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: isMobile ? 15 : 16,
                          color: AppColors.gray700,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Stats row
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
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // List view for 4-6 vaults
  Widget _buildListView(BuildContext context, VaultProvider provider) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final vault = provider.vaults[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: VaultCardWidget(
                key: ValueKey(vault.id),
                vault: vault,
                isActive: vault.isActive,
                enableGestures: false, // No gestures in browser
                onTap: () => _handleVaultTap(context, vault, provider),
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VaultManagementScreen(),
                      fullscreenDialog: true,
                    ),
                  );
                },
              ),
            );
          },
          childCount: provider.vaults.length,
        ),
      ),
    );
  }

  // Grid view for 7+ vaults
  Widget _buildGridView(BuildContext context, VaultProvider provider) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final vault = provider.vaults[index];
            return VaultCardWidget(
              key: ValueKey(vault.id),
              vault: vault,
              isActive: vault.isActive,
              enableGestures: false,
              onTap: () => _handleVaultTap(context, vault, provider),
              onLongPress: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VaultManagementScreen(),
                    fullscreenDialog: true,
                  ),
                );
              },
            );
          },
          childCount: provider.vaults.length,
        ),
      ),
    );
  }

  Future<void> _handleVaultTap(BuildContext context, VaultEntity vault, VaultProvider provider) async {
    HapticFeedback.lightImpact();

    if (!vault.isActive) {
      final success = await provider.setActiveVault(vault.id);
      if (success && context.mounted) {
        Navigator.pop(context); // Go back after activating
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to "${vault.name}"'),
            backgroundColor: AppColors.fintechTeal,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showCreateVaultModal(BuildContext context) async {
    HapticFeedback.lightImpact();

    final result = await showModalBottomSheet<VaultEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VaultCreationScreen(),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vault "${result.name}" created!'),
          backgroundColor: AppColors.fintechTeal,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
