import 'package:flutter_test/flutter_test.dart';
import 'package:futureproof/models/transaction.dart';

void main() {
  group('Database Service Integration', () {
    // Note: Full database tests require platform-specific setup
    // These tests validate data transformations and serialization

    group('Transaction Serialization for SQLite', () {
      test('should serialize transaction to SQLite map format', () {
        final date = DateTime(2024, 1, 10);
        final createdAt = DateTime(2024, 1, 9);

        final transaction = Transaction(
          id: 'test-123',
          amount: -123.45,
          category: 'groceries',
          date: date,
          note: 'Weekly shopping',
          householdId: 'house-1',
          createdAt: createdAt,
        );

        // Simulate how it would be stored in SQLite
        final sqliteMap = {
          'id': transaction.id,
          'amount': transaction.amount,
          'category': transaction.category,
          'note': transaction.note,
          'date': transaction.date.millisecondsSinceEpoch,
          'householdId': transaction.householdId,
          'createdAt': transaction.createdAt.millisecondsSinceEpoch,
        };

        expect(sqliteMap['id'], 'test-123');
        expect(sqliteMap['amount'], -123.45);
        expect(sqliteMap['category'], 'groceries');
        expect(sqliteMap['note'], 'Weekly shopping');
        expect(sqliteMap['date'], date.millisecondsSinceEpoch);
        expect(sqliteMap['householdId'], 'house-1');
        expect(sqliteMap['createdAt'], createdAt.millisecondsSinceEpoch);
      });

      test('should deserialize transaction from SQLite map format', () {
        final date = DateTime(2024, 1, 10);
        final createdAt = DateTime(2024, 1, 9);

        final sqliteMap = {
          'id': 'test-123',
          'amount': -123.45,
          'category': 'groceries',
          'note': 'Weekly shopping',
          'date': date.millisecondsSinceEpoch,
          'householdId': 'house-1',
          'createdAt': createdAt.millisecondsSinceEpoch,
        };

        final transaction = Transaction.fromSqliteMap(sqliteMap);

        expect(transaction.id, 'test-123');
        expect(transaction.amount, -123.45);
        expect(transaction.category, 'groceries');
        expect(transaction.note, 'Weekly shopping');
        expect(transaction.date, date);
        expect(transaction.householdId, 'house-1');
        expect(transaction.createdAt, createdAt);
      });

      test('should handle missing optional fields in SQLite map', () {
        final date = DateTime(2024, 1, 10);

        final sqliteMap = {
          'id': 'test-123',
          'amount': -50.0,
          'category': 'dining',
          'note': null,
          'date': date.millisecondsSinceEpoch,
          'householdId': '',
        };

        final transaction = Transaction.fromSqliteMap(sqliteMap);

        expect(transaction.id, 'test-123');
        expect(transaction.amount, -50.0);
        expect(transaction.category, 'dining');
        expect(transaction.note, null);
        expect(transaction.householdId, '');
        expect(transaction.createdAt, isNotNull); // Should default to now
      });

      test('should round-trip transaction through SQLite format', () {
        final original = Transaction(
          id: 'round-trip-test',
          amount: -250.0,
          category: 'housing',
          date: DateTime(2024, 1, 15),
          note: 'Rent payment',
          householdId: 'house-456',
          createdAt: DateTime(2024, 1, 10),
        );

        // Serialize to SQLite format
        final sqliteMap = {
          'id': original.id,
          'amount': original.amount,
          'category': original.category,
          'note': original.note,
          'date': original.date.millisecondsSinceEpoch,
          'householdId': original.householdId,
          'createdAt': original.createdAt.millisecondsSinceEpoch,
        };

        // Deserialize back
        final restored = Transaction.fromSqliteMap(sqliteMap);

        // Verify all fields match
        expect(restored.id, original.id);
        expect(restored.amount, original.amount);
        expect(restored.category, original.category);
        expect(restored.note, original.note);
        expect(restored.date, original.date);
        expect(restored.householdId, original.householdId);
        expect(restored.createdAt, original.createdAt);
      });
    });

    group('Transaction Serialization for Firestore', () {
      test('should serialize transaction to Firestore map format', () {
        final date = DateTime(2024, 1, 10);
        final createdAt = DateTime(2024, 1, 9);

        final transaction = Transaction(
          id: 'test-123',
          amount: -123.45,
          category: 'groceries',
          date: date,
          note: 'Weekly shopping',
          householdId: 'house-1',
          createdAt: createdAt,
        );

        final firestoreMap = transaction.toMap();

        expect(firestoreMap['amount'], -123.45);
        expect(firestoreMap['category'], 'groceries');
        expect(firestoreMap['note'], 'Weekly shopping');
        expect(firestoreMap['date'], date.toIso8601String());
        expect(firestoreMap['household_id'], 'house-1');
        expect(firestoreMap['created_at'], createdAt.toIso8601String());
      });

      test('should deserialize transaction from Firestore map format', () {
        final date = '2024-01-10T00:00:00.000Z';
        final createdAt = '2024-01-09T00:00:00.000Z';

        final firestoreMap = {
          'amount': 123.45,
          'category': 'income',
          'note': 'Salary',
          'date': date,
          'household_id': 'house-1',
          'created_at': createdAt,
        };

        final transaction = Transaction.fromMap(firestoreMap, 'test-id');

        expect(transaction.id, 'test-id');
        expect(transaction.amount, 123.45);
        expect(transaction.category, 'income');
        expect(transaction.note, 'Salary');
        expect(transaction.date, DateTime.parse(date));
        expect(transaction.householdId, 'house-1');
        expect(transaction.createdAt, DateTime.parse(createdAt));
      });

      test('should round-trip transaction through Firestore format', () {
        final original = Transaction(
          id: 'round-trip-test',
          amount: 3000.0,
          category: 'income',
          date: DateTime(2024, 1, 15),
          note: 'Monthly salary',
          householdId: 'house-789',
          createdAt: DateTime(2024, 1, 10),
        );

        // Serialize to Firestore format
        final firestoreMap = original.toMap();

        // Deserialize back (simulating Firestore read)
        final restored = Transaction.fromMap(firestoreMap, original.id);

        // Verify all fields match
        expect(restored.id, original.id);
        expect(restored.amount, original.amount);
        expect(restored.category, original.category);
        expect(restored.note, original.note);
        expect(restored.date, original.date);
        expect(restored.householdId, original.householdId);
        expect(restored.createdAt, original.createdAt);
      });
    });

    group('Data Type Compatibility', () {
      test('should handle double amounts correctly', () {
        final amounts = [
          -0.01,
          -100.50,
          -1000.99,
          0.0,
          50.0,
          2500.75,
        ];

        for (final amount in amounts) {
          final transaction = Transaction(
            id: 'test-$amount',
            amount: amount,
            category: amount >= 0 ? 'income' : 'groceries',
            date: DateTime.now(),
          );

          final sqliteMap = {
            'id': transaction.id,
            'amount': transaction.amount,
            'category': transaction.category,
            'date': transaction.date.millisecondsSinceEpoch,
          };

          final restored = Transaction.fromSqliteMap(sqliteMap);

          expect(restored.amount, closeTo(amount, 0.001),
            reason: 'Amount $amount should round-trip correctly');
        }
      });

      test('should handle DateTime precision', () {
        final dates = [
          DateTime(2024, 1, 1),
          DateTime(2024, 6, 15, 14, 30),
          DateTime(2024, 12, 31, 23, 59, 59),
        ];

        for (final date in dates) {
          final transaction = Transaction(
            id: 'test-${date.millisecondsSinceEpoch}',
            amount: -100.0,
            category: 'groceries',
            date: date,
          );

          final sqliteMap = {
            'id': transaction.id,
            'amount': transaction.amount,
            'category': transaction.category,
            'date': transaction.date.millisecondsSinceEpoch,
          };

          final restored = Transaction.fromSqliteMap(sqliteMap);

          expect(restored.date, date,
            reason: 'DateTime $date should round-trip correctly');
        }
      });
    });

    group('Edge Cases', () {
      test('should handle very long notes', () {
        final longNote = 'x' * 500; // Max allowed length

        final transaction = Transaction(
          id: 'test',
          amount: -50.0,
          category: 'groceries',
          date: DateTime.now(),
          note: longNote,
        );

        expect(transaction.note?.length, 500);
      });

      test('should handle special characters in notes', () {
        final specialNotes = [
          'Test with emoji 🛒',
          'Test with quotes "hello"',
          "Test with apostrophes 'world'",
          'Test with\nnewlines',
          'Test with\ttabs',
        ];

        for (final note in specialNotes) {
          final transaction = Transaction(
            id: 'test',
            amount: -50.0,
            category: 'groceries',
            date: DateTime.now(),
            note: note,
          );

          expect(transaction.note, note);
        }
      });

      test('should handle all valid categories', () {
        final categories = [
          'housing',
          'groceries',
          'dining',
          'transport',
          'entertainment',
          'health',
          'shopping',
          'subscriptions',
          'income',
        ];

        for (final category in categories) {
          final transaction = Transaction(
            id: 'test-$category',
            amount: -100.0,
            category: category,
            date: DateTime.now(),
          );

          expect(transaction.category, category);
        }
      });
    });
  });
}
