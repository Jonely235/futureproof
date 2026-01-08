import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as model;

/// SQLite-based Database service for managing transaction persistence.
///
/// Implements singleton pattern to ensure single database connection.
/// Provides CRUD operations for [Transaction] model.
///
/// Phase 1 MVP: Local-only storage (no sync)
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDatabase();
      return _database!;
    } catch (e) {
      print('❌ Error initializing database: $e');
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'futureproof.db');

      print('📁 Database path: $path');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e) {
      print('❌ Error in _initDatabase: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date INTEGER NOT NULL,
        note TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  /// Adds a new transaction to SQLite.
  ///
  /// Returns the transaction ID (same as input).
  /// Throws [Exception] if operation fails.
  Future<String> addTransaction(model.Transaction transaction) async {
    try {
      final db = await database;

      // Validate transaction has required fields
      if (transaction.id.isEmpty) {
        throw ArgumentError('Transaction ID cannot be empty');
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final data = {
        'id': transaction.id,
        'amount': transaction.amount,
        'category': transaction.category,
        'date': transaction.date.millisecondsSinceEpoch,
        'note': transaction.note,
        'created_at': now,
        'updated_at': now,
      };

      await db.insert('transactions', data, conflictAlgorithm: ConflictAlgorithm.replace);

      print('✅ Added transaction ${transaction.id} to SQLite');
      return transaction.id;
    } catch (e) {
      print('❌ Error adding transaction: $e');
      rethrow;
    }
  }

  /// Retrieves all transactions from SQLite.
  ///
  /// Returns transactions sorted by date in descending order (newest first).
  /// Returns empty list if no transactions exist or on error.
  Future<List<model.Transaction>> getAllTransactions() async {
    try {
      final db = await database;

      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        orderBy: 'date DESC',
      );

      print('📊 Retrieved ${maps.length} transactions from SQLite');

      if (maps.isEmpty) {
        return [];
      }

      return maps.map((map) => _transactionFromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting transactions: $e');
      return [];
    }
  }

  /// Retrieves transactions for a specific date range.
  Future<List<model.Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final db = await database;

      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        where: 'date >= ? AND date <= ?',
        whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
        orderBy: 'date DESC',
      );

      return maps.map((map) => _transactionFromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting transactions by date range: $e');
      return [];
    }
  }

  /// Updates an existing transaction.
  Future<bool> updateTransaction(model.Transaction transaction) async {
    try {
      final db = await database;

      final now = DateTime.now().millisecondsSinceEpoch;
      final data = {
        'id': transaction.id,
        'amount': transaction.amount,
        'category': transaction.category,
        'date': transaction.date.millisecondsSinceEpoch,
        'note': transaction.note,
        'updated_at': now,
      };

      final rowsAffected = await db.update(
        'transactions',
        data,
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      print('✅ Updated transaction ${transaction.id}');
      return rowsAffected > 0;
    } catch (e) {
      print('❌ Error updating transaction: $e');
      return false;
    }
  }

  /// Deletes a transaction by ID.
  Future<bool> deleteTransaction(String id) async {
    try {
      final db = await database;

      final rowsAffected = await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );

      print('✅ Deleted transaction $id');
      return rowsAffected > 0;
    } catch (e) {
      print('❌ Error deleting transaction: $e');
      return false;
    }
  }

  /// Deletes all transactions.
  Future<bool> deleteAllTransactions() async {
    try {
      final db = await database;

      await db.delete('transactions');

      print('✅ Deleted all transactions');
      return true;
    } catch (e) {
      print('❌ Error deleting all transactions: $e');
      return false;
    }
  }

  /// Gets total expenses for a specific month.
  Future<double> getTotalForMonth(int year, int month) async {
    try {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1).subtract(const Duration(days: 1));

      final transactions = await getTransactionsByDateRange(start, end);

      // Sum only expenses (negative amounts)
      final total = transactions
          .where((t) => t.amount < 0)
          .fold<double>(0.0, (sum, t) => sum + t.amount);

      return total.abs();
    } catch (e) {
      print('❌ Error getting total for month: $e');
      return 0.0;
    }
  }

  /// Closes the database connection.
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  /// Converts a map from SQLite to a Transaction object.
  model.Transaction _transactionFromMap(Map<String, dynamic> map) {
    return model.Transaction(
      id: map['id'] as String,
      amount: map['amount'] as double,
      category: map['category'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      note: map['note'] as String?,
      householdId: '', // MVP: No households
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
