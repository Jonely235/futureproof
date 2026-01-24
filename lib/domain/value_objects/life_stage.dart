/// Life stages for adapting insight messaging
/// Different stages require different financial priorities
enum LifeStage {
  /// Student or early education
  /// Focus: Survival, velocity, building habits
  student,

  /// Early career, first jobs, establishing foundations
  /// Focus: Savings optimization, compound growth visualizations
  earlyCareer,

  /// Family building, mortgage, dependents
  /// Focus: Insurance, emergency fund, education planning
  family,

  /// Pre-retirement, wealth preservation
  /// Focus: Decumulation strategy, healthcare planning
  retirement,
}

/// Extension for life stage metadata
extension LifeStageExtension on LifeStage {
  /// Display name for UI
  String get displayName {
    switch (this) {
      case LifeStage.student:
        return 'Student';
      case LifeStage.earlyCareer:
        return 'Early Career';
      case LifeStage.family:
        return 'Family';
      case LifeStage.retirement:
        return 'Retirement';
    }
  }

  /// Description for onboarding
  String get description {
    switch (this) {
      case LifeStage.student:
        return 'Focus on building good financial habits';
      case LifeStage.earlyCareer:
        return 'Optimize savings and leverage compound growth';
      case LifeStage.family:
        return 'Balance protection with growth for dependents';
      case LifeStage.retirement:
        return 'Preserve wealth and plan for healthcare';
    }
  }
}

/// Financial stress levels for adapting insight tone and urgency
enum FinancialStressLevel {
  /// Healthy margins, comfortable cash flow
  /// Approach: Soft nudges, long-term focus
  low,

  /// Some tightness, but manageable
  /// Approach: Balanced urgency, specific guidance
  medium,

  /// Very tight cash flow, potential crisis
  /// Approach: Hard cues, direct language, survival focus
  high,
}

/// Extension for stress level metadata
extension FinancialStressLevelExtension on FinancialStressLevel {
  /// Display name for UI
  String get displayName {
    switch (this) {
      case FinancialStressLevel.low:
        return 'Low Stress';
      case FinancialStressLevel.medium:
        return 'Medium Stress';
      case FinancialStressLevel.high:
        return 'High Stress';
    }
  }

  /// Description
  String get description {
    switch (this) {
      case FinancialStressLevel.low:
        return 'You have healthy financial margins';
      case FinancialStressLevel.medium:
        return 'Some things are tight but manageable';
      case FinancialStressLevel.high:
        return 'You\'re in a difficult financial situation';
    }
  }
}

/// Insight priority levels for sorting and filtering
enum InsightPriority {
  /// Critical - requires immediate attention
  critical,

  /// High - important but not urgent
  high,

  /// Medium - informational
  medium,

  /// Low - nice to know
  low,
}

/// Extension for priority metadata
extension InsightPriorityExtension on InsightPriority {
  /// Numeric value for sorting (higher = more important)
  int get sortValue {
    switch (this) {
      case InsightPriority.critical:
        return 4;
      case InsightPriority.high:
        return 3;
      case InsightPriority.medium:
        return 2;
      case InsightPriority.low:
        return 1;
    }
  }

  /// Display name
  String get displayName {
    switch (this) {
      case InsightPriority.critical:
        return 'Critical';
      case InsightPriority.high:
        return 'High';
      case InsightPriority.medium:
        return 'Medium';
      case InsightPriority.low:
        return 'Low';
    }
  }
}
