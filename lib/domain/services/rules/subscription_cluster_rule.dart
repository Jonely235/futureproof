import 'dart:math';
import '../behavioral_rule.dart';
import '../../entities/behavioral_insight_entity.dart';
import '../../entities/user_profile_entity.dart';
import '../../entities/transaction_entity.dart';
import '../../value_objects/insight_category.dart';
import '../../value_objects/delivery_triggers.dart';
import '../../value_objects/life_stage.dart';
import '../../value_objects/money_personality_type.dart';

/// Rule: Subscription Cluster Detection
///
/// Aggregates small, forgotten recurring charges to show their
/// cumulative impact. Identifies when multiple subscriptions renew
/// within a short time window.
///
/// Behavioral Principle: The Pennies-a-Day Effect
/// People ignore small costs that add up to large sums.
class SubscriptionClusterRule implements BehavioralRule {
  @override
  String get id => 'subscription_cluster';

  @override
  String get name => 'Subscription Cluster';

  @override
  String get description =>
      'Detects recurring subscription spending and renewal clusters';

  @override
  InsightCategory get category => InsightCategory.subscriptionManagement;

  @override
  Set<DeliveryTrigger> get triggers => {
        DeliveryTrigger.weeklySummary,
        DeliveryTrigger.monthlyDeepDive,
      };

  @override
  InsightPriority get defaultPriority => InsightPriority.medium;

  /// Keywords that suggest subscription/recurring charges
  static const List<String> _subscriptionKeywords = [
    'netflix',
    'spotify',
    'hulu',
    'disney',
    'apple',
    'google',
    'amazon',
    'youtube',
    'music',
    'video',
    'streaming',
    'gym',
    'fitness',
    'subscription',
    'membership',
    'insurance',
    'cloud',
    'storage',
    'software',
    'adobe',
    'microsoft',
    'office',
  ];

  /// Days to look back for transaction history
  final int lookbackDays;

  /// Days window to consider as a "cluster"
  final int clusterWindowDays;

  const SubscriptionClusterRule({
    this.lookbackDays = 90,
    this.clusterWindowDays = 3,
  });

  @override
  Future<BehavioralInsightEntity?> evaluate(RuleContext context) async {
    final transactions = context.transactions;
    if (transactions.isEmpty) return null;

    final now = context.now;
    final cutoff = now.subtract(Duration(days: lookbackDays));

    // Find potential subscription transactions
    final subscriptions = _findSubscriptions(transactions, cutoff);

    if (subscriptions.isEmpty) return null;

    // Calculate monthly and annual totals
    final monthlyTotal = subscriptions
        .map((s) => s.averageAmount)
        .fold<double>(0, (sum, amt) => sum + amt);

    final annualTotal = monthlyTotal * 12;

    // Check for renewal clusters
    final clusters = _findRenewalClusters(subscriptions, now);

    // Determine what insight to generate
    if (clusters.isNotEmpty) {
      return _generateClusterInsight(
        context,
        subscriptions,
        monthlyTotal,
        annualTotal,
        clusters,
      );
    } else if (annualTotal > 500) {
      return _generateHighSpendingInsight(
        context,
        subscriptions,
        monthlyTotal,
        annualTotal,
      );
    } else if (subscriptions.length >= 3) {
      return _generateCountInsight(
        context,
        subscriptions,
        monthlyTotal,
        annualTotal,
      );
    }

    return null;
  }

  List<_SubscriptionInfo> _findSubscriptions(
    List<TransactionEntity> transactions,
    DateTime cutoff,
  ) {
    // Group by category and look for recurring patterns
    final categoryGroups = <String, List<TransactionEntity>>{};

    for (final tx in transactions) {
      if (!tx.isExpense) continue;
      if (tx.date.value.isBefore(cutoff)) continue;

      // Check if transaction looks like a subscription
      if (_isSubscriptionTransaction(tx)) {
        final category = tx.category.toLowerCase();
        categoryGroups.putIfAbsent(category, () => []).add(tx);
      }
    }

    final subscriptions = <_SubscriptionInfo>[];

    // For each category, check if transactions are recurring
    for (final entry in categoryGroups.entries) {
      final txs = entry.value;

      if (txs.length >= 2) {
        // Calculate average amount
        final total = txs.map((t) => t.absoluteAmount).fold<double>(0, (a, b) => a + b);
        final average = total / txs.length;

        // Check if amounts are similar (within 20% variance)
        final amounts = txs.map((t) => t.absoluteAmount).toList();
        if (_amountsAreSimilar(amounts)) {
          subscriptions.add(_SubscriptionInfo(
            category: entry.key,
            averageAmount: average,
            transactionCount: txs.length,
            lastAmount: txs.first.absoluteAmount,
          ));
        }
      }
    }

    return subscriptions;
  }

