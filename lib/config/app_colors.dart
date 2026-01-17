library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._internal();

  // ============================================
  // PRIMARY BLACKS
  // ============================================

  static const black = Color(0xFF0A0A0A);
  static const charcoal = Color(0xFF1A1A1A);
  static const slate = Color(0xFF2D2D2D);

  // ============================================
  // GRAY SCALE
  // ============================================

  static const gray900 = Color(0xFF404040);
  static const gray700 = Color(0xFF6B6B6B);
  static const gray500 = Color(0xFF9E9E9E);
  static const gray300 = Color(0xFFD4D4D4);
  static const gray100 = Color(0xFFF5F5F5);

  // ============================================
  // WHITE SCALE
  // ============================================

  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFFAFAFA);
  static const paper = Color(0xFFF0F0F0);

  // ============================================
  // ACCENT COLORS
  // ============================================

  static const gold = Color(0xFFC9A962);
  static const crimson = Color(0xFFD4483A);

  // ============================================
  // STATUS COLORS
  // ============================================

  static const success = Color(0xFF4CAF50);
  static const danger = Color(0xFFD4483A);

  // ============================================
  // UI COLORS
  // ============================================

  static const outline = Color(0xFFBDBDBD);
  static const border = Color(0xFFE0E0E0);
  static const shadow = Color(0x14000000);

  // Convenience aliases
  static const background = offWhite;
  static const primary = fintechTeal;
  static const accent = fintechTeal;

  // ============================================
  // CATEGORY COLORS
  // ============================================

  static const categoryGroceries = Color(0xFF4CAF50);
  static const categoryDiningOut = Color(0xFFFF9800);
  static const categoryTransport = Color(0xFF2196F3);
  static const categoryEntertainment = Color(0xFF9C27B0);
  static const categoryHealth = Color(0xFFF44336);
  static const categoryShopping = Color(0xFFE91E63);
  static const categorySubscriptions = Color(0xFF00BCD4);
  static const categoryHousing = Color(0xFF795548);
  static const categoryOther = Color(0xFF9E9E9E);

  // ============================================
  // FINTHECH PALETTE (Analytics/Settings)
  // ============================================

  static const fintechTeal = Color(0xFF00BFA5);
  static const fintechTealLight = Color(0xFF5DF2D6);
  static const fintechNavy = Color(0xFF1A237E);
  static const fintechIndigo = Color(0xFF3949AB);
  static const fintechTrust = Color(0xFF00897B);
  static const fintechGrowth = Color(0xFF43A047);

  // ============================================
  // CATEGORY COLORS MAP (for donut chart & insights)
  // ============================================

  static const Map<String, Color> categoryColors = {
    'Groceries': Color(0xFF4CAF50),      // Green - essential
    'Dining Out': Color(0xFFFF9800),     // Orange - discretionary
    'Transport': Color(0xFF2196F3),      // Blue - movement
    'Entertainment': Color(0xFF9C27B0),  // Purple - fun
    'Health': Color(0xFFF44336),         // Red - wellness
    'Shopping': Color(0xFFE91E63),       // Pink - retail
    'Subscriptions': Color(0xFF00BCD4),  // Cyan - recurring
    'Housing': Color(0xFF795548),        // Brown - shelter
    'Education': Color(0xFF00BCD4),      // Cyan - growth
    'Travel': Color(0xFFFF9800),         // Orange - adventure
    'Personal': Color(0xFF9C27B0),       // Purple - self
    'Gifts': Color(0xFFE91E63),          // Pink - generosity
    'Investments': Color(0xFF4CAF50),    // Green - returns
    'Other': Color(0xFF9E9E9E),          // Gray - neutral
  };
}
