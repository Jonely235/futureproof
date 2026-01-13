import '../entities/budget_entity.dart';

/// Budget repository interface - manages budget data access
abstract class BudgetRepository {
  /// Get current budget
  Future<BudgetEntity> getCurrentBudget();

  /// Update budget goals
  Future<void> updateBudget({
    required double monthlyIncome,
    required double savingsGoal,
  });

  /// Get budget status for a specific period
  Future<BudgetStatus> getBudgetStatus({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Observe budget changes
  Stream<BudgetEntity> observeBudget();
}

/// Budget status - represents current budget health
class BudgetStatus {
  final double spent;
  final double remaining;
  final double percentageUsed;
  final bool isOnTrack;
  final bool isOverBudget;

  const BudgetStatus({
    required this.spent,
    required this.remaining,
    required this.percentageUsed,
    required this.isOnTrack,
    required this.isOverBudget,
  });

  /// Business rule: Get status message
  String get statusMessage {
    if (isOverBudget) return 'Over budget';
    if (percentageUsed >= 90) return 'Near limit';
    if (percentageUsed >= 50) return 'On track';
    return 'Great start';
  }
}