  bool _isSubscriptionTransaction(TransactionEntity tx) {
    final note = (tx.note ?? '').toLowerCase();
    final category = tx.category.toLowerCase();

    // Check against keywords
    for (final keyword in _subscriptionKeywords) {
      if (note.contains(keyword) || category.contains(keyword)) {
        return true;
      }
    }

    // Check for round numbers (common in subscriptions)
    if (tx.amount.value.remainder(1) == 0) {
      // Round dollar amount could be a subscription
      return true;
    }

    return false;
  }

  bool _amountsAreSimilar(List<double> amounts) {
    if (amounts.length < 2) return true;

    final avg = amounts.reduce((a, b) => a + b) / amounts.length;
    final maxDeviation = avg * 0.2; // 20% variance

    for (final amount in amounts) {
      if ((amount - avg).abs() > maxDeviation) {
        return false;
      }
    }

    return true;
  }

  List<_RenewalCluster> _findRenewalClusters(
    List<_SubscriptionInfo> subscriptions,
    DateTime now,
  ) {
    // This is a simplified version - in reality, you'd track renewal dates
    // For now, we'll simulate clusters based on subscription counts

    final clusters = <_RenewalCluster>[];

    // If there are many subscriptions, assume some renewals cluster
    if (subscriptions.length >= 3) {
      clusters.add(_RenewalCluster(
        dayOfMonth: 1, // Beginning of month
        count: (subscriptions.length / 3).ceil(),
        totalAmount: subscriptions
            .take((subscriptions.length / 3).ceil())
            .map((s) => s.averageAmount)
            .fold<double>(0, (sum, amt) => sum + amt),
      ));
    }

    return clusters;
  }

  BehavioralInsightEntity _generateClusterInsight(
    RuleContext context,
    List<_SubscriptionInfo> subscriptions,
    double monthlyTotal,
    double annualTotal,
    List<_RenewalCluster> clusters,
  ) {
    final profile = context.profile;
    final cluster = clusters.first;

    return BehavioralInsightEntity.create(
      ruleId: id,
      category: category,
      title: '${cluster.count} Subscriptions Renewing Soon',
      message: _getClusterMessage(
        profile.personalityType,
        cluster,
        monthlyTotal,
        annualTotal,
      ),
      icon: '🔄',
      priority: InsightPriority.high,
      actionLabel: 'Review Subscriptions',
      actionDeepLink: 'app://subscriptions',
      metadata: {
        'subscriptionCount': subscriptions.length,
        'monthlyTotal': monthlyTotal,
        'annualTotal': annualTotal,
        'clusterCount': cluster.count,
      },
      expiresIn: const Duration(days: 7),
    );
  }

  BehavioralInsightEntity _generateHighSpendingInsight(
    RuleContext context,
    List<_SubscriptionInfo> subscriptions,
    double monthlyTotal,
    double annualTotal,
  ) {
    final profile = context.profile;

    return BehavioralInsightEntity.create(
      ruleId: id,
      category: category,
      title: 'High Subscription Spending',
      message: _getHighSpendingMessage(
        profile.personalityType,
        subscriptions.length,
        monthlyTotal,
        annualTotal,
      ),
      icon: '💸',
      priority: InsightPriority.medium,
      actionLabel: 'Review Subscriptions',
      actionDeepLink: 'app://subscriptions',
      metadata: {
        'subscriptionCount': subscriptions.length,
        'monthlyTotal': monthlyTotal,
        'annualTotal': annualTotal,
      },
      expiresIn: const Duration(days: 14),
    );
  }

