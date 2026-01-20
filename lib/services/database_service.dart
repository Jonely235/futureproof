import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../models/app_error.dart';
import '../models/transaction.dart' as model;
import '../utils/app_logger.dart';
import '../utils/error_tracker.dart';

/// Database service for multi-vault finance app
///
/// Each vault has its own isolated SQLite database.
/// Use getDatabaseForVault(vaultId) to get a specific vault's database.
/// For backward compatibility, the default database property returns
/// the active vault's database (or a default database if no vault is active).
class DatabaseService {
  static final _instance = DatabaseService._internal();
  static final _databases = <String, Database>{};
  static final _log = Logger('DatabaseService');

  // Default database for backward compatibility (used when no vault is active)
  static Database? _defaultDatabase;

  // Web transactions storage (per-vault)
  final Map<String, List<model.Transaction>> _webTransactions = {};

  // Active vault ID
  String? _activeVaultId;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  bool get _isWeb => kIsWeb;

  /// Set the active vault ID
  void setActiveVault(String? vaultId) {
    _activeVaultId = vaultId;
    AppLogger.database.info('🔑 Active vault set to: $vaultId');
  }

  /// Get active vault ID
  String? get activeVaultId => _activeVaultId;

  /// Get database for a specific vault
  Future<Database> getDatabaseForVault(String vaultId) async {
    if (_isWeb) {
      throw const AppError(
        type: AppErrorType.database,
        message: 'Database not available on web platform',
        technicalDetails: 'Web platform uses in-memory storage only',
      );
    }

    // Return cached database if available
    if (_databases.containsKey(vaultId)) {
      return _databases[vaultId]!;
    }

    try {
      final db = await _initDatabaseForVault(vaultId);
      _databases[vaultId] = db;
      return db;
    } catch (e, st) {
      _log.severe('Error initializing database for vault: $vaultId', e);
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not initialize database for vault',
        technicalDetails: 'Vault ID: $vaultId',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  /// Get the active vault's database (or default database for backward compatibility)
  Future<Database> get database async {
    if (_isWeb) {
      throw const AppError(
        type: AppErrorType.database,
        message: 'Database not available on web platform',
        technicalDetails: 'Web platform uses in-memory storage only',
      );
    }

    // If active vault is set, use its database
    if (_activeVaultId != null && _databases.containsKey(_activeVaultId)) {
      return _databases[_activeVaultId]!;
    }

    // Otherwise, use default database (backward compatibility)
    if (_defaultDatabase != null) return _defaultDatabase!;

    try {
      _defaultDatabase = await _initDefaultDatabase();
      return _defaultDatabase!;
    } catch (e, st) {
      _log.severe('Error initializing default database', e);
      throw AppError(
        type: AppErrorType.database,
        message: 'Could not initialize database',
        technicalDetails: 'Database initialization failed',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  /// Initialize database for a specific vault
  Future<Database> _initDatabaseForVault(String vaultId) async {
    if (_isWeb) {
      _log.info('Using in-memory storage for web (UI testing only)');
      throw const AppError(
        type: AppErrorType.database,
        message: 'Database not available on web platform',
        technicalDetails: 'Web platform uses in-memory storage only',
      );
    }

    // Get vault directory from app documents
    final appDocDir = await getApplicationDocumentsDirectory();
    final vaultsDir = Directory('${appDocDir.path}/vaults/$vaultId');

    // Create vault directory if it doesn't exist
    if (!await vaultsDir.exists()) {
      await vaultsDir.create(recursive: true);
    }

    final dbPath = join(vaultsDir.path, 'transactions.db');

    AppLogger.database.info('📁 Vault database path: $dbPath');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Initialize default database (backward compatibility)
  Future<Database> _initDefaultDatabase() async {
    if (_isWeb) {
      _log.info('Using in-memory storage for web (UI testing only)');
      throw const AppError(
        type: AppErrorType.database,
        message: 'Database not available on web platform',
        technicalDetails: 'Web platform uses in-memory storage only',
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'futureproof.db');

    AppLogger.database.info('📁 Default database path: $path');

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

  /// Get web transactions for a vault
  List<model.Transaction> _getWebTransactions(String vaultId) {
    if (!_webTransactions.containsKey(vaultId)) {
      _webTransactions[vaultId] = [];
    }
    return _webTransactions[vaultId]!;
  }

  Future<String> addTransaction(model.Transaction transaction, {String? vaultId}) async {
    try {
      final effectiveVaultId = vaultId ?? _activeVaultId;

      if (_isWeb) {
        // Web: use in-memory storage for the vault
        final storage = effectiveVaultId ?? 'default';
        _getWebTransactions(storage).add(transaction);
        return transaction.id;
      }

      // Get the appropriate database
      final db = effectiveVaultId != null
          ? await getDatabaseForVault(effectiveVaultId)
          : await database;

      if (transaction.id.isEmpty) {
        throw const AppError(
          type: AppErrorType.validation,
          message: 'Transaction ID cannot be empty',
          technicalDetails: 'Transaction ID validation failed',
        );
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

      await db.insert('transactions', data,
          conflictAlgorithm: ConflictAlgorithm.replace);

      final vaultMsg = effectiveVaultId != null ? ' [vault: $effectiveVaultId]' : '';
      AppLogger.database
          .info('✅ Added transaction ${transaction.id} to SQLite$vaultMsg');
      return transaction.id;
    } catch (e, st) {
      AppLogger.database.severe('❌ Error adding transaction', e);
      if (e is AppError) {
        ErrorTracker()
            .trackError(e, 'DatabaseService.addTransaction', stackTrace: st);
        rethrow;
      }
      final appError = AppError(
        type: AppErrorType.database,
        message: 'Could not save transaction to database',
        technicalDetails: 'Transaction ID: ${transaction.id}',
        originalError: e,
        stackTrace: st,
      );
      ErrorTracker().trackError(appError, 'DatabaseService.addTransaction',
          stackTrace: st);
      throw appError;
    }
  }

  Future<List<model.Transaction>> getAllTransactions({String? vaultId}) async {
    try {
      final effectiveVaultId = vaultId ?? _activeVaultId;

      if (_isWeb) {
        // Web: use in-memory storage for the vault
        final storage = effectiveVaultId ?? 'default';
        final transactions = List<model.Transaction>.from(_getWebTransactions(storage));
        transactions.sort((a, b) => b.date.compareTo(a.date));
        return transactions;
      }

      // Get the appropriate database
      final db = effectiveVaultId != null
          ? await getDatabaseForVault(effectiveVaultId)
          : await database;

      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        orderBy: 'date DESC',
      );

      final vaultMsg = effectiveVaultId != null ? ' [vault: $effectiveVaultId]' : '';
      AppLogger.database
          .info('📊 Retrieved ${maps.length} transactions from SQLite$vaultMsg');

      if (maps.isEmpty) return [];

      return maps.map((map) => _transactionFromMap(map)).toList();
    } catch (e, st) {
      AppLogger.database.severe('❌ Error getting transactions', e);
      if (e is AppError) {
        ErrorTracker().trackError(e, 'DatabaseService.getAllTransactions',
            stackTrace: st);
        rethrow;
      }
      final appError = AppError(
        type: AppErrorType.database,
        message: 'Could not retrieve transactions from database',
        technicalDetails: 'Query failed: getAllTransactions',
        originalError: e,
        stackTrace: st,
      );
      ErrorTracker().trackError(appError, 'DatabaseService.getAllTransactions',
          stackTrace: st);
      throw appError;
    }
  }

  Future<List<model.Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end, {
    String? vaultId,
  }) async {
    try {
      final effectiveVaultId = vaultId ?? _activeVaultId;

      if (_isWeb) {
        final storage = effectiveVaultId ?? 'default';
        return _getWebTransactions(storage)
            .where((t) =>
                t.date.isAfter(start.subtract(const Duration(days: 1))) &&
                t.date.isBefore(end.add(const Duration(days: 1))))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      }

      final db = effectiveVaultId != null
          ? await getDatabaseForVault(effectiveVaultId)
          : await database;

      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        where: 'date >= ? AND date <= ?',
        whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
        orderBy: 'date DESC',
      );

      return maps.map((map) => _transactionFromMap(map)).toList();
    } catch (e, st) {
      AppLogger.database
          .severe('❌ Error getting transactions by date range', e);
      if (e is AppError) {
        ErrorTracker().trackError(
            e, 'DatabaseService.getTransactionsByDateRange',
            stackTrace: st);
        rethrow;
      }
      final appError = AppError(
        type: AppErrorType.database,
        message: 'Could not retrieve transactions for date range',
        technicalDetails: 'Range: $start to $end',
        originalError: e,
        stackTrace: st,
      );
      ErrorTracker().trackError(
          appError, 'DatabaseService.getTransactionsByDateRange',
          stackTrace: st);
      throw appError;
    }
  }

  Future<bool> updateTransaction(model.Transaction transaction, {String? vaultId}) async {
    try {
      final effectiveVaultId = vaultId ?? _activeVaultId;

      if (_isWeb) {
        final storage = effectiveVaultId ?? 'default';
        final index = _getWebTransactions(storage).indexWhere((t) => t.id == transaction.id);
        if (index >= 0) {
          _getWebTransactions(storage)[index] = transaction;
          AppLogger.database
              .info('✅ Updated transaction ${transaction.id} in web memory');
          return true;
        }
        return false;
      }

      final db = effectiveVaultId != null
          ? await getDatabaseForVault(effectiveVaultId)
          : await database;

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
      if (e is AppError) {
        ErrorTracker()
            .trackError(e, 'DatabaseService.updateTransaction', stackTrace: st);
        rethrow;
      }
      final appError = AppError(
        type: AppErrorType.database,
        message: 'Could not update transaction in database',
        technicalDetails: 'Transaction ID: ${transaction.id}',
        originalError: e,
        stackTrace: st,
      );
      ErrorTracker().trackError(appError, 'DatabaseService.updateTransaction',
          stackTrace: st);
      throw appError;
    }
  }

  Future<bool> deleteTransaction(String id, {String? vaultId}) async {
    try {
      final effectiveVaultId = vaultId ?? _activeVaultId;

      if (_isWeb) {
        final storage = effectiveVaultId ?? 'default';
        _getWebTransactions(storage).removeWhere((t) => t.id == id);
        AppLogger.database.info('✅ Deleted transaction $id from web memory');
        return true;
      }

      final db = effectiveVaultId != null
          ? await getDatabaseForVault(effectiveVaultId)
          : await database;

      final rowsAffected = await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );

      AppLogger.database.info('✅ Deleted transaction $id');
      return rowsAffected > 0;
    } catch (e, st) {
      AppLogger.database.severe('❌ Error deleting transaction', e);
      if (e is AppError) {
        ErrorTracker()
            .trackError(e, 'DatabaseService.deleteTransaction', stackTrace: st);
        rethrow;
      }
      final appError = AppError(
        type: AppErrorType.database,
        message: 'Could not delete transaction from database',
        technicalDetails: 'Transaction ID: $id',
        originalError: e,
        stackTrace: st,
      );
      ErrorTracker().trackError(appError, 'DatabaseService.deleteTransaction',
          stackTrace: st);
      throw appError;
    }
  }

  Future<bool> deleteAllTransactions({String? vaultId}) async {
    try {
      final effectiveVaultId = vaultId ?? _activeVaultId;

      if (_isWeb) {
        final storage = effectiveVaultId ?? 'default';
        _getWebTransactions(storage).clear();
        AppLogger.database.info('✅ Deleted all transactions from web memory');
        return true;
      }

      final db = effectiveVaultId != null
          ? await getDatabaseForVault(effectiveVaultId)
          : await database;

      await db.delete('transactions');
      AppLogger.database.info('✅ Deleted all transactions');
      return true;
    } catch (e, st) {
      AppLogger.database.severe('❌ Error deleting all transactions', e);
      if (e is AppError) {
        ErrorTracker().trackError(e, 'DatabaseService.deleteAllTransactions',
            stackTrace: st);
        rethrow;
      }
      final appError = AppError(
        type: AppErrorType.database,
        message: 'Could not delete all transactions from database',
        originalError: e,
        stackTrace: st,
      );
      ErrorTracker().trackError(
          appError, 'DatabaseService.deleteAllTransactions',
          stackTrace: st);
      throw appError;
    }
  }

  Future<double> getTotalForMonth(int year, int month, {String? vaultId}) async {
    try {
      final start = DateTime(year, month, 1);
      final end =
          DateTime(year, month + 1, 1).subtract(const Duration(days: 1));

      final transactions = await getTransactionsByDateRange(start, end, vaultId: vaultId);

      final total = transactions
          .where((t) => t.amount < 0)
          .fold<double>(0.0, (sum, t) => sum + t.amount);

      return total.abs();
    } catch (e, st) {
      AppLogger.database.severe('❌ Error getting total for month', e);
      if (e is AppError) {
        ErrorTracker()
            .trackError(e, 'DatabaseService.getTotalForMonth', stackTrace: st);
        rethrow;
      }
      final appError = AppError(
        type: AppErrorType.database,
        message: 'Could not calculate total for month',
        technicalDetails: 'Month: $year-$month',
        originalError: e,
        stackTrace: st,
      );
      ErrorTracker().trackError(appError, 'DatabaseService.getTotalForMonth',
          stackTrace: st);
      throw appError;
    }
  }

  Future<void> close({String? vaultId}) async {
    if (_isWeb) return;

    if (vaultId != null) {
      // Close specific vault database
      final db = _databases[vaultId];
      if (db != null) {
        await db.close();
        _databases.remove(vaultId);
        AppLogger.database.info('🔒 Closed vault database: $vaultId');
      }
    } else {
      // Close all databases
      for (final db in _databases.values) {
        await db.close();
      }
      _databases.clear();

      if (_defaultDatabase != null) {
        await _defaultDatabase!.close();
        _defaultDatabase = null;
      }
      AppLogger.database.info('🔒 Closed all databases');
    }
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
