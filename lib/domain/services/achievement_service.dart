import '../entities/gamification_entity.dart';
import '../entities/streak_entity.dart';
import '../entities/transaction_entity.dart';

/// Achievement service - business logic for unlocking achievements
class AchievementService {
  /// Check for new achievements based on user activity
  List<Achievement> checkAchievements({
    required StreakEntity streak,
    required List<TransactionEntity> transactions,
    required GamificationEntity currentGamification,
    required double totalSaved,
  }) {
    final newAchievements = <Achievement>[];
    final unlockedIds = currentGamification.unlockedAchievements.map((a) => a.id).toSet();

    // Check streak achievements
    final streakAchievement = _checkStreakAchievement(streak, unlockedIds);
    if (streakAchievement != null) {
      newAchievements.add(streakAchievement);
    }

    // Check savings achievements
    final savingsAchievement = _checkSavingsAchievement(totalSaved, unlockedIds);
    if (savingsAchievement != null) {
      newAchievements.add(savingsAchievement);
    }

    // Check consistency achievements (transaction count)
    final consistencyAchievement = _checkConsistencyAchievement(
      transactions.length,
      unlockedIds,
    );
    if (consistencyAchievement != null) {
      newAchievements.add(consistencyAchievement);
    }

    // Check milestone achievements
    final milestoneAchievement = _checkMilestoneAchievement(
      totalSaved,
      unlockedIds,
    );
    if (milestoneAchievement != null) {
      newAchievements.add(milestoneAchievement);
    }

    return newAchievements;
  }

  /// Check streak-related achievements
  Achievement? _checkStreakAchievement(
    StreakEntity streak,
    Set<String> unlockedIds,
  ) {
    if (streak.currentStreak >= 30 && !unlockedIds.contains('streak_30')) {
      return Achievement(
        id: 'streak_30',
        title: 'Month Master',
        description: '30-day budget streak',
        icon: '🏆',
        points: 100,
        unlockedAt: DateTime.now(),
        category: AchievementCategory.streak,
      );
    } else if (streak.currentStreak >= 14 && !unlockedIds.contains('streak_14')) {
      return Achievement(
        id: 'streak_14',
        title: 'Two Week Warrior',
        description: '14-day budget streak',
        icon: '⭐',
        points: 50,
        unlockedAt: DateTime.now(),
        category: AchievementCategory.streak,
      );
    } else if (streak.currentStreak >= 7 && !unlockedIds.contains('streak_7')) {
      return Achievement(
        id: 'streak_7',
        title: 'Week Warrior',
        description: '7-day budget streak',
        icon: '🌟',
        points: 25,
        unlockedAt: DateTime.now(),
        category: AchievementCategory.streak,
      );
    } else if (streak.currentStreak >= 3 && !unlockedIds.contains('streak_3')) {
      return Achievement(
        id: 'streak_3',
        title: 'Getting Started',
        description: '3-day budget streak',
        icon: '🎯',
        points: 10,
        unlockedAt: DateTime.now(),
        category: AchievementCategory.streak,
      );
    }
    return null;
  }

  /// Check savings-related achievements
  Achievement? _checkSavingsAchievement(
    double totalSaved,
    Set<String> unlockedIds,
  ) {
    if (totalSaved >= 1000 && !unlockedIds.contains('savings_1k')) {
      return Achievement(
        id: 'savings_1k',
        title: 'Grand Saver',
        description: 'Saved \$1,000 total',
        icon: '💰',
        points: 75,
        unlockedAt: DateTime.now(),
        category: AchievementCategory.savings,
      );
    } else if (totalSaved >= 500 && !unlockedIds.contains('savings_500')) {
      return Achievement(
        id: 'savings_500',
        title: 'Half Grand',
        description: 'Saved \$500 total',
        icon: '💵',
        points: 40,
        unlockedAt: DateTime.now(),
        category: AchievementCategory.savings,
      );
    } else if (totalSaved >= 100 && !unlockedIds.contains('savings_100')) {
      return Achievement(
        id: 'savings_100',
        title: 'Century Saver',
        description: 'Saved \$100 total',
        icon: '💎',
        points: 20,
        unlockedAt: DateTime.now(),
        category: AchievementCategory.savings,
      );
    }
    return null;
  }

  /// Check consistency achievements
  Achievement? _checkConsistencyAchievement(
    int transactionCount,
    Set<String> unlockedIds,
  ) {
    if (transactionCount >= 100 && !unlockedIds.contains('consistent_100')) {
      return Achievement(
        id: 'consistent_100',
        title: 'Century Tracker',
        description: 'Recorded 100 transactions',
        icon: '📊',
        points: 30,
        unlockedAt: DateTime.now(),
        category: AchievementCategory.consistency,
      );
    } else if (transactionCount >= 50 && !unlockedIds.contains('consistent_50')) {
      return Achievement(
        id: 'consistent_50',
        title: 'Half Century',
        description: 'Recorded 50 transactions',
        icon: '📝',
        points: 15,
        unlockedAt: DateTime.now(),
        category: AchievementCategory.consistency,
      );
    } else if (transactionCount >= 10 && !unlockedIds.contains('consistent_10')) {
      return Achievement(
        id: 'consistent_10',
        title: 'Getting Organized',
        description: 'Recorded 10 transactions',
        icon: '✅',
        points: 5,
        unlockedAt: DateTime.now(),
        category: AchievementCategory.consistency,
      );
    }
    return null;
  }

  /// Check milestone achievements
  Achievement? _checkMilestoneAchievement(
    double totalSaved,
    Set<String> unlockedIds,
  ) {
    // First achievement when user starts tracking
    if (totalSaved > 0 && !unlockedIds.contains('first_save')) {
      return Achievement(
        id: 'first_save',
        title: 'First Steps',
        description: 'Started your financial journey',
        icon: '🚀',
        points: 5,
        unlockedAt: DateTime.now(),
        category: AchievementCategory.milestone,
      );
    }
    return null;
  }
}
