import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_error.dart';
import '../services/analytics_service.dart';
import '../services/backup_service.dart';
import '../utils/app_logger.dart';
import '../utils/error_display.dart';
import '../config/app_colors.dart';
import '../widgets/theme_picker_widget.dart';

/// Settings Screen
///
/// Allows users to configure monthly income, savings goals,
/// and other app preferences.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _incomeController = TextEditingController();
  final _savingsController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final monthlyIncome = prefs.getDouble('monthly_income') ?? 5000.0;
      final savingsGoal = prefs.getDouble('savings_goal') ?? 1000.0;

      setState(() {
        _incomeController.text = monthlyIncome.toStringAsFixed(0);
        _savingsController.text = savingsGoal.toStringAsFixed(0);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.settings.severe('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    HapticFeedback.mediumImpact();

    final income = double.tryParse(_incomeController.text);
    final savings = double.tryParse(_savingsController.text);

    if (income == null || income <= 0) {
      HapticFeedback.heavyImpact();
      ErrorDisplay.showErrorSnackBar(
        context,
        AppError(
          type: AppErrorType.validation,
          message: 'Please enter a valid monthly income',
        ),
      );
      return;
    }

    if (savings == null || savings < 0) {
      HapticFeedback.heavyImpact();
      ErrorDisplay.showErrorSnackBar(
        context,
        AppError(
          type: AppErrorType.validation,
          message: 'Please enter a valid savings goal',
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('monthly_income', income);
      await prefs.setDouble('savings_goal', savings);

      // Verify save by reading back
      final savedIncome = await prefs.getDouble('monthly_income');
      final savedSavings = await prefs.getDouble('savings_goal');

      if (savedIncome == income && savedSavings == savings) {
        HapticFeedback.lightImpact();

        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          ErrorDisplay.showSuccessSnackBar(
            context,
            'Settings saved successfully',
          );
          // Don't navigate away automatically - let user decide when to leave
        }
      } else {
        throw Exception('Settings verification failed');
      }
    } catch (e, st) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        final error = e is AppError
            ? e
            : AppError.fromException(
                e,
                type: AppErrorType.validation,
                stackTrace: st,
              );
        AppLogger.settings.severe('Error saving settings', error);
        setState(() {
          _isSaving = false;
        });
        ErrorDisplay.showErrorSnackBar(context, error);
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults?'),
        content: const Text(
            'This will reset all settings to default values. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      HapticFeedback.mediumImpact();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('monthly_income');
        await prefs.remove('savings_goal');

        HapticFeedback.lightImpact();
        await _loadSettings();

        if (mounted) {
          ErrorDisplay.showSuccessSnackBar(
            context,
            'Settings reset to defaults',
          );
        }
      } catch (e, st) {
        HapticFeedback.heavyImpact();
        if (mounted) {
          final error = e is AppError
              ? e
              : AppError.fromException(
                  e,
                  type: AppErrorType.validation,
                  stackTrace: st,
                );
          AppLogger.settings.severe('Error resetting settings', error);
          ErrorDisplay.showErrorSnackBar(context, error);
        }
      }
    }
  }

  Widget _buildSmartInsights() {
    return FutureBuilder<Map<String, dynamic>>(
      future: AnalyticsService().getQuickStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        final totalSpending = stats['totalSpending'] as double;
        final monthlyIncome = stats['monthlyIncome'] as double;
        final remaining = monthlyIncome - totalSpending;
        final savings = stats['savings'] as double;
        final savingsRate = stats['savingsRate'] as double;
        final isOnTrack = stats['isOnTrack'] as bool;

        return Column(
          children: [
            // Section Header
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: const AppColors.black,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Smart Insights',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const AppColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Visual Stat Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.account_balance_wallet,
                    value: '\$${remaining.toStringAsFixed(0)}',
                    label: 'Remaining',
                    color: const AppColors.black,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCircularProgressCard(
                    value: savingsRate.clamp(0.0, 1.0),
                    label: 'Budget OK',
                    color: isOnTrack ? const AppColors.success : const AppColors.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.trending_up,
                    value: '\$${savings.toStringAsFixed(0)}',
                    label: 'Savings',
                    color: AppColors.slate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.local_fire_department,
                    value: _getStreakDays(),
                    label: 'Day Streak',
                    color: const AppColors.gold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Tip of the Day
            _buildTipCard(
              tip: _getDailyTip(stats),
            ),

            const SizedBox(height: 12),

            // Top Category Alert (if applicable)
            if (stats['topCategory'] != null && (stats['topCategoryAmount'] as double) > monthlyIncome * 0.3)
              _buildCategoryAlert(
                category: stats['topCategory'] as String,
                amount: stats['topCategoryAmount'] as double,
              ),
          ],
        );
      },
    );
  }

  Widget _buildRecommendationItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const AppColors.gray700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularProgressCard({
    required double value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: value,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 4,
                ),
                Center(
                  child: Text(
                    '${(value * 100).toInt()}%',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const AppColors.gray700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard({required String tip}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const AppColors.gold,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb,
            color: const AppColors.gold,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: const AppColors.black,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAlert({
    required String category,
    required double amount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const AppColors.danger,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: const AppColors.danger,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'High Spending Alert',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const AppColors.danger,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$category: \$${amount.toStringAsFixed(0)} this month',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: const AppColors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStreakDays() {
    // Simple streak calculation - in real app, calculate from actual data
    return '3';
  }

  String _getDailyTip(Map<String, dynamic> stats) {
    final tips = [
      'Your dining spending is 20% lower than last month. Great progress!',
      'Setting aside small amounts daily adds up to big savings.',
      'Review subscriptions monthly to avoid unnecessary charges.',
      'Try the 50/30/20 rule: 50% needs, 30% wants, 20% savings.',
      'Small changes in daily habits can lead to big financial wins.',
    ];

    // Simple rotation based on day of month
    final dayOfMonth = DateTime.now().day;
    return tips[dayOfMonth % tips.length];
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const AppColors.offWhite,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 140,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
                    title: Text(
                      'Settings',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: const AppColors.black,
                      ),
                    ),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                        // Financial Goals Section
                        _buildSectionHeader('Financial Goals'),
                        _buildSettingsSection([
                          _buildSettingCard(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Monthly Income',
                            subtitle: 'Your total monthly household income',
                            child: TextField(
                              controller: _incomeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Income',
                                prefixText: '\$',
                                border: InputBorder.none,
                                filled: true,
                              ),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSettingCard(
                            icon: Icons.savings_outlined,
                            title: 'Savings Goal',
                            subtitle: 'How much you want to save each month',
                            child: TextField(
                              controller: _savingsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Goal',
                                prefixText: '\$',
                                border: InputBorder.none,
                                filled: true,
                              ),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ]),

                        const SizedBox(height: 32),

                        // Smart Insights Section
                        _buildSectionHeader('Smart Insights'),
                        _buildSettingsSection([
                          _buildSmartInsights(),
                        ]),

                        const SizedBox(height: 32),

                        // Theme Section
                        _buildSectionHeader('Appearance'),
                        _buildSettingsSection([
                          ThemePickerWidget(
                            onThemeChanged: (theme) {
                              // Trigger rebuild to show updated selection
                              setState(() {});
                            },
                          ),
                        ]),

                        const SizedBox(height: 32),

                        // Backup & Export Section
                        _buildSectionHeader('Backup & Export'),
                        _buildSettingsSection([
                          _buildBackupSection(),
                        ]),

                        const SizedBox(height: 32),

                        // App Info Section
                        _buildSectionHeader('About'),
                        _buildSettingsSection([
                          _buildInfoRow('Version', '1.0.0'),
                          _buildInfoRow('Build', 'MVP Complete'),
                          _buildInfoRow('Status', '🎉 Ready'),
                        ]),

                        const SizedBox(height: 32),

                        // Action Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveSettings,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const AppColors.black,
                                    foregroundColor: const AppColors.white,
                                    disabledBackgroundColor: const AppColors.border,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(AppColors.black),
                                          ),
                                        )
                                      : Text(
                                          'Save Settings',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _resetToDefaults,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const AppColors.danger,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    side: const BorderSide(color: AppColors.danger),
                                  ),
                                  child: Text(
                                    'Reset to Defaults',
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

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Text(
        title,
        style: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const AppColors.black,
        ),
      ),
    );
  }

  Widget _buildSettingsSection(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const AppColors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const AppColors.black,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const AppColors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: const AppColors.gray700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const AppColors.offWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const AppColors.border,
              width: 1,
            ),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const AppColors.gray700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSection() {
    final backupService = BackupService();

    return FutureBuilder<DateTime?>(
      future: backupService.getLastBackupDate(),
      builder: (context, snapshot) {
        final lastBackup = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_upload,
                  color: const AppColors.black,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Backup',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const AppColors.black,
                        ),
                      ),
                      if (lastBackup != null)
                        Text(
                          'Last backup: ${_formatDate(lastBackup)}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            color: const AppColors.gray700,
                          ),
                        )
                      else
                        Text(
                          'No backups yet',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            color: const AppColors.gray700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportData(context, backupService),
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(
                      'Export',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const AppColors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _importData(context, backupService),
                    icon: const Icon(Icons.upload, size: 18),
                    label: Text(
                      'Import',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const AppColors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.black),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _exportData(BuildContext context, BackupService backupService) async {
    HapticFeedback.lightImpact();

    try {
      // Export data
      final jsonData = await backupService.exportData();
      final filename = backupService.getExportFilename();

      // Show success dialog with data
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your data has been exported successfully.'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const AppColors.gray100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    jsonData,
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Copy this data and save it to a file:'),
                const SizedBox(height: 8),
                Text(
                  filename,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: jsonData));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data copied to clipboard!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('Copy to Clipboard'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }

      // Save last backup timestamp
      await backupService.saveLastBackupDate();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context, BackupService backupService) async {
    HapticFeedback.lightImpact();

    // Show text input dialog
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your backup JSON data below:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'Paste JSON data here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        // Import data
        final importResult = await backupService.importData(result);

        if (context.mounted) {
          if (importResult.success) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Import Successful'),
                content: Text(
                  'Imported ${importResult.importedCount} transactions\n'
                  '${importResult.skippedCount > 0 ? 'Skipped ${importResult.skippedCount} duplicates' : ''}',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Reload settings to reflect any changes
                      _loadSettings();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Import failed: ${importResult.errorMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
