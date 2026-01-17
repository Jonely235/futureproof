import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_colors.dart';
import '../widgets/backup_section_widget.dart';
import '../widgets/financial_goals_form_widget.dart';
import '../widgets/settings/anti_fragile_settings_widget.dart';
import '../widgets/firebase_config_widget.dart';
import '../widgets/settings/premium_quick_actions_card.dart';
import '../widgets/settings/quick_actions_color_picker.dart';
import '../widgets/theme_picker_widget.dart';
import '../widgets/ui_helpers.dart';
import '../data/repositories/firebase_backup_repository_impl.dart';
import 'debug/error_history_screen.dart';
import 'add_expense_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'ai_settings_screen.dart';

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
  late final FirebaseBackupRepositoryImpl _cloudBackupRepo;
  Color _selectedQuickActionsColor = AppColors.fintechTeal;

  @override
  void initState() {
    super.initState();
    _cloudBackupRepo = FirebaseBackupRepositoryImpl();
    _loadSavedColor();
  }

  Future<void> _loadSavedColor() async {
    // Load saved color from shared preferences
    // For now, just use the default
    setState(() {
      _selectedQuickActionsColor = AppColors.fintechTeal;
    });
  }

  @override
  void dispose() {
    _cloudBackupRepo.dispose();
    super.dispose();
  }

  void _navigateToAddExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpenseScreen(),
      ),
    );
  }

  void _navigateToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AnalyticsDashboardScreen(),
      ),
    );
  }

  void _showSyncSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sync started...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(
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
                  color: AppColors.black,
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

                  // Premium Quick Actions Card
                  PremiumQuickActionsCard(
                    primaryColor: _selectedQuickActionsColor,
                    actions: [
                      QuickAction(
                        icon: Icons.add_rounded,
                        title: 'Add Expense',
                        subtitle: 'Quickly add a new transaction',
                        onTap: _navigateToAddExpense,
                      ),
                      QuickAction(
                        icon: Icons.bar_chart_rounded,
                        title: 'View Analytics',
                        subtitle: 'See your spending insights',
                        onTap: _navigateToAnalytics,
                      ),
                      QuickAction(
                        icon: Icons.cloud_sync_rounded,
                        title: 'Sync Now',
                        subtitle: 'Force backup to cloud',
                        onTap: _showSyncSnackBar,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Financial Goals Section
                  FadeInWidget(
                    delay: const Duration(milliseconds: 200),
                    child: Column(
                      children: [
                        _buildSectionHeader('Financial Goals'),
                        _buildSettingsSection([
                          const FinancialGoalsFormWidget(),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Anti-Fragile Wallet Settings Section (NEW)
                  FadeInWidget(
                    delay: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        _buildSectionHeader('Virtual Vault Settings'),
                        _buildSettingsSection([
                          const AntiFragileSettingsWidget(),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Quick Actions Color Section (NEW)
                  FadeInWidget(
                    delay: const Duration(milliseconds: 250),
                    child: Column(
                      children: [
                        _buildSectionHeader('Quick Actions Style'),
                        _buildSettingsSection([
                          QuickActionsColorPicker(
                            selectedColor: _selectedQuickActionsColor,
                            onColorSelected: (color) {
                              setState(() {
                                _selectedQuickActionsColor = color;
                              });
                              // TODO: Save to shared preferences
                            },
                          ),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Theme Section
                  FadeInWidget(
                    delay: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        _buildSectionHeader('Appearance'),
                        _buildSettingsSection([
                          ThemePickerWidget(
                            onThemeChanged: (theme) {
                              // Trigger rebuild to show updated selection
                              setState(() {});
                            },
                          ),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // AI Settings Section (NEW)
                  FadeInWidget(
                    delay: const Duration(milliseconds: 350),
                    child: Column(
                      children: [
                        _buildSectionHeader('AI Financial Advisor'),
                        _buildSettingsSection([
                          ListTile(
                            leading: const Icon(Icons.smart_toy),
                            title: const Text('AI Settings'),
                            subtitle: const Text('Manage AI model & features'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AISettingsScreen(),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.psychology),
                            title: const Text('About AI Features'),
                            subtitle: const Text('Learn how AI helps you'),
                            trailing: const Icon(Icons.info_outline),
                            onTap: () {
                              _showAIDialog();
                            },
                          ),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Cloud Sync Section (NEW)
                  FadeInWidget(
                    delay: const Duration(milliseconds: 400),
                    child: Column(
                      children: [
                        _buildSectionHeader('Cloud Sync'),
                        _buildSettingsSection([
                          FirebaseConfigWidget(
                            cloudBackupRepo: _cloudBackupRepo,
                          ),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Backup & Export Section
                  FadeInWidget(
                    delay: const Duration(milliseconds: 500),
                    child: Column(
                      children: [
                        _buildSectionHeader('Backup & Export'),
                        _buildSettingsSection([
                          const BackupSectionWidget(),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // App Info Section
                  FadeInWidget(
                    delay: const Duration(milliseconds: 600),
                    child: Column(
                      children: [
                        _buildSectionHeader('About'),
                        _buildSettingsSection([
                          _buildInfoRow('Version', '1.0.0'),
                          _buildInfoRow('Build', 'MVP Complete'),
                          _buildInfoRow('Status', '🎉 Ready'),
                        ]),
                      ],
                    ),
                  ),

                  if (kDebugMode) ...[
                    const SizedBox(height: 32),
                    // Developer Tools Section
                    FadeInWidget(
                      delay: const Duration(milliseconds: 700),
                      child: Column(
                        children: [
                          _buildSectionHeader('Developer Tools'),
                          _buildSettingsSection([
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.bug_report,
                                  color: Colors.red),
                              title: Text(
                                'Error History',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.black,
                                ),
                              ),
                              subtitle: Text(
                                'View and export app error logs',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  color: AppColors.gray700,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right, size: 20),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ErrorHistoryScreen(),
                                  ),
                                );
                              },
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],

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
          color: AppColors.black,
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
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
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
              color: AppColors.gray700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _showAIDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.smart_toy, color: AppColors.fintechTeal),
            const SizedBox(width: 8),
            const Text('AI Financial Advisor'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FutureProof uses Llama-3.2-3B-Instruct, an advanced AI that runs completely on your device.',
                style: GoogleFonts.spaceGrotesk(fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                '💬 Natural Input',
                'Type expenses naturally like "Lunch at Chipotle \$18"',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                '🤖 Smart Insights',
                'Get personalized financial advice instead of generic tips',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                '🔐 100% Private',
                'All AI processing happens on your device. No data leaves.',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                '📱 Works Offline',
                'No internet connection needed after setup',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AISettingsScreen(),
                ),
              );
            },
            child: const Text('Setup AI'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: AppColors.gray700,
          ),
        ),
      ],
    );
  }
}
