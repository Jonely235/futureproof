import 'behavioral_rule.dart';
import '../entities/behavioral_insight_entity.dart';
import '../entities/user_profile_entity.dart';
import '../entities/transaction_entity.dart';
import '../entities/budget_entity.dart';
import '../entities/streak_entity.dart';
import '../entities/war_mode_entity.dart';
import '../repositories/user_profile_repository.dart';
import '../repositories/behavioral_insight_repository.dart';
import '../value_objects/delivery_triggers.dart';
import '../value_objects/insight_category.dart';
import '../value_objects/life_stage.dart';

/// Engine for evaluating behavioral rules and generating insights
/// Orchestrates rule execution, deduplication, and storage
class BehavioralInsightEngine {
  final UserProfileRepository _profileRepository;
  final BehavioralInsightRepository _insightRepository;

  /// Registered rules indexed by ID
  final Map<String, BehavioralRule> _rules = {};

  /// Rules indexed by category for quick lookup
  final Map<InsightCategory, List<BehavioralRule>> _rulesByCategory = {};

  /// Rules indexed by trigger for quick lookup
  final Map<DeliveryTrigger, List<BehavioralRule>> _rulesByTrigger = {};

  BehavioralInsightEngine({
    required UserProfileRepository profileRepository,
    required BehavioralInsightRepository insightRepository,
  })  : _profileRepository = profileRepository,
        _insightRepository = insightRepository;

  /// Register a rule with the engine
  void registerRule(BehavioralRule rule) {
    _rules[rule.id] = rule;

    // Index by category
    _rulesByCategory.putIfAbsent(rule.category, () => []).add(rule);

    // Index by trigger
    for (final trigger in rule.triggers) {
      _rulesByTrigger.putIfAbsent(trigger, () => []).add(rule);
    }
  }

  /// Register multiple rules at once
  void registerRules(List<BehavioralRule> rules) {
    for (final rule in rules) {
      registerRule(rule);
    }
  }

  /// Unregister a rule from the engine
  void unregisterRule(String ruleId) {
    final rule = _rules.remove(ruleId);
    if (rule != null) {
      _rulesByCategory[rule.category]?.remove(rule);
      for (final trigger in rule.triggers) {
        _rulesByTrigger[trigger]?.remove(rule);
      }
    }
  }

  /// Get all registered rules
  List<BehavioralRule> get allRules => _rules.values.toList();

  /// Get rules for a specific category
  List<BehavioralRule> getRulesForCategory(InsightCategory category) {
    return _rulesByCategory[category] ?? [];
  }

  /// Get rules for a specific trigger
  List<BehavioralRule> getRulesForTrigger(DeliveryTrigger trigger) {
    return _rulesByTrigger[trigger] ?? [];
  }

  /// Get rules that should run for the given profile
  List<BehavioralRule> getEnabledRules(UserProfileEntity profile) {
    return _rules.values
        .where((rule) => rule.shouldRunForProfile(profile))
        .toList();
  }

  /// Evaluate all rules and return generated insights
  /// This is the main entry point for insight generation
  Future<InsightEvaluationResult> evaluateRules({
    required DeliveryTrigger trigger,
    RuleContext? context,
  }) async {
    final startTime = DateTime.now();

    // Get current profile
    final profile = await _profileRepository.getCurrentProfile();
    if (profile == null) {
      return InsightEvaluationResult.noProfile();
    }

    // Get rules for this trigger
    final triggerRules = getRulesForTrigger(trigger);
    final enabledRules = triggerRules
        .where((rule) => rule.shouldRunForProfile(profile))
        .toList();

    if (enabledRules.isEmpty) {
      return InsightEvaluationResult.noRules(trigger);
    }

    // Evaluate each rule
    final results = <RuleResult>[];
    final insights = <BehavioralInsightEntity>[];

    for (final rule in enabledRules) {
      final ruleStart = DateTime.now();

      try {
        final insight = await rule.evaluate(context ?? _createContext(profile));

        final executionMs =
            DateTime.now().difference(ruleStart).inMilliseconds;

        if (insight != null) {
          results.add(RuleResult.success(
            ruleId: rule.id,
            insight: insight,
            executionMs: executionMs,
          ));
          insights.add(insight);
        } else {
          results.add(RuleResult.noInsight(
            ruleId: rule.id,
            executionMs: executionMs,
          ));
        }
      } catch (e, s) {
        results.add(RuleResult.failure(
          ruleId: rule.id,
          error: '$e',
          executionMs: DateTime.now().difference(ruleStart).inMilliseconds,
        ));
        // Continue evaluating other rules even if one fails
      }
    }

    // Deduplicate insights
    final uniqueInsights = _deduplicateInsights(insights);

    // Sort by priority
    uniqueInsights.sort((a, b) => b.priority.sortValue.compareTo(a.priority.sortValue));

    final duration = DateTime.now().difference(startTime);

    return InsightEvaluationResult(
      trigger: trigger,
      insights: uniqueInsights,
      results: results,
      durationMs: duration.inMilliseconds,
      rulesEvaluated: enabledRules.length,
    );
  }

