import '../behavioral_rule.dart';
import '../../entities/behavioral_insight_entity.dart';
import '../../entities/user_profile_entity.dart';
import '../../entities/budget_entity.dart';
import '../../value_objects/insight_category.dart';
import '../../value_objects/delivery_triggers.dart';
import '../../value_objects/life_stage.dart';
import '../../value_objects/money_personality_type.dart';

/// Rule: Safe to Spend (Daily Budget Velocity)
///
/// Calculates the remaining budget divided by remaining days in the month
/// to give users a "daily safe spend" number.
///
/// Behavioral Principle: Anchoring and Adjustment
/// By providing a daily safe spend number, we set an anchor that helps
/// users regulate their daily behavior.
class SafeToSpendRule implements BehavioralRule {
  @override
  String get id => 'safe_to_spend_daily';

  @override
  String get name => 'Safe to Spend (Daily)';

  @override
  String get description =>
      'Calculates remaining budget divided by remaining days in month';

  @override
  InsightCategory get category => InsightCategory.budgetHealth;

  @override
  Set<DeliveryTrigger> get triggers => {
        DeliveryTrigger.morningDigest,
        DeliveryTrigger.preDecision,
      };

  @override
  InsightPriority get defaultPriority => InsightPriority.medium;

  /// Thresholds for generating insights
  static const double _criticalThreshold = 0.5; // 50% of daily budget
  static const double _warningThreshold = 0.8; // 80% of daily budget
  static const double _surplusThreshold = 1.2; // 120% of daily budget

  @override
  Future<BehavioralInsightEntity?> evaluate(RuleContext context) async {
    // Need budget to calculate safe to spend
    final budget = context.budget;
    if (budget == null) return null;

    final now = context.now;
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1)
        .subtract(const Duration(days: 1));

    // Don't run on the last day of month (no future days to project)
    if (now.day >= monthEnd.day) return null;

    // Calculate total spent this month
    final totalSpent = context.getTotalSpentInPeriod(monthStart, now);
    final remaining = budget.getRemaining(totalSpent);

    // Calculate days remaining
    final daysLeft = monthEnd.day - now.day;
    if (daysLeft <= 0) return null;

    // Calculate safe daily spend
    final safeToSpend = remaining / daysLeft;
    final dailyBudget = budget.dailyBudget;

    // If daily budget is 0 or negative, skip
    if (dailyBudget <= 0) return null;

    // Calculate ratio
    final ratio = dailyBudget > 0 ? safeToSpend / dailyBudget : 0;

