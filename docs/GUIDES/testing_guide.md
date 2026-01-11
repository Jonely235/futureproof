# Comprehensive Testing Guide for FutureProof

> **Complete testing strategy and implementation guide**
> **Created**: 2026-01-10
> **Updated**: January 11, 2026

---

## 📋 Table of Contents
1. [Testing Strategy Overview](#testing-strategy-overview)
2. [Test Structure](#test-structure)
3. [Unit Tests](#unit-tests)
4. [Widget Tests](#widget-tests)
5. [Integration Tests](#integration-tests)
6. [Test Coverage](#test-coverage)
7. [Testing Checklist](#testing-checklist)

---

## 🎯 Testing Strategy Overview

### Testing Pyramid

```
        /\
       /  \      E2E Tests (5%)
      /____\     - Critical user flows only
     /      \    - Slow, brittle
    /________\
   /          \  Integration Tests (15%)
  /  Widget    \ - Service integration
 /_____________\ - Medium speed
/   Unit Tests  \ (80%)
/________________\
  - Fast, reliable
  - Business logic
```

### Coverage Goals

| Layer | Target | Current | Priority |
|-------|--------|---------|----------|
| Unit Tests | 80% | 0% | 🔴 Critical |
| Widget Tests | 60% | 0% | 🟡 Medium |
| Integration Tests | Key Flows | 0% | 🟡 Medium |
| E2E Tests | Critical Path | 0% | 🟢 Low |

---

## 📁 Test Structure

### Directory Layout

```
test/
├── models/                              # Unit tests for models
│   ├── transaction_test.dart           # Basic model tests
│   ├── transaction_validation_test.dart # Validation tests
│   ├── household_test.dart
│   └── spending_analysis_test.dart
│
├── services/                            # Unit tests for services
│   ├── finance_calculator_test.dart    # Calculation logic
│   ├── analytics_service_test.dart     # Analytics logic
│   └── database_service_test.dart      # Database operations
│
├── providers/                           # State management tests
│   └── transaction_provider_test.dart
│
├── screens/                             # Widget tests
│   ├── home_screen_test.dart
│   ├── add_expense_screen_test.dart
│   └── transaction_history_screen_test.dart
│
├── widgets/                             # Custom widget tests
│   ├── pie_chart_widget_test.dart
│   └── bar_chart_widget_test.dart
│
└── integration_test/                   # Integration tests
    └── app_test.dart
```

---

## 🧪 Unit Tests

### Best Practices

```dart
void main() {
  group('ClassName', () {
    late ClassName instance;

    setUp(() {
      // Runs before EACH test
      instance = ClassName();
    });

    tearDown(() {
      // Runs after EACH test
      instance.dispose();
    });

    test('should [do something] when [condition]', () {
      // Arrange
      final input = ...;

      // Act
      final result = instance.method(input);

      // Assert
      expect(result, equals(expected));
    });
  });
}
```

### Model Tests Example

```dart
// test/models/transaction_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:futureproof/models/transaction.dart';

void main() {
  group('Transaction Model', () {
    group('Creation', () {
      test('should create transaction with required fields', () {
        // Arrange
        final id = 'test-123';
        final amount = -50.0;
        final category = 'groceries';
        final date = DateTime(2024, 1, 10);

        // Act
        final transaction = Transaction(
          id: id,
          amount: amount,
          category: category,
          date: date,
        );

        // Assert
        expect(transaction.id, id);
        expect(transaction.amount, amount);
        expect(transaction.category, category);
        expect(transaction.date, date);
      });

      test('should use current time for createdAt if not provided', () {
        final before = DateTime.now();
        final t = Transaction(
          id: 'test',
          amount: -50.0,
          category: 'groceries',
          date: DateTime.now(),
        );
        final after = DateTime.now();

        expect(t.createdAt.isAfter(before.subtract(const Duration(seconds: 1)))), true);
        expect(t.createdAt.isBefore(after.add(const Duration(seconds: 1)))), true);
      });
    });

    group('Type Checking', () {
      test('should identify expense correctly', () {
        final expense = Transaction(
          id: '1',
          amount: -100.0,
          category: 'dining',
          date: DateTime.now(),
        );

        expect(expense.isExpense, true);
        expect(expense.isIncome, false);
      });

      test('should identify income correctly', () {
        final income = Transaction(
          id: '2',
          amount: 1000.0,
          category: 'income',
          date: DateTime.now(),
        );

        expect(income.isIncome, true);
        expect(income.isExpense, false);
      });
    });

    group('Formatting', () {
      test('should format expense amount correctly', () {
        final t = Transaction(
          id: '1',
          amount: -123.45,
          category: 'shopping',
          date: DateTime.now(),
        );

        expect(t.formattedAmount, '\$123.45');
      });

      test('should format income amount correctly', () {
        final t = Transaction(
          id: '1',
          amount: 2500.0,
          category: 'income',
          date: DateTime.now(),
        );

        expect(t.formattedAmount, '\$2500.00');
      });
    });
  });
}
```

### Service Tests Example

```dart
// test/services/finance_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:futureproof/services/finance_calculator.dart';

void main() {
  group('FinanceCalculator', () {
    group('calculateStatus', () {
      test('should return GOOD status with large surplus', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 2000,
          savingsGoal: 1000,
        );

        expect(status.level, StatusLevel.good);
        expect(status.remaining, 2000.0);
        expect(status.emoji, '✅');
        expect(status.message, contains('left'));
      });

      test('should return CAUTION status with small deficit', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 4600,
          savingsGoal: 1000,
        );

        expect(status.level, StatusLevel.caution);
        expect(status.remaining, -600.0);
        expect(status.emoji, '⚠️');
      });

      test('should return DANGER status with large deficit', () {
        final status = FinanceCalculator.calculateStatus(
          monthlyIncome: 5000,
          monthlyExpenses: 6000,
          savingsGoal: 1000,
        );

        expect(status.level, StatusLevel.danger);
        expect(status.remaining, -2000.0);
        expect(status.emoji, '❌');
      });
    });

    group('calculateTotalExpenses', () {
      test('should sum only negative amounts', () {
        final transactions = [
          Transaction(id: '1', amount: -100.0, category: 'food', date: DateTime.now()),
          Transaction(id: '2', amount: -50.0, category: 'food', date: DateTime.now()),
          Transaction(id: '3', amount: 200.0, category: 'income', date: DateTime.now()),
          Transaction(id: '4', amount: 500.0, category: 'income', date: DateTime.now()),
        ];

        final total = FinanceCalculator.calculateTotalExpenses(transactions);

        expect(total, 150.0);
      });

      test('should return zero for empty list', () {
        final total = FinanceCalculator.calculateTotalExpenses([]);
        expect(total, 0.0);
      });
    });
  });
}
```

---

## 🎨 Widget Tests

### Example Widget Test

```dart
// test/screens/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futureproof/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:futureproof/providers/transaction_provider.dart';

void main() {
  group('HomeScreen Widget', () {
    testWidgets('should display app title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(),
        ),
      );

      expect(find.text('FutureProof'), findsOneWidget);
    });

    testWidgets('should display "Are We Okay?" button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(),
        ),
      );

      expect(find.text('Are We Okay?'), findsOneWidget);
    });

    testWidgets('should show loading indicator initially', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TransactionProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should navigate to dialog when button tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(),
        ),
      );

      final button = find.text('Are We Okay?');
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Financial Health'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
```

---

## 🔄 Integration Tests

### Critical User Flows

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:futureproof/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FutureProof E2E Tests', () {
    testWidgets('Complete expense tracking flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Verify home screen loads
      expect(find.text('FutureProof'), findsOneWidget);
      expect(find.text('Are We Okay?'), findsOneWidget);

      // 2. Add an expense
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('amount_field')), '50');

      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // 3. Navigate to history
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // 4. Verify expense appears
      expect(find.text('\$50.00'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);

      // 5. Check financial status
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Are We Okay?'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('Should validate form inputs', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Try to add without amount
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter an amount'), findsOneWidget);
    });
  });
}
```

---

## 📊 Test Coverage

### Running Coverage

```bash
# Run tests with coverage
flutter test --coverage

# Generate HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html

# Open report
open coverage/html/index.html  # Mac
xdg-open coverage/html/index.html  # Linux
start coverage/html/index.html  # Windows
```

### Coverage Targets by File

```
lib/models/
├── transaction.dart              95%+  (critical)
├── household.dart                80%+  (medium)
└── spending_analysis.dart        85%+  (high)

lib/services/
├── database_service.dart         80%+  (high)
├── finance_calculator.dart       90%+  (critical)
└── analytics_service.dart        75%+  (medium)

lib/screens/
├── home_screen.dart              60%+  (low-medium)
├── add_expense_screen.dart       60%+  (low-medium)
└── transaction_history_screen.dart 50%+ (low)
```

---

## ✅ Testing Checklist

### Before Writing Tests
- [ ] Understand the feature requirements
- [ ] Identify public methods/properties
- [ ] List edge cases and error conditions
- [ ] Plan test structure (groups)

### While Writing Tests
- [ ] Use descriptive test names (should/when)
- [ ] Follow Arrange-Act-Assert pattern
- [ ] Test both success and failure cases
- [ ] Mock external dependencies
- [ ] Add meaningful assertion messages

### After Writing Tests
- [ ] Run tests: `flutter test`
- [ ] Check coverage: `flutter test --coverage`
- [ ] Verify all edge cases covered
- [ ] Run on multiple platforms if relevant
- [ ] Update documentation

---

## 🚀 Running Tests

### All Tests
```bash
flutter test
```

### Specific Test File
```bash
flutter test test/models/transaction_test.dart
```

### With Coverage
```bash
flutter test --coverage
```

### Integration Tests
```bash
flutter test integration_test/
```

---

**Last Updated**: January 11, 2026
**Related Files**: DEVELOPMENT.md, code_quality_guide.md, TASKS.md
