import 'package:flutter/material.dart';
import '../models/transaction.dart' as model;

/// Spending Analysis Model
///
/// Contains complete financial analysis results
/// including breakdowns, trends, anomalies, and insights.
class SpendingAnalysis {
  /// Total spending by category
  final Map<String, double> byCategory;

  /// Monthly spending totals (chronological)
  final List<MonthlySpending> monthlyTrends;

  /// Average monthly spending
  final double averageMonthlySpending;

  /// Highest spending category
  final String highestCategory;

  /// Highest spending amount
  final double highestCategoryAmount;

  /// Lowest spending category
  final String lowestCategory;

  /// Lowest spending amount
  final double lowestCategoryAmount;

  /// Detected anomalies (unusual transactions)
  final List<model.Transaction> anomalies;

  /// Predicted spending for next month
  final double predictedNextMonth;

  /// Budget vs actual comparison
  final Map<String, BudgetComparison> budgetComparisons;

  /// Generated insights
  final List<Insight> insights;

  SpendingAnalysis({
    required this.byCategory,
    required this.monthlyTrends,
    required this.averageMonthlySpending,
    required this.highestCategory,
    required this.highestCategoryAmount,
    required this.lowestCategory,
    required this.lowestCategoryAmount,
    required this.anomalies,
    required this.predictedNextMonth,
    required this.budgetComparisons,
    required this.insights,
  });

  /// Calculate total spending across all categories
  double get totalSpending => byCategory.values.fold(0, (a, b) => a + b);

  /// Get percentage of total spending for a category
  double getCategoryPercentage(String category) {
    if (totalSpending == 0) return 0.0;
    return (byCategory[category] ?? 0) / totalSpending;
  }

  /// Check if spending is trending up
  bool get isTrendingUp {
    if (monthlyTrends.length < 2) return false;
    final latest = monthlyTrends.last.amount;
    final previous = monthlyTrends[monthlyTrends.length - 2].amount;
    return latest > previous;
  }

  /// Get trend percentage
  double get trendPercentage {
    if (monthlyTrends.length < 2) return 0.0;
    final latest = monthlyTrends.last.amount;
    final previous = monthlyTrends[monthlyTrends.length - 2].amount;
    if (previous == 0) return 0.0;
    return ((latest - previous) / previous) * 100;
  }