    // Generate insight based on ratio
    return _generateInsight(
      context: context,
      safeToSpend: safeToSpend,
      dailyBudget: dailyBudget,
      ratio: ratio.toDouble(),
      remaining: remaining,
      daysLeft: daysLeft,
    );
  }

  BehavioralInsightEntity _generateInsight({
    required RuleContext context,
    required double safeToSpend,
    required double dailyBudget,
    required double ratio,
    required double remaining,
    required int daysLeft,
  }) {
    final profile = context.profile;
    String title;
    String message;
    String icon;
    InsightPriority priority;
    String? actionLabel;

    // Personalize based on personality and stress level
    final isHighStress = profile.stressLevel == FinancialStressLevel.high;
    final personality = profile.personalityType;

    if (ratio < _criticalThreshold) {
      // Critical: Spending way too fast
      priority = isHighStress ? InsightPriority.critical : InsightPriority.high;
      icon = '⚠️';
      actionLabel = 'View Budget';

      title = _personalizeTitle(personality, 'tight_budget', isHighStress);
      message = _personalizeCriticalMessage(
        personality,
        safeToSpend,
        dailyBudget,
        remaining,
        daysLeft,
        isHighStress,
      );
    } else if (ratio < _warningThreshold) {
      // Warning: Spending faster than ideal
      priority = InsightPriority.medium;
      icon = '⚡';
      actionLabel = null;

      title = _personalizeTitle(personality, 'caution_needed', false);
      message = _personalizeWarningMessage(
        personality,
        safeToSpend,
        dailyBudget,
        daysLeft,
      );
    } else if (ratio > _surplusThreshold) {
      // Surplus: Doing great, opportunity to save
      priority = InsightPriority.low;
      icon = '🎉';
      actionLabel = 'Move to Savings';

      title = _personalizeTitle(personality, 'extra_cushion', false);
      message = _personalizeSurplusMessage(
        personality,
        safeToSpend,
        dailyBudget,
        remaining,
      );
    } else {
      // On track
      priority = InsightPriority.low;
      icon = '✅';
      actionLabel = null;

      title = _personalizeTitle(personality, 'on_track', false);
      message = _personalizeOnTrackMessage(personality, safeToSpend, daysLeft);
    }

    return BehavioralInsightEntity.create(
      ruleId: id,
      category: category,
      title: title,
      message: message,
      icon: icon,
      priority: priority,
      actionLabel: actionLabel,
      actionDeepLink: actionLabel != null ? 'app://budget' : null,
      metadata: {
        'safeToSpend': safeToSpend,
        'dailyBudget': dailyBudget,
        'ratio': ratio.toDouble(),
        'remaining': remaining,
        'daysLeft': daysLeft,
      },
      expiresIn: const Duration(hours: 24),
    );
  }

  String _personalizeTitle(
    MoneyPersonalityType personality,
    String situation,
    bool isHighStress,
  ) {
    final titles = {
      'tight_budget': {
        MoneyPersonalityType.saver: 'Budget Running Low',
        MoneyPersonalityType.spender: 'Daily Budget Limited',
        MoneyPersonalityType.sharer: 'Tight on Funds',
        MoneyPersonalityType.investor: 'Cash Flow Alert',
        MoneyPersonalityType.gambler: 'Risk of Overspending',
      },
      'caution_needed': {
        MoneyPersonalityType.saver: 'Stay Vigilant',
        MoneyPersonalityType.spender: 'Pace Yourself',
        MoneyPersonalityType.sharer: 'Be Careful',
        MoneyPersonalityType.investor: 'Monitor Spending',
        MoneyPersonalityType.gambler: 'Slow Down',
      },
      'extra_cushion': {
        MoneyPersonalityType.saver: 'Opportunity to Save',
        MoneyPersonalityType.spender: 'Extra Room Today',
        MoneyPersonalityType.sharer: 'Surplus Available',
        MoneyPersonalityType.investor: 'Positive Variance',
        MoneyPersonalityType.gambler: 'Winning This Month',
      },
      'on_track': {
        MoneyPersonalityType.saver: 'Right on Target',
        MoneyPersonalityType.spender: 'Looking Good',
        MoneyPersonalityType.sharer: 'On Track',
        MoneyPersonalityType.investor: 'Optimal Pace',
        MoneyPersonalityType.gambler: 'Safe Zone',
      },
    };

    return titles[situation]?[personality] ?? 'Safe to Spend';
  }

  String _personalizeCriticalMessage(
    MoneyPersonalityType personality,
    double safeToSpend,
    double dailyBudget,
    double remaining,
    int daysLeft,
    bool isHighStress,
  ) {
    final shortfall = (1 - (safeToSpend / dailyBudget)) * 100;

    switch (personality) {
      case MoneyPersonalityType.saver:
        return 'You have \$${remaining.toStringAsFixed(0)} for $daysLeft days. '
            'That\'s \$${safeToSpend.toStringAsFixed(0)} per day — ${shortfall.toStringAsFixed(0)}% below your usual. '
            'Protect your remaining funds carefully.';

      case MoneyPersonalityType.spender:
        return 'Daily budget is \$${safeToSpend.toStringAsFixed(0)} for the next $daysLeft days. '
            'That\'s tighter than normal. Try to find free alternatives for today\'s plans.';

      case MoneyPersonalityType.sharer:
        return 'You have \$${remaining.toStringAsFixed(0)} left for $daysLeft days. '
            'Be selective about requests for help right now — you need to secure your own foundation first.';

      case MoneyPersonalityType.investor:
        return 'Cash flow projected at \$${safeToSpend.toStringAsFixed(0)}/day vs your \$${dailyBudget.toStringAsFixed(0)} baseline. '
            'Consider this a drawdown period — protect your liquidity.';

      case MoneyPersonalityType.gambler:
        return 'Daily budget cut to \$${safeToSpend.toStringAsFixed(0)} — ${shortfall.toStringAsFixed(0)}% below normal. '
            'Time to fold on unnecessary expenses. Play it safe for the rest of the month.';
    }
  }

  String _personalizeWarningMessage(
    MoneyPersonalityType personality,
    double safeToSpend,
    double dailyBudget,
    int daysLeft,
  ) {
    switch (personality) {
      case MoneyPersonalityType.saver:
        return 'Safe to spend: \$${safeToSpend.toStringAsFixed(0)}/day. '
            'A bit under your usual \$${dailyBudget.toStringAsFixed(0)}. Stay mindful today.';

      case MoneyPersonalityType.spender:
        return 'You\'ve got \$${safeToSpend.toStringAsFixed(0)} per day for $daysLeft days. '
            'Still room for fun, but maybe skip the impulse purchase.';

      case MoneyPersonalityType.sharer:
        return 'Daily budget: \$${safeToSpend.toStringAsFixed(0)}. '
            'Still enough to help others, but be thoughtful about how much.';

      case MoneyPersonalityType.investor:
        return 'Projected daily spend: \$${safeToSpend.toStringAsFixed(0)}. '
            'Slight variance from baseline — monitor your discretionary spending.';

      case MoneyPersonalityType.gambler:
        return 'Daily budget: \$${safeToSpend.toStringAsFixed(0)}. '
            'Not bad, but don\'t push your luck. Keep it conservative.';
    }
  }

  String _personalizeSurplusMessage(
    MoneyPersonalityType personality,
    double safeToSpend,
    double dailyBudget,
    double remaining,
  ) {
    final surplus = ((safeToSpend / dailyBudget) - 1) * 100;

    switch (personality) {
      case MoneyPersonalityType.saver:
        return 'Excellent! You\'re running ${surplus.toStringAsFixed(0)}% under budget. '
            'Move the extra to your savings goal before it gets spent elsewhere.';

      case MoneyPersonalityType.spender:
        return 'You\'ve got \$${safeToSpend.toStringAsFixed(0)} per day — ${surplus.toStringAsFixed(0)}% more than usual! '
            'You\'ve earned some guilt-free spending, or save it for something bigger.';

      case MoneyPersonalityType.sharer:
        return 'Great job! You have extra this month. '
            'Consider using your surplus to help others or give to a cause you care about.';

      case MoneyPersonalityType.investor:
        return 'Positive variance of ${surplus.toStringAsFixed(0)}%. '
            'This surplus could compound significantly if deployed to your investment accounts.';

      case MoneyPersonalityType.gambler:
        return 'You\'re up ${surplus.toStringAsFixed(0)}% this month! '
            'Cash out while you\'re ahead — move the winnings to savings.';
    }
  }

  String _personalizeOnTrackMessage(
    MoneyPersonalityType personality,
    double safeToSpend,
    int daysLeft,
  ) {
    switch (personality) {
      case MoneyPersonalityType.saver:
        return 'Safe to spend: \$${safeToSpend.toStringAsFixed(0)} per day. '
            'Right on target for $daysLeft days. Keep at it!';

      case MoneyPersonalityType.spender:
        return 'You\'ve got \$${safeToSpend.toStringAsFixed(0)} daily for $daysLeft days. '
            'Looking good — stay within this and you\'ll finish the month strong.';

      case MoneyPersonalityType.sharer:
        return 'Safe to spend: \$${safeToSpend.toStringAsFixed(0)}/day. '
            'Your generosity can continue at this pace — you\'re on track!';

      case MoneyPersonalityType.investor:
        return 'Daily spend projection: \$${safeToSpend.toStringAsFixed(0)}. '
            'Optimal velocity for your budget parameters.';

      case MoneyPersonalityType.gambler:
        return 'Safe to spend: \$${safeToSpend.toStringAsFixed(0)}. '
            'You\'re playing it safe and winning. Keep it steady.';
    }
  }

  @override
  bool shouldRunForProfile(UserProfileEntity profile) {
    return profile.isCategoryEnabled(category) &&
        profile.stressLevel != FinancialStressLevel.high;
  }

  @override
  bool shouldRunForTrigger(DeliveryTrigger trigger) {
    return triggers.contains(trigger);
  }

  @override
  Duration get estimatedExecutionTime => const Duration(milliseconds: 50);
}
