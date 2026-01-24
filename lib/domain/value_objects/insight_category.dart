/// Insight categories for organizing behavioral interventions
/// Each category targets specific behavioral biases or financial patterns
enum InsightCategory {
  /// Budget health and spending velocity monitoring
  /// Behavioral principle: Anchoring and Adjustment
  budgetHealth,

  /// Unusual spending or anomaly detection
  /// Behavioral principle: Salience
  anomalyDetection,

  /// Goal progress tracking and projection
  /// Behavioral principle: Goal Gradient Effect
  goalProgress,

  /// Future balance prediction and cash flow gaps
  /// Behavioral principle: Future Self-Continuity
  cashFlowForecast,

  /// Debt payoff strategies and visualization
  /// Behavioral principle: Variable Reward
  debtPayoff,

  /// Subscription and recurring charge management
  /// Behavioral principle: The Pennies-a-Day Effect
  subscriptionManagement,

  /// Predictive scenario-based alerts
  /// Behavioral principle: Prospective Hindsight
  scenarioAlert,

  /// Streak tracking and momentum building
  /// Behavioral principle: Habit Formation
  streakAndMomentum,

  /// Crisis mode alerts during economic stress
  /// Behavioral principle: Scarcity Mindset mitigation
  warMode,
}

/// Extension for category metadata
extension InsightCategoryExtension on InsightCategory {
  /// Display name for UI
  String get displayName {
    switch (this) {
      case InsightCategory.budgetHealth:
        return 'Budget Health';
      case InsightCategory.anomalyDetection:
        return 'Anomaly Detection';
      case InsightCategory.goalProgress:
        return 'Goal Progress';
      case InsightCategory.cashFlowForecast:
        return 'Cash Flow Forecast';
      case InsightCategory.debtPayoff:
        return 'Debt Payoff';
      case InsightCategory.subscriptionManagement:
        return 'Subscriptions';
      case InsightCategory.scenarioAlert:
        return 'Smart Alerts';
      case InsightCategory.streakAndMomentum:
        return 'Streaks';
      case InsightCategory.warMode:
        return 'War Mode';
    }
  }

  /// Default icon for category
  String get defaultIcon {
    switch (this) {
      case InsightCategory.budgetHealth:
        return '📊';
      case InsightCategory.anomalyDetection:
        return '⚠️';
      case InsightCategory.goalProgress:
        return '🎯';
      case InsightCategory.cashFlowForecast:
        return '📈';
      case InsightCategory.debtPayoff:
        return '💳';
      case InsightCategory.subscriptionManagement:
        return '🔄';
      case InsightCategory.scenarioAlert:
        return '🔔';
      case InsightCategory.streakAndMomentum:
        return '🔥';
      case InsightCategory.warMode:
        return '🚨';
    }
  }

  /// Whether this category is essential (cannot be disabled)
  bool get isEssential {
    switch (this) {
      case InsightCategory.warMode:
        return true;
      case InsightCategory.budgetHealth:
      case InsightCategory.anomalyDetection:
      case InsightCategory.goalProgress:
      case InsightCategory.cashFlowForecast:
      case InsightCategory.debtPayoff:
      case InsightCategory.subscriptionManagement:
      case InsightCategory.scenarioAlert:
      case InsightCategory.streakAndMomentum:
        return false;
    }
  }
}
