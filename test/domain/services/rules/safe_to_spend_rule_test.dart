import 'package:flutter_test/flutter_test.dart';
import 'package:futureproof/domain/entities/user_profile_entity.dart';
import 'package:futureproof/domain/entities/behavioral_insight_entity.dart';
import 'package:futureproof/domain/entities/budget_entity.dart';
import 'package:futureproof/domain/entities/streak_entity.dart';
import 'package:futureproof/domain/entities/transaction_entity.dart';
import 'package:futureproof/domain/services/rule_context_impl.dart';
import 'package:futureproof/domain/services/rules/safe_to_spend_rule.dart';
import 'package:futureproof/domain/value_objects/life_stage.dart';
import 'package:futureproof/domain/value_objects/money_personality_type.dart';
import 'package:futureproof/domain/value_objects/insight_category.dart';

void main() {
  group('SafeToSpendRule', () {
    late SafeToSpendRule rule;
    late UserProfileEntity profile;
    late BudgetEntity budget;
    late List<TransactionEntity> transactions;

    setUp(() {
      rule = const SafeToSpendRule();

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

      // Monthly budget of $3000 = $100/day
      budget = const BudgetEntity(
        monthlyIncome: 4000,
        monthlyBudget: 3000,
        dailyBudget: 100,
        weeklyBudget: 750,
      );

      transactions = [];
    });

    test('has correct metadata', () {
      expect(rule.id, 'safe_to_spend_daily');
      expect(rule.name, 'Safe to Spend (Daily)');
      expect(rule.category, InsightCategory.budgetHealth);
      expect(rule.triggers, contains(DeliveryTrigger.morningDigest));
      expect(rule.defaultPriority, InsightPriority.medium);
    });

    test('returns null when no budget is provided', () async {
      final context = RuleContextImpl(
        profile: profile,
        now: DateTime(2024, 1, 15),
        transactions: transactions,
        budget: null,
      );

      final result = await rule.evaluate(context);

      expect(result, isNull);
    });

    test('returns null on last day of month', () async {
      final context = RuleContextImpl(
        profile: profile,
        now: DateTime(2024, 1, 31), // Last day of January
        transactions: transactions,
        budget: budget,
      );

      final result = await rule.evaluate(context);

      expect(result, isNull);
    });

    test('generates critical alert when spending too fast', () async {
      // Spent $2000 by day 15 = $133/day average
      // Remaining: $1000 for 16 days = $62.50/day (62.5% of budget)
      final spentTransactions = List.generate(
        20,
        (i) => TransactionEntity(
          id: 'tx$i',
          amount: -100,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, i + 1)),
          note: null,
        ),
      );

      final context = RuleContextImpl(
        profile: profile,
        now: DateTime(2024, 1, 15),
        transactions: spentTransactions,
        budget: budget,
      );

      final result = await rule.evaluate(context);

      expect(result, isNotNull);
      expect(result!.category, InsightCategory.budgetHealth);
      expect(result.priority, InsightPriority.high);
      expect(result.icon, '⚠️');
      expect(result.actionLabel, 'View Budget');
    });

    test('generates surplus alert when under budget pace', () async {
      // Spent only $800 by day 15 = $53/day average
      // Remaining: $2200 for 16 days = $137.50/day (137.5% of budget)
      final spentTransactions = List.generate(
        10,
        (i) => TransactionEntity(
          id: 'tx$i',
          amount: -80,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, i + 1)),
          note: null,
        ),
      );

      final context = RuleContextImpl(
        profile: profile,
        now: DateTime(2024, 1, 15),
        transactions: spentTransactions,
        budget: budget,
      );

      final result = await rule.evaluate(context);

      expect(result, isNotNull);
      expect(result!.category, InsightCategory.budgetHealth);
      expect(result.priority, InsightPriority.low);
      expect(result.icon, '🎉');
      expect(result.actionLabel, 'Move to Savings');
    });

    test('generates on-track alert when pacing correctly', () async {
      // Spent exactly $1500 by day 15 = $100/day average (on track)
      final spentTransactions = List.generate(
        15,
        (i) => TransactionEntity(
          id: 'tx$i',
          amount: -100,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, i + 1)),
          note: null,
        ),
      );

      final context = RuleContextImpl(
        profile: profile,
        now: DateTime(2024, 1, 15),
        transactions: spentTransactions,
        budget: budget,
      );

      final result = await rule.evaluate(context);

      expect(result, isNotNull);
      expect(result!.category, InsightCategory.budgetHealth);
      expect(result.priority, InsightPriority.low);
      expect(result.icon, '✅');
    });

    test('personalizes message for saver personality', () async {
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

      // Overspending scenario
      final spentTransactions = List.generate(
        20,
        (i) => TransactionEntity(
          id: 'tx$i',
          amount: -100,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, i + 1)),
          note: null,
        ),
      );

      final context = RuleContextImpl(
        profile: saverProfile,
        now: DateTime(2024, 1, 15),
        transactions: spentTransactions,
        budget: budget,
      );

      final result = await rule.evaluate(context);

      expect(result, isNotNull);
      expect(result!.title, contains('Budget'));
      expect(result.message, contains('protect'));
    });

    test('personalizes message for investor personality', () async {
      final investorProfile = UserProfileEntity(
        id: 'test',
        personalityType: MoneyPersonalityType.investor,
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

      // Surplus scenario
      final spentTransactions = List.generate(
        8,
        (i) => TransactionEntity(
          id: 'tx$i',
          amount: -80,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, i + 1)),
          note: null,
        ),
      );

      final context = RuleContextImpl(
        profile: investorProfile,
        now: DateTime(2024, 1, 15),
        transactions: spentTransactions,
        budget: budget,
      );

      final result = await rule.evaluate(context);

      expect(result, isNotNull);
      expect(result!.title, contains('Positive Variance'));
      expect(result.message, contains('compound'));
    });

    test('includes correct metadata', () async {
      final spentTransactions = List.generate(
        15,
        (i) => TransactionEntity(
          id: 'tx$i',
          amount: -100,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, i + 1)),
          note: null,
        ),
      );

      final context = RuleContextImpl(
        profile: profile,
        now: DateTime(2024, 1, 15),
        transactions: spentTransactions,
        budget: budget,
      );

      final result = await rule.evaluate(context);

      expect(result, isNotNull);
      expect(result!.metadata, containsPair('safeToSpend', isA<double>()));
      expect(result.metadata, containsPair('dailyBudget', 100.0));
      expect(result.metadata, containsPair('daysLeft', 16));
    });

    test('insight expires after 24 hours', () async {
      final spentTransactions = List.generate(
        15,
        (i) => TransactionEntity(
          id: 'tx$i',
          amount: -100,
          category: 'Food',
          date: TransactionDate(DateTime(2024, 1, i + 1)),
          note: null,
        ),
      );

      final context = RuleContextImpl(
        profile: profile,
        now: DateTime(2024, 1, 15),
        transactions: spentTransactions,
        budget: budget,
      );

      final result = await rule.evaluate(context);

      expect(result, isNotNull);
      expect(result!.expiresAt, isNotNull);
      final expiryAge = result.expiresAt!.difference(result.generatedAt);
      expect(expiryAge, const Duration(hours: 24));
    });
  });
}
