import 'package:flutter/foundation.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../../domain/services/insight_generation_service.dart';
import '../../domain/services/budget_comparison_service.dart';

/// Insight provider - generates and manages financial insights
/// Replaces hardcoded SmartInsightsWidget with dynamic, data-driven insights
class InsightProvider extends ChangeNotifier {
  final TransactionRepository _transactionRepository;
  final BudgetRepository _budgetRepository;
  final GamificationRepository _gamificationRepository;
  final InsightGenerationService _insightService;
  final BudgetComparisonService _budgetComparisonService;

  // State
  List<Insight> _insights = [];
  bool _isLoading = false;
  String? _error;

  InsightProvider({
    required TransactionRepository transactionRepository,
    required BudgetRepository budgetRepository,
    required GamificationRepository gamificationRepository,
    InsightGenerationService? insightService,
    BudgetComparisonService? budgetComparisonService,
  })  : _transactionRepository = transactionRepository,
        _budgetRepository = budgetRepository,
        _gamificationRepository = gamificationRepository,
        _insightService = insightService ?? InsightGenerationService(),
        _budgetComparisonService = budgetComparisonService ?? BudgetComparisonService();

  // Getters
  List<Insight> get insights => _insights;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Insight> get alertInsights =>
      _insights.where((i) => i.priority == InsightPriority.high).toList();
  List<Insight> get warningInsights =>
      _insights.where((i) => i.priority == InsightPriority.medium).toList();
  List<Insight> get infoInsights =>
      _insights.where((i) => i.priority == InsightPriority.low).toList();

  /// Generate insights from current financial data
  Future<void> generateInsights() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch required data
      final transactions = await _transactionRepository.getAllTransactions();
      final budget = await _budgetRepository.getCurrentBudget();
      final streak = await _gamificationRepository.getCurrentStreak();

      // Calculate month-over-month data
      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final previousMonthStart = DateTime(
        now.month == 1 ? now.year - 1 : now.year,
        now.month == 1 ? 12 : now.month - 1,
        1,
      );

      final currentMonthTransactions =
          await _transactionRepository.getTransactionsByDateRange(
        currentMonthStart,
        now,
      );

      final previousMonthTransactions =
          await _transactionRepository.getTransactionsByDateRange(
        previousMonthStart,
        currentMonthStart.subtract(const Duration(days: 1)),
      );

      final momComparison = _budgetComparisonService.compareMonths(
        currentMonthTransactions: currentMonthTransactions,
        previousMonthTransactions: previousMonthTransactions,
      );

      final momData = MonthOverMonthData(
        currentMonth: momComparison.currentMonthSpent,
        previousMonth: momComparison.previousMonthSpent,
        difference: momComparison.difference,
        improved: momComparison.improved,
      );

      // Use domain service to generate insights
      _insights = await _insightService.generateInsights(
        transactions: transactions,
        budget: budget,
        streak: streak,
        monthOverMonth: momData,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e, st) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Call this after transaction changes to refresh insights
  Future<void> onTransactionsChanged() async {
    await generateInsights();
  }

  /// Get insights by type
  List<Insight> getInsightsByType(InsightType type) {
    return _insights.where((i) => i.type == type).toList();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
