import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/finance_config.dart';
import '../config/app_colors.dart';

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
        return AppColors.success;
      case StatusLevel.caution:
        return AppColors.gold;
      case StatusLevel.danger:
        return AppColors.danger;
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
  static FinanceStatus calculateStatus({
    required double monthlyIncome,
    required double monthlyExpenses,
    required double savingsGoal,
    List<String>? insights,
  }) {
    final config = FinanceConfig.instance;
    final remaining = monthlyIncome - monthlyExpenses - savingsGoal;
    final buffer = config.calculateBuffer(monthlyIncome);
    final formatter = NumberFormat.currency(symbol: '\$');

    String message;
    StatusLevel level;

    if (remaining >= buffer) {
      level = StatusLevel.good;
      message = "You're doing great! You have ${formatter.format(remaining)} remaining this month.";
    } else if (remaining > 0) {
      level = StatusLevel.good;
      message = "You're on track! ${formatter.format(remaining)} left for flexible spending.";
    } else if (remaining > -buffer) {
      level = StatusLevel.caution;
      message = "You're ${formatter.format(remaining.abs())} over budget. Consider reviewing your spending.";
    } else {
      level = StatusLevel.danger;
      message = "Over budget by ${formatter.format(remaining.abs())}. Review all spending and pause non-essentials.";
    }

    return FinanceStatus(
      message: message,
      level: level,
      remaining: remaining,
    );
  }

  static double calculateTotalExpenses(List transactions) {
    return transactions
        .where((t) => t.amount < 0)
        .fold(0.0, (sum, t) => sum + t.amount.abs());
  }

  static double calculateTotalIncome(List transactions) {
    return transactions
        .where((t) => t.amount > 0)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

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
