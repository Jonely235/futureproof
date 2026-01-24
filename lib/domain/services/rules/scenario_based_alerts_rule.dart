import '../behavioral_rule.dart';
import '../../entities/behavioral_insight_entity.dart';
import '../../entities/user_profile_entity.dart';
import '../../entities/budget_entity.dart';
import '../../entities/streak_entity.dart';
import '../../value_objects/insight_category.dart';
import '../../value_objects/delivery_triggers.dart';
import '../../value_objects/life_stage.dart';
import '../../value_objects/money_personality_type.dart';

/// Rule: Scenario-Based Alerts
///
/// Combines multiple data points to predict problems before they manifest.
/// These alerts transition the system from a "rear-view mirror" to a "radar".
///
/// Behavioral Principle: Predictive Intervention
/// Alerting users BEFORE problems occur allows them to change behavior.
class ScenarioBasedAlertsRule implements BehavioralRule {
  @override
  String get id => 'scenario_alerts';

  @override
  String get name => 'Scenario-Based Alerts';

  @override
  String get description =>
      'Predictive alerts combining multiple data points';

  @override
  InsightCategory get category => InsightCategory.scenarioAlert;

  @override
  Set<DeliveryTrigger> get triggers => {
        DeliveryTrigger.preDecision,
        DeliveryTrigger.morningDigest,
        DeliveryTrigger.postTransaction,
      };

  @override
  InsightPriority get defaultPriority => InsightPriority.high;

  const ScenarioBasedAlertsRule();

  @override
  Future<BehavioralInsightEntity?> evaluate(RuleContext context) async {
    final budget = context.budget;
    if (budget == null) return null;

    final scenarios = <_Scenario>[];

    // Check each scenario
    scenarios.addAll(_checkScenarios(context));

    if (scenarios.isEmpty) return null;

    // Return the highest priority scenario
    scenarios.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    final topScenario = scenarios.first;

    return _generateInsight(context, topScenario);
  }

  List<_Scenario> _checkScenarios(RuleContext context) {
    final scenarios = <_Scenario>[];

    // Scenario 1: Salary Delay + Payment Risk
    final salaryDelayRisk = _checkSalaryDelayRisk(context);
    if (salaryDelayRisk != null) scenarios.add(salaryDelayRisk);

    // Scenario 2: Heavy Week + Card Bill Impact
    final heavyWeekRisk = _checkHeavyWeekRisk(context);
    if (heavyWeekRisk != null) scenarios.add(heavyWeekRisk);

    // Scenario 3: Credit Utilization Risk
    final creditRisk = _checkCreditUtilizationRisk(context);
    if (creditRisk != null) scenarios.add(creditRisk);

    // Scenario 4: Safe to Save Nudge
    final safeToSave = _checkSafeToSave(context);
    if (safeToSave != null) scenarios.add(safeToSave);

    // Scenario 5: Unusual Category Recurrence
    final unusualRecurrence = _checkUnusualRecurrence(context);
    if (unusualRecurrence != null) scenarios.add(unusualRecurrence);

    return scenarios;
  }

  _Scenario? _checkSalaryDelayRisk(RuleContext context) {
    final budget = context.budget;
    final streak = context.streak;

    if (budget == null || streak == null) return null;

    final now = context.now;
    final daysUntilMonthEnd = DateTime(now.year, now.month + 1, 0).day - now.day;

    // Calculate remaining budget
    final monthStart = DateTime(now.year, now.month, 1);
    final spentSoFar = context.getTotalSpentInPeriod(monthStart, now);
    final remaining = budget.getRemaining(spentSoFar);

    // If remaining is negative and we're far from month end
    if (remaining < 0 && daysUntilMonthEnd > 7) {
      return _Scenario(
        type: 'salary_delay_payment_risk',
        title: 'Funds Running Low',
        message: 'You\'re \$${remaining.abs().toStringAsFixed(0)} short with '
            '$daysUntilMonthEnd days left in the month. '
            'Reduce spending or move funds to cover the gap.',
        icon: '⚠️',
        actionLabel: 'Review Spending',
        priority: InsightPriority.critical,
        metadata: {
          'shortfall': remaining.abs(),
          'daysLeft': daysUntilMonthEnd,
        },
      );
    }

    return null;
  }

  _Scenario? _checkHeavyWeekRisk(RuleContext context) {
    final budget = context.budget;
    if (budget == null) return null;

    final now = context.now;
    final weekAgo = now.subtract(const Duration(days: 7));

    final weeklySpend = context.getTotalSpentInPeriod(weekAgo, now);
    final expectedWeeklySpend = budget.dailyBudget * 7;

    // If spending is 30% more than usual
    if (weeklySpend > expectedWeeklySpend * 1.3) {
      final overspend = weeklySpend - expectedWeeklySpend;
      final percentage = ((weeklySpend / expectedWeeklySpend - 1) * 100).toInt();

      return _Scenario(
        type: 'heavy_week_card_bill',
        title: 'Heavy Spending Week',
        message: 'You\'ve spent $percentage% more than usual this week '
            '(\$${overspend.toStringAsFixed(0)} over). '
            'Your next card payment will be higher as a result.',
        icon: '📊',
        actionLabel: 'View Breakdown',
        priority: InsightPriority.medium,
        metadata: {
          'weeklySpend': weeklySpend,
          'expected': expectedWeeklySpend,
          'overspend': overspend,
        },
      );
    }

    return null;
  }

