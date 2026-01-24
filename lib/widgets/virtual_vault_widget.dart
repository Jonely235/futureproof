import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../design/design_tokens.dart';
import '../domain/entities/virtual_vault_entity.dart';
import '../domain/entities/war_mode_entity.dart';

/// Widget displaying the Virtual Vault (Available Now)
/// Shows only the safe-to-spend amount, hiding committed funds
class VirtualVaultWidget extends StatelessWidget {
  final VirtualVaultEntity vault;
  final WarModeEntity warMode;
  final VoidCallback? onVaultTap;

  const VirtualVaultWidget({
    super.key,
    required this.vault,
    required this.warMode,
    this.onVaultTap,
  });

  @override
  Widget build(BuildContext context) {
    final availableColor = _getAvailableColor();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: DesignTokens.borderRadiusLg,
        border: Border.all(
          color: availableColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AVAILABLE NOW',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                  color: AppColors.gray700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: warMode.level.colorCode != '#4CAF50'
                      ? _parseColor(warMode.level.colorCode).withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      warMode.level.emoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      warMode.level.displayName,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _parseColor(warMode.level.colorCode),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${vault.availableNow.value.toStringAsFixed(2)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                        color: availableColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vault.statusMessage,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        color: AppColors.gray700,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onVaultTap,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.lock,
                        size: 20,
                        color: AppColors.gray700,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'VAULT',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray700,
                        ),
                      ),
                      Text(
                        '\$${vault.committedFunds.value.toStringAsFixed(0)}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
            child: LinearProgressIndicator(
              value: (vault.availablePercentage / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(availableColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvailableColor() {
    if (!vault.isHealthy) {
      return AppColors.danger;
    } else if (vault.isInDangerZone) {
      return AppColors.gold;
    } else if (vault.availablePercentage < 25) {
      return AppColors.gold;
    } else {
      return AppColors.success;
    }
  }

  Color _parseColor(String hexCode) {
    final colorValue = int.parse(hexCode.replaceFirst('#', '0xFF'));
    return Color(colorValue);
  }
}
