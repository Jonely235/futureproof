import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/streak_entity.dart';
import '../../domain/entities/gamification_entity.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../../domain/services/streak_calculator_service.dart';
import '../../domain/services/achievement_service.dart';
import '../../models/transaction.dart' as model;

/// Gamification repository implementation
/// Manages streak tracking and achievements using SharedPreferences
class GamificationRepositoryImpl implements GamificationRepository {
  final StreakCalculatorService _streakCalculator;
  final AchievementService _achievementService;

  // Cache
  StreakEntity? _cachedStreak;
  GamificationEntity? _cachedGamification;

  // Stream controllers
  final _streakController = StreamController<StreakEntity>.broadcast();
  final _gamificationController = StreamController<GamificationEntity>.broadcast();

  GamificationRepositoryImpl({
    StreakCalculatorService? streakCalculator,
    AchievementService? achievementService,
  })  : _streakCalculator = streakCalculator ?? StreakCalculatorService(),
        _achievementService = achievementService ?? AchievementService();

  // SharedPreferences keys
  static const String _streakStartKey = 'streak_start_date';
  static const String _streakCountKey = 'streak_count';
  static const String _bestStreakKey = 'best_streak';
  static const String _totalScoreKey = 'total_score';
  static const String _unlockedAchievementsKey = 'unlocked_achievements';

  @override
  Future<StreakEntity> getCurrentStreak() async {
    if (_cachedStreak != null) return _cachedStreak!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final streakCount = prefs.getInt(_streakCountKey) ?? 0;
      final bestStreak = prefs.getInt(_bestStreakKey) ?? 0;
      final startDateMillis = prefs.getInt(_streakStartKey) ??
          DateTime.now().millisecondsSinceEpoch;

      _cachedStreak = StreakEntity(
        currentStreak: streakCount,
        bestStreak: bestStreak,
        streakStartDate: DateTime.fromMillisecondsSinceEpoch(startDateMillis),
        lastBrokenDate: DateTime.now(),
      );

      return _cachedStreak!;
    } catch (e) {
      // Return initial streak on error
      return StreakEntity.initial();
    }
  }

  @override
  Future<void> updateStreak() async {
    // This is called by the provider after transactions change
    // The actual calculation happens in the provider which has access to budget data
    // Here we just persist the updated streak
    if (_cachedStreak != null) {
      await _saveStreak(_cachedStreak!);
      _streakController.add(_cachedStreak!);
    }
  }

  @override
  Future<void> resetStreak() async {
    _cachedStreak = StreakEntity.initial();
    await _saveStreak(_cachedStreak!);
    _streakController.add(_cachedStreak!);
  }

  @override
  Future<GamificationEntity> getGamificationState() async {
    if (_cachedGamification != null) return _cachedGamification!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final totalScore = prefs.getInt(_totalScoreKey) ?? 0;
      final achievementsJson = prefs.getString(_unlockedAchievementsKey);

      final achievements = <Achievement>[];
      if (achievementsJson != null && achievementsJson.isNotEmpty) {
        // Parse JSON and create achievements
        // For now, return empty list - implementation would deserialize JSON
      }

      final currentLevel = (totalScore / 100).floor() + 1;
      final progressInLevel = (totalScore % 100) / 100;

      _cachedGamification = GamificationEntity(
        unlockedAchievements: achievements,
        totalScore: totalScore,
        currentLevel: currentLevel,
        nextLevelScore: currentLevel * 100,
        progressToNextLevel: progressInLevel,
      );

      return _cachedGamification!;
    } catch (e) {
      return GamificationEntity.initial();
    }
  }

  @override
  Future<void> unlockAchievement(String achievementId) async {
    // Implementation would add achievement to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    // TODO: Implement achievement serialization
    await _invalidateGamificationCache();
  }

  @override
  Future<List<Achievement>> checkForNewAchievements() async {
    // This is called by the provider with actual data
    // Repository just handles persistence
    return [];
  }

  @override
  Stream<StreakEntity> observeStreak() {
    getCurrentStreak();
    return _streakController.stream;
  }

  @override
  Stream<GamificationEntity> observeGamificationState() {
    getGamificationState();
    return _gamificationController.stream;
  }

  Future<void> _saveStreak(StreakEntity streak) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_streakCountKey, streak.currentStreak);
    await prefs.setInt(_bestStreakKey, streak.bestStreak);
    await prefs.setInt(_streakStartKey, streak.streakStartDate.millisecondsSinceEpoch);
  }

  Future<void> _invalidateGamificationCache() async {
    _cachedGamification = null;
    final gamification = await getGamificationState();
    _gamificationController.add(gamification);
  }

  void dispose() {
    _streakController.close();
    _gamificationController.close();
  }
}
