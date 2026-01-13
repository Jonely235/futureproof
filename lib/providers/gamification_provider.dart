import 'package:flutter/foundation.dart';
import '../../domain/entities/streak_entity.dart';
import '../../domain/entities/gamification_entity.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/services/streak_calculator_service.dart';
import '../../domain/services/achievement_service.dart';
import '../../domain/services/budget_comparison_service.dart';

/// Gamification provider - manages streaks, achievements, and motivational stats
/// Uses Clean Architecture: Provider → Repository/Domain Services → Entities
class GamificationProvider extends ChangeNotifier {
  final GamificationRepository _gamificationRepository;
  final TransactionRepository _transactionRepository;
  final BudgetRepository _budgetRepository;
  final StreakCalculatorService _streakCalculator;
  final AchievementService _achievementService;
  final BudgetComparisonService _budgetComparisonService;

  // State
  StreakEntity? _streak;
  GamificationEntity? _gamification;
  MonthOverMonthComparison? _monthOverMonthComparison;
  List<Achievement> _newAchievements = [];

  // Loading state
  bool _isLoading = false;
  String? _error;

  GamificationProvider({
    required GamificationRepository gamificationRepository,
    required TransactionRepository transactionRepository,
    required BudgetRepository budgetRepository,
    StreakCalculatorService? streakCalculator,
    AchievementService? achievementService,
    BudgetComparisonService? budgetComparisonService,
  })  : _gamificationRepository = gamificationRepository,
        _transactionRepository = transactionRepository,
        _budgetRepository = budgetRepository,
        _streakCalculator = streakCalculator ?? StreakCalculatorService(),
        _achievementService = achievementService ?? AchievementService(),
        _budgetComparisonService = budgetComparisonService ?? BudgetComparisonService();

  // Getters
  StreakEntity? get streak => _streak;
  GamificationEntity? get gamification => _gamification;
  MonthOverMonthComparison? get monthOverMonthComparison => _monthOverMonthComparison;
  List<Achievement> get newAchievements => _newAchievements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all gamification data
  Future<void> loadGamificationData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load streak and gamification state
      _streak = await _gamificationRepository.getCurrentStreak();
      _gamification = await _gamificationRepository.getGamificationState();

      // Calculate streak with current transactions and budget
      await _refreshStreak();

      // Calculate month-over-month comparison
      await _refreshMonthOverMonth();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh streak based on current transactions and budget
  Future<void> _refreshStreak() async {
    try {
      final transactions = await _transactionRepository.getAllTransactions();
      final budget = await _budgetRepository.getCurrentBudget();

      // Use domain service to calculate streak
      final calculatedStreak = _streakCalculator.calculateStreak(
        transactions: transactions,
        budget: budget,
        currentStreak: _streak,
      );

      _streak = calculatedStreak;
      await _gamificationRepository.updateStreak();
    } catch (e) {
      // Keep existing streak on error
    }
  }

  /// Refresh month-over-month comparison
  Future<void> _refreshMonthOverMonth() async {
    try {
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

      _monthOverMonthComparison = _budgetComparisonService.compareMonths(
        currentMonthTransactions: currentMonthTransactions,
        previousMonthTransactions: previousMonthTransactions,
      );
    } catch (e) {
      // Keep existing comparison on error
    }
  }

  /// Check for new achievements and unlock them
  Future<void> checkAndUnlockAchievements() async {
    try {
      final transactions = await _transactionRepository.getAllTransactions();
      final budget = await _budgetRepository.getCurrentBudget();
      final totalSpent = transactions
          .where((t) => t.isExpense)
          .fold<double>(0, (sum, t) => sum + t.absoluteAmount);
      final totalSaved = budget.monthlyIncome - totalSpent;

      final newAchievementList = _achievementService.checkAchievements(
        streak: _streak!,
        transactions: transactions,
        currentGamification: _gamification!,
        totalSaved: totalSaved,
      );

      for (final achievement in newAchievementList) {
        await _gamificationRepository.unlockAchievement(achievement.id);
      }

      if (newAchievementList.isNotEmpty) {
        _newAchievements.addAll(newAchievementList);
        _gamification = await _gamificationRepository.getGamificationState();
        notifyListeners();
      }
    } catch (e) {
      // Silently fail achievement check
    }
  }

  /// Reset streak (called when budget exceeded)
  Future<void> resetStreak() async {
    await _gamificationRepository.resetStreak();
    _streak = await _gamificationRepository.getCurrentStreak();
    notifyListeners();
  }

  /// Call this after transaction changes to update gamification data
  Future<void> onTransactionsChanged() async {
    await _refreshStreak();
    await _refreshMonthOverMonth();
    await checkAndUnlockAchievements();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
