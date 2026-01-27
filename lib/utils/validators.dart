/// Money validation utilities
///
/// Provides validation for financial amounts to prevent:
/// - Integer overflow from extremely large values
/// - Floating point precision issues
/// - Invalid number formats
class MoneyValidator {
  // Maximum amount: ~1 billion (prevents overflow issues)
  static const double maxAmount = 999999999.99;

  // Minimum amount for transactions: 1 cent
  static const double minTransactionAmount = 0.01;

  // Minimum amount for optional fields (can be zero)
  static const double minOptionalAmount = 0.0;

  // Maximum decimal places for currency
  static const int maxDecimalPlaces = 2;

  /// Validates an optional monetary amount (can be zero or empty)
  ///
  /// Use this for fields like monthly income, savings goal, etc.
  /// Returns [MoneyValidationResult.success] with the parsed amount if valid,
  /// or [MoneyValidationResult.failure] with an error message if invalid.
  static MoneyValidationResult validateOptional(String input) {
    // Check for empty input (allowed for optional fields)
    if (input.trim().isEmpty) {
      return const MoneyValidationResult.success(0.0);
    }

    // Parse the number
    final amount = double.tryParse(input);
    if (amount == null) {
      return const MoneyValidationResult.failure('Invalid number format');
    }

    // Check for negative values
    if (amount < minOptionalAmount) {
      return const MoneyValidationResult.failure(
        'Amount cannot be negative',
      );
    }

    // Check maximum amount
    if (amount > maxAmount) {
      return MoneyValidationResult.failure(
        'Amount cannot exceed \$${maxAmount.toStringAsFixed(2)}',
      );
    }

    // Check decimal places
    final parts = input.split('.');
    if (parts.length == 2 && parts[1].length > maxDecimalPlaces) {
      return MoneyValidationResult.failure(
        'Maximum $maxDecimalPlaces decimal places allowed',
      );
    }

    return MoneyValidationResult.success(amount);
  }

  /// Validates a monetary amount string
  ///
  /// Returns [MoneyValidationResult.success] with the parsed amount if valid,
  /// or [MoneyValidationResult.failure] with an error message if invalid.
  static MoneyValidationResult validate(String input) {
    // Check for empty input
    if (input.trim().isEmpty) {
      return const MoneyValidationResult.failure('Please enter an amount');
    }

    // Parse the number
    final amount = double.tryParse(input);
    if (amount == null) {
      return const MoneyValidationResult.failure('Invalid number format');
    }

    // Check minimum amount
    if (amount < minTransactionAmount) {
      return MoneyValidationResult.failure(
        'Amount must be at least \$${minTransactionAmount.toStringAsFixed(2)}',
      );
    }

    // Check maximum amount
    if (amount > maxAmount) {
      return MoneyValidationResult.failure(
        'Amount cannot exceed \$${maxAmount.toStringAsFixed(2)}',
      );
    }

    // Check decimal places
    final parts = input.split('.');
    if (parts.length == 2 && parts[1].length > maxDecimalPlaces) {
      return MoneyValidationResult.failure(
        'Maximum $maxDecimalPlaces decimal places allowed',
      );
    }

    return MoneyValidationResult.success(amount);
  }

  /// Validates a monetary amount string with custom bounds
  static MoneyValidationResult validateWithBounds(
    String input, {
    double? min,
    double? max,
  }) {
    final result = validate(input);
    if (!result.isValid) return result;

    final amount = result.value!;
    if (min != null && amount < min) {
      return MoneyValidationResult.failure(
        'Amount must be at least \$${min.toStringAsFixed(2)}',
      );
    }
    if (max != null && amount > max) {
      return MoneyValidationResult.failure(
        'Amount cannot exceed \$${max.toStringAsFixed(2)}',
      );
    }

    return result;
  }
}

/// Result of money validation
class MoneyValidationResult {
  final double? value;
  final String? errorMessage;

  const MoneyValidationResult.success(this.value)
      : errorMessage = null,
        isValid = true;

  const MoneyValidationResult.failure(this.errorMessage)
      : value = null,
        isValid = false;

  final bool isValid;

  @override
  String toString() => isValid ? 'Success: \$${value!.toStringAsFixed(2)}' : 'Error: $errorMessage';
}
