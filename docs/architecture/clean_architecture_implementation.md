# Clean Architecture Implementation Guide

## Overview

This document explains the Clean Architecture implementation for FutureProof, including the structure, how to use it, and migration path.

## Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                     │
│  (UI - Screens, Widgets, Providers)                     │
│  - Uses domain entities and repositories                │
│  - Manages UI state with ChangeNotifier                 │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                     DOMAIN LAYER                        │
│  (Business Logic - Entities, Services, Repositories)   │
│  - Framework-independent                                │
│  - Contains business rules                               │
│  - Defines repository interfaces                        │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                      DATA LAYER                         │
│  (Data Access - DTOs, Datasources, Mappers)            │
│  - Implements repository interfaces                    │
│  - Converts between DTOs and entities                   │
│  - Accesses external services (DB, API)                 │
└─────────────────────────────────────────────────────────┘
```

## Directory Structure

```
lib/
├── domain/                          # Business logic layer
│   ├── entities/                    # Core business objects
│   │   ├── transaction_entity.dart
│   │   ├── budget_entity.dart
│   │   ├── streak_entity.dart
│   │   └── gamification_entity.dart
│   ├── value_objects/               # Value objects
│   │   ├── money.dart
│   │   └── transaction_date.dart
│   ├── repositories/                # Repository interfaces
│   │   ├── transaction_repository.dart
│   │   ├── budget_repository.dart
│   │   ├── gamification_repository.dart
│   │   └── cloud_backup_repository.dart
│   └── services/                    # Domain services
│       ├── streak_calculator_service.dart
│       ├── budget_comparison_service.dart
│       ├── achievement_service.dart
│       └── insight_generation_service.dart
│
├── data/                            # Data access layer
│   ├── mappers/                     # Entity ↔ Model conversion
│   │   └── transaction_mapper.dart
│   └── repositories/                # Repository implementations
│       ├── transaction_repository_impl.dart
│       ├── budget_repository_impl.dart
│       └── gamification_repository_impl.dart
│
├── providers/                       # Presentation layer (state)
│   ├── transaction_provider.dart    # (existing - to be refactored)
│   ├── gamification_provider.dart   # (new - streaks, achievements)
│   └── insight_provider.dart        # (new - insights)
│
└── screens/                         # UI layer
    └── home_screen.dart             # (uses providers)
```

## Key Components

### 1. Domain Entities (Framework-independent)

**TransactionEntity**
```dart
final transaction = TransactionEntity.create(
  id: '1',
  amount: -50.0,
  category: 'groceries',
  date: DateTime.now(),
);

// Business rules built-in
print(transaction.isExpense);  // true
print(transaction.absoluteAmount);  // 50.0
```

**StreakEntity**
```dart
final streak = StreakEntity(
  currentStreak: 5,
  bestStreak: 10,
  streakStartDate: DateTime.now(),
  lastBrokenDate: DateTime.now(),
);

// Business rules
print(streak.isActive);  // true
print(streak.isNewBest);  // false
print(streak.milestone);  // "Good! 1 week!"
```

### 2. Domain Services (Business logic)

**StreakCalculatorService**
```dart
final service = StreakCalculatorService();
final streak = service.calculateStreak(
  transactions: transactions,
  budget: budget,
  currentStreak: currentStreak,
);
```

**InsightGenerationService**
```dart
final service = InsightGenerationService();
final insights = service.generateInsights(
  transactions: transactions,
  budget: budget,
  streak: streak,
  monthOverMonth: momData,
);
```

### 3. Repositories (Data access contracts)

**Interfaces (Domain)**
```dart
abstract class TransactionRepository {
  Future<List<TransactionEntity>> getAllTransactions();
  Future<void> addTransaction(TransactionEntity transaction);
  // ...
}
```

**Implementations (Data)**
```dart
class TransactionRepositoryImpl implements TransactionRepository {
  final DatabaseService _databaseService;

