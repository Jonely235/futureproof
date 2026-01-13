import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/budget_repository.dart';

/// Budget repository implementation
/// Manages budget data using SharedPreferences
class BudgetRepositoryImpl implements BudgetRepository {
  // Cache
  BudgetEntity? _cachedBudget;

  // Stream controller
  final _budgetController = StreamController<BudgetEntity>.broadcast();

  // SharedPreferences keys
  static const String _monthlyIncomeKey = 'monthly_income';
  static const String _savingsGoalKey = 'savings_goal';

  @override
  Future<BudgetEntity> getCurrentBudget() async {
    if (_cachedBudget != null) return _cachedBudget!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final monthlyIncome = prefs.getDouble(_monthlyIncomeKey) ?? 5000.0;
      final savingsGoal = prefs.getDouble(_savingsGoalKey) ?? 1000.0;

      _cachedBudget = BudgetEntity.fromIncomeAndGoals(
        monthlyIncome: monthlyIncome,
        savingsGoal: savingsGoal,
      );

      return _cachedBudget!;
    } catch (e) {
      // Return default budget on error
      return BudgetEntity.fromIncomeAndGoals(
        monthlyIncome: 5000.0,
        savingsGoal: 1000.0,
      );
    }
  }

  @override
  Future<void> updateBudget({
    required double monthlyIncome,
    required double savingsGoal,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_monthlyIncomeKey, monthlyIncome);
      await prefs.setDouble(_savingsGoalKey, savingsGoal);

      _invalidateCache();
      final budget = await getCurrentBudget();
      _budgetController.add(budget);
    } catch (e) {
      throw Exception('Failed to update budget: $e');
    }
  }

  @override
  Future<BudgetStatus> getBudgetStatus({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // This requires transactions, which are managed by TransactionRepository
    // For now, return a default status
    // In the provider layer, we'll combine budget + transactions to calculate this
    return const BudgetStatus(
      spent: 0,
      remaining: 0,
      percentageUsed: 0,
      isOnTrack: true,
      isOverBudget: false,
    );
  }

  @override
  Stream<BudgetEntity> observeBudget() {
    getCurrentBudget();
    return _budgetController.stream;
  }

  void _invalidateCache() {
    _cachedBudget = null;
  }

  void dispose() {
    _budgetController.close();
  }
}
