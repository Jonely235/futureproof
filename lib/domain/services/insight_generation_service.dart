import '../entities/transaction_entity.dart';
import '../entities/budget_entity.dart';
import '../entities/streak_entity.dart';
import '../../services/ai/ai_service.dart';

/// Insight generation service - generates personalized financial insights
/// Enhanced with Llama-3.2-3B-Instruct for AI-powered insights
/// Falls back to rule-based insights when AI is unavailable
class InsightGenerationService {
  /// Optional AI service for enhanced insights
  AIService? _aiService;

  /// Set the AI service for enhanced insights
  void setAIService(AIService? aiService) {
    _aiService = aiService;
  }

  /// Check if AI service is available
  bool get isAIEnabled => _aiService != null && _aiService!.isReady;
  /// Generate comprehensive insights from financial data
  /// Uses AI if available, otherwise falls back to rule-based insights
  Future<List<Insight>> generateInsights({
    required List<TransactionEntity> transactions,
    required BudgetEntity budget,
    required StreakEntity streak,
    required MonthOverMonthData? monthOverMonth,
  }) async {
    // Try AI-generated insights first
    if (isAIEnabled) {
      try {
        final aiInsight = await _generateAIInsight(
          transactions,
          budget,
          streak,
        );

        // Combine AI insight with essential rule-based insights
        final insights = <Insight>[];

        // Add AI insight as the primary insight
        insights.add(aiInsight);

        // Add critical rule-based insights (budget status, streak)
        insights.add(_generateBudgetHealthInsight(transactions, budget));
        insights.add(_generateStreakInsight(streak));

        return insights;
      } catch (e) {
        // Fall back to rule-based if AI fails
        return _generateRuleBasedInsights(
          transactions,
          budget,
          streak,
          monthOverMonth,
        );
      }
    }

    // Use rule-based insights
    return _generateRuleBasedInsights(
      transactions,
      budget,
      streak,
      monthOverMonth,
    );
  }

  /// Generate insights using AI
  Future<Insight> _generateAIInsight(
    List<TransactionEntity> transactions,
    BudgetEntity budget,
    StreakEntity streak,
  ) async {
    // Calculate category breakdown
    final categoryBreakdown = <String, double>{};
    for (final transaction in transactions) {
      if (transaction.isExpense) {
        categoryBreakdown[transaction.category] =
            (categoryBreakdown[transaction.category] ?? 0) + transaction.absoluteAmount;
      }
    }

    // Calculate daily average
    final now = DateTime.now();
    final daysPassed = now.day;
    final dailyAverage = daysPassed > 0
        ? transactions
            .where((t) => t.isExpense)
            .fold<double>(0, (sum, t) => sum + t.absoluteAmount) / daysPassed
        : 0.0;

    // Get AI-generated insight
    final aiMessage = await _aiService!.generateInsights(
      transactions: transactions,
      budget: budget,
      streak: streak,
      categoryBreakdown: categoryBreakdown,
      dailyAverage: dailyAverage,
    );

    return Insight(
      type: InsightType.info,
      title: 'AI Insight',
      message: aiMessage,
      icon: '🤖',
      priority: InsightPriority.high,
      actionText: 'Ask follow-up',
    );
  }

  /// Generate rule-based insights (fallback)
  List<Insight> _generateRuleBasedInsights(
    List<TransactionEntity> transactions,
    BudgetEntity budget,
    StreakEntity streak,
    MonthOverMonthData? monthOverMonth,
  ) {
    final insights = <Insight>[];

    // Budget health insight
    insights.add(_generateBudgetHealthInsight(
      transactions,
      budget,
    ));

    // Streak insight
    insights.add(_generateStreakInsight(streak));

    // Category insights
    insights.addAll(_generateCategoryInsights(transactions, budget));

    // Month over month insight
    if (monthOverMonth != null) {
      insights.add(_generateMonthOverMonthInsight(monthOverMonth));
    }

    // Spending velocity insight
    insights.add(_generateSpendingVelocityInsight(transactions, budget));

    return insights;
  }

