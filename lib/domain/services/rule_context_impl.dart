import 'behavioral_rule.dart';
import '../entities/user_profile_entity.dart';
import '../entities/transaction_entity.dart';
import '../entities/budget_entity.dart';
import '../entities/streak_entity.dart';
import '../entities/war_mode_entity.dart';
import '../repositories/transaction_repository.dart';
import '../value_objects/life_stage.dart';

/// Implementation of RuleContext
/// Provides cached data access and helper methods for rule evaluation
class RuleContextImpl implements RuleContext {
  @override
  final UserProfileEntity profile;

  @override
  final DateTime now;

  @override
  final List<TransactionEntity> transactions;

  @override
  final BudgetEntity? budget;

  @override
  final StreakEntity? streak;

  @override
  final WarModeEntity? warMode;

  // Cached computations
  Map<String, List<TransactionEntity>>? _categoryCache;
  Map<String, double>? _spendingByCategoryCache;

  RuleContextImpl({
    required this.profile,
    required this.now,
    required this.transactions,
    this.budget,
    this.streak,
    this.warMode,
  });

  /// Create from repository (loads transactions)
  static Future<RuleContextImpl> create({
    required UserProfileEntity profile,
    required TransactionRepository transactionRepository,
    BudgetEntity? budget,
    StreakEntity? streak,
    WarModeEntity? warMode,
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();
    final transactions = await transactionRepository.getAllTransactions();

    return RuleContextImpl(
      profile: profile,
      now: currentTime,
      transactions: transactions,
      budget: budget,
      streak: streak,
      warMode: warMode,
    );
  }

  @override
  List<TransactionEntity> getTransactionsByCategory(String category) {
    _ensureCategoryCache();
    return _categoryCache![category] ?? [];
  }

  @override
  List<TransactionEntity> getTransactionsInDateRange(
    DateTime start,
    DateTime end,
  ) {
    return transactions.where((t) {
      final txDate = DateTime(t.date.value.year, t.date.value.month, t.date.value.day);
      final startDate = DateTime(start.year, start.month, start.day);
      final endDate = DateTime(end.year, end.month, end.day);
      return !txDate.isBefore(startDate) && !txDate.isAfter(endDate);
    }).toList();
  }

  @override
  double getTotalSpentInPeriod(DateTime start, DateTime end) {
    final periodTransactions = getTransactionsInDateRange(start, end);
    return periodTransactions
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount.value);
  }

  @override
  double getTotalIncomeInPeriod(DateTime start, DateTime end) {
    final periodTransactions = getTransactionsInDateRange(start, end);
    return periodTransactions
        .where((t) => t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount.value);
  }

  @override
  double getAverageDailySpend({int days = 30}) {
    final cutoff = now.subtract(Duration(days: days));
    final total = getTotalSpentInPeriod(cutoff, now);
    return total / days;
  }

  @override
  double getAverageWeeklySpend({int weeks = 4}) {
    return getAverageDailySpend(days: weeks * 7) * 7;
  }

  @override
  bool isCategoryTrendingUp(String category, {double threshold = 1.2}) {
    // Compare last 7 days to previous 7 days
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));

    final recent = getTotalSpentByCategoryInPeriod(
      category,
      fourteenDaysAgo,
      sevenDaysAgo,
    );
    final current = getTotalSpentByCategoryInPeriod(
      category,
      sevenDaysAgo,
      now,
    );

    if (recent == 0) return current > 0;
    return (current / recent) > threshold;
  }

  @override
  bool isCategoryTrendingDown(String category, {double threshold = 0.8}) {
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));

    final recent = getTotalSpentByCategoryInPeriod(
      category,
      fourteenDaysAgo,
      sevenDaysAgo,
    );
    final current = getTotalSpentByCategoryInPeriod(
      category,
      sevenDaysAgo,
      now,
    );

    if (recent == 0) return false;
    return (current / recent) < threshold;
  }

  @override
  String? getTopCategory(DateTime start, DateTime end) {
    final spending = getSpendingByCategory(start, end);
    if (spending.isEmpty) return null;

    final topEntry = spending.entries.reduce((a, b) => a.value > b.value ? a : b);
    return topEntry.key;
  }

  @override
  Map<String, double> getSpendingByCategory(DateTime start, DateTime end) {
    final periodTransactions = getTransactionsInDateRange(start, end);
    final spending = <String, double>{};

    for (final tx in periodTransactions) {
      if (tx.isExpense) {
        spending[tx.category] = (spending[tx.category] ?? 0) + tx.amount.value.abs();
      }
    }

    return spending;
  }

  @override
  int? getDaysUntilNextBill() {
    // This would require recurring bill data
    // For now, return null to indicate no data
    return null;
  }

  @override
  double getUpcomingBillsTotal({int days = 7}) {
    // This would require recurring bill data
    // For now, return 0
    return 0;
  }

  // Private helper methods

  void _ensureCategoryCache() {
    _categoryCache ??= {};
    if (_categoryCache!.isEmpty) {
      for (final tx in transactions) {
        _categoryCache!.putIfAbsent(tx.category, () => []).add(tx);
      }
    }
  }

  double getTotalSpentByCategoryInPeriod(
    String category,
    DateTime start,
    DateTime end,
  ) {
    final periodTransactions = getTransactionsInDateRange(start, end);
    return periodTransactions
        .where((t) => t.category == category && t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount.value.abs());
  }

  /// Clear caches to free memory
  void dispose() {
    _categoryCache = null;
    _spendingByCategoryCache = null;
  }
}
