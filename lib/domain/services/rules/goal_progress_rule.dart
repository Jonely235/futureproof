import '../behavioral_rule.dart';
import '../../entities/behavioral_insight_entity.dart';
import '../../entities/user_profile_entity.dart';
import '../../entities/budget_entity.dart';
import '../../value_objects/insight_category.dart';
import '../../value_objects/delivery_triggers.dart';
import '../../value_objects/life_stage.dart';
import '../../value_objects/money_personality_type.dart';

/// Rule: Goal Progress and Projection
///
/// Tracks progress toward savings goals and projects completion date.
/// Uses Goal Gradient Effect - people work harder as they get closer to a goal.
///
/// Behavioral Principle: Goal Gradient Effect
/// People work harder as they get closer to a goal. Showing progress
/// creates momentum.
class GoalProgressRule implements BehavioralRule {
  @override
  String get id => 'goal_progress';

  @override
  String get name => 'Goal Progress';

  @override
  String get description =>
      'Tracks savings goal progress and projects completion';

  @override
  InsightCategory get category => InsightCategory.goalProgress;

  @override
  Set<DeliveryTrigger> get triggers => {
        DeliveryTrigger.weeklySummary,
        DeliveryTrigger.monthlyDeepDive,
      };

  @override
  InsightPriority get defaultPriority => InsightPriority.low;

  /// Milestone percentages for generating insights
  static const List<double> milestones = [0.25, 0.50, 0.75, 0.80, 0.90, 1.0];

  @override
  Future<BehavioralInsightEntity?> evaluate(RuleContext context) async {
    final budget = context.budget;
    if (budget == null) return null;

    final goalAmount = budget.savingsGoal;
    if (goalAmount <= 0) return null;

    // Calculate current savings
    // For this implementation, we'll calculate from budget status
    final now = context.now;
    final monthStart = DateTime(now.year, now.month, 1);

    final spent = context.getTotalSpentInPeriod(monthStart, now);
    final remaining = budget.getRemaining(spent);

    // Assume savings is the remaining budget (simplified)
    final currentSavings = remaining > 0 ? remaining : 0.0;

    final progress = currentSavings / goalAmount;
    final monthsRemaining = (goalAmount - currentSavings) /
        (budget.savingsGoal > 0 ? budget.savingsGoal : budget.monthlyBudget * 0.1);

    // Determine which insight to generate
    if (progress >= 1.0) {
      return _generateGoalAchievedInsight(context, currentSavings, goalAmount);
    } else if (_isMilestone(progress)) {
      return _generateMilestoneInsight(
        context,
        currentSavings,
        goalAmount,
        progress,
        monthsRemaining,
      );
    } else if (progress >= 0.8) {
      return _generateNearGoalInsight(
        context,
        currentSavings,
        goalAmount,
        progress,
        monthsRemaining,
      );
    } else if (progress < 0.25 && monthsRemaining > 12) {
      return _generateOffTrackInsight(
        context,
        currentSavings,
        goalAmount,
        progress,
        monthsRemaining,
      );
    }

    return null;
  }

  bool _isMilestone(double progress) {
    for (final milestone in milestones) {
      // Check if we're close to a milestone (within 1%)
      if ((progress - milestone).abs() < 0.01) {
        return true;
      }
    }
    return false;
  }

  BehavioralInsightEntity _generateGoalAchievedInsight(
    RuleContext context,
    double current,
    double goal,
  ) {
    final profile = context.profile;

    return BehavioralInsightEntity.create(
      ruleId: id,
      category: category,
      title: '🎉 Goal Achieved!',
      message: _getAchievedMessage(profile.personalityType, current, goal),
      icon: '🏆',
      priority: InsightPriority.low,
      actionLabel: 'Set New Goal',
      actionDeepLink: 'app://goals',
      metadata: {
        'current': current,
        'goal': goal,
        'progress': 1.0,
        'achieved': true,
      },
      expiresIn: const Duration(days: 7),
    );
  }

  BehavioralInsightEntity _generateMilestoneInsight(
    RuleContext context,
    double current,
    double goal,
    double progress,
    double monthsRemaining,
  ) {
    final profile = context.profile;
    final percentage = (progress * 100).toInt();

    return BehavioralInsightEntity.create(
      ruleId: id,
      category: category,
      title: '$percentage% to Goal!',
      message: _getMilestoneMessage(
        profile.personalityType,
        current,
        goal,
        percentage,
        monthsRemaining,
      ),
      icon: _getMilestoneIcon(progress),
      priority: percentage >= 80 ? InsightPriority.medium : InsightPriority.low,
      actionLabel: 'Add to Savings',
      actionDeepLink: 'app://goals',
      metadata: {
        'current': current,
        'goal': goal,
        'progress': progress,
        'percentage': percentage,
        'milestone': true,
      },
      expiresIn: const Duration(days: 3),
    );
  }

