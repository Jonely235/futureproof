import '../entities/streak_entity.dart';
import '../entities/transaction_entity.dart';
import '../entities/budget_entity.dart';

/// Streak calculator service - business logic for calculating streaks
/// This is a domain service, contains pure business rules
class StreakCalculatorService {
  /// Calculate current streak from transactions
  StreakEntity calculateStreak({
    required List<TransactionEntity> transactions,
    required BudgetEntity budget,
    StreakEntity? currentStreak,
  }) {
    final dailyBudget = budget.dailyBudget;
    final today = DateTime.now();

    // Group transactions by date
    final Map<String, double> dailySpending = {};
    for (final transaction in transactions) {
      if (!transaction.isExpense) continue;

      final dateKey = _formatDateKey(transaction.date.value);
      dailySpending[dateKey] =
          (dailySpending[dateKey] ?? 0) + transaction.absoluteAmount;
    }

    // Calculate consecutive days under budget starting from today
    int streakCount = 0;
    for (int i = 0; i < 365; i++) {
      final date = today.subtract(Duration(days: i));
      final dateKey = _formatDateKey(date);
      final spent = dailySpending[dateKey] ?? 0.0;

      if (spent <= dailyBudget) {
        streakCount++;
      } else {
        // Budget exceeded, streak broken
        break;
      }
    }

    // Update best streak if needed
    final bestStreak = currentStreak != null
        ? (streakCount > currentStreak.bestStreak
            ? streakCount
            : currentStreak.bestStreak)
        : streakCount;

    return StreakEntity(
      currentStreak: streakCount,
      bestStreak: bestStreak,
      streakStartDate: currentStreak?.streakStartDate ?? DateTime.now(),
      lastBrokenDate: streakCount == 0 ? DateTime.now() : (currentStreak?.lastBrokenDate ?? DateTime.now()),
    );
  }

  /// Check if streak should be reset based on today's spending
  bool shouldResetStreak({
    required List<TransactionEntity> todayTransactions,
    required BudgetEntity budget,
  }) {
    final dailyBudget = budget.dailyBudget;
    final todaySpent = todayTransactions
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.absoluteAmount);

    return todaySpent > dailyBudget;
  }

  /// Get streak motivation message
  String getMotivationMessage(StreakEntity streak) {
    if (streak.currentStreak == 0) {
      return 'Start your streak today! Stay under budget.';
    } else if (streak.currentStreak < 3) {
      return 'Great start! Keep going for 3 days.';
    } else if (streak.currentStreak < 7) {
      return 'You\'re building momentum! Aim for a week.';
    } else if (streak.currentStreak < 14) {
      return 'Amazing! One week strong. Go for two!';
    } else if (streak.currentStreak < 30) {
      return 'Incredible! You\'re mastering your budget.';
    } else {
      return 'Legendary! 30+ days of financial discipline!';
    }
  }

  /// Format date as YYYY-MM-DD key
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
