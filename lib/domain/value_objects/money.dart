/// Money value object - represents monetary values in the domain
/// Ensures valid money values and encapsulates currency logic
class Money {
  final double value;

  const Money(this.value);

  /// Business rule: Money cannot be NaN or infinity
  bool get isValid => !value.isNaN && !value.isInfinite;

  /// Business rule: Money is positive (income)
  bool get isPositive => value > 0;

  /// Business rule: Money is negative (expense)
  bool get isNegative => value < 0;

  /// Business rule: Money is zero
  bool get isZero => value == 0;

  /// Add two money values
  Money add(Money other) {
    return Money(value + other.value);
  }

  /// Subtract money value
  Money subtract(Money other) {
    return Money(value - other.value);
  }

  /// Get absolute value
  Money get absolute => Money(value.abs());

  /// Format as currency string
  String format() {
    if (value >= 0) {
      return '+\$${value.toStringAsFixed(2)}';
    } else {
      return '-\$${value.abs().toStringAsFixed(2)}';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Money && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => format();
}
