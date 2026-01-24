import '../entities/behavioral_insight_entity.dart';
import '../entities/user_profile_entity.dart';
import '../value_objects/insight_category.dart';
import '../value_objects/money_personality_type.dart';
import '../value_objects/life_stage.dart';

/// Service for personalizing insight messages based on user profile
/// Adapts tone, language, and framing to match personality and stress level
class InsightPersonalizationService {
  /// Personalize an insight based on user profile
  /// Returns a new insight with personalized content
  BehavioralInsightEntity personalize(
    BehavioralInsightEntity insight,
    UserProfileEntity profile,
  ) {
    // Skip if insight is already personalized for this profile
    if (insight.metadata?['personalizedFor'] == profile.id) {
      return insight;
    }

    // Get personalized components
    final title = _personalizeTitle(
      insight.title,
      insight.category,
      profile.personalityType,
      insight.priority,
    );

    final message = _personalizeMessage(
      insight.message,
      insight.category,
      profile.personalityType,
      profile.stressLevel,
    );

    // Return personalized insight
    return insight.copyWith(
      title: title,
      message: message,
      metadata: {
        ...?insight.metadata,
        'personalizedFor': profile.id,
        'personalityType': profile.personalityType.name,
        'stressLevel': profile.stressLevel.name,
      },
    );
  }

  /// Personalize title based on personality
  String _personalizeTitle(
    String baseTitle,
    InsightCategory category,
    MoneyPersonalityType personality,
    InsightPriority priority,
  ) {
    // For critical alerts, be direct regardless of personality
    if (priority == InsightPriority.critical) {
      return baseTitle;
    }

    // Add personality-appropriate prefix
    switch (personality) {
      case MoneyPersonalityType.saver:
        return _addSaverPrefix(baseTitle, category);
      case MoneyPersonalityType.spender:
        return _addSpenderPrefix(baseTitle, category);
      case MoneyPersonalityType.sharer:
        return _addSharerPrefix(baseTitle, category);
      case MoneyPersonalityType.investor:
        return _addInvestorPrefix(baseTitle, category);
      case MoneyPersonalityType.gambler:
        return _addGamblerPrefix(baseTitle, category);
    }
  }

  /// Personalize message based on personality and stress level
  String _personalizeMessage(
    String baseMessage,
    InsightCategory category,
    MoneyPersonalityType personality,
    FinancialStressLevel stressLevel,
  ) {
    var message = baseMessage;

    // Adjust tone based on stress level
    if (stressLevel == FinancialStressLevel.high) {
      message = _addStressUrgency(message, category);
    } else if (stressLevel == FinancialStressLevel.low) {
      message = _addEncouragement(message, category);
    }

    // Add personality framing
    message = _addPersonalityFraming(message, category, personality);

    return message;
  }

  /// Add stress-appropriate urgency
  String _addStressUrgency(String message, InsightCategory category) {
    // For high stress, be more direct and actionable
    final prefixes = [
      'Important: ',
      'Please review: ',
      'Action needed: ',
    ];

    // Don't double-prefix
    for (final prefix in prefixes) {
      if (message.startsWith(prefix)) {
        return message;
      }
    }

    return 'Important: $message';
  }

  /// Add encouragement for low-stress users
  String _addEncouragement(String message, InsightCategory category) {
    if (category == InsightCategory.goalProgress ||
        category == InsightCategory.streakAndMomentum) {
      return '$message Keep up the great work!';
    }
    return message;
  }

  /// Add personality-based framing
  String _addPersonalityFraming(
    String message,
    InsightCategory category,
    MoneyPersonalityType personality,
  ) {
    // The message is likely already personalized from the rule
    // This is a fallback for cases where it isn't
    return message;
  }

  String _addSaverPrefix(String title, InsightCategory category) {
    switch (category) {
      case InsightCategory.budgetHealth:
        return 'Budget Check: $title';
      case InsightCategory.anomalyDetection:
        return 'Transaction Alert: $title';
      default:
        return title;
    }
  }

  String _addSpenderPrefix(String title, InsightCategory category) {
    switch (category) {
      case InsightCategory.budgetHealth:
        return 'Spending Update: $title';
      case InsightCategory.anomalyDetection:
        return 'Purchase Alert: $title';
      default:
        return title;
    }
  }

  String _addSharerPrefix(String title, InsightCategory category) {
    switch (category) {
      case InsightCategory.budgetHealth:
        return 'Your Budget: $title';
      default:
        return title;
    }
  }

  String _addInvestorPrefix(String title, InsightCategory category) {
    switch (category) {
      case InsightCategory.budgetHealth:
        return 'Financial Update: $title';
      case InsightCategory.cashFlowForecast:
        return 'Cash Flow Analysis: $title';
      default:
        return title;
    }
  }

  String _addGamblerPrefix(String title, InsightCategory category) {
    switch (category) {
      case InsightCategory.budgetHealth:
        return 'Budget Status: $title';
      default:
        return title;
    }
  }

