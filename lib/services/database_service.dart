import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart' as model;

/// Database service for managing transaction persistence.
///
/// Implements singleton pattern to ensure single database connection.
/// Provides CRUD operations for [Transaction] model.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database and create tables if they don't exist
  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'futureproof.db');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  /// Create the transactions table
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        householdId TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  /// Adds a new transaction to the database.
  ///
  /// Returns the row ID of the inserted transaction.
  /// Throws [ArgumentError] if transaction ID is invalid.
  Future<int> addTransaction(model.Transaction transaction) async {
    try {
      final db = await database;

      // Validate transaction has required fields
      if (transaction.id.isEmpty) {
        throw ArgumentError('Transaction ID cannot be empty');
      }

      return await db.insert(
        'transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error adding transaction: $e');
      rethrow;
    }
  }

  /// Retrieves all transactions from the database.
  ///
  /// Returns transactions sorted by date in descending order (newest first).
  /// Returns empty list if database is empty or on error.
  Future<List<model.Transaction>> getAllTransactions() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        orderBy: 'date DESC',
      );

      if (maps.isEmpty) {
        return [];
      }

      return List.generate(maps.length, (i) {
        return model.Transaction.fromSqliteMap(maps[i]);
      });
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  /// Retrieves a specific transaction by ID.
  ///
  /// Returns null if not found.
  Future<model.Transaction?> getTransactionById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return model.Transaction.fromSqliteMap(maps.first);
    } catch (e) {
      print('Error getting transaction by ID: $e');
      return null;
    }
  }

  /// Updates an existing transaction in the database.
  ///
  /// Returns the number of rows affected (should be 1).
  /// Returns 0 if transaction not found.
  Future<int> updateTransaction(model.Transaction transaction) async {
    try {
      if (transaction.id.isEmpty) {
        throw ArgumentError('Transaction ID is required for update');
      }

      final db = await database;
      final rowsAffected = await db.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      if (rowsAffected == 0) {
        print('Warning: No transaction found with ID ${transaction.id}');
      }

      return rowsAffected;
    } catch (e) {
      print('Error updating transaction: $e');
      return 0;
    }
  }

  /// Deletes a transaction from the database by ID.
  ///
  /// Returns the number of rows deleted.
  Future<int> deleteTransaction(String id) async {
    try {
      final db = await database;
      return await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting transaction: $e');
      return 0;
    }
  }

  /// Deletes all transactions from the database.
  ///
  /// Returns the number of rows deleted.
  Future<int> deleteAllTransactions() async {
    try {
      final db = await database;
      return await db.delete('transactions');
    } catch (e) {
      print('Error deleting all transactions: $e');
      return 0;
    }
  }
}