  _Scenario? _checkCreditUtilizationRisk(RuleContext context) {
    final budget = context.budget;
    if (budget == null) return null;

    final now = context.now;
    final monthStart = DateTime(now.year, now.month, 1);

    final spent = context.getTotalSpentInPeriod(monthStart, now);
    final utilization = spent / budget.monthlyBudget;

    // If over 70% utilization
    if (utilization > 0.7) {
      final percentage = (utilization * 100).toInt();

      return _Scenario(
        type: 'credit_utilization_risk',
        title: 'Budget Capacity Alert',
        message: 'You\'ve used $percentage% of your monthly budget. '
            'High utilization this early in the month could lead to '
            'difficulty covering expenses later.',
        icon: '💳',
        actionLabel: 'Slow Down',
        priority: utilization > 0.85 ? InsightPriority.high : InsightPriority.medium,
        metadata: {
          'utilization': utilization,
          'percentage': percentage,
        },
      );
    }

    return null;
  }

  _Scenario? _checkSafeToSave(RuleContext context) {
    final budget = context.budget;
    if (budget == null) return null;

    final now = context.now;
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final spent = context.getTotalSpentInPeriod(monthStart, now);
    final remaining = budget.getRemaining(spent);

    // If we have a significant surplus (more than 20% of budget remaining)
    // and we're past the first week of the month
    if (now.day > 7 && remaining > budget.monthlyBudget * 0.2) {
      return _Scenario(
        type: 'safe_to_save_nudge',
        title: 'Safe to Save!',
        message: 'You have a surplus of \$${remaining.toStringAsFixed(0)} '
            'with ${monthEnd.day - now.day} days left. '
            'Consider moving some to savings now!',
        icon: '🎉',
        actionLabel: 'Save Now',
        priority: InsightPriority.low,
        metadata: {
          'surplus': remaining,
          'daysLeft': monthEnd.day - now.day,
        },
      );
    }

    return null;
  }

  _Scenario? _checkUnusualRecurrence(RuleContext context) {
    // Check if a discretionary category is trending up significantly
    final budget = context.budget;
    if (budget == null) return null;

    final now = context.now;
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    for (final category in ['Food', 'Shopping', 'Entertainment']) {
      final thisMonthSpend = context.getTransactionsByCategory(category)
          .where((t) => t.isExpense && t.date.value.isAfter(thisMonthStart))
          .fold<double>(0, (sum, t) => sum + t.absoluteAmount);

      final lastMonthSpend = context.getTransactionsByCategory(category)
          .where((t) => t.isExpense &&
              t.date.value.isAfter(lastMonthStart) &&
              t.date.value.isBefore(thisMonthStart))
          .fold<double>(0, (sum, t) => sum + t.absoluteAmount);

      if (lastMonthSpend > 0 && thisMonthSpend > lastMonthSpend * 1.5) {
        final increase = ((thisMonthSpend / lastMonthSpend - 1) * 100).toInt();

        return _Scenario(
          type: 'unusual_category_recurrence',
          title: '$category Spending Up',
          message: 'You\'ve spent $increase% more on $category this month '
              '(\$${thisMonthSpend.toStringAsFixed(0)} vs \$${lastMonthSpend.toStringAsFixed(0)} last month). '
              'Want to set a limit for the rest of the month?',
          icon: '📈',
          actionLabel: 'Set Limit',
          priority: InsightPriority.medium,
          metadata: {
            'category': category,
            'thisMonth': thisMonthSpend,
            'lastMonth': lastMonthSpend,
            'increase': increase,
          },
        );
      }
    }

    return null;
  }

  BehavioralInsightEntity _generateInsight(
    RuleContext context,
    _Scenario scenario,
  ) {
    return BehavioralInsightEntity.create(
      ruleId: id,
      category: category,
      title: scenario.title,
      message: scenario.message,
      icon: scenario.icon,
      priority: scenario.priority,
      actionLabel: scenario.actionLabel,
      actionDeepLink: _getDeepLink(scenario.type),
      metadata: scenario.metadata,
      expiresIn: _getExpiry(scenario.priority),
    );
  }

  String? _getDeepLink(String scenarioType) {
    switch (scenarioType) {
      case 'salary_delay_payment_risk':
        return 'app://budget';
      case 'heavy_week_card_bill':
        return 'app://analytics';
      case 'credit_utilization_risk':
        return 'app://budget';
      case 'safe_to_save_nudge':
        return 'app://savings';
      case 'unusual_category_recurrence':
        return 'app://budget?tab=categories';
      default:
        return 'app://home';
    }
  }

  Duration _getExpiry(InsightPriority priority) {
    switch (priority) {
      case InsightPriority.critical:
        return const Duration(hours: 12);
      case InsightPriority.high:
        return const Duration(hours: 24);
      case InsightPriority.medium:
        return const Duration(days: 2);
      case InsightPriority.low:
        return const Duration(days: 7);
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
  Duration get estimatedExecutionTime => const Duration(milliseconds: 120);
}

class _Scenario {
  final String type;
  final String title;
  final String message;
  final String icon;
  final String? actionLabel;
  final InsightPriority priority;
  final Map<String, dynamic>? metadata;

  _Scenario({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    required this.priority,
    this.metadata,
  });
}
