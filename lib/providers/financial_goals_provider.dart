import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

/// Provider for managing financial goals state
///
/// Handles:
/// - Monthly income tracking
/// - Monthly savings goal tracking
/// - Persistence to SharedPreferences
/// - Validation for financial values
class FinancialGoalsProvider extends ChangeNotifier {
  static const String _monthlyIncomeKey = 'monthly_income';
  static const String _savingsGoalKey = 'savings_goal';

  // Default values
  static const double _defaultMonthlyIncome = 5000.0;
  static const double _defaultSavingsGoal = 1000.0;

  double _monthlyIncome = _defaultMonthlyIncome;
  double _savingsGoal = _defaultSavingsGoal;
  bool _isLoading = true;

  /// Get current monthly income
  double get monthlyIncome => _monthlyIncome;

  /// Get current savings goal
  double get monthlySavingsTarget => _savingsGoal;

  /// Get formatted income string
  String get formattedIncome => '\$${_monthlyIncome.toStringAsFixed(0)}';

  /// Get formatted savings goal string
  String get formattedSavingsGoal => '\$${_savingsGoal.toStringAsFixed(0)}';

  /// Check if loading
  bool get isLoading => _isLoading;

  /// Load financial goals from SharedPreferences
  Future<void> loadGoals() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      _monthlyIncome = prefs.getDouble(_monthlyIncomeKey) ?? _defaultMonthlyIncome;
      _savingsGoal = prefs.getDouble(_savingsGoalKey) ?? _defaultSavingsGoal;

      AppLogger.ui.info('Loaded financial goals: income=\$$_monthlyIncome, savings=\$$_savingsGoal');
    } catch (e, st) {
      AppLogger.ui.warning('Error loading financial goals: $e');
      // Keep defaults on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update monthly income
  /// Returns true if successful, false otherwise
  Future<bool> updateIncome(double value) async {
    // Validate income
    if (value <= 0) {
      AppLogger.ui.warning('Invalid income: $value');
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_monthlyIncomeKey, value);

      // Verify save
      final saved = prefs.getDouble(_monthlyIncomeKey);
      if (saved == value) {
        _monthlyIncome = value;
        notifyListeners();
        AppLogger.ui.info('Updated monthly income: \$$value');
        return true;
      } else {
        AppLogger.ui.warning('Income verification failed');
        return false;
      }
    } catch (e) {
      AppLogger.ui.warning('Error updating income: $e');
      return false;
    }
  }

  /// Update savings goal
  /// Returns true if successful, false otherwise
  Future<bool> updateSavingsTarget(double value) async {
    // Validate savings (can be 0, but not negative)
    if (value < 0) {
      AppLogger.ui.warning('Invalid savings goal: $value');
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_savingsGoalKey, value);

      // Verify save
      final saved = prefs.getDouble(_savingsGoalKey);
      if (saved == value) {
        _savingsGoal = value;
        notifyListeners();
        AppLogger.ui.info('Updated savings goal: \$$value');
        return true;
      } else {
        AppLogger.ui.warning('Savings goal verification failed');
        return false;
      }
    } catch (e) {
      AppLogger.ui.warning('Error updating savings goal: $e');
      return false;
    }
  }

  /// Update both income and savings at once
  /// Returns true if both successful, false otherwise
  Future<bool> updateBoth({double? income, double? savings}) async {
    bool success = true;

    if (income != null) {
      success = success && await updateIncome(income);
    }

    if (savings != null) {
      success = success && await updateSavingsTarget(savings);
    }

    return success;
  }

  /// Reset to default values
  Future<void> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_monthlyIncomeKey);
      await prefs.remove(_savingsGoalKey);

      _monthlyIncome = _defaultMonthlyIncome;
      _savingsGoal = _defaultSavingsGoal;
      notifyListeners();

      AppLogger.ui.info('Reset financial goals to defaults');
    } catch (e) {
      AppLogger.ui.warning('Error resetting financial goals: $e');
    }
  }

  /// Calculate savings rate as percentage
  double get savingsRate {
    if (_monthlyIncome <= 0) return 0.0;
    return (_savingsGoal / _monthlyIncome * 100).clamp(0, 100);
  }

  /// Get savings rate formatted
  String get formattedSavingsRate => '${savingsRate.toStringAsFixed(1)}%';
}
