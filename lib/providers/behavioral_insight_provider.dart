import 'package:flutter/foundation.dart';
import '../domain/entities/user_profile_entity.dart';
import '../domain/entities/behavioral_insight_entity.dart';
import '../domain/entities/budget_entity.dart';
import '../domain/entities/streak_entity.dart';
import '../domain/services/behavioral_insight_engine.dart';
import '../domain/services/rule_context_impl.dart';
import '../domain/repositories/user_profile_repository.dart';
import '../domain/repositories/behavioral_insight_repository.dart';
import '../domain/repositories/transaction_repository.dart';
import '../domain/repositories/budget_repository.dart';
import '../domain/repositories/gamification_repository.dart';
import '../domain/value_objects/delivery_triggers.dart';
import '../domain/value_objects/insight_category.dart';
import '../domain/value_objects/life_stage.dart';
import '../domain/value_objects/money_personality_type.dart';

/// Provider for behavioral insights
/// Bridges domain services and UI
class BehavioralInsightProvider extends ChangeNotifier {
  final BehavioralInsightEngine _engine;
  final UserProfileRepository _profileRepository;
  final BehavioralInsightRepository _insightRepository;
  final TransactionRepository _transactionRepository;
  final BudgetRepository? _budgetRepository;
  final GamificationRepository? _gamificationRepository;

  List<BehavioralInsightEntity> _insights = [];
  UserProfileEntity? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  BehavioralInsightProvider({
    required BehavioralInsightEngine engine,
    required UserProfileRepository profileRepository,
    required BehavioralInsightRepository insightRepository,
    required TransactionRepository transactionRepository,
    BudgetRepository? budgetRepository,
    GamificationRepository? gamificationRepository,
  })  : _engine = engine,
        _profileRepository = profileRepository,
        _insightRepository = insightRepository,
        _transactionRepository = transactionRepository,
        _budgetRepository = budgetRepository,
        _gamificationRepository = gamificationRepository {
    _initialize();
  }

  /// Get current insights
  List<BehavioralInsightEntity> get insights => List.unmodifiable(_insights);

  /// Get insights filtered by category
  List<BehavioralInsightEntity> getInsightsByCategory(InsightCategory category) {
    return _insights.where((i) => i.category == category).toList();
  }

  /// Get insights by priority
  List<BehavioralInsightEntity> getInsightsByPriority(InsightPriority minPriority) {
    return _insights.where((i) => i.priority.sortValue >= minPriority.sortValue).toList();
  }

  /// Get pending action insights
  List<BehavioralInsightEntity> get pendingActionInsights {
    return _insights.where((i) =>
        i.actionLabel != null &&
        !i.actionPerformed &&
        !i.isDismissed
    ).toList();
  }

  /// User profile
  UserProfileEntity? get profile => _profile;

  /// Loading state
  bool get isLoading => _isLoading;

  /// Error message
  String? get errorMessage => _errorMessage;

  /// Whether there are any insights to show
  bool get hasInsights => _insights.isNotEmpty;

  /// Count of insights shown today
  int get insightsShownToday => _insights
      .where((i) => i.lastDisplayedAt != null)
      .map((i) => i.lastDisplayedAt!)
      .where((date) {
        final now = DateTime.now();
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      }).length;

  /// Initialize the provider
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load profile
      await loadProfile();

      // Load active insights
      await refreshInsights();

      // Listen to profile changes
      _profileRepository.observeProfile().listen((profile) {
        if (profile != null) {
          _profile = profile;
          notifyListeners();
        }
      });

