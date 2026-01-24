import '../value_objects/money_personality_type.dart';
import '../value_objects/life_stage.dart';
import '../value_objects/delivery_triggers.dart';
import '../value_objects/insight_category.dart';


/// User profile for behavioral insight personalization
/// Stores preferences, personality type, and delivery settings
class UserProfileEntity {
  /// Unique identifier for this profile
  final String id;

  /// User's money personality type
  final MoneyPersonalityType personalityType;

  /// User's current life stage
  final LifeStage lifeStage;

  /// Current financial stress level
  final FinancialStressLevel stressLevel;

  /// Enabled insight categories (user can disable non-essential categories)
  final Set<InsightCategory> enabledInsightCategories;

  /// Preferred delivery time for daily insights
  final TimeOfDay preferredDailyTime;

  /// Maximum number of insights to show per day (prevents overload)
  final int maxInsightsPerDay;

  /// Cooldown hours between similar insights (prevents repetition)
  final int cooldownHours;

  /// Whether war mode is enabled (crisis budgeting)
  final bool warModeEnabled;

  /// Whether location-based alerts are enabled
  final bool locationAlertsEnabled;

  /// Profile creation date
  final DateTime createdAt;

  /// Last update date
  final DateTime updatedAt;

  UserProfileEntity({
    required this.id,
    required this.personalityType,
    required this.lifeStage,
    required this.stressLevel,
    required this.enabledInsightCategories,
    required this.preferredDailyTime,
    this.maxInsightsPerDay = 5,
    this.cooldownHours = 4,
    this.warModeEnabled = false,
    this.locationAlertsEnabled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory to create a new user profile with defaults
  factory UserProfileEntity.create({
    required String id,
    MoneyPersonalityType? personalityType,
    LifeStage? lifeStage,
    FinancialStressLevel? stressLevel,
  }) {
    final now = DateTime.now();
    return UserProfileEntity(
      id: id,
      personalityType: personalityType ?? MoneyPersonalityType.spender,
      lifeStage: lifeStage ?? LifeStage.earlyCareer,
      stressLevel: stressLevel ?? FinancialStressLevel.medium,
      enabledInsightCategories: InsightCategory.values.toSet(),
      preferredDailyTime: const TimeOfDay(hour: 8, minute: 0),
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Check if a category is enabled
  bool isCategoryEnabled(InsightCategory category) {
    return enabledInsightCategories.contains(category);
  }

  /// Get preferred tone for insights based on personality
  InsightTone get preferredTone => personalityType.preferredTone;

  /// Copy with for immutability
  UserProfileEntity copyWith({
    String? id,
    MoneyPersonalityType? personalityType,
    LifeStage? lifeStage,
    FinancialStressLevel? stressLevel,
    Set<InsightCategory>? enabledInsightCategories,
    TimeOfDay? preferredDailyTime,
    int? maxInsightsPerDay,
    int? cooldownHours,
    bool? warModeEnabled,
    bool? locationAlertsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileEntity(
      id: id ?? this.id,
      personalityType: personalityType ?? this.personalityType,
      lifeStage: lifeStage ?? this.lifeStage,
      stressLevel: stressLevel ?? this.stressLevel,
      enabledInsightCategories:
          enabledInsightCategories ?? this.enabledInsightCategories,
      preferredDailyTime: preferredDailyTime ?? this.preferredDailyTime,
      maxInsightsPerDay: maxInsightsPerDay ?? this.maxInsightsPerDay,
      cooldownHours: cooldownHours ?? this.cooldownHours,
      warModeEnabled: warModeEnabled ?? this.warModeEnabled,
      locationAlertsEnabled: locationAlertsEnabled ?? this.locationAlertsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfileEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Time of day for scheduling daily insights
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({
    required this.hour,
    required this.minute,
  }) : assert(hour >= 0 && hour < 24),
        assert(minute >= 0 && minute < 60);

  /// Convert to DateTime for today
  DateTime toDateTime([DateTime? base]) {
    final now = base ?? DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  /// Parse from string "HH:MM"
  static TimeOfDay parse(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  /// Format as string "HH:MM"
  String format() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeOfDay && other.hour == hour && other.minute == minute;
  }

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}
