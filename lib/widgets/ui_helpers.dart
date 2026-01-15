import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

/// Gradient icon container for fintech aesthetic
///
/// Provides a consistent gradient background for icons with
/// enhanced shadows and rounded corners.
class GradientIconContainer extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final double size;
  final Color? iconColor;

  const GradientIconContainer({
    super.key,
    required this.icon,
    required this.gradient,
    this.size = 40,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: iconColor ?? Colors.white,
        size: size * 0.5,
      ),
    );
  }
}

/// Fade-in animation wrapper with optional slide-up effect
///
/// Provides smooth fade-in animations for widgets.
/// Can be customized with duration, delay, and curve.
class FadeInWidget extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset slideOffset;

  const FadeInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.curve = Curves.easeOut,
    this.slideOffset = const Offset(0, 20),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: slideOffset * (1 - value),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Settings tile helper with colored icon
///
/// Provides a consistent settings tile layout with:
/// - Colored icon container
/// - Title and optional subtitle
/// - Tap handling
/// - Optional trailing widget
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showArrow;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),

            // Title & subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: AppColors.gray700,
                      ),
                    ),
                ],
              ),
            ),

            // Trailing or arrow
            if (trailing != null) trailing!,
            if (trailing == null && showArrow)
              Icon(
                Icons.chevron_right,
                color: AppColors.gray700,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

/// Fintech-themed stat card component
///
/// Features:
/// - Gradient icon container
/// - Enhanced shadows
/// - 20px border radius
/// - Optional tap handling
class FintechStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  final bool isPositive;
  final VoidCallback? onTap;

  const FintechStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.gradientColors = const [
      Color(0xFF00BFA5),
      Color(0xFF0091EA),
    ],
    this.isPositive = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: gradientColors.first.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon with gradient background
            GradientIconContainer(
              icon: icon,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              size: 48,
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(height: 8),

            // Value
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isPositive ? gradientColors.first : AppColors.danger,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
