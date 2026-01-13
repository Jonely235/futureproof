/// Gamification entity - tracks user achievements and badges
class GamificationEntity {
  final List<Achievement> unlockedAchievements;
  final int totalScore;
  final int currentLevel;
  final int nextLevelScore;
  final double progressToNextLevel;

  const GamificationEntity({
    required this.unlockedAchievements,
    required this.totalScore,
    required this.currentLevel,
    required this.nextLevelScore,
    required this.progressToNextLevel,
  });

  /// Business rule: Get level progress percentage
  double get levelProgress {
    if (nextLevelScore == 0) return 0;
    return progressToNextLevel;
  }

  /// Business rule: Is max level reached?
  bool get isMaxLevel => progressToNextLevel >= 1.0;

  /// Create initial gamification state
  factory GamificationEntity.initial() {
    return const GamificationEntity(
      unlockedAchievements: [],
      totalScore: 0,
      currentLevel: 1,
      nextLevelScore: 100,
      progressToNextLevel: 0.0,
    );
  }

  /// Add achievement and recalculate level
  GamificationEntity addAchievement(Achievement achievement) {
    final newScore = totalScore + achievement.points;
    final newLevel = (newScore / 100).floor() + 1;
    final progressInLevel = (newScore % 100) / 100;

    return GamificationEntity(
      unlockedAchievements: [...unlockedAchievements, achievement],
      totalScore: newScore,
      currentLevel: newLevel,
      nextLevelScore: newLevel * 100,
      progressToNextLevel: progressInLevel,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GamificationEntity &&
        other.totalScore == totalScore &&
        other.currentLevel == currentLevel;
  }

  @override
  int get hashCode => totalScore.hashCode ^ currentLevel.hashCode;
}

/// Achievement - represents a single achievement/badge
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int points;
  final DateTime unlockedAt;
  final AchievementCategory category;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.points,
    required this.unlockedAt,
    required this.category,
  });

  /// Business rule: Is this achievement rare (high points)?
  bool get isRare => points >= 50;

  /// Business rule: Is this achievement epic (very high points)?
  bool get isEpic => points >= 100;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Achievement && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Achievement category
enum AchievementCategory {
  streak,
  savings,
  budget,
  consistency,
  milestone,
}
