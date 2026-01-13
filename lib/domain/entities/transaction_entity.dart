import '../value_objects/money.dart';
import '../value_objects/transaction_date.dart';

/// Transaction entity - core business object in the domain layer
/// Framework-independent, contains only business logic
class TransactionEntity {
  final String id;
  final Money amount;
  final String category;
  final TransactionDate date;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Business rule: Is this an expense (negative amount)?
  bool get isExpense => amount.value < 0;

  /// Business rule: Is this income (positive amount)?
  bool get isIncome => amount.value > 0;

  /// Business rule: Get absolute amount for calculations
  double get absoluteAmount => amount.value.abs();

  /// Factory to create from domain values
  factory TransactionEntity.create({
    required String id,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) {
    final now = DateTime.now();
    return TransactionEntity(
      id: id,
      amount: Money(amount),
      category: category,
      date: TransactionDate(date),
      note: note,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Copy with method for immutability
  TransactionEntity copyWith({
    String? id,
    Money? amount,
    String? category,
    TransactionDate? date,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
