import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../providers/settings_expansion_provider.dart';
import '../providers/financial_goals_provider.dart';
import '../providers/ai_provider.dart';
import '../widgets/backup_section_widget.dart';
import '../widgets/financial_goals_form_widget.dart';
import '../widgets/settings/anti_fragile_settings_widget.dart';
import '../widgets/firebase_config_widget.dart';
import '../widgets/settings/quick_actions_color_picker.dart';
import '../widgets/settings/settings_accordion.dart';
import '../widgets/theme_picker_widget.dart';
import '../widgets/ui_helpers.dart';
import '../data/repositories/firebase_backup_repository_impl.dart';
import 'debug/error_history_screen.dart';
import 'ai_settings_screen.dart';

/// Settings Screen
///
/// Redesigned with accordion-style progressive disclosure.
/// Sections expand/collapse with smooth animations.
/// Premium Quick Actions card removed (moved to home screen).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final FirebaseBackupRepositoryImpl _cloudBackupRepo;
  Color _selectedQuickActionsColor = AppColors.fintechTeal;
  DateTime? _lastBackupTime;

  @override
  void initState() {
    super.initState();
    _cloudBackupRepo = FirebaseBackupRepositoryImpl();

    // Initialize expansion state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsExpansionProvider>().loadState();
      context.read<FinancialGoalsProvider>().loadGoals();
    });

    _loadSavedColor();
  }

  Future<void> _loadSavedColor() async {
    // Load saved color from shared preferences
    // For now, just use the default
    setState(() {
      _selectedQuickActionsColor = AppColors.fintechTeal;
    });

    // Load last backup time
    _loadLastBackupTime();
  }

  Future<void> _loadLastBackupTime() async {
    final lastBackup = await _cloudBackupRepo.getLastBackupTime();
    if (mounted) {
      setState(() {
        _lastBackupTime = lastBackup;
      });
    }
  }

  String _formatBackupTime(DateTime? time) {
    if (time == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        final minutes = difference.inMinutes;
        return minutes <= 1 ? 'Just now' : '$minutes minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${time.month}/${time.day}/${time.year}';
    }
  }

  @override
  void dispose() {
    _cloudBackupRepo.dispose();
    super.dispose();
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

          // Content with Accordion
          SliverToBoxAdapter(
            child: Consumer2<SettingsExpansionProvider, FinancialGoalsProvider>(
              builder: (context, expansionProvider, goalsProvider, child) {
                return SettingsAccordion(
                  children: [
                    const SizedBox(height: 16),

                    // ========== FINANCE SECTION (Expanded by default) ==========
                    FadeInWidget(
                      delay: const Duration(milliseconds: 200),
                      child: SettingsAccordionSection(
                        sectionId: 'finance',
                        icon: Icons.account_balance_wallet,
                        title: 'Finance',
                        summary: _buildFinanceSummary(goalsProvider),
                        iconColor: AppColors.fintechTeal,
                        isExpanded: expansionProvider.isExpanded('finance'),
                        children: [
                          const FinancialGoalsFormWidget(),
                          const SizedBox(height: 16),
                          const AntiFragileSettingsWidget(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ========== APPEARANCE SECTION (Expanded by default) ==========
                    FadeInWidget(
                      delay: const Duration(milliseconds: 300),
                      child: SettingsAccordionSection(
                        sectionId: 'appearance',
                        icon: Icons.palette,
                        title: 'Appearance',
                        summary: _buildAppearanceSummary(),
                        iconColor: AppColors.gold,
                        isExpanded: expansionProvider.isExpanded('appearance'),
                        children: [
                          ThemePickerWidget(
                            onThemeChanged: (theme) {
                              // Trigger rebuild
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Quick Actions Style',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          QuickActionsColorPicker(
                            selectedColor: _selectedQuickActionsColor,
                            onColorSelected: (color) {
                              setState(() {
                                _selectedQuickActionsColor = color;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ========== AI SETTINGS SECTION (Expanded by default) ==========
                    FadeInWidget(
                      delay: const Duration(milliseconds: 400),
                      child: SettingsAccordionSection(
                        sectionId: 'ai',
                        icon: Icons.smart_toy,
                        title: 'AI Settings',
                        summary: _buildAISummary(),
                        iconColor: AppColors.fintechIndigo,
                        isExpanded: expansionProvider.isExpanded('ai'),
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.settings),
                            title: Text(
                              'AI Configuration',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                            ),
                            subtitle: Text(
                              'Manage AI model & features',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: AppColors.gray700,
                              ),
                            ),
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
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.psychology),
                            title: Text(
                              'About AI Features',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                            ),
                            subtitle: Text(
                              'Learn how AI helps you',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: AppColors.gray700,
                              ),
                            ),
                            trailing: const Icon(Icons.info_outline),
                            onTap: () {
                              _showAIDialog();
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ========== DATA & SYNC SECTION (Collapsed by default) ==========
                    FadeInWidget(
                      delay: const Duration(milliseconds: 500),
                      child: SettingsAccordionSection(
                        sectionId: 'data',
                        icon: Icons.cloud_sync,
                        title: 'Data & Sync',
                        summary: _buildDataSyncSummary(),
                        iconColor: AppColors.fintechTrust,
                        isExpanded: expansionProvider.isExpanded('data'),
                        children: [
                          FirebaseConfigWidget(
                            cloudBackupRepo: _cloudBackupRepo,
                          ),
                          const SizedBox(height: 16),
                          const BackupSectionWidget(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ========== ABOUT SECTION (Collapsed by default) ==========
                    FadeInWidget(
                      delay: const Duration(milliseconds: 600),
                      child: SettingsAccordionSection(
                        sectionId: 'about',
                        icon: Icons.info,
                        title: 'About',
                        summary: 'Version 1.0.0',
                        iconColor: AppColors.gray700,
                        isExpanded: expansionProvider.isExpanded('about'),
                        children: [
                          _buildInfoRow('Version', '1.0.0'),
                          _buildInfoRow('Build', 'MVP Complete'),
                          _buildInfoRow('Status', '🎉 Ready'),
                        ],
                      ),
                    ),

                    // ========== ADVANCED SECTION (Collapsed by default, debug only) ==========
                    if (kDebugMode)
                      FadeInWidget(
                        delay: const Duration(milliseconds: 700),
                        child: SettingsAccordionSection(
                          sectionId: 'advanced',
                          icon: Icons.bug_report,
                          title: 'Advanced',
                          summary: 'Error logs, diagnostics',
                          iconColor: AppColors.danger,
                          isExpanded: expansionProvider.isExpanded('advanced'),
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.bug_report,
                                  color: Colors.red),
                              title: Text(
                                'Error History',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
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
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build finance section summary
  String _buildFinanceSummary(FinancialGoalsProvider provider) {
    if (provider.isLoading) {
      return 'Loading...';
    }
    return 'Income: ${provider.formattedIncome} | Reserve: \$500';
  }

  /// Build appearance section summary
  String _buildAppearanceSummary() {
    return 'Theme: System | Accent: Teal';
  }

  /// Build AI section summary
  String _buildAISummary() {
    final aiProvider = context.read<AIProvider>();
    final isReady = aiProvider.isReady;
    return isReady ? 'Model: Ready' : 'Model: Not Setup';
  }

  /// Build data & sync section summary
  String _buildDataSyncSummary() {
    return 'Last backup: ${_formatBackupTime(_lastBackupTime)}';
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
