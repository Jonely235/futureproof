import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

/// Design Tokens for FutureProof App
///
/// Central design system for consistent UI across all screens.
/// All spacing, sizing, and styling should reference these tokens.
class DesignTokens {
  DesignTokens._internal();

  // ============================================
  // SPACING SYSTEM (8px grid)
  // ============================================

  static const double spacingXxs = 4.0;
  static const double spacingXs = 8.0;
  static const double spacingSm = 12.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 20.0;
  static const double spacingXl = 24.0;
  static const double spacingXxl = 32.0;
  static const double spacing3xl = 48.0;

  // Edge insets helpers
  static const EdgeInsets paddingXs = EdgeInsets.all(spacingXs);
  static const EdgeInsets paddingSm = EdgeInsets.all(spacingSm);
  static const EdgeInsets paddingMd = EdgeInsets.all(spacingMd);
  static const EdgeInsets paddingLg = EdgeInsets.all(spacingLg);
  static const EdgeInsets paddingXl = EdgeInsets.all(spacingXl);

  static const EdgeInsets paddingHorizontalXs =
      EdgeInsets.symmetric(horizontal: spacingXs);
  static const EdgeInsets paddingHorizontalSm =
      EdgeInsets.symmetric(horizontal: spacingSm);
  static const EdgeInsets paddingHorizontalMd =
      EdgeInsets.symmetric(horizontal: spacingMd);
  static const EdgeInsets paddingHorizontalLg =
      EdgeInsets.symmetric(horizontal: spacingLg);
  static const EdgeInsets paddingHorizontalXl =
      EdgeInsets.symmetric(horizontal: spacingXl);

  static const EdgeInsets paddingVerticalXs =
      EdgeInsets.symmetric(vertical: spacingXs);
  static const EdgeInsets paddingVerticalSm =
      EdgeInsets.symmetric(vertical: spacingSm);
  static const EdgeInsets paddingVerticalMd =
      EdgeInsets.symmetric(vertical: spacingMd);
  static const EdgeInsets paddingVerticalLg =
      EdgeInsets.symmetric(vertical: spacingLg);
  static const EdgeInsets paddingVerticalXl =
      EdgeInsets.symmetric(vertical: spacingXl);

  // ============================================
  // BORDER RADIUS
  // ============================================

  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusCircle = 999.0;

  // Border radius helpers
  static const BorderRadius borderRadiusSm =
      BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd =
      BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg =
      BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl =
      BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderRadiusXxl =
      BorderRadius.all(Radius.circular(radiusXxl));

  // ============================================
  // TYPOGRAPHY
  // ============================================

  // Display headings - Playfair Display
  static const TextStyle displayLarge = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
  );

  // Headings - Playfair Display
  static TextStyle heading1({Color color = AppColors.black}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.5,
      );

  static TextStyle heading2({Color color = AppColors.black}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle heading3({Color color = AppColors.black}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // Body text - Space Grotesk
  static TextStyle bodyLarge({Color color = AppColors.black}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle bodyMedium({Color color = AppColors.black}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle bodySmall({Color color = AppColors.gray700}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  // Labels/Buttons - Space Grotesk
  static TextStyle labelLarge({Color color = AppColors.black}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle labelMedium({Color color = AppColors.black}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle labelSmall({Color color = AppColors.gray700}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.1,
      );

  // Section headers (uppercase labels)
  static TextStyle sectionHeader({Color color = AppColors.gray700}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.5,
      );

  // Monetary values - JetBrains Mono
  static TextStyle currencyLarge({Color color = AppColors.black}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -1,
      );

  static TextStyle currencyMedium({Color color = AppColors.black}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
      );

  static TextStyle currencySmall({Color color = AppColors.black}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color,
      );

  // ============================================
  // ELEVATION / SHADOWS
  // ============================================

  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static List<BoxShadow> shadowColored(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // ============================================
  // CARD STYLES
  // ============================================

  static BoxDecoration cardStyle({Color? backgroundColor}) => BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: borderRadiusLg,
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: shadowSm,
      );

  static BoxDecoration cardStyleElevated({Color? backgroundColor}) =>
      BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: borderRadiusLg,
        boxShadow: shadowMd,
      );

  static BoxDecoration cardStyleMinimal({Color? backgroundColor}) =>
      BoxDecoration(
        color: backgroundColor ?? AppColors.gray100,
        borderRadius: borderRadiusLg,
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      );

  // ============================================
  // BUTTON STYLES
  // ============================================

  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.black,
    foregroundColor: AppColors.white,
    disabledBackgroundColor: AppColors.border,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
    shape: RoundedRectangleBorder(
      borderRadius: borderRadiusLg,
    ),
    textStyle: GoogleFonts.spaceGrotesk(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
  );

  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: AppColors.black,
    side: const BorderSide(color: AppColors.black, width: 1.5),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(
      borderRadius: borderRadiusMd,
    ),
    textStyle: GoogleFonts.spaceGrotesk(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );

  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: AppColors.black,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: borderRadiusMd,
    ),
    textStyle: GoogleFonts.spaceGrotesk(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
  );

  // ============================================
  // INPUT STYLES
  // ============================================

  static InputDecoration inputStyle({String? hint}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: borderRadiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.black, width: 2),
        ),
        hintStyle: bodySmall(color: AppColors.gray500),
      );

  // ============================================
  // ICON SIZES
  // ============================================

  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // ============================================
  // SCAFFOLD BACKGROUNDS
  // ============================================

  static const Color scaffoldBackground = Color(0xFFF5F7FA);
  static const Color cardBackground = Colors.white;
  static const Color cardBackgroundSecondary = AppColors.gray100;

  // ============================================
  // APP BAR STYLES
  // ============================================

  static const AppBarTheme appBarThemeLight = AppBarTheme(
    centerTitle: false,
    elevation: 0,
    backgroundColor: Colors.white,
    foregroundColor: AppColors.black,
    iconTheme: IconThemeData(color: AppColors.black),
    titleTextStyle: TextStyle(
      color: AppColors.black,
      fontSize: 22,
      fontWeight: FontWeight.w600,
    ),
  );

  static const AppBarTheme appBarThemeTransparent = AppBarTheme(
    centerTitle: false,
    elevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.black,
    iconTheme: IconThemeData(color: AppColors.black),
    titleTextStyle: TextStyle(
      color: AppColors.black,
      fontSize: 22,
      fontWeight: FontWeight.w600,
    ),
  );

  // ============================================
  // BOTTOM NAVIGATION
  // ============================================

  static const BottomNavigationBarThemeData bottomNavTheme =
      BottomNavigationBarThemeData(
    elevation: 8,
    backgroundColor: Colors.white,
    selectedItemColor: AppColors.black,
    unselectedItemColor: AppColors.gray700,
    selectedLabelStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    unselectedLabelStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    type: BottomNavigationBarType.fixed,
  );

  // ============================================
  // COMMON WIDGET DECORATIONS
  // ============================================

  static BoxDecoration iconContainerStyle(Color color) => BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: borderRadiusMd,
      );

  static BoxDecoration gradientCardStyle(List<Color> colors) =>
      BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: borderRadiusXl,
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  // ============================================
  // ANIMATION DURATIONS
  // ============================================

  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  // ============================================
  // CURVES
  // ============================================

  static const Curve curveDefault = Curves.easeOut;
  static const Curve curveBounce = Curves.elasticOut;
}
