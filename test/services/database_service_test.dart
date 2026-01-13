import 'package:flutter_test/flutter_test.dart';
import 'package:futureproof/models/transaction.dart' as model;
import 'package:futureproof/services/database_service.dart';
import '../helper/test_helper.dart';

void main() {
  // Initialize test database for all tests
  setUpAll(() {
    initializeTestDatabase();
  });

  group('Database Service Integration', () {
    late DatabaseService databaseService;

    setUp(() async {
      databaseService = DatabaseService();
    });

    tearDown(() async {
      // Clean up database after each test
      try {
        await databaseService.deleteAllTransactions();
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    // Note: Full database tests require platform-specific setup
    // These tests validate data transformations and serialization

    group('Transaction Serialization for SQLite', () {
      test('should serialize transaction to SQLite map format', () {
        final date = DateTime(2024, 1, 10);
        final createdAt = DateTime(2024, 1, 9);

        final transaction = model.Transaction(
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

        final transaction = model.Transaction.fromSqliteMap(sqliteMap);

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

        final transaction = model.Transaction.fromSqliteMap(sqliteMap);

        expect(transaction.id, 'test-123');
        expect(transaction.amount, -50.0);
        expect(transaction.category, 'dining');
        expect(transaction.note, null);
        expect(transaction.householdId, '');
        expect(transaction.createdAt, isNotNull); // Should default to now
      });

      test('should round-trip transaction through SQLite format', () {
        final original = model.Transaction(
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
        final restored = model.Transaction.fromSqliteMap(sqliteMap);

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

        final transaction = model.Transaction(
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
        const date = '2024-01-10T00:00:00.000Z';
        const createdAt = '2024-01-09T00:00:00.000Z';

        final firestoreMap = {
          'amount': 123.45,
          'category': 'income',
          'note': 'Salary',
          'date': date,
          'household_id': 'house-1',
          'created_at': createdAt,
        };

        final transaction = model.Transaction.fromMap(firestoreMap, 'test-id');

        expect(transaction.id, 'test-id');
        expect(transaction.amount, 123.45);
        expect(transaction.category, 'income');
        expect(transaction.note, 'Salary');
        expect(transaction.date, DateTime.parse(date));
        expect(transaction.householdId, 'house-1');
        expect(transaction.createdAt, DateTime.parse(createdAt));
      });

      test('should round-trip transaction through Firestore format', () {
        final original = model.Transaction(
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
        final restored = model.Transaction.fromMap(firestoreMap, original.id);

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
          final transaction = model.Transaction(
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

          final restored = model.Transaction.fromSqliteMap(sqliteMap);

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
          final transaction = model.Transaction(
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

          final restored = model.Transaction.fromSqliteMap(sqliteMap);

          expect(restored.date, date,
              reason: 'DateTime $date should round-trip correctly');
        }
      });
    });

    group('Edge Cases', () {
      test('should handle very long notes', () {
        final longNote = 'x' * 500; // Max allowed length

        final transaction = model.Transaction(
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
          final transaction = model.Transaction(
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
          final transaction = model.Transaction(
            id: 'test-$category',
            amount: -100.0,
            category: category,
            date: DateTime.now(),
          );

          expect(transaction.category, category);
        }
      });
    });

    group('Database CRUD Operations', () {
      test('should add transaction to database', () async {
        final transaction = model.Transaction(
          id: 'test-add-1',
          amount: -100.50,
          category: 'groceries',
          date: DateTime(2024, 1, 15),
          note: 'Test transaction',
        );

        final resultId = await databaseService.addTransaction(transaction);
        expect(resultId, equals('test-add-1'));

        final transactions = await databaseService.getAllTransactions();
        expect(transactions, hasLength(1));
        expect(transactions.first.id, equals('test-add-1'));
        expect(transactions.first.amount, equals(-100.50));
        expect(transactions.first.category, equals('groceries'));
      });

      test('should add multiple transactions', () async {
        final transactions = [
          model.Transaction(
            id: 'test-multi-1',
            amount: -50.0,
            category: 'dining',
            date: DateTime(2024, 1, 10),
          ),
          model.Transaction(
            id: 'test-multi-2',
            amount: -75.0,
            category: 'transport',
            date: DateTime(2024, 1, 11),
          ),
          model.Transaction(
            id: 'test-multi-3',
            amount: 3000.0,
            category: 'income',
            date: DateTime(2024, 1, 12),
          ),
        ];

        for (final tx in transactions) {
          await databaseService.addTransaction(tx);
        }

        final retrieved = await databaseService.getAllTransactions();
        expect(retrieved, hasLength(3));
      });

      test('should update existing transaction', () async {
        final original = model.Transaction(
          id: 'test-update-1',
          amount: -100.0,
          category: 'groceries',
          date: DateTime(2024, 1, 15),
          note: 'Original note',
        );

        await databaseService.addTransaction(original);

        final updated = model.Transaction(
          id: 'test-update-1',
          amount: -150.0,
          category: 'groceries',
          date: DateTime(2024, 1, 15),
          note: 'Updated note',
        );

        final result = await databaseService.updateTransaction(updated);
        expect(result, isTrue);

        final transactions = await databaseService.getAllTransactions();
        expect(transactions, hasLength(1));
        expect(transactions.first.amount, equals(-150.0));
        expect(transactions.first.note, equals('Updated note'));
      });

      test('should return false when updating non-existent transaction',
          () async {
        final nonExistent = model.Transaction(
          id: 'does-not-exist',
          amount: -100.0,
          category: 'groceries',
          date: DateTime(2024, 1, 15),
        );

        final result = await databaseService.updateTransaction(nonExistent);
        expect(result, isFalse);
      });

      test('should delete transaction by ID', () async {
        final transaction = model.Transaction(
          id: 'test-delete-1',
          amount: -100.0,
          category: 'groceries',
          date: DateTime(2024, 1, 15),
        );

        await databaseService.addTransaction(transaction);

        final result = await databaseService.deleteTransaction('test-delete-1');
        expect(result, isTrue);

        final transactions = await databaseService.getAllTransactions();
        expect(transactions, isEmpty);
      });

      test('should return false when deleting non-existent transaction',
          () async {
        final result =
            await databaseService.deleteTransaction('does-not-exist');
        expect(result, isFalse);
      });

      test('should delete all transactions', () async {
        final transactions = [
          model.Transaction(
            id: 'test-clear-1',
            amount: -50.0,
            category: 'dining',
            date: DateTime(2024, 1, 10),
          ),
          model.Transaction(
            id: 'test-clear-2',
            amount: -75.0,
            category: 'transport',
            date: DateTime(2024, 1, 11),
          ),
        ];

        for (final tx in transactions) {
          await databaseService.addTransaction(tx);
        }

        expect(await databaseService.getAllTransactions(), hasLength(2));

        final result = await databaseService.deleteAllTransactions();
        expect(result, isTrue);

        expect(await databaseService.getAllTransactions(), isEmpty);
      });
    });

    group('Database Query Operations', () {
      test('should retrieve all transactions sorted by date descending',
          () async {
        final transactions = [
          model.Transaction(
            id: 'test-sort-1',
            amount: -100.0,
            category: 'groceries',
            date: DateTime(2024, 1, 10),
          ),
          model.Transaction(
            id: 'test-sort-2',
            amount: -200.0,
            category: 'housing',
            date: DateTime(2024, 1, 15),
          ),
          model.Transaction(
            id: 'test-sort-3',
            amount: -50.0,
            category: 'dining',
            date: DateTime(2024, 1, 12),
          ),
        ];

        for (final tx in transactions) {
          await databaseService.addTransaction(tx);
        }

        final retrieved = await databaseService.getAllTransactions();
        expect(retrieved, hasLength(3));

        // Verify descending order (newest first)
        expect(retrieved[0].id, equals('test-sort-2')); // Jan 15
        expect(retrieved[1].id, equals('test-sort-3')); // Jan 12
        expect(retrieved[2].id, equals('test-sort-1')); // Jan 10
      });

      test('should query transactions by date range', () async {
        final transactions = [
          model.Transaction(
            id: 'test-range-1',
            amount: -100.0,
            category: 'groceries',
            date: DateTime(2024, 1, 5),
          ),
          model.Transaction(
            id: 'test-range-2',
            amount: -200.0,
            category: 'housing',
            date: DateTime(2024, 1, 10),
          ),
          model.Transaction(
            id: 'test-range-3',
            amount: -150.0,
            category: 'dining',
            date: DateTime(2024, 1, 15),
          ),
          model.Transaction(
            id: 'test-range-4',
            amount: -50.0,
            category: 'transport',
            date: DateTime(2024, 1, 20),
          ),
        ];

        for (final tx in transactions) {
          await databaseService.addTransaction(tx);
        }

        final start = DateTime(2024, 1, 8);
        final end = DateTime(2024, 1, 18);

        final retrieved =
            await databaseService.getTransactionsByDateRange(start, end);
        expect(retrieved, hasLength(2));

        final ids = retrieved.map((t) => t.id).toSet();
        expect(ids, contains('test-range-2'));
        expect(ids, contains('test-range-3'));
        expect(ids, isNot(contains('test-range-1')));
        expect(ids, isNot(contains('test-range-4')));
      });

      test('should return empty list for date range with no transactions',
          () async {
        final transaction = model.Transaction(
          id: 'test-empty-range',
          amount: -100.0,
          category: 'groceries',
          date: DateTime(2024, 1, 10),
        );

        await databaseService.addTransaction(transaction);

        final start = DateTime(2024, 2, 1);
        final end = DateTime(2024, 2, 28);

        final retrieved =
            await databaseService.getTransactionsByDateRange(start, end);
        expect(retrieved, isEmpty);
      });

      test('should calculate total for month', () async {
        final transactions = [
          model.Transaction(
            id: 'test-total-1',
            amount: -100.0,
            category: 'groceries',
            date: DateTime(2024, 1, 5),
          ),
          model.Transaction(
            id: 'test-total-2',
            amount: -200.0,
            category: 'housing',
            date: DateTime(2024, 1, 15),
          ),
          model.Transaction(
            id: 'test-total-3',
            amount: 3000.0,
            category: 'income',
            date: DateTime(2024, 1, 1),
          ),
          model.Transaction(
            id: 'test-total-4',
            amount: -50.0,
            category: 'dining',
            date: DateTime(2024, 2, 10),
          ),
        ];

        for (final tx in transactions) {
          await databaseService.addTransaction(tx);
        }

        final januaryTotal = await databaseService.getTotalForMonth(2024, 1);
        expect(januaryTotal,
            equals(300.0)); // 100 + 200 (absolute value of expenses)

        final februaryTotal = await databaseService.getTotalForMonth(2024, 2);
        expect(februaryTotal, equals(50.0));
      });

      test(
          'should return empty list when getting all transactions from empty database',
          () async {
        final transactions = await databaseService.getAllTransactions();
        expect(transactions, isEmpty);
      });
    });

    group('Database Error Handling', () {
      test('should reject transaction with empty ID', () async {
        // Transaction model itself validates ID and throws AssertionError
        expect(
          () => model.Transaction(
            id: '',
            amount: -100.0,
            category: 'groceries',
            date: DateTime(2024, 1, 15),
          ),
          throwsAssertionError,
        );
      });

      test('should handle duplicate transaction IDs with replace', () async {
        final original = model.Transaction(
          id: 'test-duplicate',
          amount: -100.0,
          category: 'groceries',
          date: DateTime(2024, 1, 15),
          note: 'Original',
        );

        await databaseService.addTransaction(original);

        final duplicate = model.Transaction(
          id: 'test-duplicate',
          amount: -200.0,
          category: 'groceries',
          date: DateTime(2024, 1, 15),
          note: 'Duplicate',
        );

        // Should replace due to ConflictAlgorithm.replace
        await databaseService.addTransaction(duplicate);

        final transactions = await databaseService.getAllTransactions();
        expect(transactions, hasLength(1));
        expect(transactions.first.amount, equals(-200.0));
        expect(transactions.first.note, equals('Duplicate'));
      });

      test('should preserve data integrity through CRUD operations', () async {
        final original = model.Transaction(
          id: 'test-integrity',
          amount: -123.45,
          category: 'groceries',
          date: DateTime(2024, 1, 15, 14, 30),
          note: 'Test integrity 🛒',
        );

        // Add
        await databaseService.addTransaction(original);

        // Retrieve
        var transactions = await databaseService.getAllTransactions();
        expect(transactions, hasLength(1));
        expect(transactions.first.amount, equals(-123.45));
        expect(transactions.first.note, equals('Test integrity 🛒'));

        // Update
        final updated = model.Transaction(
          id: 'test-integrity',
          amount: -250.0,
          category: 'groceries',
          date: DateTime(2024, 1, 15, 14, 30),
          note: 'Updated integrity',
        );
        await databaseService.updateTransaction(updated);

        // Verify update
        transactions = await databaseService.getAllTransactions();
        expect(transactions.first.amount, equals(-250.0));
        expect(transactions.first.note, equals('Updated integrity'));

        // Delete
        await databaseService.deleteTransaction('test-integrity');

        // Verify deletion
        transactions = await databaseService.getAllTransactions();
        expect(transactions, isEmpty);
      });
    });
  });
}
