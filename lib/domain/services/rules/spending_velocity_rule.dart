import '../behavioral_rule.dart';
import '../../entities/behavioral_insight_entity.dart';
import '../../entities/user_profile_entity.dart';
import '../../entities/budget_entity.dart';
import '../../value_objects/insight_category.dart';
import '../../value_objects/delivery_triggers.dart';
import '../../value_objects/life_stage.dart';
import '../../value_objects/money_personality_type.dart';

/// Rule: Spending Velocity
///
/// Compares current rate of spending (last 7 days) to the expected rate
/// based on budget and day of month. Helps users catch overspending early.
///
/// Behavioral Principle: Feedback Loop
/// Providing timely feedback on spending velocity allows users to adjust
/// behavior before it's too late.
class SpendingVelocityRule implements BehavioralRule {
  @override
  String get id => 'spending_velocity';

  @override
  String get name => 'Spending Velocity';

  @override
  String get description =>
      'Compares recent spending rate to expected budget pace';

  @override
  InsightCategory get category => InsightCategory.budgetHealth;

  @override
  Set<DeliveryTrigger> get triggers => {
        DeliveryTrigger.weeklySummary,
        DeliveryTrigger.preDecision,
      };

  @override
  InsightPriority get defaultPriority => InsightPriority.medium;

  /// Days to look back for recent spending
  final int lookbackDays;

  /// Thresholds for velocity warnings (as percentage of expected)
  final double warningThreshold;
  final double criticalThreshold;

  const SpendingVelocityRule({
    this.lookbackDays = 7,
    this.warningThreshold = 1.3, // 130% of expected
    this.criticalThreshold = 1.5, // 150% of expected
  });

  @override
  Future<BehavioralInsightEntity?> evaluate(RuleContext context) async {
    final budget = context.budget;
    if (budget == null) return null;

    final now = context.now;
    final weekAgo = now.subtract(Duration(days: lookbackDays));

    // Get spending in the lookback period
    final recentSpent = context.getTotalSpentInPeriod(weekAgo, now);

    // Calculate expected spending for this period
    final expectedSpent = budget.dailyBudget * lookbackDays;

    // Skip if expected is too small
    if (expectedSpent <= 0) return null;

    // Calculate velocity ratio
    final velocity = recentSpent / expectedSpent;

    // Determine if we need to alert
    String? status;
    if (velocity >= criticalThreshold) {
      status = 'critical';
    } else if (velocity >= warningThreshold) {
      status = 'warning';
    } else if (velocity <= 0.5) {
      status = 'excellent';
    } else {
      return null; // On track, no alert needed
    }

    return _generateInsight(
      context: context,
      recentSpent: recentSpent,
      expectedSpent: expectedSpent,
      velocity: velocity,
      status: status,
    );
  }

  BehavioralInsightEntity _generateInsight({
    required RuleContext context,
    required double recentSpent,
    required double expectedSpent,
    required double velocity,
    required String status,
  }) {
    final profile = context.profile;
    final personality = profile.personalityType;
    final isHighStress = profile.stressLevel == FinancialStressLevel.high;

    final title = _getTitle(personality, status);
    final message = _getMessage(
      personality,
      status,
      recentSpent,
      expectedSpent,
      velocity,
      lookbackDays,
      isHighStress,
    );
    final icon = _getIcon(status);
    final priority = _getPriority(status, isHighStress);

    return BehavioralInsightEntity.create(
      ruleId: id,
      category: category,
      title: title,
      message: message,
      icon: icon,
      priority: priority,
      actionLabel: status != 'excellent' ? 'View Spending' : null,
      actionDeepLink: status != 'excellent' ? 'app://analytics' : null,
      metadata: {
        'recentSpent': recentSpent,
        'expectedSpent': expectedSpent,
        'velocity': velocity,
        'lookbackDays': lookbackDays,
        'status': status,
      },
      expiresIn: const Duration(hours: 48),
    );
  }