  @override
  Future<List<TransactionEntity>> getAllTransactions() async {
    final models = await _databaseService.getAllTransactions();
    return TransactionMapper.toEntityList(models);
  }
}
```

### 4. Providers (Presentation state management)

**GamificationProvider**
```dart
class GamificationProvider extends ChangeNotifier {
  final GamificationRepository _repository;
  final StreakCalculatorService _streakService;

  Future<void> loadGamificationData() async {
    _streak = await _repository.getCurrentStreak();
    // Use domain service for calculations
    final calculated = _streakService.calculateStreak(...);
    _streak = calculated;
    notifyListeners();
  }
}
```

## Usage Example: Wiring Up in main.dart

```dart
// main.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize repositories
  final transactionRepo = TransactionRepositoryImpl();
  final budgetRepo = BudgetRepositoryImpl();
  final gamificationRepo = GamificationRepositoryImpl();

  // Domain services (can be singleton or created in providers)
  final streakService = StreakCalculatorService();
  final achievementService = AchievementService();
  final budgetComparisonService = BudgetComparisonService();
  final insightService = InsightGenerationService();

  runApp(
    MultiProvider(
      providers: [
        // Existing provider (will be refactored later)
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(),
        ),

        // NEW: Gamification provider (streaks, achievements)
        ChangeNotifierProvider(
          create: (_) => GamificationProvider(
            gamificationRepository: gamificationRepo,
            transactionRepository: transactionRepo,
            budgetRepository: budgetRepo,
            streakCalculator: streakService,
            achievementService: achievementService,
            budgetComparisonService: budgetComparisonService,
          ),
        ),

        // NEW: Insight provider (dynamic insights)
        ChangeNotifierProvider(
          create: (_) => InsightProvider(
            transactionRepository: transactionRepo,
            budgetRepository: budgetRepo,
            gamificationRepository: gamificationRepo,
            insightService: insightService,
            budgetComparisonService: budgetComparisonService,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

## Usage Example: Home Screen with Real Data

```dart
// home_screen.dart

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gamificationProvider = context.watch<GamificationProvider>();
    final insightProvider = context.watch<InsightProvider>();

    return Scaffold(
      body: Column(
        children: [
          // Real streak data (no more hardcoded "🔥 3 days")
          if (gamificationProvider.streak != null)
            _buildStreakCard(gamificationProvider.streak!),

          // Dynamic insights (no more hardcoded tips)
          ListView.builder(
            itemCount: insightProvider.insights.length,
            itemBuilder: (context, index) {
              final insight = insightProvider.insights[index];
              return _buildInsightCard(insight);
            },
          ),

          // Real month-over-month comparison
          if (gamificationProvider.monthOverMonthComparison != null)
            _buildMoMCard(gamificationProvider.monthOverMonthComparison!),
        ],
      ),
    );
  }

  Widget _buildStreakCard(StreakEntity streak) {
    return Card(
      child: Column(
        children: [
          Text(streak.milestone),  // "Good! 1 week!"
          Text('🔥 ${streak.currentStreak} days'),
          Text(_getMotivationMessage(streak)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(Insight insight) {
    return Card(
      child: ListTile(
        leading: Text(insight.icon),  // "⚠️", "✅", etc.
        title: Text(insight.title),
        subtitle: Text(insight.message),
        trailing: insight.actionText != null
            ? ElevatedButton(
                onPressed: () { /* handle action */ },
                child: Text(insight.actionText!),
              )
            : null,
      ),
    );
  }

  Widget _buildMoMCard(MonthOverMonthComparison mom) {
    return Card(
      child: Column(
        children: [
          Text('vs Last Month'),
          Text(mom.formattedDifference),  // "+$200" or "-$200"
          Text(mom.formattedPercentage),  // "+12%" or "-12%"
          Text(mom.message),  // Dynamic message
        ],
      ),
    );
  }

  String _getMotivationMessage(StreakEntity streak) {
    if (streak.currentStreak == 0) return 'Start your streak today!';
    if (streak.currentStreak < 3) return 'Keep going!';
    if (streak.currentStreak < 7) return 'Building momentum!';
    if (streak.currentStreak < 30) return 'Amazing streak!';
    return 'Legendary!';
  }
}
```

## Data Flow Example

```
User adds transaction
    ↓
TransactionProvider.addTransaction()
    ↓
TransactionRepository.addTransaction(entity)
    ↓
DatabaseService.addTransaction(model)  [DATA LAYER]
    ↓
GamificationProvider.onTransactionsChanged()
    ↓
StreakCalculatorService.calculateStreak()  [DOMAIN SERVICE]
    ↓
GamificationRepository.updateStreak()
    ↓
GamificationProvider.streak updated
    ↓
Home Screen rebuilds with new streak data
    ↓
User sees: "🔥 4 days" (real data!)
```

## Benefits

1. **Testability**: Each layer can be tested in isolation
   - Domain entities have no dependencies
   - Services can be unit tested
   - Repositories can be mocked

2. **Maintainability**: Clear boundaries
   - Domain logic independent of framework
   - Data access isolated
   - UI only concerned with presentation

3. **Scalability**: Easy to extend
   - Add new features in domain layer
   - Swap data sources (SQLite → Google Drive)
   - Add new UI without affecting business logic

4. **Real Data**: No more hardcoded values
   - Streaks calculated from actual transactions
   - Insights generated dynamically
   - Month-over-month comparisons accurate

## Migration Strategy

### Phase 1: Foundation (DONE ✅)
- Create domain entities
- Create repository interfaces
- Create domain services
- Create repository implementations
- Create new providers

### Phase 2: Wire to UI (IN PROGRESS)
- Update main.dart to provide repositories and new providers
- Update home screen to use GamificationProvider
- Update home screen to use InsightProvider
- Replace hardcoded values with real data

### Phase 3: Remove Old Code
- Remove hardcoded motivational data
- Remove old SmartInsightsWidget from settings
- Clean up unused imports

### Phase 4: Testing
- Unit test domain entities
- Unit test domain services
- Widget test with mock providers
- Integration test real data flow

## Next Steps

1. ✅ Domain layer created
2. ✅ Data layer created
3. ✅ New providers created
4. ⏸️ Wire up in main.dart
5. ⏸️ Update home screen to use real data
6. ⏸️ Move insights to home screen (from settings)
7. ⏸️ Add Google Sign-In + Drive sync
8. ⏸️ Test and polish

## Common Patterns

### Creating a New Feature

1. **Define entity** in `domain/entities/`
2. **Define repository interface** in `domain/repositories/`
3. **Implement repository** in `data/repositories/`
4. **Create domain service** (if complex logic) in `domain/services/`
5. **Create provider** in `providers/`
6. **Use in UI** (screen/widget)

### Testing

```dart
// Unit test domain service
test('StreakCalculatorService should calculate streak correctly', () {
  final service = StreakCalculatorService();
  final streak = service.calculateStreak(
    transactions: testTransactions,
    budget: testBudget,
    currentStreak: null,
  );

  expect(streak.currentStreak, 5);
});

// Widget test with mock provider
testWidgets('HomeScreen should display streak', (tester) async {
  final mockProvider = MockGamificationProvider();
  when(mockProvider.streak).thenReturn(testStreak);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<GamificationProvider>.value(value: mockProvider),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );

  expect(find.text('🔥 5 days'), findsOneWidget);
});
```

## Conclusion

This Clean Architecture implementation provides:
- ✅ Clear separation of concerns
- ✅ Testable business logic
- ✅ Real data instead of hardcoded values
- ✅ Easy to extend and maintain
- ✅ Scalable for future features

The architecture is now ready to power all the motivational features with real, dynamic data!
