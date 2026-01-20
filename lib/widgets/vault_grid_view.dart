import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_colors.dart';
import '../domain/entities/vault_entity.dart';
import '../widgets/vault_card_widget.dart';

/// Vault grid view widget - responsive grid layout for vaults
///
/// Displays vaults in a responsive grid with 2 columns on mobile,
/// 3 on tablet, and 4 on desktop. Features staggered entrance animations.
class VaultGridView extends StatefulWidget {
  final List<VaultEntity> vaults;
  final VaultEntity? activeVault;
  final Function(VaultEntity) onTap;
  final Function(VaultEntity) onLongPress;
  final Function(VaultEntity)? onDelete;

  const VaultGridView({
    super.key,
    required this.vaults,
    this.activeVault,
    required this.onTap,
    required this.onLongPress,
    this.onDelete,
  });

  @override
  State<VaultGridView> createState() => _VaultGridViewState();
}

class _VaultGridViewState extends State<VaultGridView>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Start staggered animation after first frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasAnimated) {
        _hasAnimated = true;
        _staggerController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(VaultGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart animation when vaults change significantly
    if (oldWidget.vaults.length != widget.vaults.length) {
      _hasAnimated = false;
      _staggerController.reset();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasAnimated) {
          _hasAnimated = true;
          _staggerController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _getCrossAxisCount(screenWidth);
    final spacing = screenWidth < 600 ? 12.0 : 16.0;

    return GridView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: spacing,
        vertical: spacing,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: _getChildAspectRatio(screenWidth),
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: widget.vaults.length,
      itemBuilder: (context, index) {
        final vault = widget.vaults[index];
        final animation = _createStaggeredAnimation(index);

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              ),
            );
          },
          child: _buildGridCard(context, vault, screenWidth),
        );
      },
    );
  }

  Widget _buildGridCard(BuildContext context, VaultEntity vault, double screenWidth) {
    final isMobile = screenWidth < 600;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: vault.isActive
            ? LinearGradient(
                colors: [
                  AppColors.fintechTeal.withOpacity(0.1),
                  AppColors.fintechTeal.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: vault.isActive
                ? AppColors.fintechTeal.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: vault.isActive
              ? BorderSide(
                  color: AppColors.fintechTeal.withOpacity(0.5),
                  width: 2,
                )
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => widget.onTap(vault),
          onLongPress: () => widget.onLongPress(vault),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and active badge row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon container
                    Container(
                      width: isMobile ? 48 : 56,
                      height: isMobile ? 48 : 56,
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
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          vault.type.icon,
                          style: TextStyle(fontSize: isMobile ? 24 : 28),
                        ),
                      ),
                    ),

                    // Active badge and sync status
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (vault.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.fintechTeal,
                                  Color(0xFF00A896),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        _buildSyncStatusIcon(vault),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Vault name
                Text(
                  vault.name,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: isMobile ? 15 : 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Vault type
                Text(
                  vault.type.displayName,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray700,
                  ),
                ),

                const Spacer(),

                // Stats row
                Row(
                  children: [
                    // Transaction count
                    Icon(
                      vault.transactionCount == 0
                          ? Icons.inventory_2_outlined
                          : Icons.receipt_long_outlined,
                      size: isMobile ? 12 : 14,
                      color: AppColors.gray700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      vault.transactionCount == 0
                          ? 'Empty'
                          : '${vault.transactionCount}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: isMobile ? 11 : 12,
                        color: AppColors.gray700,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Last modified
                    Icon(
                      Icons.access_time,
                      size: isMobile ? 10 : 12,
                      color: AppColors.gray500,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _formatShortDate(vault.lastModified),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: isMobile ? 10 : 11,
                          color: AppColors.gray700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Delete button for non-active vaults
                if (widget.onDelete != null && !vault.isActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => widget.onDelete!(vault),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: Text(
                          'Delete',
                          style: GoogleFonts.spaceGrotesk(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: BorderSide(color: AppColors.danger.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatusIcon(VaultEntity vault) {
    final syncEnabled = vault.cloudKitSyncEnabled;
    final lastSync = vault.lastCloudSync;

    IconData icon;
    Color color;
    double size = 14;

    if (!syncEnabled) {
      icon = Icons.cloud_off;
      color = AppColors.gray700;
    } else if (lastSync == null) {
      icon = Icons.sync;
      color = AppColors.fintechTeal;
    } else {
      final syncAge = DateTime.now().difference(lastSync);
      if (syncAge < const Duration(minutes: 5)) {
        icon = Icons.cloud_done;
        color = AppColors.fintechTeal;
      } else if (syncAge < const Duration(hours: 1)) {
        icon = Icons.cloud_queue;
        color = Colors.orange;
      } else {
        icon = Icons.sync_problem;
        color = AppColors.gray700;
      }
    }

    return Icon(icon, size: size, color: color);
  }

  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth < 600) {
      return 2; // Mobile
    } else if (screenWidth < 900) {
      return 3; // Tablet
    } else {
      return 4; // Desktop
    }
  }

  double _getChildAspectRatio(double screenWidth) {
    if (screenWidth < 600) {
      return 1.1; // Mobile - more square
    } else if (screenWidth < 900) {
      return 1.15; // Tablet
    } else {
      return 1.2; // Desktop
    }
  }

  Animation<double> _createStaggeredAnimation(int index) {
    final staggerDelay = (index * 0.05).clamp(0.0, 0.3);
    final curvedAnimation = CurvedAnimation(
      parent: _staggerController,
      curve: Interval(staggerDelay, 1.0, curve: Curves.easeOut),
    );
    return curvedAnimation;
  }

  String _formatShortDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