  /// Evaluate rules and save insights to repository
  Future<InsightEvaluationResult> evaluateAndSave({
    required DeliveryTrigger trigger,
    RuleContext? context,
  }) async {
    final result = await evaluateRules(trigger: trigger, context: context);

    if (result.insights.isNotEmpty) {
      await _insightRepository.saveInsights(result.insights);
    }

    return result;
  }

  /// Evaluate a single rule by ID
  Future<BehavioralInsightEntity?> evaluateRule(
    String ruleId,
    RuleContext context,
  ) async {
    final rule = _rules[ruleId];
    if (rule == null) return null;

    final profile = await _profileRepository.getCurrentProfile();
    if (profile == null || !rule.shouldRunForProfile(profile)) {
      return null;
    }

    try {
      return await rule.evaluate(context);
    } catch (e) {
      return null;
    }
  }

  /// Deduplicate insights that are essentially the same
  List<BehavioralInsightEntity> _deduplicateInsights(
    List<BehavioralInsightEntity> insights,
  ) {
    final seen = <String>{};
    final unique = <BehavioralInsightEntity>[];

    for (final insight in insights) {
      // Create a signature based on rule and key message content
      final signature = '${insight.ruleId}_${insight.title}_${insight.category}';

      if (!seen.contains(signature)) {
        seen.add(signature);
        unique.add(insight);
      }
    }

    return unique;
  }

  /// Create a basic rule context
  /// Override this in subclasses or provide custom context
  RuleContext _createContext(UserProfileEntity profile) {
    return MinimalRuleContext(profile: profile);
  }
}

/// Result of insight evaluation
class InsightEvaluationResult {
  /// The trigger that initiated this evaluation
  final DeliveryTrigger trigger;

  /// The insights that were generated
  final List<BehavioralInsightEntity> insights;

  /// Individual rule results
  final List<RuleResult> results;

  /// Total evaluation time in milliseconds
  final int durationMs;

  /// Number of rules that were evaluated
  final int rulesEvaluated;

  const InsightEvaluationResult({
    required this.trigger,
    this.insights = const [],
    this.results = const [],
    required this.durationMs,
    required this.rulesEvaluated,
  });

  /// Factory for result when no profile exists
  factory InsightEvaluationResult.noProfile() {
    return InsightEvaluationResult(
      trigger: DeliveryTrigger.manual,
      insights: [],
      results: [],
      durationMs: 0,
      rulesEvaluated: 0,
    );
  }

  /// Factory for result when no rules match
  factory InsightEvaluationResult.noRules(DeliveryTrigger trigger) {
    return InsightEvaluationResult(
      trigger: trigger,
      insights: [],
      results: [],
      durationMs: 0,
      rulesEvaluated: 0,
    );
  }

  /// Number of insights generated
  int get insightsGenerated => insights.length;

  /// Number of rules that succeeded
  int get rulesSucceeded =>
      results.where((r) => r.generatedInsight || r.error == null).length;

  /// Number of rules that failed
  int get rulesFailed => results.where((r) => r.error != null).length;

  /// Whether this evaluation was successful
  bool get isSuccess => rulesFailed == 0;

  Map<String, dynamic> toMap() {
    return {
      'trigger': trigger.name,
      'insightsGenerated': insightsGenerated,
      'rulesEvaluated': rulesEvaluated,
      'rulesSucceeded': rulesSucceeded,
      'rulesFailed': rulesFailed,
      'durationMs': durationMs,
    };
  }
}

/// Minimal rule context for cases where full context isn't available
class MinimalRuleContext implements RuleContext {
  @override
  final UserProfileEntity profile;

  @override
  DateTime get now => DateTime.now();

  @override
  List<TransactionEntity> get transactions => [];

  @override
  BudgetEntity? get budget => null;

  @override
  StreakEntity? get streak => null;

  @override
  WarModeEntity? get warMode => null;

  const MinimalRuleContext({required this.profile});

  @override
  List<TransactionEntity> getTransactionsByCategory(String category) => [];

  @override
  List<TransactionEntity> getTransactionsInDateRange(
    DateTime start,
    DateTime end,
  ) =>
      [];

  @override
  double getTotalSpentInPeriod(DateTime start, DateTime end) => 0;

  @override
  double getTotalIncomeInPeriod(DateTime start, DateTime end) => 0;

  @override
  double getAverageDailySpend({int days = 30}) => 0;

  @override
  double getAverageWeeklySpend({int weeks = 4}) => 0;

  @override
  bool isCategoryTrendingUp(String category, {double threshold = 1.2}) => false;

  @override
  bool isCategoryTrendingDown(String category, {double threshold = 0.8}) =>
      false;

  @override
  String? getTopCategory(DateTime start, DateTime end) => null;

  @override
  Map<String, double> getSpendingByCategory(DateTime start, DateTime end) => {};

  @override
  int? getDaysUntilNextBill() => null;

  @override
  double getUpcomingBillsTotal({int days = 7}) => 0;
}
