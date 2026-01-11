import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';
import '../models/transaction.dart' as model;
import '../models/app_error.dart';
import '../utils/app_logger.dart';

class DatabaseService {
  static final _instance = DatabaseService._internal();
  static Database? _database;
  static final _log = Logger('DatabaseService');

  final List<model.Transaction> _webTransactions = [];

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  bool get _isWeb => kIsWeb;

  Future<Database> get database async {
    if (_isWeb) {
      throw AppError(
        type: AppErrorType.database,
        message: 'Database not available on web platform',
        technicalDetails: 'Web platform uses in-memory storage only',
      );
    }
    if (_database != null) return _database!;
    try {
      _database = await _initDatabase();
      return _database!;
    } catch (e, st) {
      _log.severe('Error initializing database', e);
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not initialize database',
        technicalDetails: 'Database initialization failed',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<Database> _initDatabase() async {
    if (_isWeb) {
      _log.info('Using in-memory storage for web (UI testing only)');
      throw AppError(
        type: AppErrorType.database,
        message: 'Database not available on web platform',
        technicalDetails: 'Web platform uses in-memory storage only',
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'futureproof.db');

    AppLogger.database.info('📁 Database path: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
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

  Future<String> addTransaction(model.Transaction transaction) async {
    try {
      if (_isWeb) {
        _webTransactions.add(transaction);
        AppLogger.database.info('✅ Added transaction ${transaction.id} to web memory');
        return transaction.id;
      }

      if (transaction.id.isEmpty) {
        throw AppError(
          type: AppErrorType.validation,
          message: 'Transaction ID cannot be empty',
          technicalDetails: 'Transaction ID validation failed',
        );
      }

      final db = await database;
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
      AppLogger.database.info('✅ Added transaction ${transaction.id} to SQLite');
      return transaction.id;
    } catch (e, st) {
      AppLogger.database.severe('❌ Error adding transaction', e);
      if (e is AppError) rethrow;
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not save transaction to database',
        technicalDetails: 'Transaction ID: ${transaction.id}',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<List<model.Transaction>> getAllTransactions() async {
    try {
      if (_isWeb) {
        final transactions = List<model.Transaction>.from(_webTransactions);
        transactions.sort((a, b) => b.date.compareTo(a.date));
        AppLogger.database.info('📊 Retrieved ${transactions.length} transactions from web memory');
        return transactions;
      }

      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        orderBy: 'date DESC',
      );

      AppLogger.database.info('📊 Retrieved ${maps.length} transactions from SQLite');

      if (maps.isEmpty) return [];

      return maps.map((map) => _transactionFromMap(map)).toList();
    } catch (e, st) {
      AppLogger.database.severe('❌ Error getting transactions', e);
      if (e is AppError) rethrow;
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not retrieve transactions from database',
        technicalDetails: 'Query failed: getAllTransactions',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<List<model.Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      if (_isWeb) {
        return _webTransactions
            .where((t) => t.date.isAfter(start.subtract(const Duration(days: 1))) &&
                          t.date.isBefore(end.add(const Duration(days: 1))))
            .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
      }

      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        where: 'date >= ? AND date <= ?',
        whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
        orderBy: 'date DESC',
      );

      return maps.map((map) => _transactionFromMap(map)).toList();
    } catch (e, st) {
      AppLogger.database.severe('❌ Error getting transactions by date range', e);
      if (e is AppError) rethrow;
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not retrieve transactions for date range',
        technicalDetails: 'Range: $start to $end',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<bool> updateTransaction(model.Transaction transaction) async {
    try {
      if (_isWeb) {
        final index = _webTransactions.indexWhere((t) => t.id == transaction.id);
        if (index >= 0) {
          _webTransactions[index] = transaction;
          AppLogger.database.info('✅ Updated transaction ${transaction.id} in web memory');
          return true;
        }
        return false;
      }

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

      AppLogger.database.info('✅ Updated transaction ${transaction.id}');
      return rowsAffected > 0;
    } catch (e, st) {
      AppLogger.database.severe('❌ Error updating transaction', e);
      if (e is AppError) rethrow;
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not update transaction in database',
        technicalDetails: 'Transaction ID: ${transaction.id}',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<bool> deleteTransaction(String id) async {
    try {
      if (_isWeb) {
        _webTransactions.removeWhere((t) => t.id == id);
        AppLogger.database.info('✅ Deleted transaction $id from web memory');
        return true;
      }

      final db = await database;
      final rowsAffected = await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );

      AppLogger.database.info('✅ Deleted transaction $id');
      return rowsAffected > 0;
    } catch (e, st) {
      AppLogger.database.severe('❌ Error deleting transaction', e);
      if (e is AppError) rethrow;
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not delete transaction from database',
        technicalDetails: 'Transaction ID: $id',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<bool> deleteAllTransactions() async {
    try {
      if (_isWeb) {
        _webTransactions.clear();
        AppLogger.database.info('✅ Deleted all transactions from web memory');
        return true;
      }

      final db = await database;
      await db.delete('transactions');
      AppLogger.database.info('✅ Deleted all transactions');
      return true;
    } catch (e, st) {
      AppLogger.database.severe('❌ Error deleting all transactions', e);
      if (e is AppError) rethrow;
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not delete all transactions from database',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<double> getTotalForMonth(int year, int month) async {
    try {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1).subtract(const Duration(days: 1));

      final transactions = await getTransactionsByDateRange(start, end);

      final total = transactions
          .where((t) => t.amount < 0)
          .fold<double>(0.0, (sum, t) => sum + t.amount);

      return total.abs();
    } catch (e, st) {
      AppLogger.database.severe('❌ Error getting total for month', e);
      if (e is AppError) rethrow;
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not calculate total for month',
        technicalDetails: 'Month: $year-$month',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<void> close() async {
    if (_isWeb) return;
    final db = await database;
    await db.close();
  }

  model.Transaction _transactionFromMap(Map<String, dynamic> map) {
    return model.Transaction(
      id: map['id'] as String,
      amount: map['amount'] as double,
      category: map['category'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      note: map['note'] as String?,
      householdId: '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
