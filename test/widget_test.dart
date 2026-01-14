import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futureproof/main.dart';
import 'package:futureproof/theme/theme_manager.dart';
import 'package:futureproof/data/repositories/transaction_repository_impl.dart';
import 'package:futureproof/data/repositories/budget_repository_impl.dart';
import 'package:futureproof/data/repositories/gamification_repository_impl.dart';
import 'package:futureproof/domain/services/streak_calculator_service.dart';
import 'package:futureproof/domain/services/achievement_service.dart';
import 'package:futureproof/domain/services/budget_comparison_service.dart';
import 'package:futureproof/domain/services/insight_generation_service.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    final themeManager = ThemeManager();

    // Initialize all required repositories and services
    final transactionRepository = TransactionRepositoryImpl();
    final budgetRepository = BudgetRepositoryImpl();
    final gamificationRepository = GamificationRepositoryImpl();
    final streakCalculatorService = StreakCalculatorService();
    final achievementService = AchievementService();
    final budgetComparisonService = BudgetComparisonService();
    final insightGenerationService = InsightGenerationService();

    await tester.pumpWidget(FutureProofApp(
      themeManager: themeManager,
      transactionRepository: transactionRepository,
      budgetRepository: budgetRepository,
      gamificationRepository: gamificationRepository,
      streakCalculatorService: streakCalculatorService,
      achievementService: achievementService,
      budgetComparisonService: budgetComparisonService,
      insightGenerationService: insightGenerationService,
    ));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
