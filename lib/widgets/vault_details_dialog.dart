import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../domain/entities/virtual_vault_entity.dart';
import '../domain/entities/war_mode_entity.dart';

/// Dialog showing vault details (committed funds breakdown)
class VaultDetailsDialog extends StatelessWidget {
  final VirtualVaultEntity vault;
  final WarModeEntity warMode;

  const VaultDetailsDialog({
    super.key,
    required this.vault,
    required this.warMode,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lock, color: AppColors.black),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VAULT DETAILS',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                          color: AppColors.gray700,
                        ),
                      ),
                      Text(
                        'Committed Funds',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Total Cash
            _buildDetailRow(
              label: 'Total Cash',
              value: '\$${vault.totalCash.value.toStringAsFixed(2)}',
              icon: Icons.account_balance_wallet,
              color: AppColors.black,
            ),
            const SizedBox(height: 16),

            // Vaulted Amount
            _buildDetailRow(
              label: 'Locked in Vault',
              value: '\$${vault.committedFunds.value.toStringAsFixed(2)}',
              icon: Icons.lock,
              color: AppColors.gray700,
            ),
            const SizedBox(height: 16),

            // Available Now
            _buildDetailRow(
              label: 'Available Now',
              value: '\$${vault.availableNow.value.toStringAsFixed(2)}',
              icon: Icons.check_circle,
              color: vault.isHealthy ? AppColors.success : AppColors.danger,
            ),
            const SizedBox(height: 24),

            // Runway Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: warMode.level.colorCode != '#4CAF50'
                    ? _parseWarModeColor(warMode.level.colorCode)
                        .withOpacity(0.1)
                    : AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        warMode.level.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        warMode.level.displayName.toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                          color: _parseWarModeColor(warMode.level.colorCode),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    warMode.runwayMessage,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: AppColors.gray700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Got it',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: AppColors.gray700,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Safely parse war mode color hex string.
  /// The source (WarModeLevel.colorCode) is controlled and always valid,
  /// but we add defensive parsing for safety.
  Color _parseWarModeColor(String colorCode) {
    try {
      return Color(int.parse(colorCode.replaceFirst('#', '0xFF')));
    } on FormatException {
      return AppColors.gray700; // fallback
    }
  }
}
