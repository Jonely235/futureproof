# Codebase Structure

**Analysis Date:** 2026-01-11

## Directory Layout

```
lib/
├── config/                    # Configuration files
│   ├── config.dart
│   └── finance_config.dart    # Financial parameters and scoring
├── models/                    # Data models
│   ├── spending_analysis.dart # Analytics and insights
│   ├── transaction.dart       # Transaction model
│   ├── household.dart         # Household account model
│   └── user.dart              # User model
├── providers/                 # State management
│   ├── providers.dart         # Provider exports
│   └── transaction_provider.dart # Main transaction state
├── screens/                   # UI screens
│   ├── home_screen.dart           # Home/dashboard screen
│   ├── settings_screen.dart       # Settings and configuration
│   ├── add_expense_screen.dart    # Add transaction form
│   ├── transaction_history_screen.dart  # Transaction list
│   ├── edit_transaction_screen.dart    # Edit transaction
│   └── analytics_dashboard_screen.dart # Analytics visualization
├── services/                  # Business logic
│   ├── database_service.dart   # SQLite database operations
│   ├── analytics_service.dart  # Financial analysis
│   ├── backup_service.dart     # Export/import functionality
│   └── finance_calculator.dart # Financial calculations
├── theme/                     # Theming system
│   ├── app_theme.dart         # Theme definitions
│   └── theme_manager.dart     # Theme persistence and switching
└── widgets/                   # Reusable UI components
    ├── main_navigation.dart   # Bottom navigation
    ├── bar_chart_widget.dart  # Bar chart visualization
    ├── pie_chart_widget.dart  # Pie chart visualization
    ├── trend_indicator.dart   # Trend arrows
    └── velocity_chart_widget.dart  # Spending velocity chart

test/
├── integration_app_test.dart  # Integration tests
├── widget_test.dart           # Widget tests
├── services/                  # Service unit tests
│   ├── finance_calculator_test.dart
│   └── database_service_test.dart
└── models/                    # Model unit tests
    └── transaction_test.dart

docs/
├── planning/                  # GSD project planning
├── generated/                 # Generated documentation
└── GUIDES/                    # Development guides
```

## Directory Purposes

**`lib/config/`**: App configuration and constants
- Centralized financial parameters (budget thresholds, scoring)
- App-wide configuration values

**`lib/models/`**: Data structures and business entities
- Immutable data classes with JSON serialization
- Business logic validation (e.g., transaction amount)
- Analytics models (SpendingAnalysis, MonthlySpending)

**`lib/providers/`**: Reactive state management
- ChangeNotifier providers for state
- Coordinate between services and UI
- Centralized transaction state in TransactionProvider

**`lib/screens/`**: Feature-specific UI screens
- User interactions and forms
- StatefulWidget for local state
- Connect to providers via `context.watch<>()` and `context.read<>()`

**`lib/services/`**: Business logic and data persistence
- Database operations (SQLite)
- Financial analytics and insights
- Backup/export functionality
- No UI code

**`lib/theme/`**: Custom theming system
- 4 built-in themes (Editorial, Ocean Calm, Sunset Warm, Forest)
- Theme persistence via SharedPreferences
- Material Design 3 color schemes

**`lib/widgets/`**: Reusable UI components
- Charts and visualizations
- Navigation components
- Shared UI elements

**`test/`**: Test suites
- Widget tests for UI components
- Unit tests for services and models
- Integration tests for user flows

## Key File Locations

**Entry Point:**
- `lib/main.dart` - App initialization, logging setup, MultiProvider configuration

**Core State:**
- `lib/providers/transaction_provider.dart` - Central transaction state and CRUD operations

**Data Models:**
- `lib/models/transaction.dart` - Transaction model with validation
- `lib/models/spending_analysis.dart` - Analytics and insights

**Database:**
- `lib/services/database_service.dart` - SQLite operations with web fallback

**Services:**
- `lib/services/analytics_service.dart` - Financial analysis coordination
- `lib/services/backup_service.dart` - JSON export/import
- `lib/services/finance_calculator.dart` - Financial status calculations

**Configuration:**
- `lib/config/finance_config.dart` - Financial parameters and scoring logic

**Theming:**
- `lib/theme/theme_manager.dart` - Theme switching and persistence

**Navigation:**
- `lib/widgets/main_navigation.dart` - Bottom navigation structure

## Where to Add New Code

**New Screens:** `lib/screens/[feature_name]_screen.dart`
- Example: `lib/screens/budget_screen.dart`

**New Models:** `lib/models/[model_name].dart`
- Example: `lib/models/budget.dart`

**New Services:** `lib/services/[service_name].dart`
- Example: `lib/services/notification_service.dart`

**New Providers:** `lib/providers/[provider_name].dart`
- Example: `lib/providers/budget_provider.dart`

**New Widgets:** `lib/widgets/[widget_name].dart`
- Example: `lib/widgets/budget_progress_bar.dart`

**New Configuration:** `lib/config/[config_name].dart`
- Example: `lib/config/notification_config.dart`

## Naming Conventions

**Files:** `snake_case.dart`
- Examples: `transaction_provider.dart`, `home_screen.dart`, `finance_calculator.dart`

**Classes:** `PascalCase`
- Examples: `TransactionProvider`, `HomeScreen`, `FinanceCalculator`

**Variables/Methods:** `camelCase`
- Examples: `monthlyIncome`, `calculateStatus()`, `totalSpending`

**Constants:** `SCREAMING_SNAKE_CASE` (rare - most constants are private static)
- Example: None currently (prefers private static final)

**Screen Files:** `[feature]_screen.dart`
- Examples: `home_screen.dart`, `settings_screen.dart`

**Provider Files:** `[entity]_provider.dart`
- Examples: `transaction_provider.dart`

**Service Files:** `[service]_service.dart`
- Examples: `database_service.dart`, `analytics_service.dart`

## Module Boundaries

**Clear Layer Separation:**
- Screens import Providers and Services
- Providers import Services and Models
- Services import Models and infrastructure
- Models import nothing (pure data)

**No Circular Dependencies:**
- Models → Services → Providers → Screens (one-way)
- Infrastructure independent of business logic

**Feature Independence:**
- Each screen is self-contained
- Services are standalone (no inter-service dependencies)
- Widgets are reusable across screens

---

*Structure analysis: 2026-01-11*
*Update when directory organization changes*
