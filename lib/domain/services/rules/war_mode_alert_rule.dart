import '../behavioral_rule.dart';
import '../../entities/behavioral_insight_entity.dart';
import '../../entities/user_profile_entity.dart';
import '../../entities/war_mode_entity.dart';
import '../../entities/budget_entity.dart';
import '../../value_objects/insight_category.dart';
import '../../value_objects/delivery_triggers.dart';
import '../../value_objects/life_stage.dart';
import '../../value_objects/money_personality_type.dart';

/// Rule: War Mode Alert
///
/// Activates during financial crisis periods (low runway, high volatility).
/// Switches UI to "survival budgeting" — focusing only on essentials.
///
/// Behavioral Principle: Scarcity Mindset Management
/// During high stress, cognitive load increases. The system simplifies
/// to focus only on survival, reducing decision paralysis.
class WarModeAlertRule implements BehavioralRule {
  @override
  String get id => 'war_mode_alert';

  @override
  String get name => 'War Mode Alert';

  @override
  String get description =>
      'Crisis mode alerts for periods of financial stress';

  @override
  InsightCategory get category => InsightCategory.warMode;

  @override
  Set<DeliveryTrigger> get triggers => {
        DeliveryTrigger.appOpen,
        DeliveryTrigger.morningDigest,
        DeliveryTrigger.preDecision,
      };

  @override
  InsightPriority get defaultPriority => InsightPriority.critical;

  /// Runway thresholds for war mode levels
  final double criticalRunwayDays;
  final double warningRunwayDays;

  const WarModeAlertRule({
    this.criticalRunwayDays = 7, // Red alert: less than a week
    this.warningRunwayDays = 14, // Yellow alert: less than two weeks
  });

  @override
  Future<BehavioralInsightEntity?> evaluate(RuleContext context) async {
    final warMode = context.warMode;
    if (warMode == null) return null;

    // Check if war mode is active (red level)
    if (warMode.level != WarModeLevel.red) {
      // Still generate a warning if yellow
      if (warMode.level == WarModeLevel.yellow) {
        return _generateWarningAlert(context, warMode.runwayDays);
      }
      return null;
    }

    final runwayDays = warMode.runwayDays;

    // Generate alert based on runway
    if (runwayDays <= criticalRunwayDays) {
      return _generateCriticalAlert(context, runwayDays);
    }

    return null;
  }

  /// Calculate war mode status from budget and spending
  static WarModeEntity calculateFromBudget({
    required BudgetEntity budget,
    required double currentBalance,
    required double dailyAverageSpend,
  }) {
    // Calculate runway in days
    final runwayDays = dailyAverageSpend > 0
        ? currentBalance / dailyAverageSpend
        : double.infinity;

    // Determine level
    final level = runwayDays < 7
        ? WarModeLevel.red
        : runwayDays < 14
            ? WarModeLevel.yellow
            : WarModeLevel.green;

    return WarModeEntity(
      runwayDays: runwayDays,
      level: level,
      dailyAverageSpend: dailyAverageSpend,
      currentCash: currentBalance,
      calculatedAt: DateTime.now(),
    );
  }

  BehavioralInsightEntity _generateCriticalAlert(
    RuleContext context,
    double runwayDays,
  ) {
    final profile = context.profile;

    return BehavioralInsightEntity.create(
      ruleId: id,
      category: category,
      title: '⚠️ WAR MODE ACTIVATED',
      message: _getCriticalMessage(profile),
      icon: '🚨',
      priority: InsightPriority.critical,
      actionLabel: 'View Survival Budget',
      actionDeepLink: 'app://warmode',
      metadata: {
        'runwayDays': runwayDays,
        'level': 'critical',
        'survivalMode': true,
      },
      expiresIn: const Duration(hours: 12),
    );
  }

  BehavioralInsightEntity _generateWarningAlert(
    RuleContext context,
    double runwayDays,
  ) {
    final profile = context.profile;

    return BehavioralInsightEntity.create(
      ruleId: id,
      category: category,
      title: 'Low Runway Warning',
      message: _getWarningMessage(profile, runwayDays),
      icon: '⚠️',
      priority: InsightPriority.high,
      actionLabel: 'Review Budget',
      actionDeepLink: 'app://budget',
      metadata: {
        'runwayDays': runwayDays,
        'level': 'warning',
      },
      expiresIn: const Duration(hours: 24),
    );
  }

  String _getCriticalMessage(UserProfileEntity profile) {
    final personality = profile.personalityType;

    final baseMessage = 'CRITICAL: You have less than a week of funds remaining. '
        'War Mode is now active. Focus ONLY on: Housing, Food, Essential Utilities. '
        'All other spending is paused until further notice.';

    final personalityAppend = {
      MoneyPersonalityType.saver: ' Use your reserve funds now — this is what you saved for.',
      MoneyPersonalityType.spender: ' Stop all non-essential spending immediately. No exceptions.',
      MoneyPersonalityType.sharer: ' You cannot help others if you don\'t survive. Focus on yourself first.',
      MoneyPersonalityType.investor: ' Consider this a liquidity crisis. Preserve cash above all else.',
      MoneyPersonalityType.gambler: ' The house always wins. Stop playing — you\'re in survival mode.',
    };

    return baseMessage + (personalityAppend[personality] ?? '');
  }

  String _getWarningMessage(UserProfileEntity profile, double runwayDays) {
    final days = runwayDays.floor();
    return 'Your runway is down to $days day${days > 1 ? 's' : ''}. '
        'If War Mode activates, the app will switch to survival budgeting — '
        'showing only essential expenses. Consider reducing spending now to avoid this.';
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
  Duration get estimatedExecutionTime => const Duration(milliseconds: 30);
}
