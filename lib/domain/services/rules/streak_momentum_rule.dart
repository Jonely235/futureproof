import '../behavioral_rule.dart';
import '../../entities/behavioral_insight_entity.dart';
import '../../entities/user_profile_entity.dart';
import '../../entities/streak_entity.dart';
import '../../value_objects/insight_category.dart';
import '../../value_objects/delivery_triggers.dart';
import '../../value_objects/life_stage.dart';
import '../../value_objects/money_personality_type.dart';

/// Rule: Streak and Momentum
///
/// Tracks consecutive days under budget and provides motivational feedback.
/// Uses the Goal Gradient Effect — people work harder as they get closer to a goal.
///
/// Behavioral Principle: Variable Reward
/// Unpredictable milestone rewards create stronger habit loops than predictable ones.
class StreakMomentumRule implements BehavioralRule {
  @override
  String get id => 'streak_momentum';

  @override
  String get name => 'Streak & Momentum';

  @override
  String get description =>
      'Tracks budget adherence streaks and provides motivation';

  @override
  InsightCategory get category => InsightCategory.streakAndMomentum;

  @override
  Set<DeliveryTrigger> get triggers => {
        DeliveryTrigger.morningDigest,
        DeliveryTrigger.postTransaction,
      };

  @override
  InsightPriority get defaultPriority => InsightPriority.low;

  /// Milestone days for special celebrations
  static const List<int> milestones = [3, 7, 14, 21, 30, 60, 90, 180, 365];

  @override
  Future<BehavioralInsightEntity?> evaluate(RuleContext context) async {
    final streak = context.streak;
    if (streak == null) return null;

    final currentStreak = streak.currentStreak;

    // Only generate insights for specific streak states
    if (currentStreak == 0) {
      return _generateStartInsight(context);
    } else if (_isMilestone(currentStreak)) {
      return _generateMilestoneInsight(context, currentStreak);
    } else if (_isNearMilestone(currentStreak)) {
      return _generateNearMilestoneInsight(context, currentStreak);
    } else if (_isAtRisk(context)) {
      return _generateAtRiskInsight(context, currentStreak);
    }

    return null;
  }

  /// Check if this is a milestone day
  bool _isMilestone(int streak) {
    return milestones.contains(streak);
  }

  /// Check if near a milestone (within 2 days)
  bool _isNearMilestone(int streak) {
    for (final milestone in milestones) {
      if (streak >= milestone - 2 && streak < milestone) {
        return true;
      }
    }
    return false;
  }

  /// Check if streak is at risk (spent more than 50% of daily budget already today)
  bool _isAtRisk(RuleContext context) {
    if (context.streak?.currentStreak == null || context.streak!.currentStreak < 3) {
      return false;
    }

    final budget = context.budget;
    if (budget == null) return false;

    final now = context.now;
    final todayStart = DateTime(now.year, now.month, now.day);
    final todaySpent = context.getTotalSpentInPeriod(todayStart, now);

    return todaySpent > budget.dailyBudget * 0.5;
  }

  BehavioralInsightEntity _generateStartInsight(RuleContext context) {
    final profile = context.profile;
    final personality = profile.personalityType;

    return BehavioralInsightEntity.create(
      ruleId: id,
      category: category,
      title: _getStartTitle(personality),
      message: _getStartMessage(personality),
      icon: '🔥',
      priority: InsightPriority.low,
      actionLabel: 'See Today\'s Budget',
      actionDeepLink: 'app://budget',
      metadata: {'streakStatus': 'start'},
      expiresIn: const Duration(hours: 12),
    );
  }

  BehavioralInsightEntity _generateMilestoneInsight(
    RuleContext context,
    int streak,
  ) {
    final profile = context.profile;
    final personality = profile.personalityType;

    return BehavioralInsightEntity.create(
      ruleId: id,
      category: category,
      title: _getMilestoneTitle(personality, streak),
      message: _getMilestoneMessage(personality, streak),
      icon: _getMilestoneIcon(streak),
      priority: streak >= 30 ? InsightPriority.medium : InsightPriority.low,
      actionLabel: 'View Streak',
      actionDeepLink: 'app://streak',
      metadata: {
        'streak': streak,
        'milestone': true,
      },
      expiresIn: const Duration(days: 2),
    );
  }

  BehavioralInsightEntity _generateNearMilestoneInsight(
    RuleContext context,
    int streak,
  ) {
    // Find the next milestone after the current streak
    // This function is only called when _isNearMilestone returns true,
    // which guarantees streak < milestone. However, we add orElse for safety.
    final nextMilestone = milestones.firstWhere(
      (m) => m > streak,
      orElse: () => milestones.last, // Fallback to max milestone (365)
    );
    final daysToGo = nextMilestone - streak;

    return BehavioralInsightEntity.create(
      ruleId: id,
      category: category,
      title: 'Almost There!',
      message: '$daysToGo more day${daysToGo > 1 ? 's' : ''} until your $nextMilestone-day milestone. '
          'Stay strong — you\'re building something great!',
      icon: '💪',
      priority: InsightPriority.low,
      actionLabel: null,
      metadata: {
        'streak': streak,
        'nextMilestone': nextMilestone,
        'daysToGo': daysToGo,
      },
      expiresIn: const Duration(hours: 24),
    );
  }

