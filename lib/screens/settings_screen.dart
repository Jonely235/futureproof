import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_colors.dart';
import '../widgets/backup_section_widget.dart';
import '../widgets/financial_goals_form_widget.dart';
import '../widgets/theme_picker_widget.dart';
import 'debug/error_history_screen.dart';

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

                  // Financial Goals Section
                  _buildSectionHeader('Financial Goals'),
                  _buildSettingsSection([
                    const FinancialGoalsFormWidget(),
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
                    const BackupSectionWidget(),
                  ]),

                  const SizedBox(height: 32),

                  // App Info Section
                  _buildSectionHeader('About'),
                  _buildSettingsSection([
                    _buildInfoRow('Version', '1.0.0'),
                    _buildInfoRow('Build', 'MVP Complete'),
                    _buildInfoRow('Status', '🎉 Ready'),
                  ]),

                  if (kDebugMode) ...[
                    const SizedBox(height: 32),
                    // Developer Tools Section
                    _buildSectionHeader('Developer Tools'),
                    _buildSettingsSection([
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            const Icon(Icons.bug_report, color: Colors.red),
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
                              builder: (context) => const ErrorHistoryScreen(),
                            ),
                          );
                        },
                      ),
                    ]),
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
