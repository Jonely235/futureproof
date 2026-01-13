import '../entities/transaction_entity.dart';

/// Budget comparison service - business logic for comparing budgets over time
class BudgetComparisonService {
  /// Compare current month with previous month
  MonthOverMonthComparison compareMonths({
    required List<TransactionEntity> currentMonthTransactions,
    required List<TransactionEntity> previousMonthTransactions,
  }) {
    final currentMonthSpent = _calculateTotalSpent(currentMonthTransactions);
    final previousMonthSpent = _calculateTotalSpent(previousMonthTransactions);
    final difference = currentMonthSpent - previousMonthSpent;
    final percentageChange = previousMonthSpent > 0
        ? (difference / previousMonthSpent) * 100
        : 0.0;

    return MonthOverMonthComparison(
      currentMonthSpent: currentMonthSpent,
      previousMonthSpent: previousMonthSpent,
      difference: difference,
      percentageChange: percentageChange,
      improved: difference < 0, // Negative difference = spent less = improvement
    );
  }

  /// Get spending trend (up or down)
  SpendingTrend getSpendingTrend(List<List<TransactionEntity>> monthlyData) {
    if (monthlyData.length < 2) {
      return SpendingTrend.unknown;
    }

    double previousAvg = 0;
    double currentAvg = 0;

    // Split data into two halves
    final midPoint = monthlyData.length ~/ 2;
    for (int i = 0; i < monthlyData.length; i++) {
      final spent = _calculateTotalSpent(monthlyData[i]);
      if (i < midPoint) {
        previousAvg += spent;
      } else {
        currentAvg += spent;
      }
    }

    previousAvg /= midPoint;
    currentAvg /= (monthlyData.length - midPoint);

    if (currentAvg < previousAvg * 0.95) {
      return SpendingTrend.decreasing;
    } else if (currentAvg > previousAvg * 1.05) {
      return SpendingTrend.increasing;
    } else {
      return SpendingTrend.stable;
    }
  }

  /// Calculate daily average spending for a month
  double calculateDailyAverage(List<TransactionEntity> transactions) {
    if (transactions.isEmpty) return 0;

    final totalSpent = _calculateTotalSpent(transactions);
    final uniqueDays = _getUniqueDayCount(transactions);
    return uniqueDays > 0 ? totalSpent / uniqueDays : totalSpent;
  }

  /// Calculate weekly average spending
  double calculateWeeklyAverage(List<TransactionEntity> transactions) {
    final dailyAvg = calculateDailyAverage(transactions);
    return dailyAvg * 7;
  }

  /// Calculate total spent (expenses only)
  double _calculateTotalSpent(List<TransactionEntity> transactions) {
    return transactions
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.absoluteAmount);
  }

  /// Get count of unique days with transactions
  int _getUniqueDayCount(List<TransactionEntity> transactions) {
    final uniqueDays = <String>{};
    for (final transaction in transactions) {
      final dateKey = _formatDateKey(transaction.date.value);
      uniqueDays.add(dateKey);
    }
    return uniqueDays.length;
  }

  /// Format date as YYYY-MM-DD
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Month over month comparison result
class MonthOverMonthComparison {
  final double currentMonthSpent;
  final double previousMonthSpent;
  final double difference;
  final double percentageChange;
  final bool improved;

  const MonthOverMonthComparison({
    required this.currentMonthSpent,
    required this.previousMonthSpent,
    required this.difference,
    required this.percentageChange,
    required this.improved,
  });

  /// Get formatted difference string
  String get formattedDifference {
    final prefix = difference > 0 ? '+' : '';
    return '$prefix\$${difference.abs().toStringAsFixed(0)}';
  }

  /// Get formatted percentage string
  String get formattedPercentage {
    final prefix = percentageChange > 0 ? '+' : '';
    return '$prefix${percentageChange.abs().toStringAsFixed(1)}%';
  }

  /// Get comparison message
  String get message {
    if (improved) {
      return 'Saved ${formattedDifference} vs last month';
    } else {
      return 'Spent ${formattedDifference} more vs last month';
    }
  }
}

/// Spending trend enum
enum SpendingTrend {
  increasing,
  decreasing,
  stable,
  unknown,
}
