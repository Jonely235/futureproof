class Transaction {
  // Validation constants
  static const double _minAmount = -1000000.0;
  static const double _maxAmount = 1000000.0;
  static const int _maxNoteLength = 500;
  static const int _maxIdLength = 100;
  static const int _maxCategoryLength = 50;

  static const List<String> _validCategories = [
    'housing',
    'groceries',
    'dining',
    'transport',
    'entertainment',
    'health',
    'shopping',
    'subscriptions',
    'income',
  ];

  final String id;
  final double amount;
  final String category;
  final String? note;
  final DateTime date;
  final String householdId;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.amount,
    required this.category,
    this.note,
    required this.date,
    this.householdId = '',
    DateTime? createdAt,
  })  : assert(id.trim().isNotEmpty, 'ID cannot be empty'),
        assert(id.length <= _maxIdLength, 'ID too long'),
        assert(amount >= _minAmount && amount <= _maxAmount, 'Amount out of range'),
        assert(category.trim().isNotEmpty, 'Category cannot be empty'),
        assert(category.length <= _maxCategoryLength, 'Category too long'),
        assert(note == null || note.length <= _maxNoteLength, 'Note too long'),
        createdAt = createdAt ?? DateTime.now() {
    final normalizedCategory = category.toLowerCase().trim();
    if (!_validCategories.contains(normalizedCategory)) {
      throw ArgumentError(
        'Invalid category: $category. Must be one of: ${_validCategories.join(", ")}',
      );
    }
  }

  factory Transaction.fromMap(Map<String, dynamic> map, String id) {
    return Transaction(
      id: id,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      householdId: map['household_id'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  factory Transaction.fromSqliteMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      note: map['note'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      householdId: map['householdId'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
      'household_id': householdId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isIncome => amount > 0;
  bool get isExpense => amount < 0;

  String get formattedAmount => '\$${amount.abs().toStringAsFixed(2)}';

  String get categoryEmoji {
    final categoryLower = category.toLowerCase();
    const emojiMap = {
      'housing': '🏠',
      'groceries': '🛒',
      'dining': '🍽️',
      'transport': '🚗',
      'entertainment': '🎭',
      'health': '💊',
      'shopping': '🛍️',
      'subscriptions': '📱',
      'income': '💰',
    };
    return emojiMap[categoryLower] ?? '💸';
  }
}
