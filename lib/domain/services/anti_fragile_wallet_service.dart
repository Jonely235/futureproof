import '../entities/virtual_vault_entity.dart';
import '../entities/war_mode_entity.dart';
import '../entities/transaction_entity.dart';
import '../value_objects/category_classification.dart';

/// Anti-Fragile Wallet Service
/// Core business logic for calculating anti-fragile wallet metrics
class AntiFragileWalletService {
  /// Calculate virtual vault (Available Now)
  ///
  /// Business Rule: Available Now = Total Cash - (Bills + Min Reserve + Savings)
  static VirtualVaultEntity calculateVirtualVault({
    required double totalCash,
    required double monthlyBills,
    required double minimumReserve,
    required double savingsGoal,
  }) {
    return VirtualVaultEntity.calculate(
      totalCash: totalCash,
      monthlyBills: monthlyBills,
      minimumReserve: minimumReserve,
      savingsGoal: savingsGoal,
    );
  }

  /// Calculate war mode status
  ///
  /// Business Rule: Runway = Current Cash / Daily Average Spend
  /// Danger Levels: Green (>30 days), Yellow (15-30), Red (<15)
  static WarModeEntity calculateWarMode({
    required double currentCash,
    required List<TransactionEntity> transactions,
  }) {
    // Calculate daily average from last 30 days of spending
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final recentExpenses = transactions.where((t) {
      return t.isExpense && t.date.value.isAfter(thirtyDaysAgo);
    }).toList();

    final dailyAverageSpend = recentExpenses.isEmpty
        ? 0.0
        : recentExpenses
            .map((t) => t.absoluteAmount)
            .reduce((a, b) => a + b) / 30;

    return WarModeEntity.calculate(
      currentCash: currentCash,
      dailyAverageSpend: dailyAverageSpend,
    );
  }

  /// Classify a category as Need or Want
  static CategoryClassification classifyCategory(String category) {
    return CategoryClassification.fromCategory(category);
  }

  /// Filter transactions by classification type
  static List<TransactionEntity> filterByClassification({
    required List<TransactionEntity> transactions,
    required CategoryType type,
  }) {
    return transactions.where((t) {
      final classification = classifyCategory(t.category);
      return type == CategoryType.neutral
          ? classification.type == CategoryType.neutral
          : classification.type == type;
    }).toList();
  }

  /// Calculate total spending by classification type
  static double calculateSpendingByType({
    required List<TransactionEntity> transactions,
    required CategoryType type,
  }) {
    final filtered = filterByClassification(
      transactions: transactions,
      type: type,
    );

    return filtered
        .map((t) => t.absoluteAmount)
        .fold(0.0, (sum, amount) => sum + amount);
  }

  /// Get spending breakdown by classification
  static Map<CategoryType, double> getSpendingBreakdown({
    required List<TransactionEntity> transactions,
  }) {
    return {
      CategoryType.need: calculateSpendingByType(
        transactions: transactions,
        type: CategoryType.need,
      ),
      CategoryType.want: calculateSpendingByType(
        transactions: transactions,
        type: CategoryType.want,
      ),
    };
  }

  /// Get categories by classification type
  static List<String> getCategoriesByType(CategoryType type) {
    switch (type) {
      case CategoryType.need:
        return const ['housing', 'groceries', 'health', 'transport'];
      case CategoryType.want:
        return const ['dining', 'entertainment', 'shopping', 'subscriptions'];
      case CategoryType.neutral:
        return ['income'];
    }
  }

  /// Check if a category should be restricted in current war mode
  static bool shouldRestrictCategory({
    required String category,
    required WarModeEntity warMode,
  }) {
    final classification = classifyCategory(category);
    return warMode.shouldRestrictWants && classification.shouldBeRestricted;
  }
}
