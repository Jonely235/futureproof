/// War Mode entity
/// Represents financial runway and danger level assessment
///
/// Business Rule: Runway = Current Cash / Daily Average Spend
class WarModeEntity {
  final double runwayDays;
  final WarModeLevel level;
  final double dailyAverageSpend;
  final double currentCash;
  final DateTime calculatedAt;

  const WarModeEntity({
    required this.runwayDays,
    required this.level,
    required this.dailyAverageSpend,
    required this.currentCash,
    required this.calculatedAt,
  });

  /// Factory to calculate war mode status
  factory WarModeEntity.calculate({
    required double currentCash,
    required double dailyAverageSpend,
  }) {
    // Guard against division by zero
    final runway = dailyAverageSpend > 0
        ? currentCash / dailyAverageSpend
        : double.infinity;

    // Determine danger level
    final level = _determineLevel(runway);

    return WarModeEntity(
      runwayDays: runway,
      level: level,
      dailyAverageSpend: dailyAverageSpend,
      currentCash: currentCash,
      calculatedAt: DateTime.now(),
    );
  }

  /// Business rule: Determine war mode level based on runway
  static WarModeLevel _determineLevel(double runwayDays) {
    if (runwayDays.isInfinite || runwayDays >= 30) {
      return WarModeLevel.green;  // Safe: 30+ days
    } else if (runwayDays >= 15) {
      return WarModeLevel.yellow; // Caution: 15-29 days
    } else {
      return WarModeLevel.red;    // Danger: < 15 days
    }
  }

  /// Business rule: Should restrict wants in current mode?
  bool get shouldRestrictWants => level == WarModeLevel.red;

  /// Business rule: Should add friction to spending?
  bool get shouldAddFriction => level == WarModeLevel.red;

  /// Business rule: Get user-friendly runway message
  String get runwayMessage {
    if (runwayDays.isInfinite) {
      return 'Infinite runway (no spending detected)';
    }

    if (runwayDays >= 365) {
      final years = (runwayDays / 365).toStringAsFixed(1);
      return '$years years of runway';
    }

    if (runwayDays >= 30) {
      final months = (runwayDays / 30).toStringAsFixed(1);
      return '$months months of runway';
    }

    return '${runwayDays.toStringAsFixed(0)} days of runway';
  }

  @override
  bool operator ==(Object other) =>
      other is WarModeEntity &&
      other.runwayDays == runwayDays &&
      other.level == level;

  @override
  int get hashCode => Object.hash(runwayDays, level);

  @override
  String toString() =>
      'WarModeEntity(runway: ${runwayDays.toStringAsFixed(1)} days, level: $level)';
}

/// War Mode danger levels
enum WarModeLevel {
  green,  // Safe: 30+ days runway
  yellow, // Caution: 15-29 days runway
  red,    // Danger: < 15 days runway
}

/// Extension to get color for WarModeLevel
extension WarModeLevelExtension on WarModeLevel {
  String get colorCode {
    switch (this) {
      case WarModeLevel.green:
        return '#4CAF50';
      case WarModeLevel.yellow:
        return '#FFC107';
      case WarModeLevel.red:
        return '#D32F2F';
    }
  }

  String get emoji {
    switch (this) {
      case WarModeLevel.green:
        return '✅';
      case WarModeLevel.yellow:
        return '⚠️';
      case WarModeLevel.red:
        return '🚨';
    }
  }

  String get displayName {
    switch (this) {
      case WarModeLevel.green:
        return 'Safe';
      case WarModeLevel.yellow:
        return 'Caution';
      case WarModeLevel.red:
        return 'Danger';
    }
  }
}
