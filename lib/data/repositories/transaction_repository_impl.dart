import 'dart:async';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../data/mappers/transaction_mapper.dart';
import '../../services/database_service.dart';
import '../../models/transaction.dart' as model;

/// Transaction repository implementation
/// Implements domain interface using concrete data sources
class TransactionRepositoryImpl implements TransactionRepository {
  final DatabaseService _databaseService;

  TransactionRepositoryImpl({
    DatabaseService? databaseService,
  }) : _databaseService = databaseService ?? DatabaseService();

  // Cache for reactive updates
  final _controller = StreamController<List<TransactionEntity>>.broadcast();
  List<TransactionEntity>? _cachedTransactions;

  @override
  Future<List<TransactionEntity>> getAllTransactions() async {
    try {
      final models = await _databaseService.getAllTransactions();
      _cachedTransactions = TransactionMapper.toEntityList(models);
      _controller.add(_cachedTransactions!);
      return _cachedTransactions!;
    } catch (e, st) {
      throw Exception('Failed to get transactions: $e');
    }
  }

  @override
  Future<TransactionEntity?> getTransactionById(String id) async {
    try {
      final transactions = await getAllTransactions();
      return transactions.firstWhere(
        (t) => t.id == id,
        orElse: () => throw Exception('Transaction not found'),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    try {
      final model = TransactionMapper.toDataModel(transaction);
      await _databaseService.addTransaction(model);
      _invalidateCache();
    } catch (e, st) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    try {
      final model = TransactionMapper.toDataModel(transaction);
      await _databaseService.updateTransaction(model);
      _invalidateCache();
    } catch (e, st) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await _databaseService.deleteTransaction(id);
      _invalidateCache();
    } catch (e, st) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  @override
  Future<List<TransactionEntity>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final transactions = await getAllTransactions();
      return transactions.where((t) {
        final date = t.date.value;
        return date.isAfter(start.subtract(const Duration(days: 1))) &&
            date.isBefore(end.add(const Duration(days: 1)));
      }).toList();
    } catch (e, st) {
      throw Exception('Failed to get transactions by date range: $e');
    }
  }

  @override
  Future<List<TransactionEntity>> getTransactionsByCategory(
    String category,
  ) async {
    try {
      final transactions = await getAllTransactions();
      return transactions
          .where((t) => t.category.toLowerCase() == category.toLowerCase())
          .toList();
    } catch (e, st) {
      throw Exception('Failed to get transactions by category: $e');
    }
  }

  @override
  Future<void> syncWithCloud() async {
    // TODO: Implement cloud sync in Phase 5
    // For now, this is a no-op
  }

  @override
  Stream<List<TransactionEntity>> observeTransactions() {
    // Load initial data
    getAllTransactions();
    return _controller.stream;
  }

  void _invalidateCache() {
    _cachedTransactions = null;
  }

  void dispose() {
    _controller.close();
  }
}
