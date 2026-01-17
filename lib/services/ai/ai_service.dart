import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/entities/streak_entity.dart';

/// Abstract AI Service interface for Llama-3.2-3B-Instruct integration
/// This abstraction allows for multiple implementations (on-device, cloud, hybrid)
abstract class AIService {
  /// Initialize the AI service and load the model
  Future<void> initialize();

  /// Check if the service is ready to process requests
  bool get isReady;

  /// Generate personalized financial insights from user data
  Future<String> generateInsights({
    required List<TransactionEntity> transactions,
    required BudgetEntity budget,
    required StreakEntity streak,
    required Map<String, double> categoryBreakdown,
    required double dailyAverage,
  });

  /// Parse natural language input into structured transaction data
  /// Example: "Lunch at Chipotle for $18" -> Transaction(amount: 18.0, category: "Dining", description: "Lunch at Chipotle")
  Future<ParsedTransaction?> parseTransaction(String naturalLanguageInput);

  /// Answer financial questions in natural language
  /// Example: "Can I afford a new laptop this month?"
  Future<String> answerFinancialQuestion(
    String question,
    List<TransactionEntity> transactions,
    BudgetEntity budget,
  );

  /// Generate "what-if" scenario analysis
  /// Example: "What if I cut dining expenses to $200/month?"
  Future<String> analyzeScenario(
    String scenario,
    List<TransactionEntity> transactions,
    BudgetEntity budget,
  );

  /// Categorize a transaction based on description
  Future<String> categorizeTransaction(String description, double amount);

  /// Generate conversational response for chat interface
  Future<String> chat(String userMessage, FinancialContext context);

  /// Clean up resources
  Future<void> dispose();
}

/// Parsed transaction from natural language input
class ParsedTransaction {
  final double amount;
  final String category;
  final String description;
  final DateTime? date;
  final bool isExpense;
  final double confidence;

  const ParsedTransaction({
    required this.amount,
    required this.category,
    required this.description,
    this.date,
    this.isExpense = true,
    this.confidence = 1.0,
  });

  @override
  String toString() {
    return 'ParsedTransaction(amount: $amount, category: $category, description: $description, isExpense: $isExpense, confidence: $confidence)';
  }
}

/// Financial context for AI interactions
class FinancialContext {
  final List<TransactionEntity> transactions;
  final BudgetEntity budget;
  final StreakEntity streak;
  final Map<String, double> categoryBreakdown;
  final double monthlySpending;
  final double dailyAverage;
  final int daysRemainingInMonth;
  final double budgetRemaining;

  const FinancialContext({
    required this.transactions,
    required this.budget,
    required this.streak,
    required this.categoryBreakdown,
    required this.monthlySpending,
    required this.dailyAverage,
    required this.daysRemainingInMonth,
    required this.budgetRemaining,
  });
}

/// AI service exception
class AIServiceException implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const AIServiceException(
    this.message, {
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('AIServiceException: $message');
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }
    return buffer.toString();
  }
}
