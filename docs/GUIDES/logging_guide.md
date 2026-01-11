# Logging Guide for FutureProof

This guide explains how to use the `AppLogger` utility for consistent, structured logging across the FutureProof application.

## Quick Start

```dart
import 'lib/utils/app_logger.dart';

// Simple info log
AppLogger.logInfo(AppLogger.ui, 'Home screen loaded');

// Warning with context
AppLogger.logWarning(AppLogger.services, 'API rate limit approached', error);

// Error with full details
AppLogger.logError(AppLogger.database, 'Failed to save transaction', error, stackTrace);
```

## Log Levels

### INFO
**Use for:** Normal operations, expected application flow
- User actions (navigation, button clicks)
- Successful operations (save, load, update)
- State changes
- Initialization steps

```dart
// ✅ Good
AppLogger.logInfo(AppLogger.ui, 'User navigated to Settings');
AppLogger.logInfo(AppLogger.database, 'Loaded 15 transactions');

// ❌ Bad - too verbose
AppLogger.logInfo(AppLogger.ui, 'Render method called');
```

### WARNING
**Use for:** Recoverable issues, unexpected but non-fatal situations
- Missing data with fallback defaults
- API retries needed
- Cached data used when fresh data unavailable
- Deprecated feature usage

```dart
// ✅ Good
AppLogger.logWarning(AppLogger.services, 'Using cached category data');
AppLogger.logWarning(AppLogger.analytics, 'Failed to track event, will retry');

// ❌ Bad - should be SEVERE
AppLogger.logWarning(AppLogger.database, 'Database file corrupted');
```

### SEVERE
**Use for:** Errors that impact functionality
- Failed operations (save, load, delete failed)
- Uncaught exceptions
- Data corruption or loss
- Critical system failures

```dart
// ✅ Good
try {
  await saveTransaction(transaction);
} catch (e, stack) {
  AppLogger.logError(AppLogger.database, 'Failed to save transaction', e, stack);
}

// ❌ Bad - no context
AppLogger.logError(AppLogger.general, 'Error occurred');
```

## Logger Categories

Use the appropriate logger for each component:

- **`AppLogger.ui`** - Screen/widget lifecycle, user interactions
- **`AppLogger.database`** - Storage operations, queries
- **`AppLogger.analytics`** - Tracking events, metrics
- **`AppLogger.services`** - Business logic, calculations
- **`AppLogger.general`** - Uncategorized logs (avoid when possible)

## Common Patterns

### Service Layer
```dart
class TransactionService {
  static const _logger = AppLogger.services; // Store reference

  Future<void> processTransaction(Transaction t) async {
    AppLogger.logInfo(_logger, 'Processing transaction: ${t.id}');

    try {
      // ... operation
      AppLogger.logInfo(_logger, 'Transaction processed successfully');
    } catch (e, stack) {
      AppLogger.logError(_logger, 'Failed to process transaction', e, stack);
      rethrow;
    }
  }
}
```

### UI Layer
```dart
class HomeScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    AppLogger.logInfo(AppLogger.ui, 'Home screen initialized');
  }

  void _handleRefresh() {
    AppLogger.logInfo(AppLogger.ui, 'User triggered refresh');
    // ... refresh logic
  }
}
```

### Error Boundaries
```dart
Future<void> loadData() async {
  try {
    final data = await fetchFromDatabase();
    AppLogger.logInfo(AppLogger.database, 'Loaded ${data.length} items');
  } catch (e, stack) {
    AppLogger.logError(
      AppLogger.database,
      'Failed to load data from database',
      e,
      stack,
    );
    // Show user-friendly error
  }
}
```

## Migration from print()

### Before
```dart
print('Loading transactions...');
print('Error: $e');
print('Stack trace: $stackTrace');
```

### After
```dart
import 'lib/utils/app_logger.dart';

// Info message
AppLogger.logInfo(AppLogger.database, 'Loading transactions');

// Error with context
AppLogger.logError(AppLogger.database, 'Failed to load transactions', e, stackTrace);
```

## Best Practices

1. **Be specific** - Include relevant context (what, where, why)
2. **Don't log sensitive data** - Avoid passwords, tokens, PII
3. **Use appropriate levels** - INFO for normal, WARNING for recoverable, SEVERE for errors
4. **Include stack traces for errors** - Helps debugging
5. **Keep messages concise** - One line per log when possible
6. **Log at boundaries** - Service entry/exit, API calls, storage operations

## Examples

### ❌ Anti-patterns
```dart
// Too vague
AppLogger.logInfo(AppLogger.ui, 'Something happened');

// Wrong level
AppLogger.logInfo(AppLogger.database, 'Database connection failed');

// Too verbose
AppLogger.logInfo(AppLogger.ui, 'Build called at ${DateTime.now()}');

// Duplicates error (Logger.log handles error/stackTrace formatting)
print('Error: $error');
AppLogger.logError(AppLogger.services, 'Operation failed', error);
```

### ✅ Good patterns
```dart
// Clear context
AppLogger.logInfo(AppLogger.ui, 'Settings screen: Theme changed to dark');

// Correct level
AppLogger.logError(AppLogger.database, 'Failed to open database: $path', error, stack);

// Concise and informative
AppLogger.logWarning(AppLogger.services, 'Using offline mode - API unavailable');

// Proper error logging with stack trace
try {
  await riskyOperation();
} catch (e, stack) {
  AppLogger.logError(AppLogger.services, 'Risk operation failed', e, stack);
  rethrow; // Re-throw if caller needs to handle
}
```

## Testing with Logs

When debugging, temporarily lower the log level in `lib/main.dart`:

```dart
// For debugging (very verbose)
Logger.root.level = Level.ALL;

// Normal operation (recommended)
Logger.root.level = Level.INFO;

// Production (errors only)
Logger.root.level = Level.SEVERE;
```