  /// Batch personalize multiple insights
  List<BehavioralInsightEntity> personalizeBatch(
    List<BehavioralInsightEntity> insights,
    UserProfileEntity profile,
  ) {
    return insights
        .map((insight) => personalize(insight, profile))
        .toList();
  }

  /// Check if an insight should be shown to a user
  bool shouldShowInsight(
    BehavioralInsightEntity insight,
    UserProfileEntity profile,
  ) {
    // Check if category is enabled
    if (!profile.isCategoryEnabled(insight.category)) {
      return false;
    }

    // Check cooldown period
    // (This would be checked via repository in real usage)

    // Check if stress level matches insight priority
    if (profile.stressLevel == FinancialStressLevel.high) {
      // In high stress, only show critical and high priority
      if (insight.priority == InsightPriority.low) {
        return false;
      }
    }

    return true;
  }

  /// Filter insights that should be shown to user
  List<BehavioralInsightEntity> filterInsights(
    List<BehavioralInsightEntity> insights,
    UserProfileEntity profile,
  ) {
    return insights
        .where((insight) => shouldShowInsight(insight, profile))
        .toList();
  }

  /// Sort insights by relevance for a specific user
  List<BehavioralInsightEntity> sortByRelevance(
    List<BehavioralInsightEntity> insights,
    UserProfileEntity profile,
  ) {
    // Sort by priority, then by category preference
    final sorted = List<BehavioralInsightEntity>.from(insights);

    sorted.sort((a, b) {
      // First by priority
      final priorityCompare = b.priority.sortValue.compareTo(a.priority.sortValue);
      if (priorityCompare != 0) return priorityCompare;

      // Then by category preference (essential categories first)
      final aEssential = a.category.isEssential;
      final bEssential = b.category.isEssential;
      if (aEssential && !bEssential) return -1;
      if (!aEssential && bEssential) return 1;

      // Finally by generated time (newest first)
      return b.generatedAt.compareTo(a.generatedAt);
    });

    return sorted;
  }

  /// Get recommended daily insights for a user
  List<BehavioralInsightEntity> getDailyRecommendations(
    List<BehavioralInsightEntity> availableInsights,
    UserProfileEntity profile,
  ) {
    // Filter, personalize, and sort
    final filtered = filterInsights(availableInsights, profile);
    final personalized = personalizeBatch(filtered, profile);
    final sorted = sortByRelevance(personalized, profile);

    // Limit to max insights per day
    final maxInsights = profile.maxInsightsPerDay;
    if (sorted.length > maxInsights) {
      return sorted.take(maxInsights).toList();
    }

    return sorted;
  }

  /// Get the optimal time to show an insight
  DateTime? getOptimalShowTime(
    BehavioralInsightEntity insight,
    UserProfileEntity profile,
  ) {
    // For daily insights, use the user's preferred time
    if (insight.category == InsightCategory.budgetHealth) {
      final now = DateTime.now();
      return DateTime(
        now.year,
        now.month,
        now.day,
        profile.preferredDailyTime.hour,
        profile.preferredDailyTime.minute,
      );
    }

    // For weekly summaries, Sunday evening
    if (insight.category == InsightCategory.subscriptionManagement) {
      final now = DateTime.now();
      final nextSunday = now.add(Duration(days: 7 - now.weekday % 7));
      return DateTime(
        nextSunday.year,
        nextSunday.month,
        nextSunday.day,
        19, // 7 PM
      );
    }

    return null;
  }

  /// Generate a personalized follow-up message
  String generateFollowUp(
    BehavioralInsightEntity insight,
    bool actionPerformed,
    UserProfileEntity profile,
  ) {
    if (actionPerformed) {
      return _getPositiveFollowUp(profile.personalityType);
    } else {
      return _getGentleReminder(profile.personalityType, insight.category);
    }
  }

  String _getPositiveFollowUp(MoneyPersonalityType personality) {
    switch (personality) {
      case MoneyPersonalityType.saver:
        return 'Great job staying on top of your finances!';
      case MoneyPersonalityType.spender:
        return 'Nice work! Your future self will thank you.';
      case MoneyPersonalityType.sharer:
        return 'You\'re building a solid foundation for helping others.';
      case MoneyPersonalityType.investor:
        return 'Smart move. Your financial discipline pays dividends.';
      case MoneyPersonalityType.gambler:
        return 'Winner! You made the right call today.';
    }
  }

  String _getGentleReminder(MoneyPersonalityType personality, InsightCategory category) {
    switch (personality) {
      case MoneyPersonalityType.saver:
        return 'This insight is still waiting for your attention.';
      case MoneyPersonalityType.spender:
        return 'Still worth a look when you have a moment.';
      case MoneyPersonalityType.sharer:
        return 'Taking care of this helps you take care of others.';
      case MoneyPersonalityType.investor:
        return 'Addressing this improves your financial position.';
      case MoneyPersonalityType.gambler:
        return 'Don\'t leave money on the table — check this out.';
    }
  }
}
