import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'providers/transaction_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/insight_provider.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'data/repositories/budget_repository_impl.dart';
import 'data/repositories/gamification_repository_impl.dart';
import 'domain/services/streak_calculator_service.dart';
import 'domain/services/achievement_service.dart';
import 'domain/services/budget_comparison_service.dart';
import 'domain/services/insight_generation_service.dart';
import 'theme/theme_manager.dart';
import 'widgets/main_navigation.dart';

String _getEmojiForLevel(Level level) {
  if (level >= Level.SEVERE) return '❌';
  if (level >= Level.WARNING) return '⚠️';
  return 'ℹ️';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    final emoji = _getEmojiForLevel(record.level);
    final timestamp = record.time.toIso8601String().substring(11, 23);
    final message =
        '$emoji ${record.level.name} [$timestamp] ${record.loggerName}: ${record.message}';

    if (record.error != null) {
      // ignore: avoid_print
      print('$message\n  Error: ${record.error}');
      if (record.stackTrace != null) {
        // ignore: avoid_print
        print('  Stack: ${record.stackTrace}');
      }
    } else if (record.stackTrace != null) {
      // ignore: avoid_print
      print('$message\n  Stack: ${record.stackTrace}');
    } else {
      // ignore: avoid_print
      print(message);
    }
  });

  // Initialize theme manager
  final themeManager = ThemeManager();
  await themeManager.init();

  // Initialize Clean Architecture repositories
  final transactionRepository = TransactionRepositoryImpl();
  final budgetRepository = BudgetRepositoryImpl();
  final gamificationRepository = GamificationRepositoryImpl();

  // Initialize domain services
  final streakCalculatorService = StreakCalculatorService();
  final achievementService = AchievementService();
  final budgetComparisonService = BudgetComparisonService();
  final insightGenerationService = InsightGenerationService();

  runApp(FutureProofApp(
    themeManager: themeManager,
    transactionRepository: transactionRepository,
    budgetRepository: budgetRepository,
    gamificationRepository: gamificationRepository,
    streakCalculatorService: streakCalculatorService,
    achievementService: achievementService,
    budgetComparisonService: budgetComparisonService,
    insightGenerationService: insightGenerationService,
  ));
}

class FutureProofApp extends StatefulWidget {
  final ThemeManager themeManager;
  final TransactionRepositoryImpl transactionRepository;
  final BudgetRepositoryImpl budgetRepository;
  final GamificationRepositoryImpl gamificationRepository;
  final StreakCalculatorService streakCalculatorService;
  final AchievementService achievementService;
  final BudgetComparisonService budgetComparisonService;
  final InsightGenerationService insightGenerationService;

  const FutureProofApp({
    super.key,
    required this.themeManager,
    required this.transactionRepository,
    required this.budgetRepository,
    required this.gamificationRepository,
    required this.streakCalculatorService,
    required this.achievementService,
    required this.budgetComparisonService,
    required this.insightGenerationService,
  });

  @override
  State<FutureProofApp> createState() => _FutureProofAppState();
}

class _FutureProofAppState extends State<FutureProofApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Existing provider (will be refactored later to use repository)
        ChangeNotifierProvider(create: (_) => TransactionProvider()),

        // NEW: Gamification provider - manages streaks, achievements, MoM comparisons
        ChangeNotifierProvider(
          create: (_) => GamificationProvider(
            gamificationRepository: widget.gamificationRepository,
            transactionRepository: widget.transactionRepository,
            budgetRepository: widget.budgetRepository,
            streakCalculator: widget.streakCalculatorService,
            achievementService: widget.achievementService,
            budgetComparisonService: widget.budgetComparisonService,
          ),
        ),

        // NEW: Insight provider - generates dynamic financial insights
        ChangeNotifierProvider(
          create: (_) => InsightProvider(
            transactionRepository: widget.transactionRepository,
            budgetRepository: widget.budgetRepository,
            gamificationRepository: widget.gamificationRepository,
            insightService: widget.insightGenerationService,
            budgetComparisonService: widget.budgetComparisonService,
          ),
        ),

        // Theme manager
        Provider<ThemeManager>.value(value: widget.themeManager),
      ],
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, child) {
          return MaterialApp(
            title: 'FutureProof',
            debugShowCheckedModeBanner: false,
            theme: themeManager.getThemeData(),
            home: const MainNavigation(),
          );
        },
      ),
    );
  }
}
