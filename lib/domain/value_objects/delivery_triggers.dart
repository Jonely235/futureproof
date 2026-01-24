/// Delivery frequency for insight notifications
enum DeliveryFrequency {
  /// Immediately after relevant event (e.g., post-transaction)
  realTime,

  /// Once per day at preferred time
  daily,

  /// Once per week summary
  weekly,

  /// Once per month deep dive
  monthly,
}

/// Events that trigger insight generation and delivery
enum DeliveryTrigger {
  /// Immediately after a transaction is added
  postTransaction,

  /// Before user makes spending decisions (morning digest)
  preDecision,

  /// Morning summary of safe-to-spend and daily outlook
  morningDigest,

  /// Evening summary of day's spending
  eveningDigest,

  /// Weekly retrospective and velocity check
  weeklySummary,

  /// Monthly strategic review and goal progress
  monthlyDeepDive,

  /// User manually requests insights
  manual,

  /// App opened/foregrounded
  appOpen,

  /// User enters high-risk location (e.g., mall)
  location,
}

/// Extension for trigger metadata
extension DeliveryTriggerExtension on DeliveryTrigger {
  /// Display name for UI
  String get displayName {
    switch (this) {
      case DeliveryTrigger.postTransaction:
        return 'After Transactions';
      case DeliveryTrigger.preDecision:
        return 'Before Spending';
      case DeliveryTrigger.morningDigest:
        return 'Morning Digest';
      case DeliveryTrigger.eveningDigest:
        return 'Evening Summary';
      case DeliveryTrigger.weeklySummary:
        return 'Weekly Summary';
      case DeliveryTrigger.monthlyDeepDive:
        return 'Monthly Review';
      case DeliveryTrigger.manual:
        return 'Manual Only';
      case DeliveryTrigger.appOpen:
        return 'On App Open';
      case DeliveryTrigger.location:
        return 'Location-Based';
    }
  }

  /// Default delivery frequency for this trigger
  DeliveryFrequency get defaultFrequency {
    switch (this) {
      case DeliveryTrigger.postTransaction:
      case DeliveryTrigger.appOpen:
      case DeliveryTrigger.location:
        return DeliveryFrequency.realTime;
      case DeliveryTrigger.preDecision:
      case DeliveryTrigger.morningDigest:
      case DeliveryTrigger.eveningDigest:
        return DeliveryFrequency.daily;
      case DeliveryTrigger.weeklySummary:
        return DeliveryFrequency.weekly;
      case DeliveryTrigger.monthlyDeepDive:
        return DeliveryFrequency.monthly;
      case DeliveryTrigger.manual:
        return DeliveryFrequency.daily;
    }
  }
}
