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
    AppTheme.lavenderDream,
    AppTheme.midnightBlue,
    AppTheme.cherryBlossom,
    AppTheme.goldenHour,
    AppTheme.arcticFrost,
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
      _currentTheme =
          availableThemes[themeIndex.clamp(0, availableThemes.length - 1)];
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
      case AppTheme.lavenderDream:
        return _buildLavenderDreamTheme();
      case AppTheme.midnightBlue:
        return _buildMidnightBlueTheme();
      case AppTheme.cherryBlossom:
        return _buildCherryBlossomTheme();
      case AppTheme.goldenHour:
        return _buildGoldenHourTheme();
      case AppTheme.arcticFrost:
        return _buildArcticFrostTheme();
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
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0288D1),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFB3E5FC),
        onPrimaryContainer: Color(0xFF001F3F),
        secondary: Color(0xFF00ACC1),
        onSecondary: Color(0xFFFFFFFF),
        surface: Color(0xFFE1F5FE),
        onSurface: Color(0xFF01579B),
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
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFFF7043),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFFFCCBC),
        secondary: Color(0xFFFF8A65),
        onSecondary: Color(0xFFFFFFFF),
        surface: Color(0xFFFBE9E7),
        onSurface: Color(0xFFBF360C),
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
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF43A047),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFC8E6C9),
        secondary: Color(0xFF66BB6A),
        onSecondary: Color(0xFFFFFFFF),
        surface: Color(0xFFF1F8E9),
        onSurface: Color(0xFF1B5E20),
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

  /// Lavender Dream theme - purple and lavender gradients
  ThemeData _buildLavenderDreamTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF9C27B0),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFE1BEE7),
        secondary: Color(0xFFBA68C8),
        onSecondary: Color(0xFFFFFFFF),
        surface: Color(0xFFF3E5F5),
        onSurface: Color(0xFF4A148C),
      ),
      scaffoldBackgroundColor: const Color(0xFFF3E5F5),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFF9C27B0),
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

  /// Midnight Blue theme - deep blue, professional
  ThemeData _buildMidnightBlueTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1A237E),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFC5CAE9),
        secondary: Color(0xFF3F51B5),
        onSecondary: Color(0xFFFFFFFF),
        surface: Color(0xFFE8EAF6),
        onSurface: Color(0xFF1A237E),
      ),
      scaffoldBackgroundColor: const Color(0xFFE8EAF6),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFF1A237E),
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

  /// Cherry Blossom theme - pink and rose, elegant
  ThemeData _buildCherryBlossomTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFE91E63),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFFCE4EC),
        secondary: Color(0xFFF06292),
        onSecondary: Color(0xFFFFFFFF),
        surface: Color(0xFFFCE4EC),
        onSurface: Color(0xFF880E4F),
      ),
      scaffoldBackgroundColor: const Color(0xFFFCE4EC),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFFE91E63),
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

  /// Golden Hour theme - warm gold and orange
  ThemeData _buildGoldenHourTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFFF6F00),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFFFD54F),
        secondary: Color(0xFFFF8F00),
        onSecondary: Color(0xFFFFFFFF),
        surface: Color(0xFFFFF8E1),
        onSurface: Color(0xFFBF360C),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFF8E1),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFFFF6F00),
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

  /// Arctic Frost theme - white and icy blue, clean
  ThemeData _buildArcticFrostTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF00BCD4),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFB2EBF2),
        secondary: Color(0xFF00ACC1),
        onSecondary: Color(0xFFFFFFFF),
        surface: Color(0xFFE0F7FA),
        onSurface: Color(0xFF006064),
      ),
      scaffoldBackgroundColor: const Color(0xFFE0F7FA),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFF00BCD4),
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
  forest,
  lavenderDream,
  midnightBlue,
  cherryBlossom,
  goldenHour,
  arcticFrost;

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
      case lavenderDream:
        return 'Lavender Dream';
      case midnightBlue:
        return 'Midnight Blue';
      case cherryBlossom:
        return 'Cherry Blossom';
      case goldenHour:
        return 'Golden Hour';
      case arcticFrost:
        return 'Arctic Frost';
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
      case lavenderDream:
        return 'Purple and lavender, dreamy vibes';
      case midnightBlue:
        return 'Deep blue, professional and clean';
      case cherryBlossom:
        return 'Pink and rose, elegant and soft';
      case goldenHour:
        return 'Warm gold and orange, sunny feel';
      case arcticFrost:
        return 'White and icy blue, fresh and clean';
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
      case lavenderDream:
        return const Color(0xFF9C27B0);
      case midnightBlue:
        return const Color(0xFF1A237E);
      case cherryBlossom:
        return const Color(0xFFE91E63);
      case goldenHour:
        return const Color(0xFFFF6F00);
      case arcticFrost:
        return const Color(0xFF00BCD4);
    }
  }
}
