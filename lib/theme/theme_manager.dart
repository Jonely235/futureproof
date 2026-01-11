import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages theme selection and persistence
class ThemeManager {
  static const String _themeKey = 'selected_theme';

  // Available themes
  static const List<AppTheme> availableThemes = [
    AppTheme.editorial,
    AppTheme.oceanCalm,
    AppTheme.sunsetWarm,
    AppTheme.forest,
  ];

  // Current theme
  AppTheme _currentTheme = AppTheme.editorial;

  /// Get current theme
  AppTheme get currentTheme => _currentTheme;

  /// Initialize theme from SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 0;
      _currentTheme = availableThemes[themeIndex.clamp(0, availableThemes.length - 1)];
    } catch (e) {
      // Default to editorial if loading fails
      _currentTheme = AppTheme.editorial;
    }
  }

  /// Set theme and persist
  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, availableThemes.indexOf(theme));
    } catch (e) {
      // Silently fail - theme will still work, just won't persist
    }
  }

  /// Get theme data for current theme
  ThemeData getThemeData() {
    switch (_currentTheme) {
      case AppTheme.editorial:
        return _buildEditorialTheme();
      case AppTheme.oceanCalm:
        return _buildOceanCalmTheme();
      case AppTheme.sunsetWarm:
        return _buildSunsetWarmTheme();
      case AppTheme.forest:
        return _buildForestTheme();
    }
  }

  /// Editorial theme - black & white, elegant
  ThemeData _buildEditorialTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF0A0A0A),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0A0A0A),
        onPrimary: Color(0xFFFFFFFF),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF0A0A0A),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF0A0A0A),
        iconTheme: IconThemeData(color: Color(0xFF0A0A0A)),
        titleTextStyle: TextStyle(
          color: Color(0xFF0A0A0A),
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  /// Ocean Calm theme - blues and teals
  ThemeData _buildOceanCalmTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF0288D1),
        onPrimary: const Color(0xFFFFFFFF),
        primaryContainer: const Color(0xFFB3E5FC),
        onPrimaryContainer: const Color(0xFF001F3F),
        secondary: const Color(0xFF00ACC1),
        onSecondary: const Color(0xFFFFFFFF),
        surface: const Color(0xFFE1F5FE),
        onSurface: const Color(0xFF01579B),
      ),
      scaffoldBackgroundColor: const Color(0xFFE1F5FE),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFF0288D1),
        foregroundColor: Color(0xFFFFFFFF),
        iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
        titleTextStyle: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  /// Sunset Warm theme - orange and coral
  ThemeData _buildSunsetWarmTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFFFF7043),
        onPrimary: const Color(0xFFFFFFFF),
        primaryContainer: const Color(0xFFFFCCBC),
        secondary: const Color(0xFFFF8A65),
        onSecondary: const Color(0xFFFFFFFF),
        surface: const Color(0xFFFBE9E7),
        onSurface: const Color(0xFFBF360C),
      ),
      scaffoldBackgroundColor: const Color(0xFFFBE9E7),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFFFF7043),
        foregroundColor: Color(0xFFFFFFFF),
        iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
        titleTextStyle: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  /// Forest theme - greens and earth tones
  ThemeData _buildForestTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF43A047),
        onPrimary: const Color(0xFFFFFFFF),
        primaryContainer: const Color(0xFFC8E6C9),
        secondary: const Color(0xFF66BB6A),
        onSecondary: const Color(0xFFFFFFFF),
        surface: const Color(0xFFF1F8E9),
        onSurface: const Color(0xFF1B5E20),
      ),
      scaffoldBackgroundColor: const Color(0xFFF1F8E9),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFF43A047),
        foregroundColor: Color(0xFFFFFFFF),
        iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
        titleTextStyle: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}

/// Available themes enum
enum AppTheme {
  editorial,
  oceanCalm,
  sunsetWarm,
  forest;

  String get displayName {
    switch (this) {
      case editorial:
        return 'Editorial';
      case oceanCalm:
        return 'Ocean Calm';
      case sunsetWarm:
        return 'Sunset Warm';
      case forest:
        return 'Forest';
    }
  }

  String get description {
    switch (this) {
      case editorial:
        return 'Black & white, elegant and minimal';
      case oceanCalm:
        return 'Blues and teals, calming gradients';
      case sunsetWarm:
        return 'Orange and coral, cozy feel';
      case forest:
        return 'Greens and earth tones, natural';
    }
  }

  Color get previewColor {
    switch (this) {
      case editorial:
        return const Color(0xFF0A0A0A);
      case oceanCalm:
        return const Color(0xFF0288D1);
      case sunsetWarm:
        return const Color(0xFFFF7043);
      case forest:
        return const Color(0xFF43A047);
    }
  }
}
