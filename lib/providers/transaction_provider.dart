import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/analytics_service.dart';

/// Centralized state management for transactions.
///
/// Provides CRUD operations and loading states for the transaction list.
/// Uses ChangeNotifier to notify listeners when state changes.
///
/// Usage:
/// ```dart
/// // In main.dart
/// ChangeNotifierProvider(create: (_) => TransactionProvider())
///
/// // In widgets
/// final provider = context.watch<TransactionProvider>();
/// final provider = context.read<TransactionProvider>();
/// ```
class TransactionProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final AnalyticsService _analyticsService = AnalyticsService();

  // Private state
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // Public getters
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Check if there are any transactions
  bool get hasTransactions => _transactions.isNotEmpty;

  /// Get transactions by category
  Map<String, List<Transaction>> get transactionsByCategory {
    final Map<String, List<Transaction>> grouped = {};
    for (final transaction in _transactions) {
      grouped.putIfAbsent(transaction.category, () => []).add(transaction);
    }
    return grouped;
  }

  /// Get total expenses (sum of negative amounts)
  double get totalExpenses {
    return _transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount.abs());
  }

  /// Get total income (sum of positive amounts)
  double get totalIncome {
    return _transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Get transactions for a specific category
  List<Transaction> getTransactionsByCategory(String category) {
    return _transactions
        .where((t) => t.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Get recent transactions (last N)
  List<Transaction> getRecentTransactions(int count) {
    final sorted = List<Transaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(count).toList();
  }

  /// Load all transactions from database
  ///
  /// Sets loading state and updates the transaction list.
  /// Emits error if loading fails.
  Future<void> loadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _db.getAllTransactions();
    } catch (e) {
      _error = 'Failed to load transactions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new transaction
  ///
  /// Returns true if successful, false otherwise.
  /// Updates the transaction list after adding.
  Future<bool> addTransaction(Transaction transaction) async {
    try {
      await _db.addTransaction(transaction);
      // Clear analytics cache
      _analyticsService.refresh();
      await loadTransactions();
      return true;
    } catch (e) {
      _error = 'Failed to add transaction: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update an existing transaction
  ///
  /// Returns true if successful, false otherwise.
  /// Updates the transaction list after updating.
  Future<bool> updateTransaction(Transaction transaction) async {
    try {
      final success = await _db.updateTransaction(transaction);
      if (success) {
        // Clear analytics cache
        _analyticsService.refresh();
        await loadTransactions();
      }
      return success;
    } catch (e) {
      _error = 'Failed to update: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete a transaction by ID
  ///
  /// Returns true if successful, false otherwise.
  /// Updates the transaction list after deleting.
  Future<bool> deleteTransaction(String id) async {
    try {
      final success = await _db.deleteTransaction(id);
      if (success) {
        // Clear analytics cache
        _analyticsService.refresh();
        await loadTransactions();
      }
      return success;
    } catch (e) {
      _error = 'Failed to delete: $e';
      notifyListeners();
      return false;
    }
  }

  /// Get transaction by ID
  Transaction? getTransactionById(String id) {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear any error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh transactions from database
  ///
  /// Alias for loadTransactions() for semantic clarity.
  Future<void> refresh() async {
    await loadTransactions();
  }
}
