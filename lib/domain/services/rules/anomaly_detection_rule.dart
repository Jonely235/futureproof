import 'dart:math';
import '../behavioral_rule.dart';
import '../rule_context_impl.dart';
import '../../entities/behavioral_insight_entity.dart';
import '../../entities/user_profile_entity.dart';
import '../../entities/transaction_entity.dart';
import '../../value_objects/insight_category.dart';
import '../../value_objects/delivery_triggers.dart';
import '../../value_objects/life_stage.dart';
import '../../value_objects/money_personality_type.dart';

/// Rule: Anomaly Detection
///
/// Detects transactions that deviate significantly from established spending patterns.
/// Identifies potential fraud, unconscious overspending, or unusual events.
///
/// Behavioral Principle: Salience
/// Highlighting outliers makes the cost of behavior more visible and prompts
/// conscious review rather than automatic spending.
class AnomalyDetectionRule implements BehavioralRule {
  @override
  String get id => 'anomaly_detection';

  @override
  String get name => 'Anomaly Detection';

  @override
  String get description =>
      'Detects spending that deviates from established norms';

  @override
  InsightCategory get category => InsightCategory.anomalyDetection;

  @override
  Set<DeliveryTrigger> get triggers => {
        DeliveryTrigger.postTransaction,
      };

  @override
  InsightPriority get defaultPriority => InsightPriority.high;

  /// Threshold multiplier for anomaly detection
  /// Transactions > this * median are flagged
  final double anomalyThreshold;

  /// Minimum transaction amount to consider (ignore very small amounts)
  final double minimumAmount;

  /// Minimum historical transactions needed for reliable detection
  final int minimumHistorySize;

  const AnomalyDetectionRule({
    this.anomalyThreshold = 2.5,
    this.minimumAmount = 50.0,
    this.minimumHistorySize = 3,
  });

  @override
  Future<BehavioralInsightEntity?> evaluate(RuleContext context) async {
    final transactions = context.transactions;
    if (transactions.isEmpty) return null;

    // Get the most recent transaction
    final recent = _getMostRecentExpense(context);
    if (recent == null) return null;

    // Skip small transactions
    if (recent.absoluteAmount < minimumAmount) return null;

    // Get historical transactions in this category (excluding today)
    final now = context.now;
    final todayStart = DateTime(now.year, now.month, now.day);

    final history = transactions.where((t) =>
        t.isExpense &&
        t.category == recent.category &&
        t.date.value.isBefore(todayStart)
    ).toList();

    if (history.length < minimumHistorySize) return null;

    // Calculate statistics
    final amounts = history.map((t) => t.absoluteAmount).toList();
    final median = _calculateMedian(amounts);
    final mean = amounts.reduce((a, b) => a + b) / amounts.length;

    // Skip if median is too small
    if (median < minimumAmount / 2) return null;

    // Check if recent transaction is anomalous
    final ratio = recent.absoluteAmount / median;
    final isAnomaly = ratio >= anomalyThreshold;

    if (!isAnomaly) return null;

    // Generate insight
    return _generateInsight(
      context: context,
      transaction: recent,
      median: median,
      mean: mean,
      ratio: ratio,
      historySize: history.length,
    );
  }

  TransactionEntity? _getMostRecentExpense(RuleContext context) {
    final transactions = context.transactions;
    if (transactions.isEmpty) return null;

    // Sort by date descending and get first expense
    final sorted = List<TransactionEntity>.from(transactions)
      ..sort((a, b) => b.date.value.compareTo(a.date.value));

    for (final t in sorted) {
      if (t.isExpense) return t;
    }

    return null;
  }

  double _calculateMedian(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) {
      return sorted[mid];
    } else {
      return (sorted[mid - 1] + sorted[mid]) / 2;
    }
  }

  BehavioralInsightEntity _generateInsight({
    required RuleContext context,
    required TransactionEntity transaction,
    required double median,
    required double mean,
    required double ratio,
    required int historySize,
  }) {
    final profile = context.profile;
    final personality = profile.personalityType;

    final title = _getTitle(personality, transaction.category);
    final message = _getMessage(
      personality,
      transaction,
      median,
      ratio,
      historySize,
    );
    final icon = _getIcon(ratio);

    return BehavioralInsightEntity.create(
      ruleId: id,
      category: category,
      title: title,
      message: message,
      icon: icon,
      priority: ratio > 4 ? InsightPriority.critical : defaultPriority,
      actionLabel: 'Review Transaction',
      actionDeepLink: 'app://transactions/${transaction.id}',
      metadata: {
        'transactionId': transaction.id,
        'amount': transaction.amount,
        'category': transaction.category,
        'median': median,
        'mean': mean,
        'ratio': ratio,
        'historySize': historySize,
      },
      expiresIn: const Duration(days: 7),
    );
  }

  String _getTitle(MoneyPersonalityType personality, String category) {
    final titles = {
      MoneyPersonalityType.saver: 'Unusual $category Expense',
      MoneyPersonalityType.spender: 'Big $category Purchase',
      MoneyPersonalityType.sharer: 'Unexpected $category Cost',
      MoneyPersonalityType.investor: 'Outlier in $category',
      MoneyPersonalityType.gambler: 'Risk: Large $category Charge',
    };

    return titles[personality] ?? 'Unusual Spending';
  }

  String _getMessage(
    MoneyPersonalityType personality,
    TransactionEntity transaction,
    double median,
    double ratio,
    int historySize,
  ) {
    final amount = transaction.absoluteAmount;
    final category = transaction.category;
    final multiplier = (ratio).toStringAsFixed(1);

    switch (personality) {
      case MoneyPersonalityType.saver:
        return 'This \$${amount.toStringAsFixed(0)} $category charge is $multiplier× '
            'your normal \$${median.toStringAsFixed(0)} for this category. '
            'Was this intentional, or should you dispute it?';

      case MoneyPersonalityType.spender:
        return 'Whoa — \$${amount.toStringAsFixed(0)} on $category? '
            'That\'s $multiplier× your usual spending. '
            'Treating yourself or did this slip by?';

      case MoneyPersonalityType.sharer:
        return 'You spent \$${amount.toStringAsFixed(0)} on $category — '
            '$multiplier× more than your typical \$${median.toStringAsFixed(0)}. '
            'Make sure this aligns with your values before it becomes a habit.';

      case MoneyPersonalityType.investor:
        return 'Transaction variance alert: \$${amount.toStringAsFixed(0)} in $category '
            'represents a ${(ratio * 100).toStringAsFixed(0)}% deviation from your '
            'historical median of \$${median.toStringAsFixed(0)}. Verify this expense.';

      case MoneyPersonalityType.gambler:
        return 'Big bet here: \$${amount.toStringAsFixed(0)} on $category is $multiplier× '
            'your average. Hope this was a winner! If not, time to cut your losses.';

      default:
        return 'This $category charge of \$${amount.toStringAsFixed(0)} is '
            '$multiplier× your normal \$${median.toStringAsFixed(0)} spending. '
            'Was this a special occasion?';
    }
  }

  String _getIcon(double ratio) {
    if (ratio >= 5) return '🚨';
    if (ratio >= 3) return '⚠️';
    return '🔍';
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
  Duration get estimatedExecutionTime => const Duration(milliseconds: 100);
}
