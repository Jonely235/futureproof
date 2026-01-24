import 'package:flutter_test/flutter_test.dart';
import 'package:futureproof/domain/entities/user_profile_entity.dart';
import 'package:futureproof/domain/entities/behavioral_insight_entity.dart';
import 'package:futureproof/domain/entities/transaction_entity.dart';
import 'package:futureproof/domain/services/rule_context_impl.dart';
import 'package:futureproof/domain/services/rules/anomaly_detection_rule.dart';
import 'package:futureproof/domain/value_objects/life_stage.dart';
import 'package:futureproof/domain/value_objects/money_personality_type.dart';
import 'package:futureproof/domain/value_objects/insight_category.dart';

void main() {
  group('AnomalyDetectionRule', () {
    late AnomalyDetectionRule rule;
    late UserProfileEntity profile;

    setUp(() {
      rule = const AnomalyDetectionRule(
        anomalyThreshold: 2.5,
        minimumAmount: 50.0,
        minimumHistorySize: 3,
      );

      profile = UserProfileEntity(
        id: 'test',
        personalityType: MoneyPersonalityType.spender,
        lifeStage: LifeStage.earlyCareer,
        stressLevel: FinancialStressLevel.medium,
        enabledInsightCategories: InsightCategory.values.toSet(),
        preferredDailyTime: const TimeOfDay(hour: 8, minute: 0),
        maxInsightsPerDay: 5,
        cooldownHours: 4,
        warModeEnabled: false,
        locationAlertsEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('has correct metadata', () {
      expect(rule.id, 'anomaly_detection');
      expect(rule.name, 'Anomaly Detection');
      expect(rule.category, InsightCategory.anomalyDetection);
      expect(rule.triggers, contains(DeliveryTrigger.postTransaction));
      expect(rule.defaultPriority, InsightPriority.high);
    });

    test('returns null when no transactions exist', () async {
      final context = RuleContextImpl(
        profile: profile,
        now: DateTime(2024, 1, 15),
        transactions: [],
      );

      final result = await rule.evaluate(context);

      expect(result, isNull);
    });

    test('returns null for transactions below minimum amount', () async {
      final transactions = [
        TransactionEntity(
          id: 'tx1',
          amount: -25, // Below $50 threshold
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 15, 12, 0)),
          note: null,
        ),
      ];

      final context = RuleContextImpl(
        profile: profile,
        now: DateTime(2024, 1, 15, 13, 0),
        transactions: transactions,
      );

      final result = await rule.evaluate(context);

      expect(result, isNull);
    });

    test('returns null when insufficient history exists', () async {
      final transactions = [
        // Only 2 historical transactions (below minimum of 3)
        TransactionEntity(
          id: 'tx1',
          amount: -60,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 14)),
          note: null,
        ),
        TransactionEntity(
          id: 'tx2',
          amount: -65,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 13)),
          note: null,
        ),
        // Recent anomalous transaction
        TransactionEntity(
          id: 'tx3',
          amount: -200,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 15, 12, 0)),
          note: null,
        ),
      ];

      final context = RuleContextImpl(
        profile: profile,
        now: DateTime(2024, 1, 15, 13, 0),
        transactions: transactions,
      );

      final result = await rule.evaluate(context);

      expect(result, isNull);
    });

    test('detects anomalous transaction (3x median)', () async {
      final transactions = [
        // Historical: normally spends ~$60 on Food
        TransactionEntity(
          id: 'tx1',
          amount: -55,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 10)),
          note: null,
        ),
        TransactionEntity(
          id: 'tx2',
          amount: -60,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 11)),
          note: null,
        ),
        TransactionEntity(
          id: 'tx3',
          amount: -65,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 12)),
          note: null,
        ),
        // Recent anomaly: $180 (3x the median)
        TransactionEntity(
          id: 'tx4',
          amount: -180,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 15, 12, 0)),
          note: null,
        ),
      ];

      final context = RuleContextImpl(
        profile: profile,
        now: DateTime(2024, 1, 15, 13, 0),
        transactions: transactions,
      );

      final result = await rule.evaluate(context);

      expect(result, isNotNull);
      expect(result!.category, InsightCategory.anomalyDetection);
      expect(result.priority, InsightPriority.high);
      expect(result.icon, '⚠️');
      expect(result.actionLabel, 'Review Transaction');
    });

    test('detects extreme anomaly (5x median) with critical priority', () async {
      final transactions = [
        // Historical: normally spends ~$50 on Food
        TransactionEntity(
          id: 'tx1',
          amount: -45,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 10)),
          note: null,
        ),
        TransactionEntity(
          id: 'tx2',
          amount: -50,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 11)),
          note: null,
        ),
        TransactionEntity(
          id: 'tx3',
          amount: -55,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 12)),
          note: null,
        ),
        // Recent extreme anomaly: $300 (6x the median)
        TransactionEntity(
          id: 'tx4',
          amount: -300,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 15, 12, 0)),
          note: null,
        ),
      ];

      final context = RuleContextImpl(
        profile: profile,
        now: DateTime(2024, 1, 15, 13, 0),
        transactions: transactions,
      );

      final result = await rule.evaluate(context);

      expect(result, isNotNull);
      expect(result!.category, InsightCategory.anomalyDetection);
      expect(result.priority, InsightPriority.critical);
      expect(result.icon, '🚨');
    });

    test('does not flag normal spending', () async {
      final transactions = [
        // Historical: spends ~$60 on Food
        TransactionEntity(
          id: 'tx1',
          amount: -55,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 10)),
          note: null,
        ),
        TransactionEntity(
          id: 'tx2',
          amount: -60,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 11)),
          note: null,
        ),
        TransactionEntity(
          id: 'tx3',
          amount: -65,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 12)),
          note: null,
        ),
        // Recent: $75 (within normal range)
        TransactionEntity(
          id: 'tx4',
          amount: -75,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 15, 12, 0)),
          note: null,
        ),
      ];

      final context = RuleContextImpl(
        profile: profile,
        now: DateTime(2024, 1, 15, 13, 0),
        transactions: transactions,
      );

      final result = await rule.evaluate(context);

      expect(result, isNull);
    });

    test('only considers transactions from same category', () async {
      final transactions = [
        // Food history
        TransactionEntity(
          id: 'tx1',
          amount: -30,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 10)),
          note: null,
        ),
        TransactionEntity(
          id: 'tx2',
          amount: -35,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 11)),
          note: null,
        ),
        TransactionEntity(
          id: 'tx3',
          amount: -40,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 12)),
          note: null,
        ),
        // Large Entertainment expense (different category, should not be anomaly)
        TransactionEntity(
          id: 'tx4',
          amount: -200,
          category: 'Entertainment',
          date: TransactionDate(DateTime(2024, 1, 15, 12, 0)),
          note: null,
        ),
        // Entertainment history
        TransactionEntity(
          id: 'tx5',
          amount: -180,
          category: 'Entertainment',
          date: TransactionDate(DateTime(2024, 1, 10)),
          note: null,
        ),
        TransactionEntity(
          id: 'tx6',
          amount: -190,
          category: 'Entertainment',
          date: TransactionDate(DateTime(2024, 1, 11)),
          note: null,
        ),
        TransactionEntity(
          id: 'tx7',
          amount: -185,
          category: 'Entertainment',
          date: TransactionDate(DateTime(2024, 1, 12)),
          note: null,
        ),
      ];

      final context = RuleContextImpl(
        profile: profile,
        now: DateTime(2024, 1, 15, 13, 0),
        transactions: transactions,
      );

      final result = await rule.evaluate(context);

      // The Entertainment transaction should not be flagged as anomalous
      // because it's within the normal range for that category
      expect(result, isNull);
    });

    test('personalizes message for different personalities', () async {
      final transactions = [
        TransactionEntity(
          id: 'tx1',
          amount: -50,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 10)),
          note: null,
        ),
        TransactionEntity(
          id: 'tx2',
          amount: -55,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 11)),
          note: null,
        ),
        TransactionEntity(
          id: 'tx3',
          amount: -60,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 12)),
          note: null,
        ),
        // Anomaly
        TransactionEntity(
          id: 'tx4',
          amount: -175,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 15, 12, 0)),
          note: null,
        ),
      ];

      // Test for saver personality
      final saverProfile = UserProfileEntity(
        id: 'test',
        personalityType: MoneyPersonalityType.saver,
        lifeStage: LifeStage.earlyCareer,
        stressLevel: FinancialStressLevel.medium,
        enabledInsightCategories: InsightCategory.values.toSet(),
        preferredDailyTime: const TimeOfDay(hour: 8, minute: 0),
        maxInsightsPerDay: 5,
        cooldownHours: 4,
        warModeEnabled: false,
        locationAlertsEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final context = RuleContextImpl(
        profile: saverProfile,
        now: DateTime(2024, 1, 15, 13, 0),
        transactions: transactions,
      );

      final result = await rule.evaluate(context);

      expect(result, isNotNull);
      expect(result!.title, contains('Unusual'));
      expect(result.message, contains('intentional'));
    });

    test('includes correct metadata', () async {
      final transactions = [
        TransactionEntity(
          id: 'tx1',
          amount: -50,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 10)),
          note: null,
        ),
        TransactionEntity(
          id: 'tx2',
          amount: -55,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 11)),
          note: null,
        ),
        TransactionEntity(
          id: 'tx3',
          amount: -60,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 12)),
          note: null,
        ),
        TransactionEntity(
          id: 'tx4',
          amount: -175,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, 15, 12, 0)),
          note: null,
        ),
      ];

      final context = RuleContextImpl(
        profile: profile,
        now: DateTime(2024, 1, 15, 13, 0),
        transactions: transactions,
      );

      final result = await rule.evaluate(context);

      expect(result, isNotNull);
      expect(result!.metadata, containsPair('transactionId', 'tx4'));
      expect(result.metadata, containsPair('category', 'Food'));
      expect(result.metadata, containsPair('ratio', greaterThan(2.5)));
    });
  });
}
