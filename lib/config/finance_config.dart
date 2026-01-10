class FinanceConfig {
  FinanceConfig._internal();
  static final instance = FinanceConfig._internal();

  // Buffer settings
  static const double bufferPercentage = 0.10;

  double calculateBuffer(double monthlyIncome) {
    return monthlyIncome * bufferPercentage;
  }

  // Anomaly detection
  static const int anomalyThresholdHigh = 3;
  static const int anomalyThresholdMedium = 1;
  static const int anomalyPenaltyHigh = 10;
  static const int anomalyPenaltyMedium = 5;

  int calculateAnomalyPenalty(int anomalyCount) {
    if (anomalyCount > anomalyThresholdHigh) {
      return anomalyPenaltyHigh;
    } else if (anomalyCount > anomalyThresholdMedium) {
      return anomalyPenaltyMedium;
    }
    return 0;
  }

  // Health score settings
  static const int overBudgetPenalty = 10;
  static const int savingsGoalBonus = 5;
  static const int trendingDownBonus = 5;

  // Financial status thresholds
  static const double dangerThreshold = 0.0;
  static const double cautionThreshold = 0.0;

  // Spending analysis settings
  static const double anomalyStdDevThreshold = 2.0;
  static const int minTrendDataPoints = 2;
  static const int minMonthsForAverage = 1;

  // Validation settings
  static const double maxTransactionAmount = 1000000.0;
  static const double minTransactionAmount = -1000000.0;
  static const int maxNoteLength = 500;

  // Display settings
  static const int currencyDecimalPlaces = 2;
  static const int trendMonthsCount = 6;

  // Insight settings
  static const int maxInsightsCount = 5;
  static const double insightMinDifferencePercent = 20.0;

  // Budget settings
  static const double defaultCategoryBudget = 500.0;
  static const double minCategoryBudget = 0.0;
  static const double maxCategoryBudget = 100000.0;

  // Validation helpers
  bool isValidAmount(double amount) {
    return amount >= minTransactionAmount && amount <= maxTransactionAmount;
  }

  bool isValidBudget(double budget) {
    return budget >= minCategoryBudget && budget <= maxCategoryBudget;
  }

  bool isValidNote(String note) {
    return note.length <= maxNoteLength;
  }

  @override
  String toString() {
    return 'FinanceConfig('
        'buffer: ${bufferPercentage * 100}%, '
        'anomalyPenalty: $anomalyPenaltyHigh/$anomalyPenaltyMedium, '
        'overBudgetPenalty: $overBudgetPenalty'
        ')';
  }
}
