import '../entities/behavioral_insight_entity.dart';
import '../value_objects/insight_category.dart';
import '../value_objects/life_stage.dart';

/// Behavioral insight repository interface
/// Defines the contract for insight data access
abstract class BehavioralInsightRepository {
  /// Get all active (non-dismissed, non-expired) insights
  Future<List<BehavioralInsightEntity>> getActiveInsights();

  /// Get insights by category
  Future<List<BehavioralInsightEntity>> getInsightsByCategory(
    InsightCategory category,
  );

  /// Get insights by priority
  Future<List<BehavioralInsightEntity>> getInsightsByPriority(
    InsightPriority minPriority,
  );

  /// Get insights generated since a given date
  Future<List<BehavioralInsightEntity>> getInsightsSince(
    DateTime since,
  );

  /// Get a specific insight by ID
  Future<BehavioralInsightEntity?> getInsightById(String id);

  /// Save a new insight
  Future<void> saveInsight(BehavioralInsightEntity insight);

  /// Save multiple insights in a batch
  Future<void> saveInsights(List<BehavioralInsightEntity> insights);

  /// Dismiss an insight (user swiped it away)
  Future<void> dismissInsight(String insightId);

  /// Mark an insight's action as performed
  Future<void> markActionPerformed(String insightId);

  /// Increment the display count for an insight
  Future<void> incrementDisplayCount(String insightId);

  /// Clear expired insights
  Future<int> clearExpiredInsights();

  /// Clear all insights (use with caution)
  Future<void> clearAllInsights();

  /// Get count of insights shown today
  Future<int> getInsightsShownToday();

  /// Check if a similar insight was shown recently (within cooldown period)
  Future<bool> wasInsightShownRecently(
    String ruleId,
    Duration cooldown,
  );

  /// Observe insight changes for reactive updates
  Stream<List<BehavioralInsightEntity>> observeInsights();

  /// Observe insights by category
  Stream<List<BehavioralInsightEntity>> observeInsightsByCategory(
    InsightCategory category,
  );

  /// Get insights that need action (actionPerformed = false, not dismissed)
  Future<List<BehavioralInsightEntity>> getPendingActionInsights();
}
