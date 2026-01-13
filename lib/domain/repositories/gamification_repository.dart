import '../entities/streak_entity.dart';
import '../entities/gamification_entity.dart';

/// Gamification repository - manages achievements and streak tracking
abstract class GamificationRepository {
  /// Get current streak
  Future<StreakEntity> getCurrentStreak();

  /// Update streak (call after transaction added)
  Future<void> updateStreak();

  /// Reset streak (call when budget exceeded)
  Future<void> resetStreak();

  /// Get all achievements
  Future<GamificationEntity> getGamificationState();

  /// Unlock achievement
  Future<void> unlockAchievement(String achievementId);

  /// Check for new achievements
  Future<List<Achievement>> checkForNewAchievements();

  /// Observe streak changes
  Stream<StreakEntity> observeStreak();

  /// Observe gamification state
  Stream<GamificationEntity> observeGamificationState();
}