  /// Generate budget health insight
  Insight _generateBudgetHealthInsight(
    List<TransactionEntity> transactions,
    BudgetEntity budget,
  ) {
    final totalSpent = transactions
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.absoluteAmount);

    final percentageUsed = budget.getBudgetStatus(totalSpent);
    final remaining = budget.getRemaining(totalSpent);

    if (percentageUsed >= 100) {
      return Insight(
        type: InsightType.alert,
        title: 'Budget Exceeded',
        message: 'You\'ve spent \$${remaining.abs().toStringAsFixed(0)} over budget this month.',
        icon: '⚠️',
        priority: InsightPriority.high,
        actionText: 'Review spending',
      );
    } else if (percentageUsed >= 90) {
      return Insight(
        type: InsightType.warning,
        title: 'Near Budget Limit',
        message: 'You\'ve used ${percentageUsed.toStringAsFixed(0)}% of your budget. \$${remaining.toStringAsFixed(0)} remaining.',
        icon: '⚡',
        priority: InsightPriority.medium,
        actionText: 'Be cautious',
      );
    } else if (percentageUsed >= 75) {
      return Insight(
        type: InsightType.info,
        title: 'Budget Progress',
        message: 'You\'ve used ${percentageUsed.toStringAsFixed(0)}% of your budget. \$${remaining.toStringAsFixed(0)} remaining.',
        icon: '📊',
        priority: InsightPriority.low,
        actionText: null,
      );
    } else {
      return Insight(
        type: InsightType.success,
        title: 'On Track',
        message: 'Great! You\'re well within budget. \$${remaining.toStringAsFixed(0)} remaining.',
        icon: '✅',
        priority: InsightPriority.low,
        actionText: null,
      );
    }
  }

  /// Generate streak insight
  Insight _generateStreakInsight(StreakEntity streak) {
    if (streak.currentStreak == 0) {
      return Insight(
        type: InsightType.info,
        title: 'Start Your Streak',
        message: 'Stay under budget today to begin your streak!',
        icon: '🔥',
        priority: InsightPriority.low,
        actionText: 'Today\'s budget',
      );
    } else if (streak.currentStreak < 3) {
      return Insight(
        type: InsightType.success,
        title: 'Streak Started!',
        message: '${streak.currentStreak} day${streak.currentStreak > 1 ? 's' : ''} under budget. Keep going!',
        icon: '🔥',
        priority: InsightPriority.low,
        actionText: null,
      );
    } else if (streak.currentStreak < 7) {
      return Insight(
        type: InsightType.success,
        title: 'Building Momentum',
        message: '${streak.currentStreak} days! Aim for a full week.',
        icon: '🔥',
        priority: InsightPriority.low,
        actionText: null,
      );
    } else if (streak.currentStreak < 30) {
      return Insight(
        type: InsightType.achievement,
        title: 'Amazing Streak!',
        message: '${streak.currentStreak} days and counting! You\'re crushing it.',
        icon: '🏆',
        priority: InsightPriority.low,
        actionText: null,
      );
    } else {
      return Insight(
        type: InsightType.achievement,
        title: 'Legendary!',
        message: '${streak.currentStreak} days! You\'re a budget master.',
        icon: '👑',
        priority: InsightPriority.low,
        actionText: null,
      );
    }
  }

  /// Generate category insights
  List<Insight> _generateCategoryInsights(
    List<TransactionEntity> transactions,
    BudgetEntity budget,
  ) {
    final insights = <Insight>[];

    // Group by category
    final categorySpending = <String, double>{};
    for (final transaction in transactions) {
      if (transaction.isExpense) {
        categorySpending[transaction.category] =
            (categorySpending[transaction.category] ?? 0) + transaction.absoluteAmount;
      }
    }

    // Sort by amount
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Top category insight
    if (sortedCategories.isNotEmpty) {
      final topCategory = sortedCategories.first;
      final percentage = (topCategory.value /
          categorySpending.values.fold<double>(0, (sum, v) => sum + v));

      insights.add(Insight(
        type: InsightType.info,
        title: 'Top Spending Category',
        message: '${topCategory.key}: \$${topCategory.value.toStringAsFixed(0)} (${(percentage * 100).toStringAsFixed(0)}% of spending)',
        icon: '🏷️',
        priority: InsightPriority.low,
        actionText: null,
      ));
    }

    return insights;
  }

  /// Generate month over month insight
  Insight _generateMonthOverMonthInsight(MonthOverMonthData data) {
    if (data.improved) {
      return Insight(
        type: InsightType.success,
        title: 'Saving More!',
        message: 'You spent ${data.formattedDifference} less than last month.',
        icon: '📉',
        priority: InsightPriority.low,
        actionText: null,
      );
    } else {
      return Insight(
        type: InsightType.warning,
        title: 'Spending Increased',
        message: 'You spent ${data.formattedDifference} more than last month.',
        icon: '📈',
        priority: InsightPriority.medium,
        actionText: 'Review changes',
      );
    }
  }

  /// Generate spending velocity insight
  Insight _generateSpendingVelocityInsight(
    List<TransactionEntity> transactions,
    BudgetEntity budget,
  ) {
    if (transactions.isEmpty) {
      return Insight(
        type: InsightType.info,
        title: 'Get Started',
        message: 'Add your first transaction to see spending insights.',
        icon: '💡',
        priority: InsightPriority.low,
        actionText: 'Add transaction',
      );
    }

    // Calculate daily average over last 7 days
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentTransactions = transactions
        .where((t) => t.isExpense && t.date.value.isAfter(sevenDaysAgo))
        .toList();

    if (recentTransactions.isEmpty) {
      return Insight(
        type: InsightType.info,
        title: 'No Recent Activity',
        message: 'No expenses in the last 7 days.',
        icon: '📅',
        priority: InsightPriority.low,
        actionText: null,
      );
    }

    final totalSpent = recentTransactions
        .fold<double>(0, (sum, t) => sum + t.absoluteAmount);
    final dailyAverage = totalSpent / 7;

    if (dailyAverage > budget.dailyBudget) {
      return Insight(
        type: InsightType.warning,
        title: 'High Spending Velocity',
        message: 'Averaging \$${dailyAverage.toStringAsFixed(0)}/day vs \$${budget.dailyBudget.toStringAsFixed(0)} budget.',
        icon: '⚡',
        priority: InsightPriority.medium,
        actionText: 'Slow down',
      );
    } else {
      return Insight(
        type: InsightType.success,
        title: 'Healthy Spending Pace',
        message: 'Averaging \$${dailyAverage.toStringAsFixed(0)}/day, well under budget.',
        icon: '✅',
        priority: InsightPriority.low,
        actionText: null,
      );
    }
  }
}

/// Insight - represents a single financial insight
class Insight {
  final InsightType type;
  final String title;
  final String message;
  final String icon;
  final InsightPriority priority;
  final String? actionText;

  const Insight({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    required this.priority,
    this.actionText,
  });
}

/// Insight type
enum InsightType {
  success,
  warning,
  alert,
  info,
  achievement,
}

/// Insight priority
enum InsightPriority {
  high,
  medium,
  low,
}

/// Month over month data
class MonthOverMonthData {
  final double currentMonth;
  final double previousMonth;
  final double difference;
  final bool improved;

  const MonthOverMonthData({
    required this.currentMonth,
    required this.previousMonth,
    required this.difference,
    required this.improved,
  });

  String get formattedDifference {
    final prefix = difference > 0 ? '+' : '';
    return '$prefix\$${difference.abs().toStringAsFixed(0)}';
  }
}