  BehavioralInsightEntity _generateNearGoalInsight(
    RuleContext context,
    double current,
    double goal,
    double progress,
    double monthsRemaining,
  ) {
    final remaining = goal - current;
    final percentage = (progress * 100).toInt();

    return BehavioralInsightEntity.create(
      ruleId: id,
      category: category,
      title: 'Almost There!',
      message: 'You\'re $percentage% to your goal! '
          'Just \$${remaining.toStringAsFixed(0)} more to go. '
          'At your current pace, you\'ll reach it in ${monthsRemaining.round()} months.',
      icon: '🎯',
      priority: InsightPriority.low,
      actionLabel: 'Accelerate',
      actionDeepLink: 'app://goals',
      metadata: {
        'current': current,
        'goal': goal,
        'progress': progress,
        'remaining': remaining,
      },
      expiresIn: const Duration(days: 7),
    );
  }

  BehavioralInsightEntity _generateOffTrackInsight(
    RuleContext context,
    double current,
    double goal,
    double progress,
    double monthsRemaining,
  ) {
    final percentage = (progress * 100).toInt();
    final personality = context.profile.personalityType;

    return BehavioralInsightEntity.create(
      ruleId: id,
      category: category,
      title: 'Goal Progress Update',
      message: _getOffTrackMessage(personality, current, goal, percentage, monthsRemaining),
      icon: '📈',
      priority: InsightPriority.medium,
      actionLabel: 'Adjust Goal',
      actionDeepLink: 'app://goals',
      metadata: {
        'current': current,
        'goal': goal,
        'progress': progress,
        'offTrack': true,
      },
      expiresIn: const Duration(days: 7),
    );
  }

  String _getAchievedMessage(
    MoneyPersonalityType personality,
    double current,
    double goal,
  ) {
    switch (personality) {
      case MoneyPersonalityType.saver:
        return 'You did it! Your goal of \$${goal.toStringAsFixed(0)} has been reached. '
            'All that discipline paid off. What\'s your next target?';

      case MoneyPersonalityType.spender:
        return 'Amazing! You hit your savings goal of \$${goal.toStringAsFixed(0)}! '
            'You proved you can do it. Time to celebrate (within reason) and set a new goal!';

      case MoneyPersonalityType.sharer:
        return 'Goal achieved! You\'ve saved \$${goal.toStringAsFixed(0)}. '
            'Your financial stability now lets you help others even more. ';

      case MoneyPersonalityType.investor:
        return 'Target reached: \$${goal.toStringAsFixed(0)}. '
            'This capital can now be deployed for growth. Consider your next investment move.';

      case MoneyPersonalityType.gambler:
        return 'Jackpot! You hit your savings goal! That\'s a win in anyone\'s book. '
            'Ready to double down on your next goal?';
    }
  }

  String _getMilestoneMessage(
    MoneyPersonalityType personality,
    double current,
    double goal,
    int percentage,
    double monthsRemaining,
  ) {
    switch (personality) {
      case MoneyPersonalityType.saver:
        return '$percentage% complete! You\'ve saved \$${current.toStringAsFixed(0)} '
            'toward your \$${goal.toStringAsFixed(0)} goal. '
            'Keep this pace and you\'ll finish in ${monthsRemaining.round()} months.';

      case MoneyPersonalityType.spender:
        return '$percentage% there! You\'ve saved \$${current.toStringAsFixed(0)} so far. '
            'The finish line is getting closer — stay motivated!';

      case MoneyPersonalityType.sharer:
        return '$percentage% to your goal! \$${current.toStringAsFixed(0)} saved means '
            'you\'re building real security for yourself and those you care about.';

      case MoneyPersonalityType.investor:
        return '$percentage% capital accumulation. Current: \$${current.toStringAsFixed(0)}, '
            'Target: \$${goal.toStringAsFixed(0)}. Projected completion: ${monthsRemaining.round()} months.';

      case MoneyPersonalityType.gambler:
        return '$percentage% in the bag! You\'ve got \$${current.toStringAsFixed(0)} '
            'on \$${goal.toStringAsFixed(0)}. The house hasn\'t won this round — keep going!';
    }
  }

  String _getOffTrackMessage(
    MoneyPersonalityType personality,
    double current,
    double goal,
    int percentage,
    double monthsRemaining,
  ) {
    switch (personality) {
      case MoneyPersonalityType.saver:
        return 'You\'re at $percentage% of your \$${goal.toStringAsFixed(0)} goal '
            'with \$${current.toStringAsFixed(0)} saved. '
            'At this pace, it\'ll take ${monthsRemaining.round()} months. Consider increasing contributions.';

      case MoneyPersonalityType.spender:
        return 'Progress check: $percentage% to your goal with \$${current.toStringAsFixed(0)} saved. '
            'To get there faster, try automating your savings.';

      case MoneyPersonalityType.sharer:
        return 'You\'ve saved $percentage% of your goal so far (\$${current.toStringAsFixed(0)}). '
            'Building this security will help you help others long-term.';

      case MoneyPersonalityType.investor:
        return 'Goal velocity analysis: $percentage% complete. '
        'Current trajectory: ${monthsRemaining.round()} months to target. '
        'Consider increasing contribution rate for better ROI.';

      case MoneyPersonalityType.gambler:
        return 'You\'re at $percentage% with \$${current.toStringAsFixed(0)} saved. '
            'The odds of hitting your goal on time are low. Time to increase your bet — contribute more!';
    }
  }

  String _getMilestoneIcon(double progress) {
    if (progress >= 1.0) return '🏆';
    if (progress >= 0.9) return '🎯';
    if (progress >= 0.75) return '⭐';
    if (progress >= 0.5) return '📈';
    return '💰';
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
