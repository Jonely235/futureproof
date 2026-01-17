import '../entities/virtual_vault_entity.dart';

/// Repository interface for anti-fragile wallet settings
/// Domain layer defines contract, data layer implements
abstract class AntiFragileSettingsRepository {
  /// Get monthly bills amount
  Future<double> getMonthlyBills();

  /// Get minimum reserve amount
  Future<double> getMinimumReserve();

  /// Get savings goal
  Future<double> getSavingsGoal();

  /// Get total cash on hand
  Future<double> getTotalCash();

  /// Update monthly bills
  Future<void> setMonthlyBills(double amount);

  /// Update minimum reserve
  Future<void> setMinimumReserve(double amount);

  /// Update savings goal
  Future<void> setSavingsGoal(double amount);

  /// Update total cash
  Future<void> setTotalCash(double amount);

  /// Stream settings for reactive updates
  Stream<VirtualVaultSettings> observeSettings();
}

/// Virtual Vault Settings value object
class VirtualVaultSettings {
  final double monthlyBills;
  final double minimumReserve;
  final double savingsGoal;
  final double totalCash;

  const VirtualVaultSettings({
    required this.monthlyBills,
    required this.minimumReserve,
    required this.savingsGoal,
    required this.totalCash,
  });

  VirtualVaultSettings copyWith({
    double? monthlyBills,
    double? minimumReserve,
    double? savingsGoal,
    double? totalCash,
  }) {
    return VirtualVaultSettings(
      monthlyBills: monthlyBills ?? this.monthlyBills,
      minimumReserve: minimumReserve ?? this.minimumReserve,
      savingsGoal: savingsGoal ?? this.savingsGoal,
      totalCash: totalCash ?? this.totalCash,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VirtualVaultSettings &&
      other.monthlyBills == monthlyBills &&
      other.minimumReserve == minimumReserve &&
      other.savingsGoal == savingsGoal &&
      other.totalCash == totalCash;

  @override
  int get hashCode =>
      Object.hash(monthlyBills, minimumReserve, savingsGoal, totalCash);

  @override
  String toString() =>
      'VirtualVaultSettings(bills: \$$monthlyBills, reserve: \$$minimumReserve, '
      'savings: \$$savingsGoal, cash: \$$totalCash)';
}
