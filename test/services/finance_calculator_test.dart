import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futureproof/models/transaction.dart';
import 'package:futureproof/services/finance_calculator.dart';

void main() {
  group('FinanceCalculator', () {
    group('calculateStatus', () {
      test('should return GOOD status with large surplus', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 2000,
          savingsGoal: 1000,
        );

        expect(status.level, StatusLevel.good);
        expect(status.remaining, 2000.0);
        expect(status.emoji, '✅');
        expect(status.message, contains('doing great'));
      });

      test('should return GOOD status exactly at buffer', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 3500,
          savingsGoal: 1000,
        );

        // 5000 - 3500 - 1000 = 500 (exactly 10% buffer)
        expect(status.level, StatusLevel.good);
        expect(status.remaining, 500.0);
      });

      test('should return GOOD status with small positive remainder', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 3500,
          savingsGoal: 1000,
        );

        expect(status.level, StatusLevel.good);
        expect(status.remaining, 500.0);
        expect(status.emoji, '✅');
      });

      test('should return DANGER status with small deficit', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 4600,
          savingsGoal: 1000,
        );

        // -600 deficit exceeds buffer, so danger
        expect(status.level, StatusLevel.danger);
        expect(status.remaining, -600.0);
        expect(status.emoji, '❌');
      });

      test('should return DANGER status with large deficit', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 6000,
          savingsGoal: 1000,
        );

        expect(status.level, StatusLevel.danger);
        expect(status.remaining, -2000.0);
        expect(status.emoji, '❌');
      });

      test('should handle zero income', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 0,
          monthlyExpenses: 0,
          savingsGoal: 0,
        );

        expect(status.remaining, 0.0);
        expect(status.level, StatusLevel.good);
      });

      test('should handle large expenses exceeding income', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 3000,
          monthlyExpenses: 8000,
          savingsGoal: 500,
        );

        expect(status.level, StatusLevel.danger);
        expect(status.remaining, -5500.0);
      });

      test('should generate "doing great" message when remaining >= buffer',
          () {
        // Buffer for 5000 income = 500
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 2000,
          savingsGoal: 1000,
        );

        // remaining = 2000 >= buffer(500) -> "doing great" message
        expect(status.level, StatusLevel.good);
        expect(status.message, contains("doing great"));
        expect(status.message, contains("remaining this month"));
      });

      test('should generate "on track" message when 0 < remaining < buffer',
          () {
        // Buffer for 5000 income = 500
        // remaining = 500, which equals buffer -> should be "doing great"
        // But if remaining is 400, it should be "on track"
        final status2 = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 3600,
          savingsGoal: 1000,
        );

        // remaining = 400 < buffer(500) but > 0 -> "on track" message
        expect(status2.level, StatusLevel.good);
        expect(status2.message, contains("on track"));
        expect(status2.message, contains("left for flexible spending"));
      });

      test('should handle very large amounts', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 10000000, // 10 million
          monthlyExpenses: 2000000, // 2 million
          savingsGoal: 1000000, // 1 million
        );

        expect(status.level, StatusLevel.good);
        expect(status.remaining, 7000000.0);
        expect(status.message, contains('\$7,000,000'));
      });

      test('should handle very small fractional amounts', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 100.50,
          monthlyExpenses: 50.25,
          savingsGoal: 25.15,
        );

        expect(status.remaining, closeTo(25.10, 0.01));
        expect(status.level, StatusLevel.good);
      });

      test('should return CAUTION status when over budget but within buffer',
          () {
        // Buffer for 5000 income = 500
        // Need remaining between -500 and 0 for CAUTION
        // remaining = income - expenses - savingsGoal = 5000 - 4200 - 1000 = -200
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 4200,
          savingsGoal: 1000,
        );

        // remaining = -200, which is > -buffer(-500) but < 0 -> CAUTION
        expect(status.level, StatusLevel.caution);
        expect(status.remaining, -200.0);
        expect(status.emoji, '⚠️');
        expect(status.message, contains("over budget"));
        expect(status.message, contains("reviewing your spending"));
      });

      test('should return DANGER status when over budget exceeds buffer', () {
        // Buffer for 5000 income = 500
        // Need remaining <= -500 for DANGER
        // remaining = income - expenses - savingsGoal = 5000 - 4600 - 1000 = -600
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 4600,
          savingsGoal: 1000,
        );

        // remaining = -600, which is <= -buffer(-500) -> DANGER
        expect(status.level, StatusLevel.danger);
        expect(status.remaining, -600.0);
        expect(status.emoji, '❌');
        expect(status.message, contains("Over budget by"));
        expect(status.message, contains("Review all spending"));
      });

      test('should handle exact buffer threshold from below', () {
        // Buffer for 5000 income = 500
        // Need remaining = -500 exactly for DANGER
        // remaining = income - expenses - savingsGoal = 5000 - 4500 - 1000 = -500
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 4500,
          savingsGoal: 1000,
        );

        // remaining = -500, which equals -buffer -> DANGER (not > -buffer)
        expect(status.level, StatusLevel.danger);
        expect(status.remaining, -500.0);
      });

      test('should handle exact buffer threshold from above', () {
        // Buffer for 5000 income = 500
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 3500, // Exactly 500 remaining
          savingsGoal: 1000,
        );

        // remaining = 500, which equals buffer -> GOOD (>= buffer)
        expect(status.level, StatusLevel.good);
        expect(status.remaining, 500.0);
      });

      test('should handle insights parameter', () {
        final insights = <String>[];
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 2000,
          savingsGoal: 1000,
          insights: insights,
        );

        // insights parameter is accepted but not currently used in the method
        expect(status.level, StatusLevel.good);
        expect(insights, isEmpty); // Verify parameter is accepted
      });

      test('should handle negative income edge case', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: -1000, // Invalid but should handle gracefully
          monthlyExpenses: 500,
          savingsGoal: 0,
        );

        expect(status.remaining, -1500.0);
        expect(status.level, StatusLevel.danger);
      });

      test('should handle zero savings goal', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 3500,
          savingsGoal: 0,
        );

        expect(status.remaining, 1500.0);
        expect(status.level, StatusLevel.good);
      });

      test('should handle expenses equal to income', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 5000,
          savingsGoal: 0,
        );

        expect(status.remaining, 0.0);
        // 0 >= buffer(500) is false, but 0 > 0 is false, and 0 > -buffer(-500) is true -> CAUTION
        expect(status.level, StatusLevel.caution);
      });
    });

    group('calculateTotalExpenses', () {
      test('should sum only negative amounts', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -100.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '2',
              amount: -50.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '3', amount: 200.0, category: 'income', date: DateTime.now()),
          Transaction(
              id: '4', amount: 500.0, category: 'income', date: DateTime.now()),
        ];

        final total = FinanceCalculator.calculateTotalExpenses(transactions);

        expect(total, 150.0);
      });

      test('should return zero for empty list', () {
        final total = FinanceCalculator.calculateTotalExpenses([]);
        expect(total, 0.0);
      });

      test('should return zero for income-only list', () {
        final transactions = [
          Transaction(
              id: '1', amount: 100.0, category: 'income', date: DateTime.now()),
          Transaction(
              id: '2', amount: 200.0, category: 'income', date: DateTime.now()),
        ];

        final total = FinanceCalculator.calculateTotalExpenses(transactions);
        expect(total, 0.0);
      });

      test('should handle zero amounts', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -100.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '2',
              amount: 0.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '3', amount: -50.0, category: 'dining', date: DateTime.now()),
        ];

        final total = FinanceCalculator.calculateTotalExpenses(transactions);
        expect(total, 150.0);
      });

      test('should handle very small amounts', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -0.01,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '2', amount: -0.99, category: 'dining', date: DateTime.now()),
        ];

        final total = FinanceCalculator.calculateTotalExpenses(transactions);
        expect(total, closeTo(1.0, 0.001));
      });

      test('should handle very large amounts', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -1000000.0,
              category: 'housing',
              date: DateTime.now()),
          Transaction(
              id: '2',
              amount: -500000.0,
              category: 'housing',
              date: DateTime.now()),
        ];

        final total = FinanceCalculator.calculateTotalExpenses(transactions);
        expect(total, 1500000.0);
      });

      test('should handle single expense transaction', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -100.0,
              category: 'groceries',
              date: DateTime.now()),
        ];

        final total = FinanceCalculator.calculateTotalExpenses(transactions);
        expect(total, 100.0);
      });

      test('should handle mixed positive and negative amounts', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -100.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '2', amount: 50.0, category: 'income', date: DateTime.now()),
          Transaction(
              id: '3',
              amount: -200.0,
              category: 'housing',
              date: DateTime.now()),
          Transaction(
              id: '4', amount: 300.0, category: 'income', date: DateTime.now()),
        ];

        final total = FinanceCalculator.calculateTotalExpenses(transactions);
        expect(total, 300.0); // Only expenses counted
      });
    });

    group('calculateTotalIncome', () {
      test('should sum only positive amounts', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -100.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '2',
              amount: -50.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '3', amount: 200.0, category: 'income', date: DateTime.now()),
          Transaction(
              id: '4', amount: 500.0, category: 'income', date: DateTime.now()),
        ];

        final total = FinanceCalculator.calculateTotalIncome(transactions);

        expect(total, 700.0);
      });

      test('should return zero for empty list', () {
        final total = FinanceCalculator.calculateTotalIncome([]);
        expect(total, 0.0);
      });

      test('should return zero for expense-only list', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -100.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '2',
              amount: -200.0,
              category: 'housing',
              date: DateTime.now()),
        ];

        final total = FinanceCalculator.calculateTotalIncome(transactions);
        expect(total, 0.0);
      });

      test('should handle zero amounts', () {
        final transactions = [
          Transaction(
              id: '1', amount: 100.0, category: 'income', date: DateTime.now()),
          Transaction(
              id: '2',
              amount: 0.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '3', amount: 50.0, category: 'income', date: DateTime.now()),
        ];

        final total = FinanceCalculator.calculateTotalIncome(transactions);
        expect(total, 150.0);
      });

      test('should handle very small amounts', () {
        final transactions = [
          Transaction(
              id: '1', amount: 0.01, category: 'income', date: DateTime.now()),
          Transaction(
              id: '2', amount: 0.99, category: 'income', date: DateTime.now()),
        ];

        final total = FinanceCalculator.calculateTotalIncome(transactions);
        expect(total, closeTo(1.0, 0.001));
      });

      test('should handle very large amounts', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: 1000000.0,
              category: 'income',
              date: DateTime.now()),
          Transaction(
              id: '2',
              amount: 500000.0,
              category: 'income',
              date: DateTime.now()),
        ];

        final total = FinanceCalculator.calculateTotalIncome(transactions);
        expect(total, 1500000.0);
      });

      test('should handle single income transaction', () {
        final transactions = [
          Transaction(
              id: '1', amount: 100.0, category: 'income', date: DateTime.now()),
        ];

        final total = FinanceCalculator.calculateTotalIncome(transactions);
        expect(total, 100.0);
      });

      test('should handle mixed positive and negative amounts', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -100.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '2', amount: 50.0, category: 'income', date: DateTime.now()),
          Transaction(
              id: '3',
              amount: -200.0,
              category: 'housing',
              date: DateTime.now()),
          Transaction(
              id: '4', amount: 300.0, category: 'income', date: DateTime.now()),
        ];

        final total = FinanceCalculator.calculateTotalIncome(transactions);
        expect(total, 350.0); // Only income counted
      });
    });

    group('groupByCategory', () {
      test('should group expenses by category', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -100.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '2',
              amount: -50.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '3',
              amount: -200.0,
              category: 'dining',
              date: DateTime.now()),
          Transaction(
              id: '4', amount: 100.0, category: 'income', date: DateTime.now()),
        ];

        final grouped = FinanceCalculator.groupByCategory(transactions);

        expect(grouped['groceries'], 150.0);
        expect(grouped['dining'], 200.0);
        expect(grouped['income'], isNull); // Income should be excluded
      });

      test('should return empty map for no transactions', () {
        final grouped = FinanceCalculator.groupByCategory([]);
        expect(grouped, isEmpty);
      });

      test('should exclude income from grouping', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: 1000.0,
              category: 'income',
              date: DateTime.now()),
          Transaction(
              id: '2', amount: 500.0, category: 'income', date: DateTime.now()),
        ];

        final grouped = FinanceCalculator.groupByCategory(transactions);
        expect(grouped, isEmpty);
      });

      test('should handle mixed categories', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -100.0,
              category: 'housing',
              date: DateTime.now()),
          Transaction(
              id: '2',
              amount: -50.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '3',
              amount: -75.0,
              category: 'transport',
              date: DateTime.now()),
          Transaction(
              id: '4',
              amount: -25.0,
              category: 'groceries',
              date: DateTime.now()),
        ];

        final grouped = FinanceCalculator.groupByCategory(transactions);

        expect(grouped['housing'], 100.0);
        expect(grouped['groceries'], 75.0);
        expect(grouped['transport'], 75.0);
      });

      test('should handle all valid expense categories', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -100.0,
              category: 'housing',
              date: DateTime.now()),
          Transaction(
              id: '2',
              amount: -200.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '3',
              amount: -150.0,
              category: 'dining',
              date: DateTime.now()),
          Transaction(
              id: '4',
              amount: -75.0,
              category: 'transport',
              date: DateTime.now()),
          Transaction(
              id: '5',
              amount: -50.0,
              category: 'entertainment',
              date: DateTime.now()),
          Transaction(
              id: '6', amount: -25.0, category: 'health', date: DateTime.now()),
          Transaction(
              id: '7',
              amount: -175.0,
              category: 'shopping',
              date: DateTime.now()),
          Transaction(
              id: '8',
              amount: -30.0,
              category: 'subscriptions',
              date: DateTime.now()),
          Transaction(
              id: '9',
              amount: 1000.0,
              category: 'income',
              date: DateTime.now()),
        ];

        final grouped = FinanceCalculator.groupByCategory(transactions);

        expect(grouped.length, 8); // All expense categories, not income
        expect(grouped['housing'], 100.0);
        expect(grouped['groceries'], 200.0);
        expect(grouped['dining'], 150.0);
        expect(grouped['transport'], 75.0);
        expect(grouped['entertainment'], 50.0);
        expect(grouped['health'], 25.0);
        expect(grouped['shopping'], 175.0);
        expect(grouped['subscriptions'], 30.0);
        expect(grouped['income'], isNull);
      });

      test('should handle very large amounts', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -1000000.0,
              category: 'housing',
              date: DateTime.now()),
          Transaction(
              id: '2',
              amount: -500000.0,
              category: 'housing',
              date: DateTime.now()),
        ];

        final grouped = FinanceCalculator.groupByCategory(transactions);
        expect(grouped['housing'], 1500000.0);
      });

      test('should handle very small fractional amounts', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -0.01,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '2',
              amount: -0.99,
              category: 'groceries',
              date: DateTime.now()),
        ];

        final grouped = FinanceCalculator.groupByCategory(transactions);
        expect(grouped['groceries'], closeTo(1.0, 0.001));
      });

      test('should handle single expense transaction', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -100.0,
              category: 'groceries',
              date: DateTime.now()),
        ];

        final grouped = FinanceCalculator.groupByCategory(transactions);
        expect(grouped.length, 1);
        expect(grouped['groceries'], 100.0);
      });

      test('should accumulate amounts for same category', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -100.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '2',
              amount: -50.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '3',
              amount: -25.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '4',
              amount: -75.0,
              category: 'groceries',
              date: DateTime.now()),
        ];

        final grouped = FinanceCalculator.groupByCategory(transactions);
        expect(grouped['groceries'], 250.0);
      });
    });

    group('getHighestSpendingCategory', () {
      test('should return category with highest spending', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -100.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '2',
              amount: -200.0,
              category: 'dining',
              date: DateTime.now()),
          Transaction(
              id: '3',
              amount: -50.0,
              category: 'groceries',
              date: DateTime.now()),
        ];

        final highest =
            FinanceCalculator.getHighestSpendingCategory(transactions);

        expect(highest, 'dining'); // 200 > 150
      });

      test('should return None for empty list', () {
        final highest = FinanceCalculator.getHighestSpendingCategory([]);
        expect(highest, 'None');
      });

      test('should return None for income-only list', () {
        final transactions = [
          Transaction(
              id: '1', amount: 100.0, category: 'income', date: DateTime.now()),
        ];

        final highest =
            FinanceCalculator.getHighestSpendingCategory(transactions);
        expect(highest, 'None');
      });

      test('should handle tie by returning first', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -100.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '2',
              amount: -100.0,
              category: 'dining',
              date: DateTime.now()),
        ];

        final highest =
            FinanceCalculator.getHighestSpendingCategory(transactions);

        // Should return one of them (implementation dependent)
        expect(['groceries', 'dining'], contains(highest));
      });

      test('should exclude income from calculation', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: 10000.0,
              category: 'income',
              date: DateTime.now()),
          Transaction(
              id: '2',
              amount: -100.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '3', amount: -50.0, category: 'dining', date: DateTime.now()),
        ];

        final highest =
            FinanceCalculator.getHighestSpendingCategory(transactions);

        expect(highest, 'groceries');
      });

      test('should handle single expense transaction', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -100.0,
              category: 'groceries',
              date: DateTime.now()),
        ];

        final highest =
            FinanceCalculator.getHighestSpendingCategory(transactions);
        expect(highest, 'groceries');
      });

      test('should handle very large amounts', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -1000000.0,
              category: 'housing',
              date: DateTime.now()),
          Transaction(
              id: '2',
              amount: -500000.0,
              category: 'groceries',
              date: DateTime.now()),
        ];

        final highest =
            FinanceCalculator.getHighestSpendingCategory(transactions);
        expect(highest, 'housing');
      });

      test('should handle all valid expense categories', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -100.0,
              category: 'housing',
              date: DateTime.now()),
          Transaction(
              id: '2',
              amount: -200.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '3',
              amount: -150.0,
              category: 'dining',
              date: DateTime.now()),
          Transaction(
              id: '4',
              amount: -75.0,
              category: 'transport',
              date: DateTime.now()),
          Transaction(
              id: '5',
              amount: -50.0,
              category: 'entertainment',
              date: DateTime.now()),
          Transaction(
              id: '6', amount: -25.0, category: 'health', date: DateTime.now()),
          Transaction(
              id: '7',
              amount: -175.0,
              category: 'shopping',
              date: DateTime.now()),
          Transaction(
              id: '8',
              amount: -30.0,
              category: 'subscriptions',
              date: DateTime.now()),
        ];

        final highest =
            FinanceCalculator.getHighestSpendingCategory(transactions);
        expect(highest, 'groceries'); // 200 is highest
      });

      test('should handle very small fractional amounts', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -0.99,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '2', amount: -0.01, category: 'dining', date: DateTime.now()),
        ];

        final highest =
            FinanceCalculator.getHighestSpendingCategory(transactions);
        expect(highest, 'groceries');
      });

      test('should accumulate transactions for same category', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -100.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '2',
              amount: -50.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '3',
              amount: -125.0,
              category: 'dining',
              date: DateTime.now()),
        ];

        final highest =
            FinanceCalculator.getHighestSpendingCategory(transactions);
        expect(highest, 'groceries'); // 150 > 125
      });

      test('should handle zero amount expenses', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: 0.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '2', amount: -50.0, category: 'dining', date: DateTime.now()),
        ];

        final highest =
            FinanceCalculator.getHighestSpendingCategory(transactions);
        expect(highest, 'dining');
      });
    });

    group('FinanceStatus', () {
      test('should have correct color for GOOD status', () {
        final status = FinanceStatus(
          message: 'Test',
          level: StatusLevel.good,
          remaining: 100.0,
        );

        expect(status.color, const Color(0xFF4CAF50)); // AppColors.success
      });

      test('should have correct color for CAUTION status', () {
        final status = FinanceStatus(
          message: 'Test',
          level: StatusLevel.caution,
          remaining: -100.0,
        );

        expect(status.color, const Color(0xFFC9A962)); // AppColors.gold
      });

      test('should have correct color for DANGER status', () {
        final status = FinanceStatus(
          message: 'Test',
          level: StatusLevel.danger,
          remaining: -500.0,
        );

        expect(status.color, const Color(0xFFD4483A)); // AppColors.danger
      });

      test('should have correct emoji for each level', () {
        final good = FinanceStatus(
          message: 'Good',
          level: StatusLevel.good,
          remaining: 100.0,
        );

        final caution = FinanceStatus(
          message: 'Caution',
          level: StatusLevel.caution,
          remaining: -100.0,
        );

        final danger = FinanceStatus(
          message: 'Danger',
          level: StatusLevel.danger,
          remaining: -500.0,
        );

        expect(good.emoji, '✅');
        expect(caution.emoji, '⚠️');
        expect(danger.emoji, '❌');
      });
    });

    group('NumberFormat edge cases', () {
      test('should handle extremely large amounts in formatted message', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 999999999999.99, // Near trillion
          monthlyExpenses: 100000000000.0,
          savingsGoal: 500000000000.0,
        );

        expect(status.level, StatusLevel.good);
        expect(status.message, contains('399,999,999,999.99'));
      });

      test('should format negative amounts in caution message', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 5300,
          savingsGoal: 0,
        );

        expect(status.level, StatusLevel.caution);
        expect(status.message, contains('\$300'));
      });

      test('should format negative amounts in danger message', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 6000,
          savingsGoal: 0,
        );

        expect(status.level, StatusLevel.danger);
        expect(status.message, contains('\$1,000'));
      });
    });

    group('insights parameter', () {
      test('should accept empty insights list', () {
        final insights = <String>[];
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 2000,
          savingsGoal: 1000,
          insights: insights,
        );

        expect(status.level, StatusLevel.good);
        expect(insights, isEmpty);
      });

      test('should accept insights with multiple items', () {
        final insights = <String>['Save more', 'Reduce dining'];
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 2000,
          savingsGoal: 1000,
          insights: insights,
        );

        expect(status.level, StatusLevel.good);
        expect(insights.length, 2);
      });

      test('should accept null insights parameter', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 2000,
          savingsGoal: 1000,
          insights: null,
        );

        expect(status.level, StatusLevel.good);
      });
    });

    group('Floating point precision', () {
      test('should handle floating point precision at buffer boundary', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000.001,
          monthlyExpenses: 3500.001,
          savingsGoal: 999.999,
        );

        expect(status.remaining, closeTo(500.001, 0.0001));
      });

      test('should handle micro-fractional amounts', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: -0.0001,
              category: 'groceries',
              date: DateTime.now()),
        ];

        final total = FinanceCalculator.calculateTotalExpenses(transactions);
        expect(total, closeTo(0.0001, 0.00001));
      });
    });

    group('Zero amount edge cases', () {
      test('should handle all transactions with zero amounts', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: 0.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '2', amount: 0.0, category: 'dining', date: DateTime.now()),
          Transaction(
              id: '3', amount: 0.0, category: 'income', date: DateTime.now()),
        ];

        final totalExpenses =
            FinanceCalculator.calculateTotalExpenses(transactions);
        final totalIncome =
            FinanceCalculator.calculateTotalIncome(transactions);
        final grouped = FinanceCalculator.groupByCategory(transactions);
        final highest =
            FinanceCalculator.getHighestSpendingCategory(transactions);

        expect(totalExpenses, 0.0);
        expect(totalIncome, 0.0);
        expect(grouped, isEmpty);
        expect(highest, 'None');
      });

      test('should handle mixed zero and non-zero amounts', () {
        final transactions = [
          Transaction(
              id: '1',
              amount: 0.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '2',
              amount: -100.0,
              category: 'groceries',
              date: DateTime.now()),
          Transaction(
              id: '3', amount: 0.0, category: 'dining', date: DateTime.now()),
          Transaction(
              id: '4', amount: -50.0, category: 'dining', date: DateTime.now()),
        ];

        final total = FinanceCalculator.calculateTotalExpenses(transactions);
        final grouped = FinanceCalculator.groupByCategory(transactions);

        expect(total, 150.0);
        expect(grouped['groceries'], 100.0);
        expect(grouped['dining'], 50.0);
      });
    });

    group('Multiple insights variations', () {
      test('should calculate status with large insights list', () {
        final insights = List.generate(20, (i) => 'Insight $i');
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 2000,
          savingsGoal: 1000,
          insights: insights,
        );

        expect(status.level, StatusLevel.good);
        expect(insights.length, 20);
      });

      test(
          'should calculate status with insights containing special characters',
          () {
        final insights = ['Save \$500', 'Reduce dining by 20%', '🎯 Goal met!'];
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 2000,
          savingsGoal: 1000,
          insights: insights,
        );

        expect(status.level, StatusLevel.good);
      });
    });

    group('Exact boundary calculations', () {
      test('should handle exact buffer minus epsilon', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 3500.01,
          savingsGoal: 1000,
        );

        expect(status.remaining, closeTo(499.99, 0.001));
        expect(status.level, StatusLevel.good);
      });

      test('should handle exact buffer plus epsilon', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 3499.99,
          savingsGoal: 1000,
        );

        expect(status.remaining, closeTo(500.01, 0.001));
        expect(status.level, StatusLevel.good);
      });
    });
  });
}