      // Listen to insight changes
      _insightRepository.observeInsights().listen((insights) {
        _insights = insights;
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user profile
  Future<void> loadProfile() async {
    try {
      _profile = await _profileRepository.getCurrentProfile();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load profile: $e';
      notifyListeners();
    }
  }

  /// Refresh insights from repository
  Future<void> refreshInsights() async {
    _isLoading = true;
    notifyListeners();

    try {
      _insights = await _insightRepository.getActiveInsights();

      // Clear expired insights
      await _insightRepository.clearExpiredInsights();

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to refresh insights: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generate insights for a specific trigger
  Future<InsightEvaluationResult> generateInsights(DeliveryTrigger trigger) async {
    if (_profile == null) {
      await loadProfile();
      if (_profile == null) {
        _errorMessage = 'No profile available';
        notifyListeners();
        return InsightEvaluationResult.noProfile();
      }
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Create context with all available data
      final context = await _createRuleContext();

      // Evaluate and save insights
      final result = await _engine.evaluateAndSave(
        trigger: trigger,
        context: context,
      );

      // Refresh insights after generation
      await refreshInsights();

      _isLoading = false;
      notifyListeners();

      return result;
    } catch (e) {
      _errorMessage = 'Failed to generate insights: $e';
      _isLoading = false;
      notifyListeners();

      return InsightEvaluationResult(
        trigger: trigger,
        insights: [],
        results: [],
        durationMs: 0,
        rulesEvaluated: 0,
      );
    }
  }

  /// Dismiss an insight
  Future<void> dismissInsight(String insightId) async {
    try {
      await _insightRepository.dismissInsight(insightId);

      // Update local state with immutable pattern
      final index = _insights.indexWhere((i) => i.id == insightId);
      if (index >= 0) {
        _insights = [
          ..._insights.sublist(0, index),
          ..._insights.sublist(index + 1),
        ];
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to dismiss insight: $e';
      notifyListeners();
    }
  }

  /// Perform an action from an insight
  Future<void> performAction(String insightId) async {
    try {
      // Mark as performed
      await _insightRepository.markActionPerformed(insightId);

      // Update local state with immutable pattern
      final index = _insights.indexWhere((i) => i.id == insightId);
      if (index >= 0) {
        final updatedInsight = _insights[index].markActionPerformed();
        _insights = [
          ..._insights.sublist(0, index),
          updatedInsight,
          ..._insights.sublist(index + 1),
        ];
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to perform action: $e';
      notifyListeners();
    }
  }

  /// Update user profile
  Future<void> updateProfile(UserProfileEntity profile) async {
    try {
      await _profileRepository.saveProfile(profile);
      _profile = profile;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      notifyListeners();
    }
  }

  /// Update personality type
  Future<void> updatePersonalityType(MoneyPersonalityType type) async {
    try {
      await _profileRepository.updatePersonalityType(type);
      await loadProfile();
    } catch (e) {
      _errorMessage = 'Failed to update personality: $e';
      notifyListeners();
    }
  }

  /// Update delivery preferences
  Future<void> updateDeliveryPreferences({
    int? maxInsightsPerDay,
    int? cooldownHours,
    TimeOfDay? preferredTime,
  }) async {
    try {
      await _profileRepository.updateDeliveryPreferences(
        maxInsightsPerDay: maxInsightsPerDay,
        cooldownHours: cooldownHours,
        preferredDailyTime: preferredTime?.toDateTime(),
      );
      await loadProfile();
    } catch (e) {
      _errorMessage = 'Failed to update delivery preferences: $e';
      notifyListeners();
    }
  }

  /// Toggle category enabled state
  Future<void> toggleCategory(InsightCategory category) async {
    if (_profile == null) return;

    final isEnabled = _profile!.enabledInsightCategories.contains(category);
    await _profileRepository.setCategoryEnabled(category.name, !isEnabled);
    await loadProfile();
  }

  /// Toggle war mode
  Future<void> toggleWarMode() async {
    if (_profile == null) return;

    await _profileRepository.setWarModeEnabled(!_profile!.warModeEnabled);
    await loadProfile();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Create rule context with all available data
  Future<RuleContextImpl> _createRuleContext() async {
    final profile = _profile ?? UserProfileEntity.create(id: 'default');

    // Get transactions
    final transactions = await _transactionRepository.getAllTransactions();

    // Get budget if available
    BudgetEntity? budget;
    if (_budgetRepository != null) {
      try {
        budget = await _budgetRepository!.getCurrentBudget();
      } catch (e) {
        // Budget not available, continue without it
      }
    }

    // Get streak if available
    StreakEntity? streak;
    if (_gamificationRepository != null) {
      try {
        streak = await _gamificationRepository!.getCurrentStreak();
      } catch (e) {
        // Streak not available, continue without it
      }
    }

    // Create context
    return RuleContextImpl(
      profile: profile,
      now: DateTime.now(),
      transactions: transactions,
      budget: budget,
      streak: streak,
      warMode: null, // TODO: Implement war mode calculation
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}