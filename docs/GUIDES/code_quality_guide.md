# Code Quality & Best Practices Guide

> **Production-ready coding standards and guidelines**
> **Created**: 2026-01-10
> **Updated**: January 11, 2026

---

## 📋 Table of Contents
1. [Logging Best Practices](#logging-best-practices)
2. [Error Handling Patterns](#error-handling-patterns)
3. [Loading States](#loading-states)
4. [Performance Optimization](#performance-optimization)
5. [Security Checklist](#security-checklist)
6. [Code Review Checklist](#code-review-checklist)

---

## 📝 Logging Best Practices

### Why Logging Matters

- **Debugging**: Understand what happened when errors occur
- **Monitoring**: Track app health in production
- **Auditing**: Security and compliance
- **Performance**: Identify slow operations

### Logging Levels

```dart
import 'package:logging/logging.dart';

// Setup in main.dart
void main() {
  // Set logging level
  Logger.root.level = Level.ALL;

  // Add listener
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
    // Also log error details
    if (record.error != null) {
      print('  Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('  Stack: ${record.stackTrace}');
    }
  });

  runApp(MyApp());
}
```

### When to Use Each Level

```dart
class MyService {
  final Logger _log = Logger('MyService');

  void someMethod() {
    // FINE - Very detailed, usually disabled in production
    _log.fine('Starting data processing');
    _log.fine('Input: $data');

    // INFO - Normal operation
    _log.info('Processing 5 transactions');
    _log.info('User added transaction successfully');

    // WARNING - Something unexpected but not fatal
    _log.warning('Transaction amount seems high: $amount');
    _log.warning('Cache miss for key: $key');

    // SEVERE - Error that affects functionality
    try {
      await databaseOperation();
    } catch (e, stackTrace) {
      _log.severe('Database operation failed', e, stackTrace);
      rethrow;
    }

    // SHOUT - Critical errors requiring immediate attention
    _log.shout('Database connection lost! App may be unusable.');
  }
}
```

---

## ⚠️ Error Handling Patterns

### Try-Catch-Finally Pattern

```dart
Future<Result> operation() async {
  try {
    // Setup
    _log.fine('Starting operation');

    // Do work
    final result = await _doWork();

    // Success
    _log.info('Operation completed');
    return Result.success(result);

  } on ArgumentError catch (e) {
    // Expected errors (validation, etc.)
    _log.warning('Validation failed: ${e.message}');
    return Result.failure(e);

  } on DatabaseException catch (e) {
    // Expected database errors
    _log.severe('Database error: ${e.toString()}');
    return Result.failure(e);

  } catch (e, stackTrace) {
    // Unexpected errors
    _log.severe('Unexpected error', e, stackTrace);
    return Result.failure(e);

  } finally {
    // Cleanup
    _log.fine('Operation cleanup complete');
  }
}
```

### Result Type Pattern

```dart
// lib/utils/result.dart
class Result<T> {
  final T? data;
  final Exception? error;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  Result.success(this.data) : error = null;

  Result.failure(this.error) : data = null;

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Exception error) onFailure,
  }) {
    if (isSuccess) {
      return onSuccess(data as T);
    } else {
      return onFailure(error!);
    }
  }
}

// Usage
final result = await databaseService.addTransaction(transaction);

result.fold(
  onSuccess: (id) {
    _log.info('Transaction added: $id');
    showSuccessSnackBar('Expense added!');
  },
  onFailure: (error) {
    _log.severe('Failed to add transaction', error);
    showErrorSnackBar('Failed to add expense');
  },
);
```

---

## ⏳ Loading States

### Best Practices

```dart
class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingUI();
    }

    if (_error != null) {
      return _buildErrorUI();
    }

    return _buildContentUI();
  }

  Widget _buildLoadingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading transactions...'),
        ],
      ),
    );
  }

  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text('Something went wrong'),
          Text(_error!, style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await provider.loadTransactions();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
```

---

## 🚀 Performance Optimization

### Database Optimization

```dart
// 1. Add indexes
Future<void> _onCreate(Database db, int version) async {
  await db.execute('''
    CREATE TABLE transactions(
      id TEXT PRIMARY KEY,
      amount REAL NOT NULL,
      category TEXT NOT NULL,
      date INTEGER NOT NULL,
      note TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');

  // Create indexes for common queries
  await db.execute('CREATE INDEX idx_date ON transactions(date)');
  await db.execute('CREATE INDEX idx_category ON transactions(category)');
  await db.execute('CREATE INDEX idx_amount ON transactions(amount)');
}

// 2. Use aggregation instead of loading all data
Future<double> getTotalExpenses() async {
  final db = await database;

  final result = await db.rawQuery('''
    SELECT SUM(ABS(amount)) as total
    FROM transactions
    WHERE amount < 0
  ''');

  return (result.first['total'] as double?) ?? 0.0;
}

// 3. Use pagination for large lists
Future<List<Transaction>> getTransactions({int limit = 50, int offset = 0}) async {
  final db = await database;

  final maps = await db.query(
    'transactions',
    orderBy: 'date DESC',
    limit: limit,
    offset: offset,
  );

  return maps.map((map) => _transactionFromMap(map)).toList();
}
```

### Widget Performance

```dart
// 1. Use const constructors
const Text('Hello');  // ✅ Good
Text('Hello');         // ❌ Bad - rebuilds every time

// 2. Extract widgets
class TransactionList extends StatelessWidget {
  final List<Transaction> transactions;

  const TransactionList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        return TransactionTile(transactions[index]);  // ✅ Extracted
      },
    );
  }
}

// 3. Use ListView.builder not ListView
ListView.builder(  // ✅ Lazy loading
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)

ListView(  // ❌ Builds all items at once
  children: items.map((item) => ItemWidget(item)).toList(),
)
```

---

## 🔒 Security Checklist

### Input Validation

- [x] All user input is validated
- [x] Amounts are clamped to reasonable ranges
- [x] Categories are validated against whitelist
- [x] SQL queries use parameterized inputs
- [x] No eval() or similar dynamic code execution

### Data Protection

- [x] Sensitive data not logged in production
- [x] Database is encrypted on device (future)
- [x] HTTPS for network communication
- [x] No hardcoded API keys
- [x] Proper error messages (no info leakage)

### Code Security

```dart
// ❌ Bad - exposes internal details
catch (e) {
  print('Database error: ${e.toString()}');  // May leak file paths
  return 'Error: ${e}';  // Shows technical details to user
}

// ✅ Good - safe error handling
catch (e, stackTrace) {
  _log.severe('Operation failed', e, stackTrace);  // Logged with context
  return 'An error occurred. Please try again.';  // Generic for user
}
```

---

## 👁️ Code Review Checklist

### Functionality
- [ ] Code works as intended
- [ ] Edge cases are handled
- [ ] Error cases are covered
- [ ] No obvious bugs

### Code Quality
- [ ] Follows Dart style guide
- [ ] No dead code
- [ ] No commented-out code
- [ ] Meaningful variable names
- [ ] Proper indentation (dart format)

### Testing
- [ ] Unit tests included
- [ ] Tests cover edge cases
- [ ] Tests are readable
- [ ] Coverage target met

### Documentation
- [ ] Public APIs documented
- [ ] Complex logic explained
- [ ] Examples provided
- [ ] README updated if needed

### Performance
- [ ] No obvious performance issues
- [ ] Database queries optimized
- [ ] No unnecessary rebuilds
- [ ] Memory leaks checked

### Security
- [ ] Input validation present
- [ ] No SQL injection risk
- [ ] Error messages safe
- [ ] Sensitive data protected

---

## 📏 Code Style Guidelines

### Dart Style

```dart
// Naming
class MyClass {}                    // PascalCase for classes
const myConstant = 1.0;             // camelCase for constants
final myVariable = 'value';         // camelCase for variables
Future<void> myFunction() {}        // camelCase for functions
String _myPrivateVariable;          // _prefix for private

// Imports
import 'dart:async';                // 1. Dart core libraries
import 'package:flutter/material.dart';  // 2. Flutter packages
import '../models/transaction.dart';     // 3. Relative project imports
import 'package:my_package/my_package.dart';  // 4. Other packages

// Formatting (dart format applies these)
if (condition) {                     // Space after if
  doSomething();
} else {                             // Space after else
  doOtherThing();
}

// Line length (80 characters preferred, max 120)
final longVariableName = someFunction(with, lots, of, parameters,
    that, spans, multiple, lines);
```

### Documentation

```dart
/// One-line summary.
///
/// More detailed description if needed.
/// Can span multiple lines.
///
/// Example:
/// ```dart
/// final service = MyService();
/// await service.doSomething();
/// ```
///
/// Throws [StateError] if something goes wrong.
/// Returns a [Future] that completes with the result.
Future<Result> doSomething() async {
  // ...
}
```

---

**Last Updated**: January 11, 2026
**Related Files**: DEVELOPMENT.md, testing_guide.md
