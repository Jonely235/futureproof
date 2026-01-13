import '../entities/transaction_entity.dart';

/// Transaction repository interface - defines data access contract
/// Domain layer defines "what", data layer implements "how"
abstract class TransactionRepository {
  /// Get all transactions
  Future<List<TransactionEntity>> getAllTransactions();

  /// Get transaction by ID
  Future<TransactionEntity?> getTransactionById(String id);

  /// Add new transaction
  Future<void> addTransaction(TransactionEntity transaction);

  /// Update existing transaction
  Future<void> updateTransaction(TransactionEntity transaction);

  /// Delete transaction
  Future<void> deleteTransaction(String id);

  /// Get transactions within date range
  Future<List<TransactionEntity>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  );

  /// Get transactions by category
  Future<List<TransactionEntity>> getTransactionsByCategory(
    String category,
  );

  /// Sync with cloud (if applicable)
  Future<void> syncWithCloud();

  /// Observe transaction changes (stream for reactive updates)
  Stream<List<TransactionEntity>> observeTransactions();
}
