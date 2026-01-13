import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_colors.dart';
import '../services/analytics_service.dart';
import '../utils/app_logger.dart';

/// Smart Insights Widget
///
/// Displays financial insights including stat cards, progress indicators,
/// daily tips, and category alerts based on spending analytics.
class SmartInsightsWidget extends StatelessWidget {
  const SmartInsightsWidget({super.key});

  @override
  Widget build(BuildContext context) {
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

        AppLogger.ui.info('Smart insights displayed: '
            'remaining=\$$remaining.toStringAsFixed(0)}, '
            'savingsRate=${(savingsRate * 100).toInt()}%');

        return Column(
          children: [
            // Section Header
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppColors.black,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Smart Insights',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
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
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCircularProgressCard(
                    value: savingsRate.clamp(0.0, 1.0),
                    label: 'Budget OK',
                    color: isOnTrack ? AppColors.success : AppColors.gold,
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
                    color: AppColors.gold,
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
            if (stats['topCategory'] != null &&
                (stats['topCategoryAmount'] as double) > monthlyIncome * 0.3)
              _buildCategoryAlert(
                category: stats['topCategory'] as String,
                amount: stats['topCategoryAmount'] as double,
              ),
          ],
        );
      },
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
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
              color: AppColors.gray700,
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
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
                  backgroundColor: color.withValues(alpha: 0.2),
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
              color: AppColors.gray700,
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
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb,
            color: AppColors.gold,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: AppColors.black,
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
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.danger,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning,
            color: AppColors.danger,
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
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$category: \$${amount.toStringAsFixed(0)} this month',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: AppColors.black,
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
}
