import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/finance_config.dart';

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
        return const Color(0xFF4CAF50);
      case StatusLevel.caution:
        return const Color(0xFFFF9800);
      case StatusLevel.danger:
        return const Color(0xFFF44336);
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
      message = _chooseRandom([
        "You're doing great! You have ${formatter.format(remaining)} left. Maybe treat yourselves to something nice?",
        "On track and then some! ${formatter.format(remaining)} remaining. You're crushing it!",
        "Excellent! ${formatter.format(remaining)} left this month. Consider putting extra toward savings.",
      ]);
    } else if (remaining > 0) {
      level = StatusLevel.good;
      message = "You're on track! ${formatter.format(remaining)} left for flexible spending.";
    } else if (remaining > -buffer) {
      level = StatusLevel.caution;
      message = _chooseRandom([
        "You're ${formatter.format(remaining.abs())} over this month. Consider reviewing dining expenses this weekend.",
        "Slightly over budget by ${formatter.format(remaining.abs())}. Hold off on non-essential spending until next month.",
        "${formatter.format(remaining.abs())} over. Look for subscriptions or recurring expenses you can pause.",
      ]);
    } else {
      level = StatusLevel.danger;
      message = _chooseRandom([
        "Over budget by ${formatter.format(remaining.abs())}. Review all spending this week and pause non-essentials.",
        "${formatter.format(remaining.abs())} over. Focus on groceries instead of dining out until next month.",
        "Budget alert: ${formatter.format(remaining.abs())} over. Time for a spending freeze until next income.",
      ]);
    }

    return FinanceStatus(
      message: message,
      level: level,
      remaining: remaining,
    );
  }

  static String _chooseRandom(List<String> messages) {
    return messages[Random().nextInt(messages.length)];
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
