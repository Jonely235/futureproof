import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../design/design_tokens.dart';

/// Daily Spending Limit Widget
///
/// Shows daily spending budget with progress bar.
/// Helps users track their daily spending against budget.
class DailySpendingLimitWidget extends StatelessWidget {
  final double dailyLimit;
  final double spentToday;
  final int daysRemainingInMonth;

  const DailySpendingLimitWidget({
    super.key,
    required this.dailyLimit,
    required this.spentToday,
    required this.daysRemainingInMonth,
  });

  double get percentage {
    if (dailyLimit <= 0) return 0;
    return (spentToday / dailyLimit * 100).clamp(0, 100);
  }

  double get remaining => dailyLimit - spentToday;

  bool get isOverBudget => spentToday > dailyLimit;

  Color _getProgressColor() {
    if (isOverBudget) return AppColors.danger;
    if (percentage > 80) return const Color(0xFFFF9800);
    return AppColors.fintechTeal;
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = _getProgressColor();
    final remainingFormatted = remaining.abs().toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: DesignTokens.borderRadiusLg,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: progressColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                    ),
                    child: Icon(
                      isOverBudget ? Icons.warning : Icons.wallet,
                      color: progressColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Daily Budget',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray700,
                    ),
                  ),
                ],
              ),
              Text(
                '\$${dailyLimit.toStringAsFixed(0)}',
                style: DesignTokens.currencySmall(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),

          // Status Text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOverBudget
                    ? 'Over by \$$remainingFormatted'
                    : 'Remaining: \$$remainingFormatted',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: progressColor,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: AppColors.gray700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
