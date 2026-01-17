import '../value_objects/money.dart';

/// Virtual Vault entity
/// Represents the "Available Now" calculation for anti-fragile wallet
///
/// Business Rule: Available Now = Total Cash - (Bills + Minimum Reserve + Savings)
class VirtualVaultEntity {
  final Money totalCash;
  final Money committedFunds;  // Bills + Min Reserve + Savings
  final Money availableNow;
  final DateTime calculatedAt;

  const VirtualVaultEntity({
    required this.totalCash,
    required this.committedFunds,
    required this.availableNow,
    required this.calculatedAt,
  });

  /// Factory to calculate virtual vault from financial data
  factory VirtualVaultEntity.calculate({
    required double totalCash,
    required double monthlyBills,
    required double minimumReserve,
    required double savingsGoal,
  }) {
    final committed = monthlyBills + minimumReserve + savingsGoal;
    final available = totalCash - committed;

    return VirtualVaultEntity(
      totalCash: Money(totalCash),
      committedFunds: Money(committed),
      availableNow: Money(available),
      calculatedAt: DateTime.now(),
    );
  }

  /// Business rule: Is the vault healthy (positive available cash)?
  bool get isHealthy => availableNow.value > 0;

  /// Business rule: Get available percentage of total cash
  double get availablePercentage {
    if (totalCash.value == 0) return 0.0;
    return (availableNow.value / totalCash.value) * 100;
  }

  /// Business rule: Is vault in danger zone (negative or < 10% available)?
  bool get isInDangerZone => availableNow.value <= 0 || availablePercentage < 10;

  /// Business rule: Get vault status message
  String get statusMessage {
    if (!isHealthy) {
      return 'Overdrawn - Emergency';
    } else if (isInDangerZone) {
      return 'Critical - Less than 10% available';
    } else if (availablePercentage < 25) {
      return 'Low - Tread carefully';
    } else if (availablePercentage < 50) {
      return 'Moderate - Room to breathe';
    } else {
      return 'Healthy - Plenty available';
    }
  }

  @override
  bool operator ==(Object other) =>
      other is VirtualVaultEntity &&
      other.totalCash == totalCash &&
      other.committedFunds == committedFunds &&
      other.availableNow == availableNow;

  @override
  int get hashCode => Object.hash(totalCash, committedFunds, availableNow);

  @override
  String toString() =>
      'VirtualVaultEntity(available: \$${availableNow.value.toStringAsFixed(2)}, '
      'vaulted: \$${committedFunds.value.toStringAsFixed(2)})';
}