  String _getTitle(MoneyPersonalityType personality, String status) {
    final titles = {
      'critical': {
        MoneyPersonalityType.saver: 'Overspending Alert',
        MoneyPersonalityType.spender: 'Way Over Pace',
        MoneyPersonalityType.sharer: 'Spending Too Fast',
        MoneyPersonalityType.investor: 'Negative Cash Flow',
        MoneyPersonalityType.gambler: 'House is Winning',
      },
      'warning': {
        MoneyPersonalityType.saver: 'Elevated Spending',
        MoneyPersonalityType.spender: 'Pace Slowing Down',
        MoneyPersonalityType.sharer: 'Watch Your Spending',
        MoneyPersonalityType.investor: 'Velocity Warning',
        MoneyPersonalityType.gambler: 'Table\'s Getting Hot',
      },
      'excellent': {
        MoneyPersonalityType.saver: 'Excellent Pace',
        MoneyPersonalityType.spender: 'Killing It',
        MoneyPersonalityType.sharer: 'Great Momentum',
        MoneyPersonalityType.investor: 'Positive Variance',
        MoneyPersonalityType.gambler: 'Winner\'s Streak',
      },
    };

    return titles[status]?[personality] ?? 'Spending Velocity Update';
  }

  String _getMessage(
    MoneyPersonalityType personality,
    String status,
    double recentSpent,
    double expectedSpent,
    double velocity,
    int days,
    bool isHighStress,
  ) {
    final percentOver = ((velocity - 1) * 100).toStringAsFixed(0);
    final percentUnder = ((1 - velocity) * 100).toStringAsFixed(0);
    final dailyAverage = recentSpent / days;

    switch (status) {
      case 'critical':
        return _getCriticalMessage(
          personality,
          recentSpent,
          expectedSpent,
          dailyAverage,
          percentOver,
          days,
          isHighStress,
        );

      case 'warning':
        return _getWarningMessage(
          personality,
          recentSpent,
          expectedSpent,
          dailyAverage,
          percentOver,
          days,
        );

      case 'excellent':
        return _getExcellentMessage(
          personality,
          recentSpent,
          expectedSpent,
          dailyAverage,
          percentUnder,
          days,
        );

      default:
        return '';
    }
  }

  String _getCriticalMessage(
    MoneyPersonalityType personality,
    double recentSpent,
    double expectedSpent,
    double dailyAverage,
    String percentOver,
    int days,
    bool isHighStress,
  ) {
    final urgency = isHighStress ? 'You need to stop spending now. ' : '';

    switch (personality) {
      case MoneyPersonalityType.saver:
        return '${urgency}You\'ve spent \$${recentSpent.toStringAsFixed(0)} in the last $days days '
            '— $percentOver% over budget. At this pace, you\'ll run out before month-end. '
            'Time to cut back immediately.';

      case MoneyPersonalityType.spender:
        return 'Hey, you\'ve spent \$${recentSpent.toStringAsFixed(0)} this week — '
            'that\'s \$${dailyAverage.toStringAsFixed(0)}/day vs your \$${(expectedSpent / days).toStringAsFixed(0)} budget. '
            '${urgency}Cool it for a few days.';

      case MoneyPersonalityType.sharer:
        return 'You\'ve spent \$${recentSpent.toStringAsFixed(0)} in $days days — '
            '$percentOver% over pace. ${urgency}Before you help anyone else, '
            'you need to protect your own finances.';

      case MoneyPersonalityType.investor:
        return 'Cash flow deficit: \$${recentSpent.toStringAsFixed(0)} outflow vs '
            '\$${expectedSpent.toStringAsFixed(0)} expected. Current velocity of '
            '\$${dailyAverage.toStringAsFixed(0)}/day is unsustainable. '
            'Immediate correction required.';

      case MoneyPersonalityType.gambler:
        return 'You\'re on a losing streak — spent \$${recentSpent.toStringAsFixed(0)} '
            'when you should have spent \$${expectedSpent.toStringAsFixed(0)}. '
            '${urgency}Walk away from the table before you dig a deeper hole.';

      default:
        return 'You\'ve spent \$${recentSpent.toStringAsFixed(0)} in $days days, '
            '$percentOver% over your budget. At this rate, you\'ll run out early. '
            '${urgency}Cut back immediately.';
    }
  }

