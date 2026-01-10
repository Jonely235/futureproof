# Detailed Phase 2 & 3 Task Guides

> **Supplement to tasks.md**
> This file provides enhanced details for Phase 2 and Phase 3 tasks.
> **Created**: 2026-01-10 (Iteration 5)

---

## Task 2.2: Update Services to Use Config (Detailed)

### 🔍 Why This Matters
Completes the configuration refactoring by actually using the config class throughout the codebase. This eliminates all remaining magic numbers.

### Impact
- **Current**: Magic numbers like `0.1`, `10`, `3` scattered in services
- **After Fix**: All business logic uses centralized config

### Part 1: Update FinanceCalculator

#### Step-by-Step Instructions

**Step 1: Open the file**
```bash
code lib/services/finance_calculator.dart
```

**Step 2: Add import**
At the top of the file (around line 4):
```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/finance_config.dart';  // ✅ ADD THIS LINE
```

**Step 3: Replace buffer calculation**
Find line 50 in `calculateStatus` method:
```dart
// BEFORE:
final buffer = monthlyIncome * 0.1; // 10% buffer

// AFTER:
final config = FinanceConfig.instance;
final buffer = config.calculateBuffer(monthlyIncome);
// OR equivalently:
final buffer = monthlyIncome * config.bufferPercentage;
```

**Step 4: Verify changes**
```bash
flutter analyze lib/services/finance_calculator.dart
flutter test test/services/finance_calculator_test.dart
```

### Part 2: Update AnalyticsService

#### Step-by-Step Instructions

**Step 1: Open the file**
```bash
code lib/services/analytics_service.dart
```

**Step 2: Add import**
At the top:
```dart
import '../models/spending_analysis.dart';
import '../models/transaction.dart' as model;
import 'database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/finance_config.dart';  // ✅ ADD THIS LINE
```

**Step 3: Update health score calculation**
Find `getFinancialHealthScore` method (around line 129-164) and replace:

```dart
// BEFORE:
Future<int> getFinancialHealthScore() async {
  final analysis = await analyzeSpending();
  final prefs = await SharedPreferences.getInstance();
  final monthlyIncome = prefs.getDouble('monthly_income') ?? 0.0;
  final savingsGoal = prefs.getDouble('savings_goal') ?? 0.0;

  int score = 100;

  final overBudgetCount = analysis.budgetComparisons.values
      .where((comparison) => comparison.isOverBudget)
      .length;

  score -= overBudgetCount * 10;  // ❌ MAGIC NUMBER

  if (analysis.anomalies.length > 3) {  // ❌ MAGIC NUMBER
    score -= 10;  // ❌ MAGIC NUMBER
  } else if (analysis.anomalies.length > 1) {  // ❌ MAGIC NUMBER
    score -= 5;  // ❌ MAGIC NUMBER
  }

  final savings = monthlyIncome - analysis.totalSpending;
  if (savings >= savingsGoal && savingsGoal > 0) {
    score += 5;  // ❌ MAGIC NUMBER
  }

  if (!analysis.isTrendingUp) {
    score += 5;  // ❌ MAGIC NUMBER
  }

  return score.clamp(0, 100);
}

// AFTER:
Future<int> getFinancialHealthScore() async {
  final analysis = await analyzeSpending();
  final prefs = await SharedPreferences.getInstance();
  final monthlyIncome = prefs.getDouble('monthly_income') ?? 0.0;
  final savingsGoal = prefs.getDouble('savings_goal') ?? 0.0;

  final config = FinanceConfig.instance;  // ✅ ADD THIS
  int score = 100;

  final overBudgetCount = analysis.budgetComparisons.values
      .where((comparison) => comparison.isOverBudget)
      .length;

  score -= overBudgetCount * config.overBudgetPenalty;  // ✅ USE CONFIG

  // Use helper method for anomaly penalty
  score -= config.calculateAnomalyPenalty(analysis.anomalies.length);  // ✅ USE CONFIG

  final savings = monthlyIncome - analysis.totalSpending;
  if (savings >= savingsGoal && savingsGoal > 0) {
    score += config.savingsGoalBonus;  // ✅ USE CONFIG
  }

  if (!analysis.isTrendingUp) {
    score += config.trendingDownBonus;  // ✅ USE CONFIG
  }

  return score.clamp(0, 100);
}
```

### Migration Checklist

**FinanceCalculator**
- [ ] Buffer percentage (0.1) → `config.bufferPercentage`
- [ ] Search for other hardcoded values

**AnalyticsService**
- [ ] Over-budget penalty (10) → `config.overBudgetPenalty`
- [ ] Anomaly thresholds → `config.calculateAnomalyPenalty()`
- [ ] Anomaly penalties → `config.calculateAnomalyPenalty()`
- [ ] Savings goal bonus (5) → `config.savingsGoalBonus`
- [ ] Trending down bonus (5) → `config.trendingDownBonus`

