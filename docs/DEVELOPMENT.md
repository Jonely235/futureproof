# FutureProof - Development Guide

> Developer guidelines, coding standards, and project context
> **Last Updated**: January 11, 2026

---

## 📋 Table of Contents
1. [Context Detection](#context-detection)
2. [Universal Operational Rules](#universal-operational-rules)
3. [Coding Standards](#coding-standards)
4. [Persistent Memory](#persistent-memory)
5. [Project Information](#project-information)
6. [Quick Commands](#quick-commands)

---

## 1. Context Detection

### Auto-Run Checklist
*At the start of every session, you must:*

1. **Identify the Stack**
   - Scan root directory for `pubspec.yaml` (Flutter project)
   - Confirm Flutter and Dart versions
   - Check for key dependencies

2. **Determine Commands**
   - **Building**: `flutter build ios` or `flutter build apk`
   - **Testing**: `flutter test`
   - **Linting**: `flutter analyze`
   - **Format**: `dart format .`

3. **Respect Structure**
   - Adapt to existing folder structure in `lib/`
   - Follow naming conventions found in codebase
   - Match existing code style and patterns

---

## 2. Universal Operational Rules

### A. The "Plan Mode" Rule

If a request involves editing multiple files or complex logic:
1. **Stop and Plan** - Output a bulleted plan of changes
2. **Wait for approval** before executing code
3. **Break down** complex tasks into smaller steps

### B. The Verification Rule (Critical)

- **Never finish a task without verification**
- After editing code, run the testing command: `flutter test`
- If no tests exist, create a temporary verification script
- **Do not ask for permission** to run tests—just run them

### C. Coding Standards

- **Style**: Mimic existing coding style (indentation, comments, variable naming)
- **Errors**: Don't suppress errors. Fix them.
- **Dependencies**: Do not add new libraries unless standard library solutions are insufficient

---

## 3. Coding Standards

### Code Style

Follow the Dart style guide:
```dart
// Naming conventions
class MyClass {}                    // PascalCase for classes
const myConstant = 1.0;             // camelCase for constants
final myVariable = 'value';         // camelCase for variables
Future<void> myFunction() {}        // camelCase for functions
String _myPrivateVariable;          // _prefix for private

// Imports (ordered correctly)
import 'dart:async';                // 1. Dart core libraries
import 'package:flutter/material.dart';  // 2. Flutter packages
import '../models/transaction.dart';     // 3. Relative project imports
import 'package:my_package/my_package.dart';  // 4. Other packages
```

### Documentation

```dart
/// One-line summary of what this does.
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

### Error Handling

```dart
// ✅ Good - proper error handling with logging
try {
  await databaseOperation();
  _log.info('Operation completed successfully');
} catch (e, stackTrace) {
  _log.severe('Database operation failed', e, stackTrace);
  rethrow;
}

// ❌ Bad - silent failures
catch (e) {
  print('Error: $e');
  return null;  // Silently fails
}
```

---

## 4. Persistent Memory

### Learned Patterns & Quirks

If you (Claude) make a mistake or learn a specific quirk about this repo, add it below:

- **[Global]**: Always check for a `.env` file before assuming environment variables exist
- **[Global]**: When writing tests, ensure they clean up their own data
- **[Database]**: SQLite stores dates as INTEGER (milliseconds), not ISO strings
- **[State]**: Use Provider pattern for state management, not setState everywhere
- **[Testing]**: Always run `flutter test` before committing changes

---

## 5. Project Information

### Technology Stack

```
Frontend:  Flutter 3.27.0 (Dart SDK 3.0+)
Database:  SQLite (mobile), In-Memory (web)
State:     Provider 6.1.1
Utils:     intl, uuid, shared_preferences
```

### Architecture Pattern

```
UI Layer (Screens)
    ↓
State Management (Provider)
    ↓
Service Layer (DatabaseService, FinanceCalculator, AnalyticsService)
    ↓
Data Layer (SQLite / In-Memory / SharedPreferences)
```

### Core Features

**Phase 1 (MVP) - Complete ✅**
1. "Are We Okay?" Button - One tap financial health check
2. Quick Expense Tracking - Add expenses in 3 seconds
3. Simple Dashboard - Monthly summary with transaction history
4. SQLite Database - Local data persistence

**Phase 2 (Sync) - Complete ✅**
1. Firebase Cloud Sync - Real-time data synchronization
2. Multi-user Household Support
3. Email/Password Authentication
4. Household Code Joining

**Phase 3 (AI Analytics) - Complete ✅**
1. Spending Analysis by Category
2. Monthly Trend Calculations
3. Anomaly Detection (2x average threshold)
4. Budget vs Actual Comparisons
5. Visual Charts (Pie and Bar)
6. Automated Insights and Recommendations

### Design Principles

- **Simple over complex**: One screen, one purpose
- **Reassurance over restriction**: Encouraging messages
- **Narrative over numbers**: Explain, don't just show data
- **Fast**: Load in <2 seconds
- **Beautiful**: Material Design 3, smooth animations

---

## 6. Quick Commands

### Development

```bash
# Install dependencies
flutter pub get

# Run on Chrome (testing)
flutter run -d chrome

# Run on Android
flutter run

# Build for iOS (requires Mac)
flutter build ios --release

# Clean build
flutter clean
```

### Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/

# Run specific test file
flutter test test/models/transaction_test.dart
```

### Code Quality

```bash
# Format code
dart format .

# Analyze code
flutter analyze

# Fix issues automatically
dart fix --apply
```

### Firebase Setup (if needed)

```bash
# Add Firebase dependencies
flutter pub add firebase_core
flutter pub add cloud_firestore
flutter pub add firebase_auth
```

---

## 📁 File Structure Reference

### Models
- `transaction.dart` - Transaction data model
- `user.dart` - User data model
- `household.dart` - Household data model
- `spending_analysis.dart` - Spending analysis model

### Screens
- `home_screen.dart` - Main dashboard
- `add_expense_screen.dart` - Add expense form
- `analytics_dashboard_screen.dart` - Analytics & insights
- `transaction_history_screen.dart` - Transaction list
- `settings_screen.dart` - Settings & budget
- `edit_transaction_screen.dart` - Edit existing transaction

### Services
- `database_service.dart` - Database operations
- `finance_calculator.dart` - Financial calculations
- `analytics_service.dart` - Analytics & insights

### Widgets
- `main_navigation.dart` - Bottom navigation
- `pie_chart_widget.dart` - Custom pie chart
- `bar_chart_widget.dart` - Custom bar chart
- `trend_indicator.dart` - Trend arrows
- `velocity_chart_widget.dart` - Velocity chart

---

## 🚨 Known Issues

### iOS Build Blocked - Firebase Incompatibility

**Problem**: Cannot build iOS apps with Firebase + Flutter plugins

**Root Cause**: Fundamental architectural incompatibility between Firebase iOS SDK and Flutter plugins

**Solution**: Use local-only version (Phase 1) without Firebase for iOS builds

**Current Status**: Phase 1-3 features work on web/Android. iOS build requires removing Firebase.

---

## 💡 Motivation

### Remember

> "The best app is the one that actually exists."

> "Shipping beats perfection."

> "Your girlfriend doesn't need features. She needs reassurance."

### When You're Stuck

1. Take a break (go for a walk)
2. Talk to a potential user
3. Remember why you started
4. Do the smallest possible thing
5. Keep going

---

## 📞 Support

For questions or issues:
1. Check [STATUS.md](STATUS.md) for known issues
2. Review [TASKS.md](TASKS.md) for active development
3. See [GUIDES/](./GUIDES/) for detailed guides

---

**Keep moving forward! 🚀**