  BehavioralInsightEntity _generateAtRiskInsight(
    RuleContext context,
    int streak,
  ) {
    return BehavioralInsightEntity.create(
      ruleId: id,
      category: category,
      title: 'Protect Your Streak!',
      message: 'You\'re at $streak days and counting. '
          'You\'ve already spent more than half your daily budget. '
          'Hold off on more spending today to keep the streak alive.',
      icon: '⚠️',
      priority: InsightPriority.medium,
      actionLabel: 'View Budget',
      actionDeepLink: 'app://budget',
      metadata: {
        'streak': streak,
        'atRisk': true,
      },
      expiresIn: const Duration(hours: 6),
    );
  }

  String _getStartTitle(MoneyPersonalityType personality) {
    final titles = {
      MoneyPersonalityType.saver: 'Start Your Streak',
      MoneyPersonalityType.spender: 'New Day, New Chance',
      MoneyPersonalityType.sharer: 'Day One Begins',
      MoneyPersonalityType.investor: 'Initiate Streak',
      MoneyPersonalityType.gambler: 'First Bet: Yourself',
    };

    return titles[personality] ?? 'Start Your Streak';
  }

  String _getStartMessage(MoneyPersonalityType personality) {
    final messages = {
      MoneyPersonalityType.saver: 'Stay under budget today to begin your streak. '
          'You\'re great at this — let\'s prove it again.',

      MoneyPersonalityType.spender: 'A fresh start! Stay under budget today and '
          'kick off a new streak. You\'ve got this.',

      MoneyPersonalityType.sharer: 'Start small — just stay under budget today. '
          'Your future self (and those you help) will thank you.',

      MoneyPersonalityType.investor: 'Initiate streak protocol. '
          'One day of discipline compounds into long-term financial health.',

      MoneyPersonalityType.gambler: 'First bet of the day: yourself. '
          'Stay under budget and start a winning streak.',
    };

    return messages[personality] ??
        'Stay under budget today to begin your streak!';
  }

  String _getMilestoneTitle(MoneyPersonalityType personality, int streak) {
    if (streak >= 180) return 'Half Year Legend!';
    if (streak >= 90) return 'Quarter Year Master!';
    if (streak >= 60) return 'Two Month Champion!';
    if (streak >= 30) return 'Monthly Master!';
    if (streak >= 21) return 'Three Week Hero!';
    if (streak >= 14) return 'Two Week Warrior!';
    if (streak >= 7) return 'One Week Wonder!';
    if (streak >= 3) return 'Three Day Streak!';

    return 'Streak Started!';
  }

  String _getMilestoneMessage(MoneyPersonalityType personality, int streak) {
    final baseMessage = _getMilestoneBaseMessage(streak);

    final personalityTail = {
      MoneyPersonalityType.saver: ' Your consistency is paying off.',
      MoneyPersonalityType.spender: ' You\'re building real momentum!',
      MoneyPersonalityType.sharer: ' Your discipline will help others.',
      MoneyPersonalityType.investor: ' Compounding daily habits into wealth.',
      MoneyPersonalityType.gambler: ' You\'re beating the house!',
    };

    return baseMessage + (personalityTail[personality] ?? '');
  }

  String _getMilestoneBaseMessage(int streak) {
    if (streak >= 365) {
      return '$streak days! You\'re an absolute legend. This level of consistency is rare.';
    }
    if (streak >= 180) {
      return '$streak days! A full half year of discipline. You\'re unstoppable.';
    }
    if (streak >= 90) {
      return '$streak days! Three months of crushing it. You\'ve built a real habit.';
    }
    if (streak >= 60) {
      return '$streak days! Two months strong. This is becoming who you are.';
    }
    if (streak >= 30) {
      return '$streak days! A full month of budget mastery. Incredible work.';
    }
    if (streak >= 21) {
      return '$streak days! Three weeks! You\'ve proven you can do this.';
    }
    if (streak >= 14) {
      return '$streak days! Two weeks! Keep the momentum going.';
    }
    if (streak >= 7) {
      return '$streak days! A full week! Aim for two — you\'re on fire!';
    }
    return '$streak days! Great start! Keep it going!';
  }

  String _getMilestoneIcon(int streak) {
    if (streak >= 90) return '🏆';
    if (streak >= 30) return '👑';
    if (streak >= 14) return '🌟';
    if (streak >= 7) return '🔥';
    if (streak >= 3) return '✨';
    return '🔥';
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
