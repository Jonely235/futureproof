import 'package:flutter_test/flutter_test.dart';
import 'package:futureproof/models/transaction.dart';

void main() {
  group('Transaction Model', () {
    group('Creation', () {
      test('should create transaction with required fields', () {
        // Arrange
        final id = 'test-123';
        final amount = -50.0;
        final category = 'groceries';
        final date = DateTime(2024, 1, 10);

        // Act
        final transaction = Transaction(
          id: id,
          amount: amount,
          category: category,
          date: date,
        );

        // Assert
        expect(transaction.id, id);
        expect(transaction.amount, amount);
        expect(transaction.category, category);
        expect(transaction.date, date);
      });

      test('should use current time for createdAt if not provided', () {
        final before = DateTime.now();
        final t = Transaction(
          id: 'test',
          amount: -50.0,
          category: 'groceries',
          date: DateTime.now(),
        );
        final after = DateTime.now();

        expect(t.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), true);
        expect(t.createdAt.isBefore(after.add(const Duration(seconds: 1))), true);
      });

      test('should accept custom createdAt', () {
        final customDate = DateTime(2023, 12, 25);
        final t = Transaction(
          id: 'test',
          amount: -50.0,
          category: 'groceries',
          date: DateTime.now(),
          createdAt: customDate,
        );

        expect(t.createdAt, customDate);
      });

      test('should accept note', () {
        final t = Transaction(
          id: 'test',
          amount: -50.0,
          category: 'groceries',
          date: DateTime.now(),
          note: 'Weekly shopping',
        );

        expect(t.note, 'Weekly shopping');
      });

      test('should handle null note', () {
        final t = Transaction(
          id: 'test',
          amount: -50.0,
          category: 'groceries',
          date: DateTime.now(),
        );

        expect(t.note, null);
      });
    });

    group('Type Checking', () {
      test('should identify expense correctly', () {
        final expense = Transaction(
          id: '1',
          amount: -100.0,
          category: 'dining',
          date: DateTime.now(),
        );

        expect(expense.isExpense, true);
        expect(expense.isIncome, false);
      });

      test('should identify income correctly', () {
        final income = Transaction(
          id: '2',
          amount: 1000.0,
          category: 'income',
          date: DateTime.now(),
        );

        expect(income.isIncome, true);
        expect(income.isExpense, false);
      });

      test('should handle zero amount', () {
        final zero = Transaction(
          id: '3',
          amount: 0.0,
          category: 'groceries',
          date: DateTime.now(),
        );

        expect(zero.isIncome, false);
        expect(zero.isExpense, false);
      });
    });

    group('Formatting', () {
      test('should format expense amount correctly', () {
        final t = Transaction(
          id: '1',
          amount: -123.45,
          category: 'shopping',
          date: DateTime.now(),
        );

        expect(t.formattedAmount, '\$123.45');
      });

      test('should format income amount correctly', () {
        final t = Transaction(
          id: '1',
          amount: 2500.0,
          category: 'income',
          date: DateTime.now(),
        );

        expect(t.formattedAmount, '\$2500.00');
      });

      test('should format small amounts correctly', () {
        final t = Transaction(
          id: '1',
          amount: -0.99,
          category: 'groceries',
          date: DateTime.now(),
        );

        expect(t.formattedAmount, '\$0.99');
      });
    });

    group('Category Emojis', () {
      test('should return correct emoji for each category', () {
        final testCases = {
          'housing': '🏠',
          'groceries': '🛒',
          'dining': '🍽️',
          'transport': '🚗',
          'entertainment': '🎭',
          'health': '💊',
          'shopping': '🛍️',
          'subscriptions': '📱',
          'income': '💰',
        };

        testCases.forEach((category, expectedEmoji) {
          final t = Transaction(
            id: '1',
            amount: -50.0,
            category: category,
            date: DateTime.now(),
          );

          expect(t.categoryEmoji, expectedEmoji,
            reason: '$category should have emoji $expectedEmoji');
        });
      });

      test('should throw error for unknown category during creation', () {
        expect(
          () => Transaction(
            id: '1',
            amount: -50.0,
            category: 'unknown',
            date: DateTime.now(),
          ),
          throwsArgumentError,
        );
      });

      test('should handle case-insensitive categories', () {
        final t = Transaction(
          id: '1',
          amount: -50.0,
          category: 'GROCERIES',
          date: DateTime.now(),
        );

        expect(t.categoryEmoji, '🛒');
      });
    });

    group('Validation', () {
      test('should reject empty ID', () {
        expect(
          () => Transaction(
            id: '   ',
            amount: -50.0,
            category: 'groceries',
            date: DateTime.now(),
          ),
          throwsAssertionError,
        );
      });

      test('should reject invalid category', () {
        expect(
          () => Transaction(
            id: 'test',
            amount: -50.0,
            category: 'invalid_category',
            date: DateTime.now(),
          ),
          throwsArgumentError,
        );
      });

      test('should reject amount that is too high', () {
        expect(
          () => Transaction(
            id: 'test',
            amount: 2000000.0,
            category: 'income',
            date: DateTime.now(),
          ),
          throwsAssertionError,
        );
      });

      test('should reject amount that is too low', () {
        expect(
          () => Transaction(
            id: 'test',
            amount: -2000000.0,
            category: 'groceries',
            date: DateTime.now(),
          ),
          throwsAssertionError,
        );
      });

      test('should reject note that is too long', () {
        expect(
          () => Transaction(
            id: 'test',
            amount: -50.0,
            category: 'groceries',
            date: DateTime.now(),
            note: 'x' * 501,
          ),
          throwsAssertionError,
        );
      });

      test('should accept valid transaction', () {
        expect(
          () => Transaction(
            id: 'test-id',
            amount: -100.0,
            category: 'groceries',
            date: DateTime.now(),
            note: 'Valid note',
          ),
          returnsNormally,
        );
      });
    });

    group('Serialization', () {
      test('should serialize to map correctly', () {
        final date = DateTime(2024, 1, 10, 12, 30);
        final createdAt = DateTime(2024, 1, 10, 10, 0);
        final t = Transaction(
          id: 'test-123',
          amount: -123.45,
          category: 'groceries',
          date: date,
          note: 'Test note',
          householdId: 'house-1',
          createdAt: createdAt,
        );

        final map = t.toMap();

        expect(map['amount'], -123.45);
        expect(map['category'], 'groceries');
        expect(map['note'], 'Test note');
        expect(map['date'], date.toIso8601String());
        expect(map['household_id'], 'house-1');
        expect(map['created_at'], createdAt.toIso8601String());
      });

      test('should deserialize from Firestore map correctly', () {
        final date = '2024-01-10T12:30:00.000Z';
        final createdAt = '2024-01-10T10:00:00.000Z';

        final map = {
          'amount': 123.45,
          'category': 'income',
          'note': 'Salary',
          'date': date,
          'household_id': 'house-1',
          'created_at': createdAt,
        };

        final t = Transaction.fromMap(map, 'test-id');

        expect(t.id, 'test-id');
        expect(t.amount, 123.45);
        expect(t.category, 'income');
        expect(t.note, 'Salary');
        expect(t.date, DateTime.parse(date));
        expect(t.householdId, 'house-1');
        expect(t.createdAt, DateTime.parse(createdAt));
      });

      test('should deserialize from SQLite map correctly', () {
        final date = DateTime(2024, 1, 10);
        final createdAt = DateTime(2024, 1, 9);

        final map = {
          'id': 'test-id',
          'amount': -50.0,
          'category': 'groceries',
          'note': 'Shopping',
          'date': date.millisecondsSinceEpoch,
          'householdId': 'house-1',
          'createdAt': createdAt.millisecondsSinceEpoch,
        };

        final t = Transaction.fromSqliteMap(map);

        expect(t.id, 'test-id');
        expect(t.amount, -50.0);
        expect(t.category, 'groceries');
        expect(t.note, 'Shopping');
        expect(t.date, date);
        expect(t.householdId, 'house-1');
        expect(t.createdAt, createdAt);
      });

      test('should handle null householdId in SQLite map', () {
        final map = {
          'id': 'test-id',
          'amount': -50.0,
          'category': 'groceries',
          'date': DateTime.now().millisecondsSinceEpoch,
        };

        final t = Transaction.fromSqliteMap(map);

        expect(t.householdId, '');
      });

      test('should handle null createdAt in SQLite map', () {
        final date = DateTime.now();
        final before = DateTime.now();

        final map = {
          'id': 'test-id',
          'amount': -50.0,
          'category': 'groceries',
          'date': date.millisecondsSinceEpoch,
        };

        final t = Transaction.fromSqliteMap(map);
        final after = DateTime.now();

        expect(t.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), true);
        expect(t.createdAt.isBefore(after.add(const Duration(seconds: 1))), true);
      });
    });
  });
}
