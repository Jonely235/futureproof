import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FinanceStatus {
  final String message;
  final StatusLevel level;
  final double remaining;

  FinanceStatus({
    required this.message,
    required this.level,
    required this.remaining,
  });

  Color get color {
    switch (level) {
      case StatusLevel.good:
        return const Color(0xFF4CAF50); // Green
      case StatusLevel.caution:
        return const Color(0xFFFF9800); // Orange
      case StatusLevel.danger:
        return const Color(0xFFF44336); // Red
    }
  }

  String get emoji {
    switch (level) {
      case StatusLevel.good:
        return '✅';
      case StatusLevel.caution:
        return '⚠️';
      case StatusLevel.danger:
        return '❌';
    }
  }
}

enum StatusLevel { good, caution, danger }

class FinanceCalculator {
  /// Calculate financial status based on income, expenses, and savings goal
  static FinanceStatus calculateStatus({
    required double monthlyIncome,
    required double monthlyExpenses,
    required double savingsGoal,
    List<String>? insights,
  }) {
    final remaining = monthlyIncome - monthlyExpenses - savingsGoal;
    final buffer = monthlyIncome * 0.1; // 10% buffer

    String message;
    StatusLevel level;

    if (remaining >= buffer) {
      // Doing great!
      level = StatusLevel.good;
      message = _generateGoodMessage(remaining, monthlyIncome);
    } else if (remaining > 0) {
      // On track but not much cushion
      level = StatusLevel.good;
      message = _generateOnTrackMessage(remaining);
    } else if (remaining > -buffer) {
      // Slightly over, but recoverable
      level = StatusLevel.caution;
      message = _generateCautionMessage(remaining.abs());
    } else {
      // Significantly over budget
      level = StatusLevel.danger;
      message = _generateDangerMessage(remaining.abs());
    }

    return FinanceStatus(
      message: message,
      level: level,
      remaining: remaining,
    );
  }

  static String _generateGoodMessage(double remaining, double income) {
    final formatter = NumberFormat.currency(symbol: '\$');

    final messages = [
      "You're doing great! You have ${formatter.format(remaining)} left. Maybe treat yourselves to something nice?",
      "On track and then some! ${formatter.format(remaining)} remaining. You're crushing it!",
      "Excellent! ${formatter.format(remaining)} left this month. Consider putting extra toward savings.",
    ];

    return messages[Random().nextInt(messages.length)];
  }

  static String _generateOnTrackMessage(double remaining) {
    final formatter = NumberFormat.currency(symbol: '\$');
    return "You're on track! ${formatter.format(remaining)} left for flexible spending.";
  }

  static String _generateCautionMessage(double deficit) {
    final formatter = NumberFormat.currency(symbol: '\$');

    final messages = [
      "You're ${formatter.format(deficit)} over this month. Consider reviewing dining expenses this weekend.",
      "Slightly over budget by ${formatter.format(deficit)}. Hold off on non-essential spending until next month.",
      "${formatter.format(deficit)} over. Look for subscriptions or recurring expenses you can pause.",
    ];

    return messages[Random().nextInt(messages.length)];
  }

  static String _generateDangerMessage(double deficit) {
    final formatter = NumberFormat.currency(symbol: '\$');

    final messages = [
      "Over budget by ${formatter.format(deficit)}. Review all spending this week and pause non-essentials.",
      "${formatter.format(deficit)} over. Focus on groceries instead of dining out until next month.",
      "Budget alert: ${formatter.format(deficit)} over. Time for a spending freeze until next income.",
    ];

    return messages[Random().nextInt(messages.length)];
  }

  /// Calculate total expenses for a list of transactions
  static double calculateTotalExpenses(List transactions) {
    return transactions
        .where((t) => t.amount < 0)
        .fold(0.0, (sum, t) => sum + t.amount.abs());
  }

  /// Calculate total income for a list of transactions
  static double calculateTotalIncome(List transactions) {
    return transactions
        .where((t) => t.amount > 0)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Group transactions by category
  static Map<String, double> groupByCategory(List transactions) {
    final Map<String, double> categoryTotals = {};

    for (var transaction in transactions) {
      if (transaction.isExpense) {
        categoryTotals[transaction.category] =
            (categoryTotals[transaction.category] ?? 0) + transaction.amount.abs();
      }
    }

    return categoryTotals;
  }

  /// Get highest spending category
  static String getHighestSpendingCategory(List transactions) {
    final categoryTotals = groupByCategory(transactions);

    if (categoryTotals.isEmpty) return 'None';

    var highestCategory = 'None';
    var highestAmount = 0.0;

    categoryTotals.forEach((category, amount) {
      if (amount > highestAmount) {
        highestAmount = amount;
        highestCategory = category;
      }
    });

    return highestCategory;
  }
}
