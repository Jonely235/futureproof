import 'dart:convert';
import '../models/spending_analysis.dart';
import '../models/app_error.dart';
import '../models/transaction.dart' as model;
import 'database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/finance_config.dart';
import '../utils/app_logger.dart';

class AnalyticsService {
  final DatabaseService _dbService = DatabaseService();
  SpendingAnalysis? _cachedAnalysis;

  void _clearCache() {
    _cachedAnalysis = null;
  }

  Future<SpendingAnalysis> _getAnalysis() async {
    if (_cachedAnalysis != null) return _cachedAnalysis!;

    final transactions = await _dbService.getAllTransactions();
    final prefs = await SharedPreferences.getInstance();
    final monthlyIncome = prefs.getDouble('monthly_income') ?? 0.0;

    final categoryBudgets = <String, double>{};
    final budgetsJson = prefs.getString('category_budgets');
    if (budgetsJson != null) {
      try {
        final budgets = jsonDecode(budgetsJson) as Map<String, dynamic>;
        budgets.forEach((key, value) {
          if (value is num) {
            categoryBudgets[key] = value.toDouble();
          }
        });
      } catch (e, st) {
        AppLogger.analytics.severe('Invalid category budgets JSON', e);
        throw AppError(
          type: AppErrorType.validation,
          message: 'Invalid category budgets format',
          technicalDetails: 'JSON parse failed for: $budgetsJson',
          originalError: e,
          stackTrace: st,
        );
      }
    }

    _cachedAnalysis = SpendingAnalysis.fromTransactions(
      transactions: transactions,
      categoryBudgets: categoryBudgets.isEmpty ? null : categoryBudgets,
      monthlyIncome: monthlyIncome,
    );

    return _cachedAnalysis!;
  }

  /// Refresh analytics by clearing cache
  void refresh() {
    _clearCache();
  }

