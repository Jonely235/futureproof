import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../design/design_tokens.dart';
import '../../providers/anti_fragile_wallet_provider.dart';

/// Anti-Fragile Wallet Settings Widget
///
/// Refactored with clear semantic distinction for "Security/Resilience" concepts.
///
/// Allows users to configure:
/// - Current cash balance (total liquidity)
/// - Monthly bills (essential expenses)
/// - Minimum reserve (emergency buffer)
/// - Vault resilience reserve (capital locked for safety)
class AntiFragileSettingsWidget extends StatelessWidget {
  const AntiFragileSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AntiFragileWalletProvider>(
      builder: (context, walletProvider, child) {
        final settings = walletProvider.settings;
        final virtualVault = walletProvider.virtualVault;

        if (settings == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Calculate available now for display
        final availableNow = virtualVault?.availableNow.value ?? 0.0;
        final totalCommitted = settings.monthlyBills + settings.minimumReserve + settings.savingsGoal;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.fintechIndigo.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.fintechIndigo.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              _buildSectionHeader(context),

              const SizedBox(height: 20),

              // Info Box explaining the calculation
              _buildCalculationInfoBox(),

              const SizedBox(height: 20),

              // Current Cash Balance
              _buildSettingsRow(
                context: context,
                label: 'Current Cash Balance',
                hint: 'Total money you have right now',
                value: '\$${settings.totalCash.toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet,
                color: AppColors.fintechTeal,
                onTap: () => _showInputDialog(
                  context,
                  title: 'Current Cash Balance',
                  hint: 'Enter your total cash across all accounts',
                  subtitle: 'This is your total liquidity - all cash you currently have available.',
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
                context: context,
                label: 'Essential Expenses',
                hint: 'Fixed monthly costs (rent, utilities, etc.)',
                value: '\$${settings.monthlyBills.toStringAsFixed(0)}',
                icon: Icons.receipt_long,
                color: AppColors.danger,
                onTap: () => _showInputDialog(
                  context,
                  title: 'Essential Expenses',
                  hint: 'Enter total monthly bills',
                  subtitle: 'These are your fixed, unavoidable expenses each month.',
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
                context: context,
                label: 'Emergency Reserve',
                hint: 'Safety buffer for unexpected expenses',
                value: '\$${settings.minimumReserve.toStringAsFixed(0)}',
                icon: Icons.security,
                color: AppColors.gold,
                onTap: () => _showInputDialog(
                  context,
                  title: 'Emergency Reserve',
                  hint: 'Enter emergency savings buffer',
                  subtitle: 'This is your safety net. Keep at least \$500-1000 for emergencies.',
                  initialValue: settings.minimumReserve.toStringAsFixed(0),
                  onSave: (value) {
                    final amount = double.tryParse(value) ?? 0;
                    walletProvider.updateSettings(minimumReserve: amount);
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Vault Resilience Reserve Input (renamed from "Savings Goal")
              _buildSettingsRow(
                context: context,
                label: 'Vault Resilience Reserve',
                hint: 'Capital locked to protect against volatility',
                value: '\$${settings.savingsGoal.toStringAsFixed(0)}',
                icon: Icons.lock,
                color: AppColors.fintechIndigo,
                onTap: () => _showInputDialog(
                  context,
                  title: 'Vault Resilience Reserve',
                  hint: 'Enter amount to reserve in vault',
                  subtitle:
                      'This amount is reserved to calculate your "Available Now" balance, creating a safety net without touching your goals.',
                  initialValue: settings.savingsGoal.toStringAsFixed(0),
                  onSave: (value) {
                    final amount = double.tryParse(value) ?? 0;
                    walletProvider.updateSettings(savingsGoal: amount);
                  },
                ),
                showTooltip: true,
              ),

              const SizedBox(height: 24),

              // Available Now Display
              _buildAvailableNowCard(availableNow, totalCommitted, settings.totalCash),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.fintechIndigo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.shield,
            color: AppColors.fintechIndigo,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VIRTUAL VAULT CALCULATION',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.fintechIndigo,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Security & Resilience',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray700,
                ),
              ),
            ],
          ),
        ),
        // Help button for the entire section
        InkWell(
          onTap: () => _showVaultExplanationDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.help_outline,
              size: 20,
              color: AppColors.fintechIndigo.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculationInfoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fintechIndigo.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.fintechIndigo.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calculate_outlined,
            color: AppColors.fintechIndigo,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'These settings calculate your "Available Now" - the safe-to-spend amount after setting aside reserves.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                color: AppColors.gray700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableNowCard(double availableNow, double totalCommitted, double totalCash) {
    final isPositive = availableNow >= 0;
    final percentage = totalCash > 0
        ? (availableNow / totalCash * 100).clamp(0, 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPositive
              ? [
                  AppColors.fintechIndigo,
                  AppColors.fintechIndigo.withOpacity(0.85),
                ]
              : [
                  AppColors.danger,
                  AppColors.danger.withOpacity(0.85),
                ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPositive ? Icons.check_circle : Icons.warning,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AVAILABLE NOW',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              if (isPositive && percentage > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(0)}% of cash',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${availableNow.toStringAsFixed(0)}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPositive
                ? 'Safe to spend after \$${totalCommitted.toStringAsFixed(0)} in committed funds'
                : 'Warning: Committed funds exceed your cash balance',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              color: Colors.white70,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow({
    required BuildContext context,
    required String label,
    required String hint,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool showTooltip = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
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
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900,
                        ),
                      ),
                      if (showTooltip) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _showFieldTooltipDialog(context, label),
                          child: Icon(
                            Icons.info_outline,
                            size: 14,
                            color: color.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    hint,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.gray400,
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
    required String subtitle,
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
            color: AppColors.fintechIndigo,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty) ...[
              Text(
                subtitle,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  color: AppColors.gray700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.spaceGrotesk(color: AppColors.gray500),
                filled: true,
                fillColor: AppColors.fintechIndigo.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.fintechIndigo, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
                prefixText: '\$',
                prefixStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.fintechIndigo,
                ),
              ),
              style: GoogleFonts.jetBrainsMono(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
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
              backgroundColor: AppColors.fintechIndigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
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
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Text(
                  'Updated. "Available Now" recalculated.',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: AppColors.fintechIndigo,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showVaultExplanationDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.shield,
              color: AppColors.fintechIndigo,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Virtual Vault Explained',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExplanationItem(
                icon: Icons.account_balance_wallet,
                title: 'Current Cash Balance',
                description:
                    'The total amount of cash you currently have across all your accounts.',
              ),
              const SizedBox(height: 12),
              _buildExplanationItem(
                icon: Icons.receipt_long,
                title: 'Essential Expenses',
                description:
                    'Your fixed monthly costs like rent, utilities, and other bills.',
              ),
              const SizedBox(height: 12),
              _buildExplanationItem(
                icon: Icons.security,
                title: 'Emergency Reserve',
                description:
                    'A safety buffer for unexpected expenses. Keep \$500-1000 minimum.',
              ),
              const SizedBox(height: 12),
              _buildExplanationItem(
                icon: Icons.lock,
                title: 'Vault Resilience Reserve',
                description:
                    'Capital you set aside to protect against market volatility. This reduces your "Available Now" but keeps your savings safe.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.fintechIndigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.fintechIndigo,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Available Now = Cash - (Bills + Reserve + Vault)',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.fintechIndigo,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.fintechIndigo,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.gray700),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: AppColors.gray700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showFieldTooltipDialog(BuildContext context, String fieldName) async {
    final messages = {
      'Vault Resilience Reserve':
          'This is capital you deliberately lock away to protect against volatility. Unlike your savings goal (which you track for growth), this reserve reduces your "Available Now" to prevent overspending.',
    };

    final message = messages[fieldName] ?? '';

    if (message.isEmpty) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.fintechIndigo,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fieldName,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            height: 1.5,
            color: AppColors.gray700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.fintechIndigo,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
