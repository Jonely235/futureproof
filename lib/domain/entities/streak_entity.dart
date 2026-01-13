/// Streak entity - tracks consecutive days under budget
class StreakEntity {
  final int currentStreak;
  final int bestStreak;
  final DateTime streakStartDate;
  final DateTime lastBrokenDate;

  const StreakEntity({
    required this.currentStreak,
    required this.bestStreak,
    required this.streakStartDate,
    required this.lastBrokenDate,
  });

  /// Business rule: Is streak active?
  bool get isActive => currentStreak > 0;

  /// Business rule: Is this a new personal best?
  bool get isNewBest => currentStreak > bestStreak;

  /// Business rule: Get streak milestone
  String get milestone {
    if (currentStreak >= 30) return 'Amazing! 30+ days!';
    if (currentStreak >= 21) return 'Fantastic! 3 weeks!';
    if (currentStreak >= 14) return 'Great! 2 weeks!';
    if (currentStreak >= 7) return 'Good! 1 week!';
    if (currentStreak >= 3) return 'Keep going!';
    if (currentStreak >= 1) return 'Start strong!';
    return 'Begin your streak!';
  }

  /// Business rule: Calculate streak motivation percentage
  double get motivationPercent {
    if (currentStreak >= 30) return 1.0;
    return currentStreak / 30;
  }

  /// Create initial streak
  factory StreakEntity.initial() {
    final now = DateTime.now();
    return StreakEntity(
      currentStreak: 0,
      bestStreak: 0,
      streakStartDate: now,
      lastBrokenDate: now,
    );
  }

  /// Increment streak
  StreakEntity increment() {
    return StreakEntity(
      currentStreak: currentStreak + 1,
      bestStreak: currentStreak + 1 > bestStreak ? currentStreak + 1 : bestStreak,
      streakStartDate: streakStartDate,
      lastBrokenDate: lastBrokenDate,
    );
  }

  /// Reset streak
  StreakEntity reset() {
    final now = DateTime.now();
    return StreakEntity(
      currentStreak: 0,
      bestStreak: bestStreak,
      streakStartDate: now,
      lastBrokenDate: now,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreakEntity &&
        other.currentStreak == currentStreak &&
        other.bestStreak == bestStreak;
  }

  @override
  int get hashCode => currentStreak.hashCode ^ bestStreak.hashCode;
}
