import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/analytics_service.dart';

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
      print('Error loading settings: $e');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid monthly income'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (savings == null || savings < 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid savings goal'),
          backgroundColor: Colors.red,
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings saved successfully'),
              backgroundColor: Color(0xFF0A0A0A),
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Don't navigate away automatically - let user decide when to leave
        }
      } else {
        throw Exception('Settings verification failed');
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings reset to defaults'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        HapticFeedback.heavyImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildBudgetRecommendations() {
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
        final savings = stats['savings'] as double;
        final savingsRate = stats['savingsRate'] as double;
        final isOnTrack = stats['isOnTrack'] as bool;

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Budget Recommendations',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Current spending vs income
                _buildRecommendationItem(
                  icon: Icons.account_balance_wallet,
                  title: 'Spending Analysis',
                  description: 'You\'re spending \$${totalSpending.toStringAsFixed(0)} of \$${monthlyIncome.toStringAsFixed(0)} monthly income',
                  color: Colors.grey[900]!,
                ),
                const SizedBox(height: 12),

                // Savings status
                _buildRecommendationItem(
                  icon: isOnTrack ? Icons.check_circle : Icons.warning,
                  title: isOnTrack ? 'On Track!' : 'Savings Alert',
                  description: isOnTrack
                      ? 'Great job! You\'re saving \$${savings.toStringAsFixed(0)}/month (${savingsRate.toStringAsFixed(1)}% rate)'
                      : 'You\'re saving \$${savings.toStringAsFixed(0)}/month, which is below your goal. Consider reducing expenses.',
                  color: isOnTrack ? Colors.grey[800]! : Colors.grey[700]!,
                ),
                const SizedBox(height: 12),

                // Recommended budget allocation
                _buildRecommendationItem(
                  icon: Icons.lightbulb,
                  title: 'Recommended Budget Allocation',
                  description: _getBudgetRecommendation(monthlyIncome),
                  color: Colors.grey[900]!,
                ),
                const SizedBox(height: 12),

                // Top spending category
                if (stats['topCategory'] != null)
                  _buildRecommendationItem(
                    icon: Icons.trending_up,
                    title: 'Highest Expense Category',
                    description: '${stats['topCategory']} at \$${(stats['topCategoryAmount'] as double).toStringAsFixed(0)}/month. Consider if this can be reduced.',
                    color: Colors.grey[800]!,
                  ),
              ],
            ),
          ),
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

  String _getBudgetRecommendation(double income) {
    // 50/30/20 rule: 50% needs, 30% wants, 20% savings
    final needs = income * 0.50;
    final wants = income * 0.30;
    final savings = income * 0.20;

    return 'Based on your income, consider: \$${needs.toStringAsFixed(0)} for needs (housing, food), \$${wants.toStringAsFixed(0)} for wants (entertainment, dining), and \$${savings.toStringAsFixed(0)} for savings.';
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
      backgroundColor: const Color(0xFFFAFAFA),
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
                    background: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Settings',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0A0A0A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage your financial preferences',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              color: const Color(0xFF6B6B6B),
                            ),
                          ),
                        ],
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

                        // Budget Recommendations Section
                        _buildSectionHeader('AI Recommendations'),
                        _buildSettingsSection([
                          _buildBudgetRecommendations(),
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
                                    backgroundColor: const Color(0xFF0A0A0A),
                                    foregroundColor: const Color(0xFFFFFFFF),
                                    disabledBackgroundColor: const Color(0xFFE0E0E0),
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
                                                AlwaysStoppedAnimation<Color>(Color(0xFF0A0A0A)),
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
                                    foregroundColor: const Color(0xFFD4483A),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    side: const BorderSide(color: Color(0xFFD4483A)),
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
          color: const Color(0xFF0A0A0A),
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
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A0A0A).withOpacity(0.03),
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
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF0A0A0A),
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
                      color: const Color(0xFF0A0A0A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: const Color(0xFF6B6B6B),
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
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE0E0E0),
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
              color: const Color(0xFF6B6B6B),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0A0A0A),
            ),
          ),
        ],
      ),
    );
  }
}
