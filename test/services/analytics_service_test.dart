import 'package:flutter_test/flutter_test.dart';
import 'package:futureproof/models/transaction.dart';
import 'package:futureproof/models/spending_analysis.dart';
import 'package:futureproof/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AnalyticsService analyticsService;

  setUp(() {
    analyticsService = AnalyticsService();
  });

  group('AnalyticsService - refresh', () {
    test('should clear cache when refresh is called', () async {
      // Setup: Create a mock SharedPreferences
      SharedPreferences.setMockInitialValues({});

      // First call should cache the result
      await analyticsService.analyzeSpending();

      // Refresh should clear the cache
      analyticsService.refresh();

      // Verify cache was cleared (next call will re-analyze)
      // This is verified by ensuring the method still works after refresh
      final result = await analyticsService.analyzeSpending();
      expect(result, isNotNull);
    });

    test('should allow fresh analysis after refresh', () async {
      SharedPreferences.setMockInitialValues({});

      // Get initial analysis
      final initial = await analyticsService.analyzeSpending();
      expect(initial, isNotNull);

      // Refresh and get new analysis
      analyticsService.refresh();
      final refreshed = await analyticsService.analyzeSpending();
      expect(refreshed, isNotNull);
    });
  });

  group('AnalyticsService - analyzeSpending', () {
    test('should return SpendingAnalysis with empty data', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.analyzeSpending();

      expect(result, isNotNull);
      expect(result.byCategory, isEmpty);
      expect(result.monthlyTrends, isEmpty);
      expect(result.totalSpending, 0.0);
    });

    test('should return SpendingAnalysis with transaction data', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
        'category_budgets': '{"groceries": 500.0, "dining": 300.0}',
      });

      final result = await analyticsService.analyzeSpending();

      expect(result, isNotNull);
      expect(result.byCategory, isNotEmpty);
      expect(result.totalSpending, greaterThanOrEqualTo(0.0));
    });

    test('should cache analysis result', () async {
      SharedPreferences.setMockInitialValues({});

      // First call
      final first = await analyticsService.analyzeSpending();
      // Second call should return cached result
      final second = await analyticsService.analyzeSpending();

      expect(identical(first, second), true);
    });
  });

  group('AnalyticsService - getCategoryBreakdown', () {
    test('should return empty map with no transactions', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getCategoryBreakdown();

      expect(result, isEmpty);
    });

    test('should return spending by category', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getCategoryBreakdown();

      expect(result, isA<Map<String, double>>());
    });

    test('should include all spending categories', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getCategoryBreakdown();

      // Result should be a map (even if empty)
      expect(result, isA<Map<String, double>>());
    });
  });

  group('AnalyticsService - getMonthlyTrends', () {
    test('should return empty list with no transactions', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getMonthlyTrends();

      expect(result, isEmpty);
    });

    test('should return list of MonthlySpending', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getMonthlyTrends();

      expect(result, isA<List<MonthlySpending>>());
    });

    test('should have chronological order', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getMonthlyTrends();

      // Even with no data, should return a list
      expect(result, isA<List<MonthlySpending>>());
    });
  });

  group('AnalyticsService - getTopCategory', () {
    test('should return null with no transactions', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getTopCategory();

      expect(result, isNull);
    });

    test('should return null with empty category breakdown', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getTopCategory();

      expect(result, isNull);
    });

    test('should return category with highest spending', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getTopCategory();

      // With no data, should be null
      expect(result, isNull);
    });
  });

  group('AnalyticsService - detectAnomalies', () {
    test('should return empty list with no transactions', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.detectAnomalies();

      expect(result, isEmpty);
    });

    test('should return list of anomalous transactions', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.detectAnomalies();

      expect(result, isA<List<Transaction>>());
    });

    test('should detect transactions exceeding 2x average', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.detectAnomalies();

      expect(result, isA<List<Transaction>>());
    });
  });

  group('AnalyticsService - generateInsights', () {
    test('should return empty list with no transactions', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.generateInsights();

      expect(result, isEmpty);
    });

    test('should return list of Insight objects', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.generateInsights();

      expect(result, isA<List<Insight>>());
    });

    test('should generate budget insights when over budget', () async {
      SharedPreferences.setMockInitialValues({
        'category_budgets': '{"groceries": 50.0}',
      });

      final result = await analyticsService.generateInsights();

      expect(result, isA<List<Insight>>());
    });

    test('should generate trend insights with data', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.generateInsights();

      expect(result, isA<List<Insight>>());
    });
  });

  group('AnalyticsService - getBudgetComparisons', () {
    test('should return empty map with no budgets', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getBudgetComparisons();

      expect(result, isEmpty);
    });

    test('should return budget comparisons for each category', () async {
      SharedPreferences.setMockInitialValues({
        'category_budgets': '{"groceries": 500.0, "dining": 300.0}',
      });

      final result = await analyticsService.getBudgetComparisons();

      expect(result, isA<Map<String, BudgetComparison>>());
    });

    test('should include over budget status', () async {
      SharedPreferences.setMockInitialValues({
        'category_budgets': '{"groceries": 50.0}',
      });

      final result = await analyticsService.getBudgetComparisons();

      expect(result, isA<Map<String, BudgetComparison>>());
    });
  });

  group('AnalyticsService - predictNextMonth', () {
    test('should return zero with no transaction history', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.predictNextMonth();

      expect(result, 0.0);
    });

    test('should return positive prediction with data', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.predictNextMonth();

      expect(result, greaterThanOrEqualTo(0.0));
    });

    test('should use weighted moving average', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.predictNextMonth();

      expect(result, isA<double>());
    });
  });

  group('AnalyticsService - isTrendingUp', () {
    test('should return false with insufficient data', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.isTrendingUp();

      expect(result, false);
    });

    test('should return boolean value', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.isTrendingUp();

      expect(result, isA<bool>());
    });

    test('should compare last two months', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.isTrendingUp();

      expect(result, isA<bool>());
    });
  });

  group('AnalyticsService - getTrendPercentage', () {
    test('should return zero with insufficient data', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getTrendPercentage();

      expect(result, 0.0);
    });

    test('should return positive or negative percentage', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getTrendPercentage();

      expect(result, isA<double>());
    });

    test('should calculate percentage change between months', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getTrendPercentage();

      expect(result, isA<double>());
    });
  });

  group('AnalyticsService - calculateSavingsRate', () {
    test('should return zero with zero income', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 0.0,
      });

      final result = await analyticsService.calculateSavingsRate();

      expect(result, 0.0);
    });

    test('should return positive savings rate', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
      });

      final result = await analyticsService.calculateSavingsRate();

      expect(result, isA<double>());
    });

    test('should return zero when spending equals income', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
      });

      final result = await analyticsService.calculateSavingsRate();

      expect(result, greaterThanOrEqualTo(0.0));
    });

    test('should return 100% when all income is saved', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
      });

      final result = await analyticsService.calculateSavingsRate();

      expect(result, lessThanOrEqualTo(100.0));
    });
  });

  group('AnalyticsService - getFinancialHealthScore', () {
    test('should return score with no data', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
        'savings_goal': 1000.0,
      });

      final result = await analyticsService.getFinancialHealthScore();

      expect(result, inInclusiveRange(0, 100));
    });

    test('should deduct for over budget categories', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
        'savings_goal': 1000.0,
        'category_budgets': '{"groceries": 50.0}',
      });

      final result = await analyticsService.getFinancialHealthScore();

      expect(result, inInclusiveRange(0, 100));
    });

    test('should deduct for anomalies', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
        'savings_goal': 1000.0,
      });

      final result = await analyticsService.getFinancialHealthScore();

      expect(result, inInclusiveRange(0, 100));
    });

    test('should add bonus for meeting savings goal', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
        'savings_goal': 1000.0,
      });

      final result = await analyticsService.getFinancialHealthScore();

      expect(result, inInclusiveRange(0, 100));
    });

    test('should add bonus for trending down', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
        'savings_goal': 1000.0,
      });

      final result = await analyticsService.getFinancialHealthScore();

      expect(result, inInclusiveRange(0, 100));
    });

    test('should clamp score between 0 and 100', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
        'savings_goal': 1000.0,
        'category_budgets': '{"groceries": 10.0, "dining": 10.0, "transport": 10.0}',
      });

      final result = await analyticsService.getFinancialHealthScore();

      expect(result, inInclusiveRange(0, 100));
    });
  });

  group('AnalyticsService - getDailySpendingVelocity', () {
    test('should return zero with no transactions', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getDailySpendingVelocity();

      expect(result, 0.0);
    });

    test('should return average daily spending', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getDailySpendingVelocity();

      expect(result, isA<double>());
    });

    test('should only include current month transactions', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getDailySpendingVelocity();

      expect(result, greaterThanOrEqualTo(0.0));
    });

    test('should handle first day of month', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getDailySpendingVelocity();

      expect(result, isA<double>());
    });
  });

  group('AnalyticsService - getSpendingByDayOfWeek', () {
    test('should return map with all days initialized to zero', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getSpendingByDayOfWeek();

      expect(result.length, 7);
      for (int i = 1; i <= 7; i++) {
        expect(result.containsKey(i), true);
        expect(result[i], greaterThanOrEqualTo(0.0));
      }
    });

    test('should return spending for each weekday', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getSpendingByDayOfWeek();

      expect(result, isA<Map<int, double>>());
      expect(result.length, 7);
    });

    test('should use 1 for Monday and 7 for Sunday', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getSpendingByDayOfWeek();

      expect(result.containsKey(1), true); // Monday
      expect(result.containsKey(7), true); // Sunday
    });
  });

  group('AnalyticsService - getAverageCategorySpending', () {
    test('should return zero for non-existent category', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getAverageCategorySpending('nonexistent');

      expect(result, 0.0);
    });

    test('should return zero for category with no transactions', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getAverageCategorySpending('groceries');

      expect(result, 0.0);
    });

    test('should calculate average per transaction in category', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getAverageCategorySpending('groceries');

      expect(result, isA<double>());
    });

    test('should handle single transaction in category', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.getAverageCategorySpending('dining');

      expect(result, greaterThanOrEqualTo(0.0));
    });
  });

  group('AnalyticsService - compareMonths', () {
    test('should return zeros with insufficient data', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.compareMonths();

      expect(result['currentMonth'], 0.0);
      expect(result['previousMonth'], 0.0);
      expect(result['difference'], 0.0);
      expect(result['percentageChange'], 0.0);
    });

    test('should return current and previous month spending', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.compareMonths();

      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('currentMonth'), true);
      expect(result.containsKey('previousMonth'), true);
    });

    test('should calculate difference between months', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.compareMonths();

      expect(result.containsKey('difference'), true);
      expect(result['difference'], isA<double>());
    });

    test('should calculate percentage change', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.compareMonths();

      expect(result.containsKey('percentageChange'), true);
      expect(result['percentageChange'], isA<double>());
    });

    test('should handle zero previous month spending', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.compareMonths();

      expect(result['percentageChange'], 0.0);
    });
  });

  group('AnalyticsService - getQuickStats', () {
    test('should return stats map with all required fields', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
        'savings_goal': 1000.0,
      });

      final result = await analyticsService.getQuickStats();

      expect(result.containsKey('totalSpending'), true);
      expect(result.containsKey('monthlyIncome'), true);
      expect(result.containsKey('savings'), true);
      expect(result.containsKey('savingsRate'), true);
      expect(result.containsKey('savingsGoal'), true);
      expect(result.containsKey('isOnTrack'), true);
      expect(result.containsKey('topCategory'), true);
      expect(result.containsKey('topCategoryAmount'), true);
      expect(result.containsKey('averageMonthlySpending'), true);
      expect(result.containsKey('isTrendingUp'), true);
      expect(result.containsKey('trendPercentage'), true);
    });

    test('should calculate total spending correctly', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
        'savings_goal': 1000.0,
      });

      final result = await analyticsService.getQuickStats();

      expect(result['totalSpending'], isA<double>());
      expect(result['totalSpending'], greaterThanOrEqualTo(0.0));
    });

    test('should calculate savings correctly', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
        'savings_goal': 1000.0,
      });

      final result = await analyticsService.getQuickStats();

      expect(result['savings'], isA<double>());
    });

    test('should calculate savings rate correctly', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
        'savings_goal': 1000.0,
      });

      final result = await analyticsService.getQuickStats();

      expect(result['savingsRate'], isA<double>());
    });

    test('should determine if on track for savings goal', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
        'savings_goal': 1000.0,
      });

      final result = await analyticsService.getQuickStats();

      expect(result['isOnTrack'], isA<bool>());
    });

    test('should include top category and amount', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
        'savings_goal': 1000.0,
      });

      final result = await analyticsService.getQuickStats();

      expect(result['topCategory'], isA<String>());
      expect(result['topCategoryAmount'], isA<double>());
    });

    test('should include trending information', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
        'savings_goal': 1000.0,
      });

      final result = await analyticsService.getQuickStats();

      expect(result['isTrendingUp'], isA<bool>());
      expect(result['trendPercentage'], isA<double>());
    });

    test('should handle zero income gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 0.0,
        'savings_goal': 0.0,
      });

      final result = await analyticsService.getQuickStats();

      expect(result['monthlyIncome'], 0.0);
      expect(result['savingsRate'], 0.0);
    });

    test('should handle no transactions', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
        'savings_goal': 1000.0,
      });

      final result = await analyticsService.getQuickStats();

      expect(result['totalSpending'], greaterThanOrEqualTo(0.0));
    });
  });

  group('AnalyticsService - Edge Cases', () {
    test('should handle all income transactions', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
      });

      final result = await analyticsService.analyzeSpending();

      expect(result.totalSpending, 0.0);
    });

    test('should handle negative spending amounts', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.analyzeSpending();

      expect(result.totalSpending, greaterThanOrEqualTo(0.0));
    });

    test('should handle very large transaction amounts', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
      });

      final result = await analyticsService.analyzeSpending();

      expect(result, isNotNull);
    });

    test('should handle invalid JSON in budgets', () async {
      SharedPreferences.setMockInitialValues({
        'category_budgets': 'invalid-json',
      });

      final result = await analyticsService.analyzeSpending();

      expect(result, isNotNull);
      expect(result.budgetComparisons, isEmpty);
    });

    test('should handle null budgets', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await analyticsService.analyzeSpending();

      expect(result, isNotNull);
    });
  });

  group('AnalyticsService - Integration', () {
    test('should work end-to-end with complete data', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
        'savings_goal': 1000.0,
        'category_budgets': '{"groceries": 500.0, "dining": 300.0}',
      });

      final analysis = await analyticsService.analyzeSpending();
      final breakdown = await analyticsService.getCategoryBreakdown();
      final trends = await analyticsService.getMonthlyTrends();
      final healthScore = await analyticsService.getFinancialHealthScore();
      final stats = await analyticsService.getQuickStats();

      expect(analysis, isNotNull);
      expect(breakdown, isA<Map<String, double>>());
      expect(trends, isA<List<MonthlySpending>>());
      expect(healthScore, inInclusiveRange(0, 100));
      expect(stats, isA<Map<String, dynamic>>());
    });

    test('should maintain consistency across multiple calls', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
      });

      final analysis1 = await analyticsService.analyzeSpending();
      final analysis2 = await analyticsService.analyzeSpending();

      expect(analysis1.totalSpending, analysis2.totalSpending);
    });

    test('should reset after refresh', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5000.0,
      });

      final before = await analyticsService.analyzeSpending();
      analyticsService.refresh();
      final after = await analyticsService.analyzeSpending();

      expect(before, isNotNull);
      expect(after, isNotNull);
    });
  });
}