  /// Create from transactions
  factory SpendingAnalysis.fromTransactions({
    required List<model.Transaction> transactions,
    required Map<String, double>? categoryBudgets,
    required double monthlyIncome,
  }) {
    // Calculate spending by category
    final byCategory = <String, double>{};
    for (final transaction in transactions) {
      final category = transaction.category;
      final amount = transaction.amount.abs();
      byCategory[category] = (byCategory[category] ?? 0) + amount;
    }

    // Calculate total spending
    final totalSpending = byCategory.values.fold(0.0, (a, b) => a + b);

    // Find highest and lowest categories
    String highestCat = '';
    double highestAmt = 0.0;
    String lowestCat = '';
    double lowestAmt = double.infinity;

    byCategory.forEach((category, amount) {
      if (amount > highestAmt) {
        highestAmt = amount;
        highestCat = category;
      }
      if (amount < lowestAmt) {
        lowestAmt = amount;
        lowestCat = category;
      }
    });

    // Calculate monthly trends
    final monthlyTrends = <MonthlySpending>[];
    final transactionsByMonth = <String, List<model.Transaction>>{};

    for (final transaction in transactions) {
      final monthKey = _getMonthKey(transaction.date);
      transactionsByMonth[monthKey] = [
        ...(transactionsByMonth[monthKey] ?? []),
        transaction
      ];
    }

    transactionsByMonth.forEach((month, txs) {
      final total = txs.map((t) => t.amount.abs()).fold(0.0, (a, b) => a + b);
      monthlyTrends.add(MonthlySpending(month: month, amount: total));
    });

    // Calculate average
    final average = monthlyTrends.isEmpty
        ? 0.0
        : monthlyTrends.map((m) => m.amount).reduce((a, b) => a + b) /
            monthlyTrends.length;

    // Detect anomalies (spending > 2x average)
    final anomalies = <model.Transaction>[];
    if (monthlyTrends.isNotEmpty) {
      final avgAmount = average / monthlyTrends.length;
      final threshold = avgAmount * 2; // Simple anomaly threshold

      for (final transaction in transactions) {
        if (transaction.amount.abs() > threshold) {
          anomalies.add(transaction);
        }
      }
    }

    // Predict next month (weighted moving average)
    double predicted = 0.0;
    if (monthlyTrends.length >= 2) {
      // Weight recent months more heavily
      final weights = [1.0, 2.0, 3.0]; // Last 3 months
      final count = monthlyTrends.length.clamp(0, 3);

      double weightedSum = 0.0;
      double weightTotal = 0.0;

      for (int i = 0; i < count; i++) {
        final index = monthlyTrends.length - 1 - i;
        final weight = weights[i];
        weightedSum += monthlyTrends[index].amount * weight;
        weightTotal += weight;
      }

      predicted = weightTotal > 0 ? weightedSum / weightTotal : average;
    }

    // Generate insights
    final insights = <Insight>[];

    // Generate insights from analysis
    if (monthlyTrends.length >= 2) {
      if (monthlyTrends.last.amount >
          monthlyTrends[monthlyTrends.length - 2].amount * 1.2) {
        insights.add(Insight(
          title: 'Spending is Up',
          description:
              'You spent ${monthlyTrends.last.amount.toStringAsFixed(0)} this month, '
              '${((monthlyTrends.last.amount - monthlyTrends[monthlyTrends.length - 2].amount) / monthlyTrends[monthlyTrends.length - 2].amount * 100).toStringAsFixed(0)}% more than last month.',
          type: InsightType.warning,
          icon: '📈',
          recommendation:
              'Review your expenses to see what\'s driving the increase.',
        ));
      }

      if (monthlyTrends.last.amount <
          monthlyTrends[monthlyTrends.length - 2].amount * 0.8) {
        insights.add(Insight(
          title: 'Spending is Down',
          description: 'Great job! Your spending decreased by '
              '${((monthlyTrends[monthlyTrends.length - 2].amount - monthlyTrends.last.amount) / monthlyTrends[monthlyTrends.length - 2].amount * 100).toStringAsFixed(0)}% compared to last month.',
          type: InsightType.success,
          icon: '📉',
          recommendation:
              'Keep up the good work! Consider saving the extra money.',
        ));
      }
    }

    // Check highest category
    if (highestCat.isNotEmpty) {
      final percentage = (highestAmt / totalSpending * 100);
      insights.add(Insight(
        title: 'Top Expense Category',
        description: 'Your highest expense is $highestCat at '
            '\$${highestAmt.toStringAsFixed(0)} (\$${percentage.toStringAsFixed(0)}% of total spending).',
        type: InsightType.info,
        icon: '💰',
        value: percentage,
        recommendation: percentage > 30
            ? 'Consider if you can reduce $highestCat spending.'
            : null,
      ));
    }

    // Budget comparisons
    final budgetComparisons = <String, BudgetComparison>{};
    if (categoryBudgets != null) {
      categoryBudgets.forEach((category, budget) {
        final spent = byCategory[category] ?? 0.0;
        final remaining = budget - spent;
        final percentage = budget > 0 ? (spent / budget) * 100.0 : 0.0;

        budgetComparisons[category] = BudgetComparison(
          category: category,
          budget: budget,
          spent: spent,
          remaining: remaining,
          percentage: percentage,
          isOverBudget: spent > budget,
        );

        // Add insight if over budget
        if (spent > budget) {
          insights.add(Insight(
            title: 'Over Budget: $category',
            description:
                'You\'ve spent ${spent.toStringAsFixed(0)} on $category, '
                'exceeding your budget of ${budget.toStringAsFixed(0)} by '
                '${(spent - budget).toStringAsFixed(0)}.',
            type: InsightType.warning,
            icon: '⚠️',
            recommendation:
                'Try to reduce $category spending for the rest of the month.',
          ));
        }
      });
    }

    return SpendingAnalysis(
      byCategory: byCategory,
      monthlyTrends: monthlyTrends,
      averageMonthlySpending: average,
      highestCategory: highestCat,
      highestCategoryAmount: highestAmt,
      lowestCategory: lowestCat,
      lowestCategoryAmount: lowestAmt,
      anomalies: anomalies,
      predictedNextMonth: predicted,
      budgetComparisons: budgetComparisons,
      insights: insights,
    );
  }

  static String _getMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }
}

/// Monthly spending data
class MonthlySpending {
  final String month; // YYYY-MM format
  final double amount;

  MonthlySpending({required this.month, required this.amount});
}

/// Budget comparison data
class BudgetComparison {
  final String category;
  final double budget;
  final double spent;
  final double remaining;
  final double percentage;
  final bool isOverBudget;

  BudgetComparison({
    required this.category,
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.isOverBudget,
  });
}

/// Insight generated by AI
class Insight {
  final String title;
  final String description;
  final InsightType type;
  final String icon;
  final double? value;
  final String? recommendation;

  Insight({
    required this.title,
    required this.description,
    required this.type,
    required this.icon,
    this.value,
    this.recommendation,
  });

  Color get color {
    switch (type) {
      case InsightType.success:
        return Colors.green;
      case InsightType.warning:
        return Colors.orange;
      case InsightType.error:
        return Colors.red;
      case InsightType.info:
        return Colors.blue;
    }
  }
}

/// Insight types
enum InsightType {
  success,
  warning,
  error,
  info,
}
