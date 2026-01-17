import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/anti_fragile_settings_repository.dart';

/// Implementation of anti-fragile settings repository
/// Uses SharedPreferences for persistence
class AntiFragileSettingsRepositoryImpl
    implements AntiFragileSettingsRepository {
  static const String _keyMonthlyBills = 'anti_fragile_monthly_bills';
  static const String _keyMinReserve = 'anti_fragile_min_reserve';
  static const String _keySavingsGoal = 'anti_fragile_savings_goal';
  static const String _keyTotalCash = 'anti_fragile_total_cash';

  // Defaults
  static const double _defaultMonthlyBills = 0.0;
  static const double _defaultMinReserve = 500.0; // $500 buffer
  static const double _defaultSavingsGoal = 0.0;
  static const double _defaultTotalCash = 0.0;

  final _controller = StreamController<VirtualVaultSettings>.broadcast();

  @override
  Future<double> getMonthlyBills() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyMonthlyBills) ?? _defaultMonthlyBills;
  }

  @override
  Future<double> getMinimumReserve() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyMinReserve) ?? _defaultMinReserve;
  }

  @override
  Future<double> getSavingsGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keySavingsGoal) ?? _defaultSavingsGoal;
  }

  @override
  Future<double> getTotalCash() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyTotalCash) ?? _defaultTotalCash;
  }

  @override
  Future<void> setMonthlyBills(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMonthlyBills, amount);
    _emitUpdate();
  }

  @override
  Future<void> setMinimumReserve(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMinReserve, amount);
    _emitUpdate();
  }

  @override
  Future<void> setSavingsGoal(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keySavingsGoal, amount);
    _emitUpdate();
  }

  @override
  Future<void> setTotalCash(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTotalCash, amount);
    _emitUpdate();
  }

  @override
  Stream<VirtualVaultSettings> observeSettings() async* {
    // Emit current value immediately
    final settings = await _loadSettings();
    yield settings;

    // Stream subsequent updates
    yield* _controller.stream;
  }

  Future<VirtualVaultSettings> _loadSettings() async {
    return VirtualVaultSettings(
      monthlyBills: await getMonthlyBills(),
      minimumReserve: await getMinimumReserve(),
      savingsGoal: await getSavingsGoal(),
      totalCash: await getTotalCash(),
    );
  }

  void _emitUpdate() {
    _loadSettings().then((settings) {
      if (!_controller.isClosed) {
        _controller.add(settings);
      }
    });
  }

  void dispose() {
    _controller.close();
  }
}
