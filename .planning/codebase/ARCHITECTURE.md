# Architecture

**Analysis Date:** 2026-01-11

## Pattern Overview

**Overall:** Provider-based Layered Architecture

**Key Characteristics:**
- MVVM-like pattern with Provider for state management
- Layered architecture (UI → Provider → Service → Data)
- Service-oriented business logic
- Offline-first with local SQLite storage
- Single-direction data flow with reactive updates

## Layers

**Presentation Layer (`lib/screens/`):**
- Purpose: UI rendering and user interaction
- Contains: StatefulWidget widgets, form inputs, dialogs
- Location: `lib/screens/home_screen.dart`, `lib/screens/settings_screen.dart`, etc.
- Depends on: Provider layer for state, Services for business logic
- Used by: Main navigation widget

**State Management Layer (`lib/providers/`):**
- Purpose: Reactive state management and data coordination
- Contains: ChangeNotifier providers
- Location: `lib/providers/transaction_provider.dart`
- Depends on: Service layer for data operations
- Used by: All UI screens via `context.watch<>()` and `context.read<>()`

**Model Layer (`lib/models/`):**
- Purpose: Data structures and business entities
- Contains: Transaction, SpendingAnalysis, User, Household models
- Location: `lib/models/transaction.dart`, `lib/models/spending_analysis.dart`
- Depends on: No dependencies (pure data classes)
- Used by: All layers

**Service Layer (`lib/services/`):**
- Purpose: Business logic, data persistence, analytics
- Contains: DatabaseService, AnalyticsService, BackupService
- Location: `lib/services/database_service.dart`, `lib/services/analytics_service.dart`
- Depends on: Model layer, SQLite, SharedPreferences
- Used by: Provider layer

**Infrastructure Layer (`lib/config/`, `lib/theme/`):**
- Purpose: Configuration, theming, cross-cutting concerns
- Contains: FinanceConfig, ThemeManager
- Location: `lib/config/finance_config.dart`, `lib/theme/theme_manager.dart`
- Depends on: SharedPreferences
- Used by: All layers

**Widget Layer (`lib/widgets/`):**
- Purpose: Reusable UI components
- Contains: Navigation widgets, charts, indicators
- Location: `lib/widgets/main_navigation.dart`, `lib/widgets/bar_chart_widget.dart`
- Depends on: Models, Providers
- Used by: Screens

## Data Flow

**User Action → State Update → UI Refresh:**

1. User interacts with UI (e.g., adds transaction)
2. Screen calls Provider method (e.g., `context.read<TransactionProvider>().addTransaction()`)
3. Provider calls Service layer (e.g., `DatabaseService.addTransaction()`)
4. Service executes business logic and persists to SQLite
5. Provider calls `notifyListeners()` to trigger rebuild
6. UI automatically updates via `context.watch<TransactionProvider>()`

**Query Flow:**

1. Screen requests data via Provider (e.g., `context.watch<TransactionProvider>().transactions`)
2. Provider returns cached state or queries Service
3. Service queries SQLite via DatabaseService
4. Results returned as Model objects
5. UI renders with live data

**State Management:**
- Provider pattern with ChangeNotifier
- Centralized state in TransactionProvider
- Localized state in individual StatefulWidget screens
- Theme state persisted via ThemeManager

## Key Abstractions

**Service:**
- Purpose: Encapsulate business logic and external integrations
- Examples: `lib/services/database_service.dart`, `lib/services/analytics_service.dart`, `lib/services/backup_service.dart`
- Pattern: Stateless singletons (imported as modules)

**Provider (ChangeNotifier):**
- Purpose: Reactive state management
- Examples: `TransactionProvider` in `lib/providers/transaction_provider.dart`
- Pattern: Provider pattern with ChangeNotifier

**Model:**
- Purpose: Data structures with validation
- Examples: `Transaction`, `SpendingAnalysis`, `FinanceStatus`
- Pattern: Immutable data classes with `fromJson()`/`toJson()`

**Theme:**
- Purpose: Multi-theme support with persistence
- Examples: `ThemeManager` in `lib/theme/theme_manager.dart`
- Pattern: Singleton with SharedPreferences persistence

## Entry Points

**Main Entry:**
- Location: `lib/main.dart`
- Responsibilities:
  - Initialize logging
  - Initialize ThemeManager
  - Configure MultiProvider with TransactionProvider
  - Launch FutureProofApp widget

**App Root:**
- Location: `lib/main.dart` (FutureProofApp class)
- Responsibilities:
  - Build MaterialApp with theme
  - Configure routes
  - Set up navigation structure

**Navigation:**
- Location: `lib/widgets/main_navigation.dart` (MainNavigation widget)
- Responsibilities:
  - Bottom navigation with 4 tabs
  - IndexedStack for screen state preservation
  - FAB for adding transactions

## Error Handling

**Strategy:** Try-catch at service level, user-friendly messages in UI

**Patterns:**
- Services wrap database operations in try-catch
- Errors logged via print statements (logging package available but not extensively used)
- UI shows error messages via SnackBar
- Silent failures for non-critical operations (e.g., settings persistence)

**Logging:**
- Print statements for debugging in `lib/main.dart` and services
- logging package configured but not extensively used
- Emoji-prefixed messages for clarity (e.g., "✅ Added transaction")

## Cross-Cutting Concerns

**State Persistence:**
- SQLite via sqflite for transactions
- SharedPreferences for app settings
- ThemeManager for theme selection

**Theming:**
- 4 built-in themes (Editorial, Ocean Calm, Sunset Warm, Forest)
- ThemeManager with async initialization
- Material Design 3 color schemes

**Validation:**
- Form validation in screens (e.g., income > 0)
- Model-level validation in constructors
- User input sanitization in services

**Analytics:**
- SpendingAnalysis model with insights, trends, anomalies
- FinanceCalculator for financial status calculations
- AnalyticsService for analysis coordination

**Backup/Restore:**
- JSON export/import via BackupService
- Includes transactions and settings
- Duplicate detection on import

---

*Architecture analysis: 2026-01-11*
*Update when major patterns change*
