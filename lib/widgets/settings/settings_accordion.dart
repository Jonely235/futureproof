import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../providers/settings_expansion_provider.dart';

/// Settings Accordion Section Widget
///
/// An expandable card component for settings sections with:
/// - Collapsible header with icon, title, summary, and chevron
/// - Smooth expand/collapse animation (300ms easeInOut)
/// - Haptic feedback on tap
/// - Consistent styling matching "Refined Editorial Luxury" design
class SettingsAccordionSection extends StatelessWidget {
  final String sectionId;
  final IconData icon;
  final String title;
  final String summary;
  final List<Widget> children;
  final Color iconColor;
  final bool initiallyExpanded;
  final bool isExpanded;

  const SettingsAccordionSection({
    super.key,
    required this.sectionId,
    required this.icon,
    required this.title,
    required this.summary,
    required this.children,
    required this.isExpanded,
    this.iconColor = AppColors.fintechTeal,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsExpansionProvider>(
      builder: (context, expansionProvider, child) {
        final expanded = expansionProvider.isExpanded(sectionId);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (always visible, tappable)
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  expansionProvider.toggle(sectionId);
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Icon with colored background
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Title and summary
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              summary,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.gray700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Animated chevron
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.gray700,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Expandable content
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: expanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: children,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Settings Accordion Container
///
/// Groups multiple SettingsAccordionSection widgets together
class SettingsAccordion extends StatelessWidget {
  final List<Widget> children;

  const SettingsAccordion({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
