import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/theme_manager.dart';
import '../utils/app_logger.dart';
import '../config/app_colors.dart';
import '../design/design_tokens.dart';

/// Theme Picker Widget
///
/// Displays available theme options and allows users to switch themes.
/// Each theme shows a preview color, name, and description.
class ThemePickerWidget extends StatelessWidget {
  /// Callback when theme is changed
  final Function(AppTheme)? onThemeChanged;

  const ThemePickerWidget({
    super.key,
    this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a theme',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(height: 16),
            ...ThemeManager.availableThemes.map((theme) {
              final isSelected = themeManager.currentTheme == theme;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await themeManager.setTheme(theme);
                    AppLogger.ui.info('Theme changed to ${theme.displayName}');
                    onThemeChanged?.call(theme);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.previewColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      border: Border.all(
                        color: isSelected
                            ? theme.previewColor
                            : theme.previewColor.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.previewColor,
                            borderRadius: DesignTokens.borderRadiusSm,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                theme.displayName,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                theme.description,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  color: AppColors.gray700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.radio_button_checked,
                            color: theme.previewColor,
                            size: 24,
                          )
                        else
                          const Icon(
                            Icons.radio_button_unchecked,
                            color: AppColors.gray300,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
