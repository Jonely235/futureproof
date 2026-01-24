import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_colors.dart';

/// Trend Indicator Widget
///
/// Shows spending trend with up/down arrow and percentage.
/// Color-coded: Green for good (down), Red for bad (up).
class TrendIndicator extends StatelessWidget {
  final double percentage;
  final String? label;
  final bool showIcon;

  const TrendIndicator({
    super.key,
    required this.percentage,
    this.label,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = percentage > 0;
    final isDown = percentage < 0;

    Color getColor() {
      if (isUp) return AppColors.danger; // Spending up = bad
      if (isDown) return AppColors.success; // Spending down = good
      return AppColors.gray500;
    }

    IconData getIcon() {
      if (isUp) return Icons.trending_up;
      if (isDown) return Icons.trending_down;
      return Icons.trending_flat;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: getColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(
          color: getColor(),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              getIcon(),
              size: 20,
              color: getColor(),
            ),
            const SizedBox(width: 6),
          ],
          if (label != null) ...[
            Text(
              label!,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            '${percentage.abs().toStringAsFixed(1)}%',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: getColor(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini Trend Indicator
///
/// Compact version for use in cards and lists.
class MiniTrendIndicator extends StatelessWidget {
  final double percentage;
  final bool isGoodWhenUp;

  const MiniTrendIndicator({
    super.key,
    required this.percentage,
    this.isGoodWhenUp = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = percentage > 0;
    final isDown = percentage < 0;

    bool isGood() {
      if (isGoodWhenUp) return isUp;
      return isDown; // For spending, down is good
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUp ? Icons.arrow_upward : Icons.arrow_downward,
          size: 16,
          color: isGood() ? AppColors.success : AppColors.danger,
        ),
        const SizedBox(width: 4),
        Text(
          '${percentage.abs().toStringAsFixed(1)}%',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isGood() ? AppColors.success : AppColors.danger,
          ),
        ),
      ],
    );
  }
}

/// Budget Health Indicator
///
/// Shows budget status with visual indicator.
class BudgetHealthIndicator extends StatelessWidget {
  final double spent;
  final double budget;
  final String? label;

  const BudgetHealthIndicator({
    super.key,
    required this.spent,
    required this.budget,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = budget > 0 ? (spent / budget) * 100 : 0;
    final isOverBudget = spent > budget;

    Color getStatusColor() {
      if (isOverBudget) return AppColors.danger;
      if (percentage > 80) return AppColors.gold;
      if (percentage > 60) return const Color(0xFFFFC107); // Yellow
      return AppColors.success;
    }

    String getStatusText() {
      if (isOverBudget) return 'Over Budget';
      if (percentage > 90) return 'Almost Full';
      if (percentage > 50) return 'On Track';
      return 'Good';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(
            label!,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: AppColors.gray700,
            ),
          ),
        Row(
          children: [
            Icon(
              isOverBudget ? Icons.warning : Icons.check_circle,
              size: 16,
              color: getStatusColor(),
            ),
            const SizedBox(width: 6),
            Text(
              getStatusText(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: getStatusColor(),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: AppColors.gray700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            backgroundColor: AppColors.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(getStatusColor()),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${spent.toStringAsFixed(0)} of \$${budget.toStringAsFixed(0)}',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }
}
