import 'dart:convert';
import '../models/spending_analysis.dart';
import '../models/transaction.dart' as model;
import 'database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/finance_config.dart';

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
      } catch (e) {
        // Invalid JSON, use empty map
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
    return _getAnalysis();
  }

  Future<Map<String, double>> getCategoryBreakdown() async {
    final analysis = await _getAnalysis();
    return analysis.byCategory;
  }

  Future<List<MonthlySpending>> getMonthlyTrends() async {
    final analysis = await _getAnalysis();
    return analysis.monthlyTrends;
  }

  Future<MapEntry<String, double>?> getTopCategory() async {
    final breakdown = await getCategoryBreakdown();
    if (breakdown.isEmpty) return null;

    MapEntry<String, double>? topEntry;
    for (final entry in breakdown.entries) {
      if (topEntry == null || entry.value > topEntry.value) {
        topEntry = entry;
      }
    }
    return topEntry;
  }

  Future<List<model.Transaction>> detectAnomalies() async {
    final analysis = await _getAnalysis();
    return analysis.anomalies;
  }

  Future<List<Insight>> generateInsights() async {
    final analysis = await _getAnalysis();
    return analysis.insights;
  }

  Future<Map<String, BudgetComparison>> getBudgetComparisons() async {
    final analysis = await _getAnalysis();
    return analysis.budgetComparisons;
  }

  Future<double> predictNextMonth() async {
    final analysis = await _getAnalysis();
    return analysis.predictedNextMonth;
  }

  Future<bool> isTrendingUp() async {
    final analysis = await _getAnalysis();
    return analysis.isTrendingUp;
  }

  Future<double> getTrendPercentage() async {
    final analysis = await _getAnalysis();
    return analysis.trendPercentage;
  }

  Future<double> calculateSavingsRate() async {
    final analysis = await _getAnalysis();
    final prefs = await SharedPreferences.getInstance();
    final monthlyIncome = prefs.getDouble('monthly_income') ?? 0.0;

    if (monthlyIncome == 0) return 0.0;

    final savings = monthlyIncome - analysis.totalSpending;
    return (savings / monthlyIncome) * 100;
  }

  Future<int> getFinancialHealthScore() async {
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
  }

  Future<double> getDailySpendingVelocity() async {
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
  }

  Future<Map<int, double>> getSpendingByDayOfWeek() async {
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
  }

  Future<double> getAverageCategorySpending(String category) async {
    final transactions = await _dbService.getAllTransactions();
    final categoryTransactions = transactions
        .where((t) => t.category == category)
        .toList();

    if (categoryTransactions.isEmpty) return 0.0;

    final total =
        categoryTransactions.map((t) => t.amount.abs()).fold(0.0, (a, b) => a + b);
    return total / categoryTransactions.length;
  }

  Future<Map<String, dynamic>> compareMonths() async {
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
  }

  Future<Map<String, dynamic>> getQuickStats() async {
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
  }
}