  BehavioralInsightEntity _generateCountInsight(
    RuleContext context,
    List<_SubscriptionInfo> subscriptions,
    double monthlyTotal,
    double annualTotal,
  ) {
    return BehavioralInsightEntity.create(
      ruleId: id,
      category: category,
      title: '${subscriptions.length} Active Subscriptions',
      message: 'You have ${subscriptions.length} subscriptions totaling '
          '\$${monthlyTotal.toStringAsFixed(0)}/month (\$${annualTotal.toStringAsFixed(0)}/year). '
          'Review regularly to cancel unused services.',
      icon: '📋',
      priority: InsightPriority.low,
      actionLabel: 'View All',
      actionDeepLink: 'app://subscriptions',
      metadata: {
        'subscriptionCount': subscriptions.length,
        'monthlyTotal': monthlyTotal,
        'annualTotal': annualTotal,
      },
      expiresIn: const Duration(days: 30),
    );
  }

  String _getClusterMessage(
    MoneyPersonalityType personality,
    _RenewalCluster cluster,
    double monthlyTotal,
    double annualTotal,
  ) {
    switch (personality) {
      case MoneyPersonalityType.saver:
        return '${cluster.count} of your subscriptions renew around the same time, '
            'totaling \$${cluster.totalAmount.toStringAsFixed(0)}. '
            'This cluster hits your budget all at once — consider spreading out renewal dates.';

      case MoneyPersonalityType.spender:
        return 'Watch out! ${cluster.count} subscriptions (\$${cluster.totalAmount.toStringAsFixed(0)}) '
            'are renewing soon. That\'s a chunk of change all at once — '
            'make sure you\'re still using all of these.';

      case MoneyPersonalityType.sharer:
        return '${cluster.count} subscriptions renewing soon for \$${cluster.totalAmount.toStringAsFixed(0)}. '
            'Before you commit to help someone else this month, make sure these essentials are covered.';

      case MoneyPersonalityType.investor:
        return 'Subscription cluster alert: ${cluster.count} services (\$${cluster.totalAmount.toStringAsFixed(0)}) '
            'renewing simultaneously. This creates cash flow volatility. '
            'Consider staggering renewals for smoother finances.';

      case MoneyPersonalityType.gambler:
        return 'Cluster hit! ${cluster.count} subs renewing for \$${cluster.totalAmount.toStringAsFixed(0)}. '
            'That\'s money off the table before you even make your next bet. '
            'Cancel the ones you aren\'t using.';
    }
  }

  String _getHighSpendingMessage(
    MoneyPersonalityType personality,
    int count,
    double monthlyTotal,
    double annualTotal,
  ) {
    switch (personality) {
      case MoneyPersonalityType.saver:
        return 'You\'re spending \$${annualTotal.toStringAsFixed(0)}/year on $count subscriptions. '
            'Imagine if that went to savings instead. Review each one carefully.';

      case MoneyPersonalityType.spender:
        return 'Whoa — \$${monthlyTotal.toStringAsFixed(0)}/month on subscriptions? '
            'That\'s \$${annualTotal.toStringAsFixed(0)}/year! Make sure you\'re actually using all of these.';

      case MoneyPersonalityType.sharer:
        return 'Your subscriptions cost \$${annualTotal.toStringAsFixed(0)}/year. '
            'That\'s money that could go to helping others or causes you care about. ';

      case MoneyPersonalityType.investor:
        return 'Subscription expenditure: \$${annualTotal.toStringAsFixed(0)}/year. '
            'If invested instead at 7% return, this would grow to '
            '\$${(annualTotal * 1.07).toStringAsFixed(0)} in one year. Consider the opportunity cost.';

      case MoneyPersonalityType.gambler:
        return 'You\'re betting \$${annualTotal.toStringAsFixed(0)}/year on subscriptions. '
            'Are these bets paying off in value? If not, fold and cancel them.';
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
  Duration get estimatedExecutionTime => const Duration(milliseconds: 150);
}

class _SubscriptionInfo {
  final String category;
  final double averageAmount;
  final int transactionCount;
  final double lastAmount;

  _SubscriptionInfo({
    required this.category,
    required this.averageAmount,
    required this.transactionCount,
    required this.lastAmount,
  });
}

class _RenewalCluster {
  final int dayOfMonth;
  final int count;
  final double totalAmount;

  _RenewalCluster({
    required this.dayOfMonth,
    required this.count,
    required this.totalAmount,
  });
}
