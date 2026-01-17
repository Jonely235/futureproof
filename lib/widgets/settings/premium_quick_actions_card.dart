import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';

/// Premium Quick Actions Card
///
/// A boldly designed Quick Actions card with:
/// - Geometric layered composition
/// - Staggered animated entry
/// - Icon-first design with scale animations
/// - Premium glassmorphism effects
/// - Micro-interactions on press/hover
class PremiumQuickActionsCard extends StatefulWidget {
  final Color primaryColor;
  final List<QuickAction> actions;

  const PremiumQuickActionsCard({
    super.key,
    required this.primaryColor,
    required this.actions,
  });

  @override
  State<PremiumQuickActionsCard> createState() => _PremiumQuickActionsCardState();
}

class _PremiumQuickActionsCardState extends State<PremiumQuickActionsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          // Background layers
          _buildBackgroundLayers(),

          // Content
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryColor.withOpacity(0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.primaryColor.withOpacity(0.15),
                          widget.primaryColor.withOpacity(0.05),
                          Colors.black.withOpacity(0.3),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        _buildHeader(),

                        const SizedBox(height: 32),

                        // Actions
                        ...widget.actions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final action = entry.value;
                          return _buildAnimatedActionItem(index, action);
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundLayers() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Geometric accent shape - top right
            Positioned(
              top: -60,
              right: -60,
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.primaryColor.withOpacity(0.3),
                        widget.primaryColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
            ),

            // Secondary accent - bottom left
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.primaryColor.withOpacity(0.2),
                      widget.primaryColor.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Decorative icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.primaryColor,
                widget.primaryColor.withOpacity(0.6),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.bolt_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),

        const SizedBox(width: 16),

        // Title
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Fast access to your essentials',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFE8E8E8), // Light gray for contrast
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedActionItem(int index, QuickAction action) {
    return AnimatedBuilder(
      animation: _fadeInAnimation,
      builder: (context, child) {
        final staggerDelay = index * 0.15;
        final animationValue = math.max(
          0.0,
          (_fadeInAnimation.value - staggerDelay) / (1 - staggerDelay),
        );

        return Transform.translate(
          offset: Offset(0, 20 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildActionButton(action),
      ),
    );
  }

  Widget _buildActionButton(QuickAction action) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Haptic feedback
          // Then navigate
          action.onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                        widget.primaryColor.withOpacity(0.2),
                        widget.primaryColor.withOpacity(0.1),
                      ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.primaryColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  action.icon,
                  color: widget.primaryColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFE0E0E0), // Much lighter gray for contrast
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
