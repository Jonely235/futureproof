import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_colors.dart';
import '../domain/entities/vault_entity.dart';

/// Vault card widget - displays vault information
///
/// Shows vault name, type, transaction count, active status,
/// last modified date, and sync status. Supports swipe-to-delete
/// and drag-to-reorder gestures.
class VaultCardWidget extends StatefulWidget {
  final VaultEntity vault;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final bool enableGestures;
  final Key? reorderKey;

  const VaultCardWidget({
    super.key,
    required this.vault,
    this.isActive = false,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.enableGestures = true,
    this.reorderKey,
  });

  @override
  State<VaultCardWidget> createState() => _VaultCardWidgetState();
}

class _VaultCardWidgetState extends State<VaultCardWidget>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final cardContent = _buildCardContent();

    if (!widget.enableGestures) {
      return cardContent;
    }

    // Wrap in ReorderableDelayedDragStartListener for drag-to-reorder
    return ReorderableDelayedDragStartListener(
      key: widget.reorderKey,
      index: 0, // Will be set by parent
      child: cardContent,
    );
  }

  Widget _buildCardContent() {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      onLongPress: _handleLongPress,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: widget.isActive
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
              if (widget.isActive)
                BoxShadow(
                  color: AppColors.fintechTeal.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: widget.isActive
                  ? BorderSide(
                      color: AppColors.fintechTeal.withOpacity(0.5),
                      width: 2,
                    )
                  : BorderSide(
                      color: AppColors.gray200,
                      width: 1,
                    ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: widget.isActive
                    ? Border.all(
                        color: AppColors.fintechTeal,
                        width: 1,
                      )
                    : null,
                gradient: widget.isActive
                    ? LinearGradient(
                        colors: [
                          AppColors.fintechTeal.withOpacity(0.2),
                          AppColors.fintechTeal.withOpacity(0),
                        ],
                      )
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Vault icon with gradient background
                    _buildIconContainer(),
                    const SizedBox(width: 16),

                    // Vault info
                    Expanded(
                      child: _buildVaultInfo(),
                    ),

                    // Sync status and delete button
                    _buildTrailingWidgets(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isActive
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
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: widget.isActive
                ? AppColors.fintechTeal.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          widget.vault.type.icon,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }

  Widget _buildVaultInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name and active badge
        Row(
          children: [
            Expanded(
              child: Text(
                widget.vault.name,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.fintechTeal,
                      Color(0xFF00A896),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.fintechTeal.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
          ],
        ),
        const SizedBox(height: 6),

        // Type and sync status
        Row(
          children: [
            Text(
              widget.vault.type.displayName,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(width: 8),
            _buildSyncStatusIndicator(),
          ],
        ),
        const SizedBox(height: 6),

        // Transaction count and last modified
        Row(
          children: [
            Icon(
              widget.vault.transactionCount == 0
                  ? Icons.inventory_2_outlined
                  : Icons.receipt_long_outlined,
              size: 14,
              color: AppColors.gray700,
            ),
            const SizedBox(width: 4),
            Text(
              widget.vault.transactionCount == 0
                  ? 'Empty vault'
                  : '${widget.vault.transactionCount} transactions',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: widget.vault.transactionCount == 0
                    ? AppColors.gray700
                    : AppColors.gray700,
                fontWeight: widget.vault.transactionCount == 0
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.access_time,
              size: 12,
              color: AppColors.gray500,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDate(widget.vault.lastModified),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                color: AppColors.gray700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSyncStatusIndicator() {
    final syncEnabled = widget.vault.cloudKitSyncEnabled;
    final lastSync = widget.vault.lastCloudSync;

    IconData icon;
    Color color;

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

    return Icon(
      icon,
      size: 16,
      color: color,
    );
  }

  Widget _buildTrailingWidgets() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onDelete != null && !widget.isActive)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: AppColors.danger,
            onPressed: () {
              HapticFeedback.mediumImpact();
              widget.onDelete?.call();
            },
            tooltip: 'Delete vault',
            splashRadius: 20,
          ),
        if (widget.enableGestures && !widget.isActive)
          Icon(
            Icons.drag_handle,
            color: AppColors.gray400,
            size: 20,
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        final minutes = difference.inMinutes;
        return minutes == 0 ? 'Just now' : '${minutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
