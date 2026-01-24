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
/// Displays available theme options with enhanced visual previews.
/// Each theme shows full color preview with gradient and live preview.
class ThemePickerWidget extends StatefulWidget {
  /// Callback when theme is changed
  final Function(AppTheme)? onThemeChanged;

  const ThemePickerWidget({
    super.key,
    this.onThemeChanged,
  });

  @override
  State<ThemePickerWidget> createState() => _ThemePickerWidgetState();
}

class _ThemePickerWidgetState extends State<ThemePickerWidget> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark mode toggle
            _buildDarkModeToggle(themeManager),
            const SizedBox(height: 20),

            Text(
              'Choose a theme',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: AppColors.gray700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Theme grid
            ...ThemeManager.availableThemes.map((theme) {
              final isSelected = themeManager.currentTheme == theme;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildThemeCard(theme, isSelected, themeManager),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildDarkModeToggle(ThemeManager themeManager) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            _isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: AppColors.gray700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            _isDarkMode ? 'Dark Mode' : 'Light Mode',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const Spacer(),
          Switch(
            value: _isDarkMode,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              setState(() {
                _isDarkMode = value;
              });
              AppLogger.ui.info('Dark mode: $_isDarkMode');
            },
            activeColor: AppColors.fintechTeal,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(AppTheme theme, bool isSelected, ThemeManager themeManager) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        await themeManager.setTheme(theme);
        AppLogger.ui.info('Theme changed to ${theme.displayName}');
        widget.onThemeChanged?.call(theme);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.previewColor.withValues(alpha: _isDarkMode ? 0.15 : 0.08),
              theme.previewColor.withValues(alpha: _isDarkMode ? 0.05 : 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(
            color: isSelected
                ? theme.previewColor
                : theme.previewColor.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.previewColor.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Enhanced color preview with gradient
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.previewColor,
                    theme.previewColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: DesignTokens.borderRadiusMd,
                boxShadow: [
                  BoxShadow(
                    color: theme.previewColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 28,
                    )
                  : Icon(
                      _getThemeIcon(theme),
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 28,
                    ),
            ),
            const SizedBox(width: 16),

            // Theme info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.displayName,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
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

            // Selection indicator with animation
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isSelected ? 1.0 : 0.85,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? theme.previewColor : AppColors.gray200,
                  shape: BoxShape.circle,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getThemeIcon(AppTheme theme) {
    switch (theme) {
      case AppTheme.editorial:
        return Icons.auto_stories;
      case AppTheme.oceanCalm:
        return Icons.waves;
      case AppTheme.sunsetWarm:
        return Icons.wb_sunny;
      case AppTheme.forest:
        return Icons.nature;
      case AppTheme.lavenderDream:
        return Icons.local_florist;
      case AppTheme.midnightBlue:
        return Icons.nightlight;
      case AppTheme.cherryBlossom:
        return Icons.favorite;
      case AppTheme.goldenHour:
        return Icons.wb_twilight;
      case AppTheme.arcticFrost:
        return Icons.ac_unit;
      case AppTheme.obsidianDark:
        return Icons.bedtime;
    }
  }
}
