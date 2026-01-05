/// Household model for multi-user finance tracking
class Household {
  final String id;
  final String name;
  final List<String> memberIds;
  final DateTime createdAt;
  final double? monthlyIncome;
  final double? savingsGoal;

  Household({
    required this.id,
    required this.name,
    required this.memberIds,
    required this.createdAt,
    this.monthlyIncome,
    this.savingsGoal,
  });

  /// Create from Firestore document
  factory Household.fromMap(Map<String, dynamic> map, String id) {
    return Household(
      id: id,
      name: map['name'] as String,
      memberIds: List<String>.from(map['members'] as List),
      createdAt: DateTime.parse(map['createdAt'] as String),
      monthlyIncome: (map['monthlyIncome'] as num?)?.toDouble(),
      savingsGoal: (map['savingsGoal'] as num?)?.toDouble(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'members': memberIds,
      'createdAt': createdAt.toIso8601String(),
      'monthlyIncome': monthlyIncome,
      'savingsGoal': savingsGoal,
    };
  }

  /// Get number of members
  int get memberCount => memberIds.length;

  /// Check if user is a member
  bool hasMember(String userId) => memberIds.contains(userId);

  /// Copy with method
  Household copyWith({
    String? id,
    String? name,
    List<String>? memberIds,
    DateTime? createdAt,
    double? monthlyIncome,
    double? savingsGoal,
  }) {
    return Household(
      id: id ?? this.id,
      name: name ?? this.name,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      savingsGoal: savingsGoal ?? this.savingsGoal,
    );
  }
}
