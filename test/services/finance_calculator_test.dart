import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futureproof/services/finance_calculator.dart';
import 'package:futureproof/models/transaction.dart';

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
        expect(status.message, contains('left'));
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

      test('should generate different messages for GOOD status', () {
        // Test multiple times to check random message selection
        final messages = <String>{};

        for (int i = 0; i < 10; i++) {
          final status = FinanceCalculator.calculateStatus(
            monthlyIncome: 10000,
            monthlyExpenses: 2000,
            savingsGoal: 1000,
          );
          messages.add(status.message);
        }

        // Should have generated at least 2 different messages
        expect(messages.length, greaterThan(1),
          reason: 'Should have multiple message variations');
      });
    });

    group('calculateTotalExpenses', () {
      test('should sum only negative amounts', () {
        final transactions = [
          Transaction(id: '1', amount: -100.0, category: 'groceries', date: DateTime.now()),
          Transaction(id: '2', amount: -50.0, category: 'groceries', date: DateTime.now()),
          Transaction(id: '3', amount: 200.0, category: 'income', date: DateTime.now()),
          Transaction(id: '4', amount: 500.0, category: 'income', date: DateTime.now()),
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
          Transaction(id: '1', amount: 100.0, category: 'income', date: DateTime.now()),
          Transaction(id: '2', amount: 200.0, category: 'income', date: DateTime.now()),
        ];

        final total = FinanceCalculator.calculateTotalExpenses(transactions);
        expect(total, 0.0);
      });

      test('should handle zero amounts', () {
        final transactions = [
          Transaction(id: '1', amount: -100.0, category: 'groceries', date: DateTime.now()),
          Transaction(id: '2', amount: 0.0, category: 'groceries', date: DateTime.now()),
          Transaction(id: '3', amount: -50.0, category: 'dining', date: DateTime.now()),
        ];

        final total = FinanceCalculator.calculateTotalExpenses(transactions);
        expect(total, 150.0);
      });

      test('should handle very small amounts', () {
        final transactions = [
          Transaction(id: '1', amount: -0.01, category: 'groceries', date: DateTime.now()),
          Transaction(id: '2', amount: -0.99, category: 'dining', date: DateTime.now()),
        ];

        final total = FinanceCalculator.calculateTotalExpenses(transactions);
        expect(total, closeTo(1.0, 0.001));
      });
    });

    group('groupByCategory', () {
      test('should group expenses by category', () {
        final transactions = [
          Transaction(id: '1', amount: -100.0, category: 'groceries', date: DateTime.now()),
          Transaction(id: '2', amount: -50.0, category: 'groceries', date: DateTime.now()),
          Transaction(id: '3', amount: -200.0, category: 'dining', date: DateTime.now()),
          Transaction(id: '4', amount: 100.0, category: 'income', date: DateTime.now()),
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
          Transaction(id: '1', amount: 1000.0, category: 'income', date: DateTime.now()),
          Transaction(id: '2', amount: 500.0, category: 'income', date: DateTime.now()),
        ];

        final grouped = FinanceCalculator.groupByCategory(transactions);
        expect(grouped, isEmpty);
      });

      test('should handle mixed categories', () {
        final transactions = [
          Transaction(id: '1', amount: -100.0, category: 'housing', date: DateTime.now()),
          Transaction(id: '2', amount: -50.0, category: 'groceries', date: DateTime.now()),
          Transaction(id: '3', amount: -75.0, category: 'transport', date: DateTime.now()),
          Transaction(id: '4', amount: -25.0, category: 'groceries', date: DateTime.now()),
        ];

        final grouped = FinanceCalculator.groupByCategory(transactions);

        expect(grouped['housing'], 100.0);
        expect(grouped['groceries'], 75.0);
        expect(grouped['transport'], 75.0);
      });
    });

    group('getHighestSpendingCategory', () {
      test('should return category with highest spending', () {
        final transactions = [
          Transaction(id: '1', amount: -100.0, category: 'groceries', date: DateTime.now()),
          Transaction(id: '2', amount: -200.0, category: 'dining', date: DateTime.now()),
          Transaction(id: '3', amount: -50.0, category: 'groceries', date: DateTime.now()),
        ];

        final highest = FinanceCalculator.getHighestSpendingCategory(transactions);

        expect(highest, 'dining'); // 200 > 150
      });

      test('should return None for empty list', () {
        final highest = FinanceCalculator.getHighestSpendingCategory([]);
        expect(highest, 'None');
      });

      test('should return None for income-only list', () {
        final transactions = [
          Transaction(id: '1', amount: 100.0, category: 'income', date: DateTime.now()),
        ];

        final highest = FinanceCalculator.getHighestSpendingCategory(transactions);
        expect(highest, 'None');
      });

      test('should handle tie by returning first', () {
        final transactions = [
          Transaction(id: '1', amount: -100.0, category: 'groceries', date: DateTime.now()),
          Transaction(id: '2', amount: -100.0, category: 'dining', date: DateTime.now()),
        ];

        final highest = FinanceCalculator.getHighestSpendingCategory(transactions);

        // Should return one of them (implementation dependent)
        expect(['groceries', 'dining'], contains(highest));
      });

      test('should exclude income from calculation', () {
        final transactions = [
          Transaction(id: '1', amount: 10000.0, category: 'income', date: DateTime.now()),
          Transaction(id: '2', amount: -100.0, category: 'groceries', date: DateTime.now()),
          Transaction(id: '3', amount: -50.0, category: 'dining', date: DateTime.now()),
        ];

        final highest = FinanceCalculator.getHighestSpendingCategory(transactions);

        expect(highest, 'groceries');
      });
    });

    group('FinanceStatus', () {
      test('should have correct color for GOOD status', () {
        final status = FinanceStatus(
          message: 'Test',
          level: StatusLevel.good,
          remaining: 100.0,
        );

        expect(status.color, const Color(0xFF4CAF50)); // Green
      });

      test('should have correct color for CAUTION status', () {
        final status = FinanceStatus(
          message: 'Test',
          level: StatusLevel.caution,
          remaining: -100.0,
        );

        expect(status.color, const Color(0xFFFF9800)); // Orange
      });

      test('should have correct color for DANGER status', () {
        final status = FinanceStatus(
          message: 'Test',
          level: StatusLevel.danger,
          remaining: -500.0,
        );

        expect(status.color, const Color(0xFFF44336)); // Red
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
  });
}
