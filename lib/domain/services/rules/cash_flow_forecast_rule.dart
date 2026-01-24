import '../behavioral_rule.dart';
import '../../entities/behavioral_insight_entity.dart';
import '../../entities/user_profile_entity.dart';
import '../../entities/budget_entity.dart';
import '../../value_objects/insight_category.dart';
import '../../value_objects/delivery_triggers.dart';
import '../../value_objects/life_stage.dart';
import '../../value_objects/money_personality_type.dart';

/// Rule: Cash Flow Forecast
///
/// Projects future account balances based on recurring transactions
/// and upcoming bills. Warns if balance will go negative.
///
/// Behavioral Principle: Future Self-Continuity
/// Visualizing the "future self" in a state of financial deficit
/// encourages current-day restraint.
class CashFlowForecastRule implements BehavioralRule {
  @override
  String get id => 'cash_flow_forecast';

  @override
  String get name => 'Cash Flow Forecast';

  @override
  String get description =>
      'Projects future balances based on recurring transactions';

  @override
  InsightCategory get category => InsightCategory.cashFlowForecast;

  @override
  Set<DeliveryTrigger> get triggers => {
        DeliveryTrigger.preDecision,
        DeliveryTrigger.weeklySummary,
      };

  @override
  InsightPriority get defaultPriority => InsightPriority.high;

  /// Days to forecast into the future
  final int forecastDays;

  const CashFlowForecastRule({
    this.forecastDays = 30,
  });

  @override
  Future<BehavioralInsightEntity?> evaluate(RuleContext context) async {
    final budget = context.budget;
    if (budget == null) return null;

    // Get spending trends
    final dailyAverage = context.getAverageDailySpend(days: 30);
    final weeklyAverage = context.getAverageWeeklySpend(weeks: 4);

    // Get current balance (budget remaining)
    final now = context.now;
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1)
        .subtract(const Duration(days: 1));

    final spentSoFar = context.getTotalSpentInPeriod(monthStart, now);
    var currentBalance = budget.getRemaining(spentSoFar);

    // Project forward
    final projections = <int, double>{};
    var lowestBalance = currentBalance;
    var lowestDay = 0;

    for (int day = 1; day <= forecastDays; day++) {
      final futureDate = now.add(Duration(days: day));

      // Subtract daily spending
      currentBalance -= dailyAverage;

      // Add income (assuming payday at end of month)
      if (_isExpectedPayday(futureDate)) {
        // Add monthly income
        currentBalance += budget.monthlyIncome;
      }

      // Check for upcoming bills (simple heuristic: larger expenses on 1st and 15th)
      if (futureDate.day == 1 || futureDate.day == 15) {
        currentBalance -= weeklyAverage; // Assume bill payment
      }

      projections[day] = currentBalance;

      if (currentBalance < lowestBalance) {
        lowestBalance = currentBalance;
        lowestDay = day;
      }
    }

    // Determine if we need to alert
    String? status;
    if (lowestBalance < 0) {
      status = 'critical';
    } else if (lowestBalance < budget.dailyBudget * 3) {
      status = 'warning';
    } else if (lowestBalance < budget.dailyBudget * 7) {
      status = 'caution';
    }

    if (status == null) return null;

    return _generateInsight(
      context: context,
      status: status,
      lowestBalance: lowestBalance,
      lowestDay: lowestDay,
      projections: projections,
      currentBalance: budget.getRemaining(spentSoFar),
    );
  }

  bool _isExpectedPayday(DateTime date) {
    // Common payday patterns: last day of month, 15th, 1st
    final lastDayOfMonth = DateTime(date.year, date.month + 1, 0).day;
    return date.day == lastDayOfMonth ||
        date.day == 15 ||
        date.day == 1;
  }

  BehavioralInsightEntity _generateInsight({
    required RuleContext context,
    required String status,
    required double lowestBalance,
    required int lowestDay,
    required Map<int, double> projections,
    required double currentBalance,
  }) {
    final profile = context.profile;
    final personality = profile.personalityType;

    final title = _getTitle(personality, status);
    final message = _getMessage(
      personality,
      status,
      lowestBalance,
      lowestDay,
      currentBalance,
    );
    final icon = _getIcon(status);
    final priority = _getPriority(status);

    return BehavioralInsightEntity.create(
      ruleId: id,
      category: category,
      title: title,
      message: message,
      icon: icon,
      priority: priority,
      actionLabel: _getActionLabel(status),
      actionDeepLink: 'app://cashflow',
      metadata: {
        'lowestBalance': lowestBalance,
        'lowestDay': lowestDay,
        'forecastDays': forecastDays,
        'currentBalance': currentBalance,
        'status': status,
      },
      expiresIn: const Duration(hours: 48),
    );
  }

  String _getTitle(MoneyPersonalityType personality, String status) {
    if (status == 'critical') {
      return 'Cash Flow Warning: Negative Balance';
    }
    return 'Cash Flow Forecast';
  }

  String _getMessage(
    MoneyPersonalityType personality,
    String status,
    double lowestBalance,
    int lowestDay,
    double currentBalance,
  ) {
    final deficit = lowestBalance.abs();
    final daysUntilLow = lowestDay;

    switch (status) {
      case 'critical':
        return 'Based on your spending patterns, your account will run \$${deficit.toStringAsFixed(0)} short '
            'in $daysUntilLow days. '
            'You need to reduce spending or move funds before then to avoid problems.';

      case 'warning':
        return 'Your balance will drop to \$${lowestBalance.toStringAsFixed(0)} in $daysUntilLow days. '
            'That\'s less than 3 days of budget. Consider slowing down spending now.';

      case 'caution':
        return 'Forecast shows your balance reaching \$${lowestBalance.toStringAsFixed(0)} '
            'in $daysUntilLow days. You\'ll still be positive, but tight. Watch your spending.';

      default:
        return '';
    }
  }

  String _getIcon(String status) {
    switch (status) {
      case 'critical':
        return '⚠️';
      case 'warning':
        return '📉';
      case 'caution':
        return '📊';
      default:
        return '💰';
    }
  }

  InsightPriority _getPriority(String status) {
    switch (status) {
      case 'critical':
        return InsightPriority.critical;
      case 'warning':
        return InsightPriority.high;
      default:
        return InsightPriority.medium;
    }
  }

  String? _getActionLabel(String status) {
    if (status == 'critical') return 'Fix Cash Flow';
    if (status == 'warning') return 'View Forecast';
    return null;
  }

  @override
  bool shouldRunForProfile(UserProfileEntity profile) {
    return profile.isCategoryEnabled(category) &&
        profile.stressLevel != FinancialStressLevel.low;
  }

  @override
  bool shouldRunForTrigger(DeliveryTrigger trigger) {
    return triggers.contains(trigger);
  }

  @override
  Duration get estimatedExecutionTime => const Duration(milliseconds: 80);
}
