import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_colors.dart';
import '../widgets/backup_section_widget.dart';
import '../widgets/financial_goals_form_widget.dart';
import '../widgets/firebase_config_widget.dart';
import '../widgets/theme_picker_widget.dart';
import '../widgets/ui_helpers.dart';
import '../data/repositories/firebase_backup_repository_impl.dart';
import 'debug/error_history_screen.dart';
import 'add_expense_screen.dart';
import 'analytics_dashboard_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _cloudBackupRepo = FirebaseBackupRepositoryImpl();
  }

  @override
  void dispose() {
    _cloudBackupRepo.dispose();
    super.dispose();
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

                  // Quick Actions Card
                  FadeInWidget(
                    delay: const Duration(milliseconds: 100),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.black,
                            AppColors.charcoal,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'Quick Actions',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SettingsTile(
                            icon: Icons.add_circle_outline,
                            iconColor: Colors.white,
                            title: 'Add Expense',
                            subtitle: 'Quickly add a new transaction',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddExpenseScreen(),
                                ),
                              );
                            },
                            showArrow: true,
                          ),
                          const Divider(height: 1, color: Colors.white24),
                          SettingsTile(
                            icon: Icons.analytics_outlined,
                            iconColor: Colors.white,
                            title: 'View Analytics',
                            subtitle: 'See your spending insights',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AnalyticsDashboardScreen(),
                                ),
                              );
                            },
                            showArrow: true,
                          ),
                          const Divider(height: 1, color: Colors.white24),
                          SettingsTile(
                            icon: Icons.cloud_sync_outlined,
                            iconColor: Colors.white,
                            title: 'Sync Now',
                            subtitle: 'Force backup to cloud',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sync started...'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            showArrow: false,
                          ),
                        ],
                      ),
                    ),
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
}
