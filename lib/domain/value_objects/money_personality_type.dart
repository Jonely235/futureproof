/// Money personality types based on behavioral economics research
/// Each type has distinct cognitive biases and requires tailored messaging
enum MoneyPersonalityType {
  /// Security-focused; frugal to a fault; worries about spending
  /// Strategy: "Permission to Spend" nudges, frame spending as investments
  saver,

  /// Impulse purchases; retail therapy; finds budgets restrictive
  /// Strategy: "Values-Based Budgeting", frame saving as "Buying Future Freedom"
  spender,

  /// Generous; prioritizes others; can't say no to requests for help
  /// Strategy: "Oxygen Mask Principle", use "Giving Sinking Funds"
  sharer,

  /// Future-focused; calculated risks; may lack liquidity
  /// Strategy: "Present Value" alerts, remind to enjoy wealth today
  investor,

  /// High risk tolerance; loves the thrill; may be over-leveraged
  /// Strategy: "Risk Fencing", limit risky assets to 10% of portfolio
  gambler,
}

/// Extension for personality-specific metadata
extension MoneyPersonalityTypeExtension on MoneyPersonalityType {
  /// Display name for UI
  String get displayName {
    switch (this) {
      case MoneyPersonalityType.saver:
        return 'The Saver';
      case MoneyPersonalityType.spender:
        return 'The Spender';
      case MoneyPersonalityType.sharer:
        return 'The Sharer';
      case MoneyPersonalityType.investor:
        return 'The Investor';
      case MoneyPersonalityType.gambler:
        return 'The Gambler';
    }
  }

  /// Short description for onboarding
  String get description {
    switch (this) {
      case MoneyPersonalityType.saver:
        return 'Security-focused, frugal, and careful with every dollar';
      case MoneyPersonalityType.spender:
        return 'Enjoys spending in the moment, finds budgets restrictive';
      case MoneyPersonalityType.sharer:
        return 'Generous with others, sometimes at your own expense';
      case MoneyPersonalityType.investor:
        return 'Future-focused, takes calculated risks for growth';
      case MoneyPersonalityType.gambler:
        return 'High risk tolerance, loves the thrill of big wins';
    }
  }

  /// Preferred insight tone
  InsightTone get preferredTone {
    switch (this) {
      case MoneyPersonalityType.saver:
        return InsightTone.authoritative;
      case MoneyPersonalityType.spender:
        return InsightTone.casual;
      case MoneyPersonalityType.sharer:
        return InsightTone.supportive;
      case MoneyPersonalityType.investor:
        return InsightTone.analytical;
      case MoneyPersonalityType.gambler:
        return InsightTone.direct;
    }
  }
}

/// Insight tone styles for personalization
enum InsightTone {
  /// Authoritative, security-focused language
  authoritative,

  /// Casual, values-based messaging
  casual,

  /// Warm, empathetic, understanding
  supportive,

  /// Data-driven, future-focused
  analytical,

  /// Direct, urgent, action-oriented
  direct,
}
