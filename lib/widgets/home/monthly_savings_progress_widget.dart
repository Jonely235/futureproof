import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../design/design_tokens.dart';

/// Monthly Savings Progress Widget
///
/// Shows progress toward monthly savings goal.
/// Motivates users to save more each month.
class MonthlySavingsProgressWidget extends StatelessWidget {
  final double monthlyIncome;
  final double totalSpent;
  final double savingsGoal;

  const MonthlySavingsProgressWidget({
    super.key,
    required this.monthlyIncome,
    required this.totalSpent,
    required this.savingsGoal,
  });

  double get savedSoFar => monthlyIncome - totalSpent;
  double get percentage => (savedSoFar / savingsGoal * 100).clamp(0, 100);
  bool get isGoalReached => savedSoFar >= savingsGoal;
  int get daysRemaining => DateTime(DateTime.now().year, DateTime.now().month + 1, 0)
      .difference(DateTime.now()).inDays;

  @override
  Widget build(BuildContext context) {
    final savedFormatted = '\$${savedSoFar.abs().toStringAsFixed(0)}';
    final progressColor = savedSoFar >= 0
        ? AppColors.fintechTeal
        : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: DesignTokens.borderRadiusLg,
        border: Border.all(
          color: savedSoFar >= 0
              ? AppColors.fintechTeal.withOpacity(0.2)
              : AppColors.danger.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Savings Progress',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isGoalReached
                      ? AppColors.success.withOpacity(0.15)
                      : AppColors.gray200,
                  borderRadius: DesignTokens.borderRadiusSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isGoalReached)
                      Icon(Icons.check_circle, size: 12, color: AppColors.success),
                    if (isGoalReached) const SizedBox(width: 4),
                    Text(
                      isGoalReached ? 'Goal Reached!' : '${percentage.toStringAsFixed(0)}%',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isGoalReached ? AppColors.success : AppColors.gray700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Main Value
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                savedFormatted,
                style: DesignTokens.currencyMedium(color: progressColor),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'saved',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: AppColors.gray700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Subtitle
          Text(
            'Goal: \$${savingsGoal.toStringAsFixed(0)} • $daysRemaining days left',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(
                savedSoFar >= 0 ? AppColors.fintechTeal : AppColors.danger,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