  Future<SpendingAnalysis> analyzeSpending() async {
    try {
      return await _getAnalysis();
    } catch (e, st) {
      if (e is AppError) rethrow;
      AppLogger.analytics.severe('Error analyzing spending', e);
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not analyze spending',
        technicalDetails: 'Failed to retrieve or process transaction data',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<Map<String, double>> getCategoryBreakdown() async {
    try {
      final analysis = await _getAnalysis();
      return analysis.byCategory;
    } catch (e, st) {
      if (e is AppError) rethrow;
      AppLogger.analytics.severe('Error getting category breakdown', e);
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not retrieve category breakdown',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<List<MonthlySpending>> getMonthlyTrends() async {
    try {
      final analysis = await _getAnalysis();
      return analysis.monthlyTrends;
    } catch (e, st) {
      if (e is AppError) rethrow;
      AppLogger.analytics.severe('Error getting monthly trends', e);
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not retrieve monthly trends',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<MapEntry<String, double>?> getTopCategory() async {
    try {
      final breakdown = await getCategoryBreakdown();
      if (breakdown.isEmpty) return null;

      MapEntry<String, double>? topEntry;
      for (final entry in breakdown.entries) {
        if (topEntry == null || entry.value > topEntry.value) {
          topEntry = entry;
        }
      }
      return topEntry;
    } catch (e, st) {
      if (e is AppError) rethrow;
      AppLogger.analytics.severe('Error getting top category', e);
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not determine top spending category',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<List<model.Transaction>> detectAnomalies() async {
    try {
      final analysis = await _getAnalysis();
      return analysis.anomalies;
    } catch (e, st) {
      if (e is AppError) rethrow;
      AppLogger.analytics.severe('Error detecting anomalies', e);
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not detect spending anomalies',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<List<Insight>> generateInsights() async {
    try {
      final analysis = await _getAnalysis();
      return analysis.insights;
    } catch (e, st) {
      if (e is AppError) rethrow;
      AppLogger.analytics.severe('Error generating insights', e);
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not generate spending insights',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<Map<String, BudgetComparison>> getBudgetComparisons() async {
    try {
      final analysis = await _getAnalysis();
      return analysis.budgetComparisons;
    } catch (e, st) {
      if (e is AppError) rethrow;
      AppLogger.analytics.severe('Error getting budget comparisons', e);
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not compare spending to budgets',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<double> predictNextMonth() async {
    try {
      final analysis = await _getAnalysis();
      return analysis.predictedNextMonth;
    } catch (e, st) {
      if (e is AppError) rethrow;
      AppLogger.analytics.severe('Error predicting next month', e);
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not predict next month spending',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<bool> isTrendingUp() async {
    try {
      final analysis = await _getAnalysis();
      return analysis.isTrendingUp;
    } catch (e, st) {
      if (e is AppError) rethrow;
      AppLogger.analytics.severe('Error checking trend', e);
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not determine spending trend',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<double> getTrendPercentage() async {
    try {
      final analysis = await _getAnalysis();
      return analysis.trendPercentage;
    } catch (e, st) {
      if (e is AppError) rethrow;
      AppLogger.analytics.severe('Error getting trend percentage', e);
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not calculate trend percentage',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<double> calculateSavingsRate() async {
    try {
      final analysis = await _getAnalysis();
      final prefs = await SharedPreferences.getInstance();
      final monthlyIncome = prefs.getDouble('monthly_income') ?? 0.0;

      if (monthlyIncome == 0) return 0.0;

      final savings = monthlyIncome - analysis.totalSpending;
      return (savings / monthlyIncome) * 100;
    } catch (e, st) {
      if (e is AppError) rethrow;
      AppLogger.analytics.severe('Error calculating savings rate', e);
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not calculate savings rate',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<int> getFinancialHealthScore() async {
    try {
      final analysis = await _getAnalysis();
      final prefs = await SharedPreferences.getInstance();
      final monthlyIncome = prefs.getDouble('monthly_income') ?? 0.0;
      final savingsGoal = prefs.getDouble('savings_goal') ?? 0.0;

      final config = FinanceConfig.instance;
      int score = 100;

      final overBudgetCount = analysis.budgetComparisons.values
          .where((comparison) => comparison.isOverBudget)
          .length;

      score -= overBudgetCount * FinanceConfig.overBudgetPenalty;
      score -= config.calculateAnomalyPenalty(analysis.anomalies.length);

      final savings = monthlyIncome - analysis.totalSpending;
      if (savings >= savingsGoal && savingsGoal > 0) {
        score += FinanceConfig.savingsGoalBonus;
      }

      if (!analysis.isTrendingUp) {
        score += FinanceConfig.trendingDownBonus;
      }

      return score.clamp(0, 100);
    } catch (e, st) {
      if (e is AppError) rethrow;
      AppLogger.analytics.severe('Error calculating health score', e);
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not calculate financial health score',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<double> getDailySpendingVelocity() async {
    try {
      final transactions = await _dbService.getAllTransactions();
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      double monthlyTotal = 0;
      for (final transaction in transactions) {
        if (transaction.date.isAfter(startOfMonth) &&
            transaction.date.isBefore(now)) {
          monthlyTotal += transaction.amount.abs();
        }
      }

      final daysInMonth = now.day;
      if (daysInMonth == 0) return 0.0;

      return monthlyTotal / daysInMonth;
    } catch (e, st) {
      if (e is AppError) rethrow;
      AppLogger.analytics.severe('Error calculating daily velocity', e);
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not calculate daily spending velocity',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<Map<int, double>> getSpendingByDayOfWeek() async {
    try {
      final transactions = await _dbService.getAllTransactions();
      final spendingByDay = <int, double>{};

      for (int i = 1; i <= 7; i++) {
        spendingByDay[i] = 0.0;
      }

      for (final transaction in transactions) {
        final day = transaction.date.weekday;
        spendingByDay[day] =
            (spendingByDay[day] ?? 0.0) + transaction.amount.abs();
      }

      return spendingByDay;
    } catch (e, st) {
      if (e is AppError) rethrow;
      AppLogger.analytics.severe('Error getting spending by day', e);
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not analyze spending by day of week',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<double> getAverageCategorySpending(String category) async {
    try {
      final transactions = await _dbService.getAllTransactions();
      final categoryTransactions = transactions
          .where((t) => t.category == category)
          .toList();

      if (categoryTransactions.isEmpty) return 0.0;

      final total =
          categoryTransactions.map((t) => t.amount.abs()).fold(0.0, (a, b) => a + b);
      return total / categoryTransactions.length;
    } catch (e, st) {
      if (e is AppError) rethrow;
      AppLogger.analytics.severe('Error calculating average category spending', e);
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not calculate average spending for category',
        technicalDetails: 'Category: $category',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<Map<String, dynamic>> compareMonths() async {
    try {
      final analysis = await analyzeSpending();
      final trends = analysis.monthlyTrends;

      if (trends.length < 2) {
        return {
          'currentMonth': 0.0,
          'previousMonth': 0.0,
          'difference': 0.0,
          'percentageChange': 0.0,
        };
      }

      final current = trends.last.amount;
      final previous = trends[trends.length - 2].amount;
      final difference = current - previous;
      final percentageChange =
          previous > 0 ? (difference / previous) * 100 : 0.0;

      return {
        'currentMonth': current,
        'previousMonth': previous,
        'difference': difference,
        'percentageChange': percentageChange,
      };
    } catch (e, st) {
      if (e is AppError) rethrow;
      AppLogger.analytics.severe('Error comparing months', e);
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not compare spending between months',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<Map<String, dynamic>> getQuickStats() async {
    try {
      final analysis = await analyzeSpending();
      final prefs = await SharedPreferences.getInstance();
      final monthlyIncome = prefs.getDouble('monthly_income') ?? 0.0;
      final savingsGoal = prefs.getDouble('savings_goal') ?? 0.0;

      final savings = monthlyIncome - analysis.totalSpending;
      final savingsRate =
          monthlyIncome > 0 ? (savings / monthlyIncome) * 100 : 0.0;

      return {
        'totalSpending': analysis.totalSpending,
        'monthlyIncome': monthlyIncome,
        'savings': savings,
        'savingsRate': savingsRate,
        'savingsGoal': savingsGoal,
        'isOnTrack': savings >= savingsGoal,
        'topCategory': analysis.highestCategory,
        'topCategoryAmount': analysis.highestCategoryAmount,
        'averageMonthlySpending': analysis.averageMonthlySpending,
        'isTrendingUp': analysis.isTrendingUp,
        'trendPercentage': analysis.trendPercentage,
      };
    } catch (e, st) {
      if (e is AppError) rethrow;
      AppLogger.analytics.severe('Error getting quick stats', e);
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not retrieve quick statistics',
        originalError: e,
        stackTrace: st,
      );
    }
  }
}