### Testing After Changes
```bash
# 1. Run all tests
flutter test

# 2. Check analyzer
flutter analyze

# 3. Test manually
flutter run -d chrome

# Verify:
# - "Are We Okay?" button uses correct buffer
# - Analytics dashboard shows correct health score
# - Anomaly detection works with new thresholds
```

---

## Task 2.3: Create Transaction Provider (Detailed)

### Complete Provider Implementation

**Step 1: Create directory**
```bash
mkdir lib/providers
```

**Step 2: Create provider file**
```bash
code lib/providers/transaction_provider.dart
```

**Step 3: Full implementation**
```dart
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

/// Centralized state management for transactions.
class TransactionProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  // Private state
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // Public getters
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get transactions by category
  Map<String, List<Transaction>> get transactionsByCategory {
    final Map<String, List<Transaction>> grouped = {};
    for (final transaction in _transactions) {
      grouped.putIfAbsent(transaction.category, () => []).add(transaction);
    }
    return grouped;
  }

  /// Get total expenses
  double get totalExpenses {
    return _transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount.abs());
  }

  /// Get total income
  double get totalIncome {
    return _transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Load all transactions
  Future<void> loadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _db.getAllTransactions();
    } catch (e) {
      _error = 'Failed to load transactions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add transaction
  Future<bool> addTransaction(Transaction transaction) async {
    try {
      await _db.addTransaction(transaction);
      await loadTransactions();
      return true;
    } catch (e) {
      _error = 'Failed to add transaction: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update transaction
  Future<bool> updateTransaction(Transaction transaction) async {
    try {
      final success = await _db.updateTransaction(transaction);
      if (success) await loadTransactions();
      return success;
    } catch (e) {
      _error = 'Failed to update: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete transaction
  Future<bool> deleteTransaction(String id) async {
    try {
      final success = await _db.deleteTransaction(id);
      if (success) await loadTransactions();
      return success;
    } catch (e) {
      _error = 'Failed to delete: $e';
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
```

**Step 4: Create barrel file**
```dart
// lib/providers/providers.dart
library;

export 'transaction_provider.dart';
```

**Step 5: Update main.dart**
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/main_navigation.dart';
import 'providers/transaction_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        title: 'FutureProof',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MainNavigation(),
      ),
    );
  }
}
```

### Provider Usage Examples

```dart
// Watch for automatic updates
class TransactionList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();

    if (provider.isLoading) {
      return CircularProgressIndicator();
    }

    return ListView.builder(
      itemCount: provider.transactions.length,
      itemBuilder: (context, index) {
        return TransactionTile(provider.transactions[index]);
      },
    );
  }
}

// Read without listening
void _handleAdd(BuildContext context) async {
  final provider = context.read<TransactionProvider>();
  await provider.addTransaction(transaction);
}
```

---

## Phase 3: Testing - Additional Detail

### Test Structure Best Practices

```
test/
├── models/
│   ├── transaction_test.dart          (Task 3.1)
│   └── transaction_validation_test.dart (Task 1.4)
├── services/
│   ├── finance_calculator_test.dart   (Task 3.2)
│   ├── database_service_test.dart     (Task 3.3)
│   └── analytics_service_test.dart    (Task 3.2)
├── providers/
│   └── transaction_provider_test.dart  (Task 2.3)
├── config/
│   └── finance_config_test.dart       (Task 2.1)
└── integration_test/
    └── app_test.dart                   (Task 3.4)
```

### Test Naming Conventions

```dart
// Good test names
test('should return correct total for expenses', () { });
test('should reject negative amounts', () { });
test('should throw when category is invalid', () { });

// Bad test names
test('test1', () { });
test('it works', () { });
test('total', () { });
```

### Test Structure Pattern

```dart
void main() {
  group('ClassName', () {
    late ClassName instance;

    setUp(() {
      // Setup before each test
      instance = ClassName();
    });

    tearDown(() {
      // Cleanup after each test
    });

    group('methodName', () {
      test('should do something when condition is met', () {
        // Arrange
        final input = ...;

        // Act
        final result = instance.methodName(input);

        // Assert
        expect(result, expectedOutput);
      });
    });
  });
}
```

### Coverage Goals by Module

| Module | Target Coverage | Priority |
|--------|----------------|----------|
| Models | 90%+ | High (core data) |
| Services | 85%+ | High (business logic) |
| Providers | 80%+ | Medium (state mgmt) |
| Screens | 60%+ | Low (UI focused) |
| Config | 100% | High (constants) |

---

## Quick Reference: All Config Constants

```dart
class FinanceConfig {
  // Buffer
  static const double bufferPercentage = 0.10;

  // Anomalies
  static const int anomalyThresholdHigh = 3;
  static const int anomalyThresholdMedium = 1;
  static const int anomalyPenaltyHigh = 10;
  static const int anomalyPenaltyMedium = 5;

  // Health Score
  static const int overBudgetPenalty = 10;
  static const int savingsGoalBonus = 5;
  static const int trendingDownBonus = 5;
}
```

---

**Last Updated**: 2026-01-10
**Iteration**: 5 of 20
**Related File**: tasks.md (main task list)
