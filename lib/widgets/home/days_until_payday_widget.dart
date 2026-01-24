import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../design/design_tokens.dart';

/// Days Until Payday Widget
///
/// Shows a countdown to the next payday.
/// Assumes payday on the 1st and 15th of each month.
class DaysUntilPaydayWidget extends StatelessWidget {
  final DateTime? currentDate;

  const DaysUntilPaydayWidget({
    super.key,
    this.currentDate,
  });

  /// Calculate next payday (1st or 15th of month)
  DateTime _getNextPayday(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final firstOfThisMonth = DateTime(now.year, now.month, 1);
    final fifteenthOfThisMonth = DateTime(now.year, now.month, 15);
    final firstOfNextMonth = DateTime(now.year, now.month + 1, 1);

    if (today.isBefore(firstOfThisMonth) || today.isAtSameMomentAs(firstOfThisMonth)) {
      return firstOfThisMonth;
    } else if (today.isBefore(fifteenthOfThisMonth) || today.isAtSameMomentAs(fifteenthOfThisMonth)) {
      return fifteenthOfThisMonth;
    } else {
      return firstOfNextMonth;
    }
  }

  int _getDaysUntil(DateTime now, DateTime payday) {
    return payday.difference(now).inDays;
  }

  String _getPaydayLabel(DateTime payday) {
    final now = currentDate ?? DateTime.now();
    final days = _getDaysUntil(now, payday);

    if (days == 0) return 'Today!';
    if (days == 1) return 'Tomorrow';
    return 'In $days days';
  }

  @override
  Widget build(BuildContext context) {
    final now = currentDate ?? DateTime.now();
    final nextPayday = _getNextPayday(now);
    final daysUntil = _getDaysUntil(now, nextPayday);
    final label = _getPaydayLabel(nextPayday);

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
      child: Row(
        children: [
          // Calendar Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.fintechTeal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: AppColors.fintechTeal,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Payday',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
          // Date
          Text(
            '${nextPayday.month}/${nextPayday.day}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
          ),
        ],
      ),
    );
  }
}
