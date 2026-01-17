import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../providers/anti_fragile_wallet_provider.dart';

/// Anti-Fragile Wallet Settings Widget
///
/// Allows users to configure:
/// - Total cash on hand
/// - Monthly bills (fixed expenses)
/// - Minimum reserve (safety buffer)
/// - Savings goal
class AntiFragileSettingsWidget extends StatelessWidget {
  const AntiFragileSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AntiFragileWalletProvider>(
      builder: (context, walletProvider, child) {
        final settings = walletProvider.settings;

        if (settings == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.fintechTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: AppColors.fintechTeal,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VIRTUAL VAULT SETTINGS',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                            color: AppColors.gray700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Configure your "Available Now" calculation',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            color: AppColors.gray900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Total Cash Input
              _buildSettingsRow(
                label: 'Total Cash on Hand',
                hint: 'How much cash do you have?',
                value: '\$${settings.totalCash.toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet,
                color: AppColors.fintechTeal,
                onTap: () => _showInputDialog(
                  context,
                  title: 'Total Cash on Hand',
                  hint: 'Enter your total cash',
                  initialValue: settings.totalCash.toStringAsFixed(0),
                  onSave: (value) {
                    final amount = double.tryParse(value) ?? 0;
                    walletProvider.updateSettings(totalCash: amount);
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Monthly Bills Input
              _buildSettingsRow(
                label: 'Monthly Bills',
                hint: 'Fixed expenses (rent, utilities, etc.)',
                value: '\$${settings.monthlyBills.toStringAsFixed(0)}',
                icon: Icons.receipt_long,
                color: AppColors.danger,
                onTap: () => _showInputDialog(
                  context,
                  title: 'Monthly Bills',
                  hint: 'Enter total monthly bills',
                  initialValue: settings.monthlyBills.toStringAsFixed(0),
                  onSave: (value) {
                    final amount = double.tryParse(value) ?? 0;
                    walletProvider.updateSettings(monthlyBills: amount);
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Minimum Reserve Input
              _buildSettingsRow(
                label: 'Minimum Reserve',
                hint: 'Emergency buffer (default: \$500)',
                value: '\$${settings.minimumReserve.toStringAsFixed(0)}',
                icon: Icons.security,
                color: AppColors.gold,
                onTap: () => _showInputDialog(
                  context,
                  title: 'Minimum Reserve',
                  hint: 'Enter emergency savings buffer',
                  initialValue: settings.minimumReserve.toStringAsFixed(0),
                  onSave: (value) {
                    final amount = double.tryParse(value) ?? 0;
                    walletProvider.updateSettings(minimumReserve: amount);
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Savings Goal Input
              _buildSettingsRow(
                label: 'Savings Goal',
                hint: 'Monthly savings target',
                value: '\$${settings.savingsGoal.toStringAsFixed(0)}',
                icon: Icons.savings,
                color: AppColors.success,
                onTap: () => _showInputDialog(
                  context,
                  title: 'Savings Goal',
                  hint: 'Enter monthly savings goal',
                  initialValue: settings.savingsGoal.toStringAsFixed(0),
                  onSave: (value) {
                    final amount = double.tryParse(value) ?? 0;
                    walletProvider.updateSettings(savingsGoal: amount);
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Info Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.fintechTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.fintechTeal,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'How it works',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.fintechTeal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Available Now = Total Cash - (Bills + Reserve + Savings)',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: AppColors.gray700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This keeps your "safe to spend" amount realistic by hiding committed funds.',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: AppColors.gray700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsRow({
    required String label,
    required String hint,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700,
                    ),
                  ),
                  Text(
                    hint,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.edit,
              size: 18,
              color: AppColors.gray700,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInputDialog(
    BuildContext context, {
    required String title,
    required String hint,
    required String initialValue,
    required Function(String) onSave,
  }) async {
    final controller = TextEditingController(text: initialValue);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.spaceGrotesk(color: AppColors.gray500),
            filled: true,
            fillColor: AppColors.gray100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: GoogleFonts.spaceGrotesk(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.gray700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.fintechTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      onSave(result);

      // Show confirmation
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings saved! Available Now will update.'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
