import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'providers/transaction_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/insight_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/anti_fragile_wallet_provider.dart';
import 'providers/settings_expansion_provider.dart';
import 'providers/financial_goals_provider.dart';
import 'providers/vault_provider.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'data/repositories/budget_repository_impl.dart';
import 'data/repositories/gamification_repository_impl.dart';
import 'data/repositories/anti_fragile_settings_repository_impl.dart';
import 'data/repositories/file_vault_repository_impl.dart';
import 'domain/services/streak_calculator_service.dart';
import 'domain/services/achievement_service.dart';
import 'domain/services/budget_comparison_service.dart';
import 'domain/services/insight_generation_service.dart';
import 'theme/theme_manager.dart';
import 'widgets/main_navigation.dart';
import 'utils/app_logger.dart';

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
  final antiFragileSettingsRepository = AntiFragileSettingsRepositoryImpl();

  // Initialize multi-vault system
  final vaultRepository = FileVaultRepositoryImpl();

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
    antiFragileSettingsRepository: antiFragileSettingsRepository,
    vaultRepository: vaultRepository,
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
  final AntiFragileSettingsRepositoryImpl antiFragileSettingsRepository;
  final FileVaultRepositoryImpl vaultRepository;
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
    required this.antiFragileSettingsRepository,
    required this.vaultRepository,
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
        // NEW: Vault provider - manages multi-vault system
        ChangeNotifierProvider(
          create: (_) => VaultProvider(
            vaultRepository: widget.vaultRepository,
          )..initialize(),
        ),

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

        // NEW: AI provider - manages Llama on-device inference
        ChangeNotifierProvider(
          create: (_) => AIProvider(),
        ),

        // NEW: Anti-Fragile Wallet provider - manages Virtual Vault & War Mode
        ChangeNotifierProvider(
          create: (_) => AntiFragileWalletProvider(
            transactionRepository: widget.transactionRepository,
            settingsRepository: widget.antiFragileSettingsRepository,
          ),
        ),

        // Settings Expansion Provider - manages accordion state
        ChangeNotifierProvider(
          create: (_) => SettingsExpansionProvider(),
        ),

        // Financial Goals Provider - manages income and savings goals
        ChangeNotifierProvider(
          create: (_) => FinancialGoalsProvider(),
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
