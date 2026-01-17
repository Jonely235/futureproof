/// Category classification value object
/// Encapsulates business rules for Needs vs. Wants classification
class CategoryClassification {
  final CategoryType type;
  final String category;

  const CategoryClassification._({
    required this.type,
    required this.category,
  });

  /// Factory to determine classification based on category
  factory CategoryClassification.fromCategory(String category) {
    final normalized = category.toLowerCase().trim();

    // Needs: Essential for survival/basic functioning
    if (_needsCategories.contains(normalized)) {
      return CategoryClassification._(
        type: CategoryType.need,
        category: category,
      );
    }

    // Wants: Nice-to-have but not essential
    if (_wantsCategories.contains(normalized)) {
      return CategoryClassification._(
        type: CategoryType.want,
        category: category,
      );
    }

    // Income doesn't classify as need/want
    return CategoryClassification._(
      type: CategoryType.neutral,
      category: category,
    );
  }

  /// Business rule: Categories classified as NEEDS
  static const Set<String> _needsCategories = {
    'housing',      // Rent/mortgage, utilities
    'groceries',    // Food at home
    'health',       // Medical, prescriptions
    'transport',    // Commute, car maintenance
  };

  /// Business rule: Categories classified as WANTS
  static const Set<String> _wantsCategories = {
    'dining',          // Restaurants, takeout
    'entertainment',   // Movies, games, events
    'shopping',        // Non-essential purchases
    'subscriptions',   // Streaming, services
  };

  /// Business rule: Is this a need?
  bool get isNeed => type == CategoryType.need;

  /// Business rule: Is this a want?
  bool get isWant => type == CategoryType.want;

  /// Business rule: Should this be restricted in War Mode (Red)?
  bool get shouldBeRestricted => type == CategoryType.want;

  @override
  bool operator ==(Object other) =>
      other is CategoryClassification &&
      other.type == type &&
      other.category == category;

  @override
  int get hashCode => Object.hash(type, category);

  @override
  String toString() => 'CategoryClassification($category, $type)';
}

/// Category type enum
enum CategoryType { need, want, neutral }
