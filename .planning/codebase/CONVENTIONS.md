# Coding Conventions

**Analysis Date:** 2026-01-11

## Naming Patterns

**Files:**
- `snake_case.dart` for all Dart files
- Screen files: `[feature]_screen.dart` (e.g., `home_screen.dart`)
- Provider files: `[entity]_provider.dart` (e.g., `transaction_provider.dart`)
- Service files: `[service]_service.dart` (e.g., `database_service.dart`)
- Widget files: `[widget_name].dart` (e.g., `bar_chart_widget.dart`)

**Classes:**
- `PascalCase` for all class names
- Examples: `TransactionProvider`, `HomeScreen`, `FinanceCalculator`

**Functions/Methods:**
- `camelCase` for methods and functions
- Examples: `calculateStatus()`, `getAllTransactions()`, `_loadSettings()`

**Variables:**
- `camelCase` for local variables and parameters
- Examples: `monthlyIncome`, `totalSpending`, `categoryBreakdown`

**Private Members:**
- Underscore prefix for private class members
- Examples: `_currentTheme`, `_loadSettings()`, `_cachedAnalysis`

**Constants:**
- Most constants are `private static final`
- No SCREAMING_SNAKE_CASE detected (prefers lowerCamelCase for constants)
- Examples: `FinanceConfig.overBudgetPenalty` (static const)

**Enums:**
- `PascalCase` for enum names
- `camelCase` for enum values
- Examples: `AppTheme.editorial`, `StatusLevel.good`

## Code Style

**Indentation:**
- 2 spaces (Dart/Flutter standard)
- No tabs detected

**Formatting:**
- Standard Dart formatting (dart format)
- Trailing commas in multi-line function calls
- Consistent spacing around operators

**Quotes:**
- Single quotes for string literals
- Double quotes used in some interpolated strings
- Example: `'FutureProof'` vs `"You're on track!"`

**Semicolons:**
- Required (Dart syntax)
- Always present

**Line Length:**
- No strict line length limit detected
- Some long lines in UI building code (80-120 characters)

**Imports:**
- `import 'package:flutter/material.dart'` first (framework)
- Relative imports next: `import '../models/transaction.dart'`
- Package imports last: `import 'package:provider/provider.dart'`
- Organized alphabetically within groups

**Nullable Types:**
- Nullable types used extensively (`String?`, `DateTime?`)
- Null-aware operators (`?.`, `??`, `??=`)
- Example: `final prefs = await SharedPreferences.getInstance();`

## Import Organization

**Import Order:**
1. Flutter framework imports
2. Package imports (provider, google_fonts, etc.)
3. Relative imports (../models/, ../services/)
4. No `dart:` imports detected (uses Flutter SDK)

**Import Style:**
- No barrel files (individual imports)
- Some services use `import '../models/transaction.dart' as model` to avoid conflicts

**Unused Imports:**
- flutter_lints configured but not checking for unused imports in some files

## Error Handling

**Pattern:** Try-catch at operation boundaries

**Service Layer:**
- All database operations wrapped in try-catch
- Errors logged with print statements
- Generic error messages to users
- Example from `lib/services/database_service.dart`:
  ```dart
  try {
    // database operation
  } catch (e) {
    print('❌ Error adding transaction: $e');
  }
  ```

**UI Layer:**
- Form validation before operations
- User-friendly error messages via SnackBar
- Silent failures for non-critical settings

**Logging:**
- Print statements with emoji prefixes (✅, ❌, 📁, 📊)
- logging package configured but not extensively used
- Main logger in `lib/main.dart` with colored output

## Comments

**Documentation Style:**
- Triple-slash (`///`) for class and method documentation
- Brief one-line descriptions common
- No detailed parameter documentation in most places

**Example from `lib/services/backup_service.dart`:**
```dart
/// Export all transactions to JSON string
Future<String> exportData() async {
  // ...
}
```

**Inline Comments:**
- Brief comments for complex logic
- Section dividers in longer methods
- No excessive commenting (code is self-documenting)

**TODO Comments:**
- Not extensively used
- No critical TODOs found in analysis

## Function Design

**Method Signatures:**
- Async methods return `Future<T>` for I/O operations
- Named parameters for optional values: `{required double monthlyIncome}`
- Validation in method bodies, not signatures

**Return Values:**
- Models with full data (e.g., `Transaction`)
- Collections for queries (e.g., `List<Transaction>`)
- `Future<bool>` for success/failure operations
- Custom result objects for complex operations (e.g., `ImportResult`)

**Parameters:**
- Required parameters marked with `required` keyword
- Optional parameters have default values or are nullable
- No positional optional parameters detected

## Module Design

**Class Organization:**
- One class per file (standard Dart practice)
- Private helper classes in same file if related
- Enums defined alongside using class

**State Management:**
- Provider classes extend ChangeNotifier
- Call `notifyListeners()` after state changes
- Use `context.watch<>()` for reactive reads in UI
- Use `context.read<>()` for writes/operations

**Widget Structure:**
- StatefulWidget for screens with local state
- StatelessWidget for reusable components
- Build methods broken into private helpers (e.g., `_buildHeader()`, `_buildContent()`)

**Service Pattern:**
- Stateless singleton services (imported as modules)
- Private instances in services (e.g., `final DatabaseService _db = DatabaseService()`)
- No dependency injection framework

---

*Conventions analysis: 2026-01-11*
*Update when coding standards change*
