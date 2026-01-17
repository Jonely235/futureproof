import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/entities/virtual_vault_entity.dart';
import '../domain/entities/war_mode_entity.dart';
import '../domain/entities/transaction_entity.dart';
import '../domain/repositories/transaction_repository.dart';
import '../domain/repositories/anti_fragile_settings_repository.dart';
import '../domain/services/anti_fragile_wallet_service.dart';
import '../domain/value_objects/category_classification.dart';

/// Provider for Anti-Fragile Wallet state
/// Manages Virtual Vault and War Mode calculations
class AntiFragileWalletProvider extends ChangeNotifier {
  final TransactionRepository _transactionRepository;
  final AntiFragileSettingsRepository _settingsRepository;

  // State
  VirtualVaultEntity? _virtualVault;
  WarModeEntity? _warMode;
  List<TransactionEntity> _transactions = [];
  VirtualVaultSettings? _settings;

  // Loading state
  bool _isLoading = false;
  String? _error;

  // Stream subscriptions
  StreamSubscription? _settingsSubscription;
  StreamSubscription? _transactionsSubscription;

  AntiFragileWalletProvider({
    required TransactionRepository transactionRepository,
    required AntiFragileSettingsRepository settingsRepository,
  })  : _transactionRepository = transactionRepository,
        _settingsRepository = settingsRepository {
    _initialize();
  }

  // Getters
  VirtualVaultEntity? get virtualVault => _virtualVault;
  WarModeEntity? get warMode => _warMode;
  bool get isLoading => _isLoading;
  String? get error => _error;
  VirtualVaultSettings? get settings => _settings;

  /// Business rule: Should show "Available Now" on home screen?
  bool get shouldShowAvailableNow => _virtualVault != null;

  /// Business rule: Should apply War Mode restrictions?
  bool get shouldRestrictWants => _warMode?.shouldRestrictWants ?? false;

  /// Business rule: Get current War Mode level
  WarModeLevel get warModeLevel => _warMode?.level ?? WarModeLevel.green;

  /// Initialize: Load transactions and settings
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load transactions with error handling
      try {
        _transactions = await _transactionRepository.getAllTransactions();
      } catch (e) {
        _transactions = []; // Default to empty list on error
        _error = 'Failed to load transactions: $e';
      }

      // Load settings with error handling
      try {
        _settings = await _loadSettingsOnce();
      } catch (e) {
        // Use default settings if loading fails
        _settings = const VirtualVaultSettings(
          monthlyBills: 0.0,
          minimumReserve: 500.0,
          savingsGoal: 0.0,
          totalCash: 0.0,
        );
        _error = 'Failed to load settings, using defaults: $e';
      }

      // Calculate metrics
      await _recalculate();

      // Listen for settings changes
      _settingsSubscription = _settingsRepository.observeSettings().listen(
        (settings) {
          _settings = settings;
          _recalculate();
        },
        onError: (error) {
          _error = 'Settings stream error: $error';
          notifyListeners();
        },
      );

      // Listen for transaction changes
      _transactionsSubscription = _transactionRepository
          .observeTransactions()
          .listen(
        (transactions) {
          _transactions = transactions;
          _recalculate();
        },
        onError: (error) {
          _error = 'Transaction stream error: $error';
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Initialization failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recalculate all anti-fragile metrics
  Future<void> _recalculate() async {
    if (_settings == null) return;

    try {
      // Calculate Virtual Vault
      _virtualVault = AntiFragileWalletService.calculateVirtualVault(
        totalCash: _settings!.totalCash,
        monthlyBills: _settings!.monthlyBills,
        minimumReserve: _settings!.minimumReserve,
        savingsGoal: _settings!.savingsGoal,
      );

      // Calculate War Mode
      _warMode = AntiFragileWalletService.calculateWarMode(
        currentCash: _settings!.totalCash,
        transactions: _transactions,
      );

      notifyListeners();
    } catch (e) {
      _error = 'Calculation failed: $e';
      notifyListeners();
    }
  }

  /// Update settings
  Future<void> updateSettings({
    double? monthlyBills,
    double? minimumReserve,
    double? savingsGoal,
    double? totalCash,
  }) async {
    try {
      if (monthlyBills != null) {
        await _settingsRepository.setMonthlyBills(monthlyBills);
      }
      if (minimumReserve != null) {
        await _settingsRepository.setMinimumReserve(minimumReserve);
      }
      if (savingsGoal != null) {
        await _settingsRepository.setSavingsGoal(savingsGoal);
      }
      if (totalCash != null) {
        await _settingsRepository.setTotalCash(totalCash);
      }

      // Metrics will auto-update via stream listener
    } catch (e) {
      _error = 'Failed to update settings: $e';
      notifyListeners();
    }
  }

  /// Check if a category should be restricted
  bool isCategoryRestricted(String category) {
    if (_warMode == null) return false;
    return AntiFragileWalletService.shouldRestrictCategory(
      category: category,
      warMode: _warMode!,
    );
  }

  /// Get spending breakdown by type
  Map<CategoryType, double> getSpendingByType() {
    return AntiFragileWalletService.getSpendingBreakdown(
      transactions: _transactions,
    );
  }

  /// Get classification for a category
  CategoryClassification classifyCategory(String category) {
    return AntiFragileWalletService.classifyCategory(category);
  }

  Future<VirtualVaultSettings> _loadSettingsOnce() async {
    return VirtualVaultSettings(
      monthlyBills: await _settingsRepository.getMonthlyBills(),
      minimumReserve: await _settingsRepository.getMinimumReserve(),
      savingsGoal: await _settingsRepository.getSavingsGoal(),
      totalCash: await _settingsRepository.getTotalCash(),
    );
  }

  /// Refresh metrics
  Future<void> refresh() async {
    _transactions = await _transactionRepository.getAllTransactions();
    _settings = await _loadSettingsOnce();
    await _recalculate();
  }

  /// Clear any error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    _transactionsSubscription?.cancel();
    super.dispose();
  }
}
