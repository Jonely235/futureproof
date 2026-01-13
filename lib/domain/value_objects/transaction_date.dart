/// TransactionDate value object - wraps DateTime with date-specific business logic
class TransactionDate {
  final DateTime value;

  const TransactionDate(this.value);

  /// Get date at midnight (strip time)
  DateTime get dateOnly =>
      DateTime(value.year, value.month, value.day);

  /// Business rule: Is this transaction today?
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dateOnly == today;
  }

  /// Business rule: Is this transaction within the current month?
  bool get isThisMonth {
    final now = DateTime.now();
    return value.year == now.year && value.month == now.month;
  }

  /// Business rule: Get days since this transaction
  int daysSince() {
    final now = DateTime.now();
    final difference = now.difference(value);
    return difference.inDays;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionDate && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toIso8601String();
}
