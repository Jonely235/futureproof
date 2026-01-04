class Transaction {
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
    required this.householdId,
    required this.createdAt,
  });

  // Create from Firestore
  factory Transaction.fromMap(Map<String, dynamic> map, String id) {
    return Transaction(
      id: id,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      householdId: map['household_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Convert to Firestore
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

  // Check if transaction is income
  bool get isIncome => amount > 0;

  // Check if transaction is expense
  bool get isExpense => amount < 0;

  // Get formatted amount
  String get formattedAmount {
    return '\$${amount.abs().toStringAsFixed(2)}';
  }

  // Get category emoji
  String get categoryEmoji {
    switch (category.toLowerCase()) {
      case 'housing':
        return '🏠';
      case 'groceries':
        return '🛒';
      case 'dining':
        return '🍽️';
      case 'transport':
        return '🚗';
      case 'entertainment':
        return '🎭';
      case 'health':
        return '💊';
      case 'shopping':
        return '🛍️';
      case 'subscriptions':
        return '📱';
      case 'income':
        return '💰';
      default:
        return '💸';
    }
  }
}