  String _getWarningMessage(
    MoneyPersonalityType personality,
    double recentSpent,
    double expectedSpent,
    double dailyAverage,
    String percentOver,
    int days,
  ) {
    switch (personality) {
      case MoneyPersonalityType.saver:
        return 'You\'ve spent \$${recentSpent.toStringAsFixed(0)} in the last $days days '
            '— $percentOver% over budget pace. '
            'Consider slowing down to stay on track.';

      case MoneyPersonalityType.spender:
        return 'Spending \$${dailyAverage.toStringAsFixed(0)}/day vs your '
            '\$${(expectedSpent / days).toStringAsFixed(0)} budget. '
            'Try to keep it under \$${(expectedSpent / days).toStringAsFixed(0)} today.';

      case MoneyPersonalityType.sharer:
        return 'You\'re $percentOver% over budget pace this week. '
            'Keep being generous, but make sure you\'re not sacrificing your own goals.';

      case MoneyPersonalityType.investor:
        return 'Spending velocity at $percentOver% of expected. '
            'Consider reducing discretionary spend to return to optimal cash flow.';

      case MoneyPersonalityType.gambler:
        return 'You\'re spending $percentOver% faster than you should. '
            'The odds are catching up. Time to play it safer.';

      default:
        return 'You\'ve spent \$${recentSpent.toStringAsFixed(0)} in $days days, '
            '$percentOver% over your budget. Consider slowing down.';
    }
  }

  String _getExcellentMessage(
    MoneyPersonalityType personality,
    double recentSpent,
    double expectedSpent,
    double dailyAverage,
    String percentUnder,
    int days,
  ) {
    switch (personality) {
      case MoneyPersonalityType.saver:
        return 'Fantastic! You\'re $percentUnder% under budget pace. '
            'Only spent \$${recentSpent.toStringAsFixed(0)} of your \$${expectedSpent.toStringAsFixed(0)} '
            'for this period. Keep it up!';

      case MoneyPersonalityType.spender:
        return 'You\'re crushing it! Only \$${recentSpent.toStringAsFixed(0)} this week '
            'vs \$${expectedSpent.toStringAsFixed(0)} expected. '
            'You\'ve earned some room for fun.';

      case MoneyPersonalityType.sharer:
        return 'Great work! You\'re $percentUnder% under budget. '
            'This gives you more room to be generous later in the month.';

      case MoneyPersonalityType.investor:
        return 'Excellent velocity: $percentUnder% under expected spend. '
            'This variance represents opportunity for investment.';

      case MoneyPersonalityType.gambler:
        return 'Winner! You\'re $percentUnder% budget this week. '
            'The house is losing. Keep this streak alive.';

      default:
        return 'Great job! You\'ve spent only \$${recentSpent.toStringAsFixed(0)} '
            'of your expected \$${expectedSpent.toStringAsFixed(0)}. Keep it up!';
    }
  }

  String _getIcon(String status) {
    switch (status) {
      case 'critical':
        return '🚨';
      case 'warning':
        return '⚡';
      case 'excellent':
        return '🎉';
      default:
        return '📊';
    }
  }

  InsightPriority _getPriority(String status, bool isHighStress) {
    switch (status) {
      case 'critical':
        return isHighStress ? InsightPriority.critical : InsightPriority.high;
      case 'warning':
        return InsightPriority.medium;
      case 'excellent':
        return InsightPriority.low;
      default:
        return InsightPriority.low;
    }
  }

  @override
  bool shouldRunForProfile(UserProfileEntity profile) {
    return profile.isCategoryEnabled(category);
  }

  @override
  bool shouldRunForTrigger(DeliveryTrigger trigger) {
    return triggers.contains(trigger);
  }

  @override
  Duration get estimatedExecutionTime => const Duration(milliseconds: 50);
}
