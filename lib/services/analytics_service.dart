import '../models/spending_analysis.dart';
import '../models/transaction.dart' as model;
import 'database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Analytics Service
///
/// Provides financial intelligence including:
/// - Spending analysis and breakdowns
/// - Trend calculations
/// - Anomaly detection
/// - Budget comparisons
/// - AI-powered insights
class AnalyticsService {
  final DatabaseService _dbService = DatabaseService();

  /// Analyze spending for current user's household
  Future<SpendingAnalysis> analyzeSpending() async {
    // Get all transactions
    final transactions = await _dbService.getAllTransactions();

    // Get budgets and income from settings
    final prefs = await SharedPreferences.getInstance();
    final monthlyIncome = prefs.getDouble('monthly_income') ?? 0.0;

    // Get category budgets (stored as JSON map)
    final categoryBudgets = <String, double>{};
    final budgetsJson = prefs.getString('category_budgets');
    if (budgetsJson != null) {
      try {
        final Map<String, dynamic> budgets = Map<String, dynamic>.from(
          // Simple parse - in production use dart:convert
          _parseSimpleMap(budgetsJson),
        );
        budgets.forEach((key, value) {
          if (value is num) {
            categoryBudgets[key] = value.toDouble();
          }
        });
      } catch (e) {
        print('Error parsing budgets: $e');
      }
    }

    // Generate analysis
    return SpendingAnalysis.fromTransactions(
      transactions: transactions,
      categoryBudgets: categoryBudgets.isEmpty ? null : categoryBudgets,
      monthlyIncome: monthlyIncome,
    );
  }

  /// Get spending breakdown by category
  Future<Map<String, double>> getCategoryBreakdown() async {
    final analysis = await analyzeSpending();
    return analysis.byCategory;
  }

  /// Get monthly spending trends
  Future<List<MonthlySpending>> getMonthlyTrends() async {
    final analysis = await analyzeSpending();
    return analysis.monthlyTrends;
  }

  /// Get top spending category
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

  /// Detect spending anomalies (transactions > 2x average)
  Future<List<model.Transaction>> detectAnomalies() async {
    final analysis = await analyzeSpending();
    return analysis.anomalies;
  }

  /// Generate AI-powered insights
  Future<List<Insight>> generateInsights() async {
    final analysis = await analyzeSpending();
    return analysis.insights;
  }

  /// Get budget comparisons
  Future<Map<String, BudgetComparison>> getBudgetComparisons() async {
    final analysis = await analyzeSpending();
    return analysis.budgetComparisons;
  }

  /// Predict next month's spending
  Future<double> predictNextMonth() async {
    final analysis = await analyzeSpending();
    return analysis.predictedNextMonth;
  }

  /// Check if spending is trending up
  Future<bool> isTrendingUp() async {
    final analysis = await analyzeSpending();
    return analysis.isTrendingUp;
  }

  /// Get trend percentage
  Future<double> getTrendPercentage() async {
    final analysis = await analyzeSpending();
    return analysis.trendPercentage;
  }

  /// Calculate savings rate
  Future<double> calculateSavingsRate() async {
    final analysis = await analyzeSpending();
    final prefs = await SharedPreferences.getInstance();
    final monthlyIncome = prefs.getDouble('monthly_income') ?? 0.0;

    if (monthlyIncome == 0) return 0.0;

    final totalSpending = analysis.totalSpending;
    final savings = monthlyIncome - totalSpending;
    return (savings / monthlyIncome) * 100;
  }

  /// Get financial health score (0-100)
  Future<int> getFinancialHealthScore() async {
    final analysis = await analyzeSpending();
    final prefs = await SharedPreferences.getInstance();
    final monthlyIncome = prefs.getDouble('monthly_income') ?? 0.0;
    final savingsGoal = prefs.getDouble('savings_goal') ?? 0.0;

    int score = 100;

    // Deduct points for over-budget categories
    final overBudgetCount = analysis.budgetComparisons.values
        .where((comparison) => comparison.isOverBudget)
        .length;

    score -= overBudgetCount * 10;

    // Deduct points for anomalies
    if (analysis.anomalies.length > 3) {
      score -= 10;
    } else if (analysis.anomalies.length > 1) {
      score -= 5;
    }

    // Add points for meeting savings goal
    final savings = monthlyIncome - analysis.totalSpending;
    if (savings >= savingsGoal && savingsGoal > 0) {
      score += 5;
    }

    // Add points for trending down
    if (!analysis.isTrendingUp) {
      score += 5;
    }

    // Clamp between 0 and 100
    return score.clamp(0, 100);
  }

  /// Get spending velocity (avg daily spending this month)
  Future<double> getDailySpendingVelocity() async {
    final transactions = await _dbService.getAllTransactions();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    // Get this month's spending
    double monthlyTotal = 0;
    for (final transaction in transactions) {
      if (transaction.date.isAfter(startOfMonth) &&
          transaction.date.isBefore(now)) {
        monthlyTotal += transaction.amount.abs();
      }
    }

    // Calculate daily average
    final daysInMonth = now.day;
    if (daysInMonth == 0) return 0.0;

    return monthlyTotal / daysInMonth;
  }

  /// Get spending by day of week
  Future<Map<int, double>> getSpendingByDayOfWeek() async {
    final transactions = await _dbService.getAllTransactions();
    final spendingByDay = <int, double>{};

    // Initialize all days
    for (int i = 1; i <= 7; i++) {
      spendingByDay[i] = 0.0;
    }

    // Sum by day (1=Monday, 7=Sunday)
    for (final transaction in transactions) {
      final day = transaction.date.weekday;
      spendingByDay[day] =
          (spendingByDay[day] ?? 0.0) + transaction.amount.abs();
    }

    return spendingByDay;
  }

  /// Get average spending for a specific category
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

  /// Compare current month to previous month
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

  /// Simple map parser for category budgets
  Map<String, dynamic> _parseSimpleMap(String json) {
    // Basic JSON parsing for simple maps
    // In production, use dart:convert
    final result = <String, dynamic>{};

    // Remove { and }
    final content = json.replaceAll('{', '').replaceAll('}', '').trim();

    if (content.isEmpty) return result;

    // Split by comma
    final pairs = content.split(',');

    for (final pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        final key = parts[0].trim().replaceAll('"', '').replaceAll("'", '');
        final value = double.tryParse(parts[1].trim());
        if (key.isNotEmpty && value != null) {
          result[key] = value;
        }
      }
    }

    return result;
  }

  /// Get quick stats for home screen
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
