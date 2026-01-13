import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom app theme with distinctive typography and refined palette
///
/// Design direction: "Refined Editorial Luxury"
/// - Editorial magazine aesthetic
/// - Premium financial experience
/// - Intentional, memorable design
class AppTheme {
  AppTheme._internal();

  // ============================================
  // TYPOGRAPHY
  // ============================================

  /// Custom text theme with distinctive font pairing
  static TextTheme get _textTheme {
    return TextTheme(
      // Display - Playfair Display, elegant serif
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.02,
        color: const Color(0xFF0A0A0A),
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.02,
        color: const Color(0xFF0A0A0A),
      ),
      displaySmall: GoogleFonts.playfairDisplay(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.01,
        color: const Color(0xFF0A0A0A),
      ),

      // Headlines - Playfair Display for editorial feel
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01,
        color: const Color(0xFF0A0A0A),
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01,
        color: const Color(0xFF0A0A0A),
      ),
      headlineSmall: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0A0A0A),
      ),

      // Titles - Space Grotesk for modern feel
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.01,
        color: const Color(0xFF0A0A0A),
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF0A0A0A),
      ),
      titleSmall: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.05,
        color: const Color(0xFF0A0A0A),
      ),

      // Body - Space Grotesk for readability
      bodyLarge: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: const Color(0xFF0A0A0A),
      ),
      bodyMedium: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: const Color(0xFF2D2D2D),
      ),
      bodySmall: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: const Color(0xFF6B6B6B),
      ),

      // Labels - Space Grotesk with letter-spacing
      labelLarge: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.05,
        color: const Color(0xFF0A0A0A),
      ),
      labelMedium: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: const Color(0xFF0A0A0A),
      ),
      labelSmall: GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: const Color(0xFF404040),
      ),
    );
  }

  // ============================================
  // LIGHT THEME
  // ============================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0A0A0A),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFF5F5F5),
        onPrimaryContainer: Color(0xFF0A0A0A),
        secondary: Color(0xFF6B6B6B),
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFE0E0E0),
        onSecondaryContainer: Color(0xFF1A1A1A),
        tertiary: Color(0xFF2D2D2D),
        onTertiary: Color(0xFFFFFFFF),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF0A0A0A),
        surfaceContainerHighest: Color(0xFFF5F5F5),
        onSurfaceVariant: Color(0xFF6B6B6B),
        error: Color(0xFFD4483A),
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFFDADF2),
        outline: Color(0xFFBDBDBD),
        outlineVariant: Color(0xFFE0E0E0),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFF1A1A1A),
        onInverseSurface: Color(0xFFFFFFFF),
        inversePrimary: Color(0xFFFFFFFF),
      ),

      // Typography
      textTheme: _textTheme,

      // Scaffold
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),

      // App Bar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFFFFFFFF),
        foregroundColor: const Color(0xFF0A0A0A),
        iconTheme: const IconThemeData(color: Color(0xFF0A0A0A)),
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: const Color(0xFF0A0A0A),
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shadowColor: Color(0x14000000),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A0A0A),
          foregroundColor: const Color(0xFFFFFFFF),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0A0A0A),
          side: const BorderSide(color: Color(0xFF0A0A0A), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF0A0A0A),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0A0A0A), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD4483A), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD4483A), width: 2),
        ),
        labelStyle: GoogleFonts.spaceGrotesk(
          color: const Color(0xFF6B6B6B),
          fontSize: 15,
        ),
        hintStyle: GoogleFonts.spaceGrotesk(
          color: const Color(0xFF9E9E9E),
          fontSize: 15,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: Color(0xFF0A0A0A),
        size: 24,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
        space: 1,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A1A1A),
        contentTextStyle: GoogleFonts.spaceGrotesk(
          color: const Color(0xFFFFFFFF),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 8,
        backgroundColor: const Color(0xFFFFFFFF),
        selectedItemColor: const Color(0xFF0A0A0A),
        unselectedItemColor: const Color(0xFF6B6B6B),
        selectedLabelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: Color(0xFF0A0A0A),
        foregroundColor: Color(0xFFFFFFFF),
        shape: CircleBorder(),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF5F5F5),
        selectedColor: const Color(0xFF0A0A0A),
        labelStyle: GoogleFonts.spaceGrotesk(
          color: const Color(0xFF0A0A0A),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
      ),

      // Dialog Theme
      dialogTheme: const DialogThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        backgroundColor: Color(0xFFFFFFFF),
        titleTextStyle: TextStyle(
          color: Color(0xFF0A0A0A),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 14,
        ),
      ),
    );
  }

  // ============================================
  // DARK THEME (Future Implementation)
  // ============================================

  static ThemeData get darkTheme {
    // TODO: Implement in Sprint 5
    return lightTheme;
  }
}
