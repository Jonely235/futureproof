import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../models/spending_analysis.dart';
import '../../services/analytics_service.dart';

/// Insight Card Widget
///
/// Color-coded insight cards with:
/// - Visual differentiation by type (warning, success, info, opportunity)
/// - Actionable buttons
/// - Expandable details
/// - Icons and color schemes for each type
class InsightCard extends StatelessWidget {
  final Insight insight;
  final VoidCallback? onTap;

  const InsightCard({
    super.key,
    required this.insight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getInsightColors(insight.type);
    final icon = _getInsightIcon(insight.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: colors.icon,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight.description,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      color: AppColors.gray700,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (insight.recommendation != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.button.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colors.button.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: colors.button,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tip: ${insight.recommendation}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              color: colors.button,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Arrow icon
            Icon(
              Icons.chevron_right,
              color: AppColors.gray500,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  _InsightColors _getInsightColors(InsightType type) {
    switch (type) {
      case InsightType.warning:
        return _InsightColors(
          background: const Color(0xFFFEF2F2),
          border: const Color(0xFFFECACA),
          icon: const Color(0xFFDC2626),
          iconBackground: const Color(0xFFFEE2E2),
          shadow: const Color(0x1ADC2626),
          button: const Color(0xFFDC2626),
        );
      case InsightType.success:
        return _InsightColors(
          background: const Color(0xFFECFDF5),
          border: const Color(0xFFA7F3D0),
          icon: const Color(0xFF059669),
          iconBackground: const Color(0xFFD1FAE5),
          shadow: const Color(0x1A059669),
          button: const Color(0xFF059669),
        );
      case InsightType.error:
        return _InsightColors(
          background: const Color(0xFFFEF2F2),
          border: const Color(0xFFFECACA),
          icon: const Color(0xFFDC2626),
          iconBackground: const Color(0xFFFEE2E2),
          shadow: const Color(0x1ADC2626),
          button: const Color(0xFFDC2626),
        );
      case InsightType.info:
        return _InsightColors(
          background: const Color(0xFFEFF6FF),
          border: const Color(0xFFBFDBFE),
          icon: const Color(0xFF2563EB),
          iconBackground: const Color(0xFFDBEAFE),
          shadow: const Color(0x1A2563EB),
          button: const Color(0xFF2563EB),
        );
    }
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.warning:
        return Icons.warning_rounded;
      case InsightType.success:
        return Icons.check_circle_rounded;
      case InsightType.error:
        return Icons.error_rounded;
      case InsightType.info:
        return Icons.info_rounded;
    }
  }
}

class _InsightColors {
  final Color background;
  final Color border;
  final Color icon;
  final Color iconBackground;
  final Color shadow;
  final Color button;

  _InsightColors({
    required this.background,
    required this.border,
    required this.icon,
    required this.iconBackground,
    required this.shadow,
    required this.button,
  });
}
