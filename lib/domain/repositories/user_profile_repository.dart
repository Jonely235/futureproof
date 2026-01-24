import '../entities/user_profile_entity.dart';
import '../value_objects/money_personality_type.dart';
import '../value_objects/life_stage.dart';

/// User profile repository interface
/// Defines the contract for user profile data access
abstract class UserProfileRepository {
  /// Get the current user's profile
  /// Returns null if no profile exists yet
  Future<UserProfileEntity?> getCurrentProfile();

  /// Get profile by ID
  Future<UserProfileEntity?> getProfileById(String id);

  /// Save or update a user profile
  Future<void> saveProfile(UserProfileEntity profile);

  /// Update the user's money personality type
  Future<void> updatePersonalityType(MoneyPersonalityType type);

  /// Update the user's life stage
  Future<void> updateLifeStage(LifeStage stage);

  /// Update financial stress level
  Future<void> updateStressLevel(FinancialStressLevel level);

  /// Update delivery preferences
  Future<void> updateDeliveryPreferences({
    int? maxInsightsPerDay,
    int? cooldownHours,
    DateTime? preferredDailyTime,
  });

  /// Enable or disable an insight category
  Future<void> setCategoryEnabled(
    String categoryId,
    bool enabled,
  );

  /// Enable or disable war mode
  Future<void> setWarModeEnabled(bool enabled);

  /// Enable or disable location alerts
  Future<void> setLocationAlertsEnabled(bool enabled);

  /// Observe profile changes for reactive updates
  Stream<UserProfileEntity?> observeProfile();

  /// Delete a profile (use with caution)
  Future<void> deleteProfile(String id);
}
