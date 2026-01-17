import 'package:intl/intl.dart';

/// Builds optimized prompts for Llama-3.2-3B-Instruct for financial contexts
/// Uses Llama 3.2's chat template format with structured system prompts
class AIPromptBuilder {
  static const String systemPrompt = '''You are a financially intelligent AI assistant for FutureProof, a personal finance app. Your role is to help users understand their spending, make smarter financial decisions, and achieve their financial goals.

**Guidelines:**
- Be concise, direct, and actionable
- Use simple language (avoid financial jargon)
- Focus on what matters most to the user's financial health
- Provide specific, personalized insights (not generic advice)
- Be encouraging but realistic
- When suggesting changes, explain the impact clearly
- Use emoji sparingly for emphasis (max 2 per response)

**Financial Context:**
You have access to:
- Transaction history (amounts, categories, dates)
- Budget limits and remaining amounts
- Spending streaks (days under budget)
- Category breakdowns
- Daily spending velocity

**Output Format:**
Keep responses under 3 sentences unless more detail is requested.
Use bullet points for lists.
End with one clear action item when relevant.''';

  /// Build prompt for insight generation
  static String buildInsightPrompt({
    required Map<String, double> categoryBreakdown,
    required double budgetUsed,
    required double budgetRemaining,
    required int currentStreak,
    required double dailyAverage,
    required double dailyBudgetLimit,
    required int daysRemaining,
    required double topCategoryAmount,
    required String topCategoryName,
  }) {
    final topCategoryPercent = categoryBreakdown.isNotEmpty
        ? (topCategoryAmount / categoryBreakdown.values.fold(0, (a, b) => a + b) * 100).round()
        : 0;

    return '''<|begin_of_text|><|start_header_id|>system<|end_header_id|>

$systemPrompt<|eot_id|><|start_header_id|>user<|end_header_id|>

Analyze my financial situation and provide the most important insight:

**Budget Status:**
- Used: ${_formatPercent(budgetUsed)} of monthly budget
- Remaining: \$${_formatMoney(budgetRemaining)}
- Days left: $daysRemaining

**Spending Patterns:**
- Daily average: \$${_formatMoney(dailyAverage)} (limit: \$${_formatMoney(dailyBudgetLimit)})
- Top category: $topCategoryName (\$${_formatMoney(topCategoryAmount)}, $topCategoryPercent% of spending)
- Current streak: $currentStreak days under budget

Generate ONE key insight that matters most right now. Focus on what will have the biggest impact on their financial health this month.<|eot_id|><|start_header_id|>assistant<|end_header_id|>''';
  }

  /// Build prompt for transaction parsing
  static String buildTransactionParserPrompt(String input) {
    return '''<|begin_of_text|><|start_header_id|>system<|end_header_id|>

You are a transaction parser for a finance app. Extract structured data from natural language input.

**Valid Categories:**
Groceries, Dining Out, Transport, Shopping, Entertainment, Healthcare, Bills, Education, Personal Care, Other

**Rules:**
- Amount: Extract the dollar amount (always positive number)
- Category: Choose the most specific category match
- Description: Keep the merchant/item description concise
- Date: Assume today unless specified
- Type: Assume expense unless "income", "salary", "paid" mentioned

**Output Format (JSON only, no markdown):**
{
  "amount": 0.00,
  "category": "category_name",
  "description": "brief description",
  "is_expense": true,
  "confidence": 0.0
}

Examples:
Input: "Lunch at Chipotle \$15"
Output: {"amount": 15.00, "category": "Dining Out", "description": "Lunch at Chipotle", "is_expense": true, "confidence": 0.95}

Input: "Uber to airport \$35"
Output: {"amount": 35.00, "category": "Transport", "description": "Uber to airport", "is_expense": true, "confidence": 0.98}<|eot_id|><|start_header_id|>user<|end_header_id|>

Input: "$input"<|eot_id|><|start_header_id|>assistant<|end_header_id|>''';
  }

  /// Build prompt for financial Q&A
  static String buildQuestionPrompt(
    String question,
    Map<String, dynamic> financialData,
  ) {
    final budget = financialData['budget'] as Map<String, dynamic>;
    final spending = financialData['spending'] as Map<String, dynamic>;

    return '''<|begin_of_text|><|start_header_id|>system<|end_header_id|>

$systemPrompt<|eot_id|><|start_header_id|>user<|end_header_id|>

**My Financial Situation:**
- Monthly budget: \$${_formatMoney(budget['total'] as double)}
- Spent so far: \$${_formatMoney(spending['total'] as double)}
- Remaining: \$${_formatMoney(budget['remaining'] as double)}
- Daily spending avg: \$${_formatMoney(spending['dailyAverage'] as double)}
- Days left: ${budget['daysRemaining'] as int}

**Question:** $question

Provide a direct, helpful answer with specific numbers from my situation.<|eot_id|><|start_header_id|>assistant<|end_header_id|>''';
  }

  /// Build prompt for scenario analysis
  static String buildScenarioPrompt(
    String scenario,
    Map<String, dynamic> currentData,
  ) {
    return '''<|begin_of_text|><|start_header_id|>system<|end_header_id|>

$systemPrompt<|eot_id|><|start_header_id|>user<|end_header_id|>

**Scenario:** $scenario

**Current Spending by Category:**
${_formatCategoryBreakdown(currentData['categories'] as Map<String, double>)}

**Budget:** \$${_formatMoney(currentData['budget'] as double)}
**Current Month Spending:** \$${_formatMoney(currentData['spent'] as double)}

Analyze this scenario and explain:
1. What would change
2. The monthly/yearly impact
3. Whether it's realistic given their current patterns
4. Specific next steps to make it happen

Keep it actionable and specific to their numbers.<|eot_id|><|start_header_id|>assistant<|end_header_id|>''';
  }

  /// Build prompt for transaction categorization
  static String buildCategorizationPrompt(String description, double amount) {
    return '''<|begin_of_text|><|start_header_id|>system<|end_header_id|>

You are a transaction categorizer. Choose the best category from this list:
Groceries, Dining Out, Transport, Shopping, Entertainment, Healthcare, Bills, Education, Personal Care, Other

Consider the description, amount, and typical spending patterns.

Output ONLY the category name, nothing else.<|eot_id|><|start_header_id|>user<|end_header_id|>

Transaction: "$description" (\$${_formatMoney(amount)})<|eot_id|><|start_header_id|>assistant<|end_header_id|>''';
  }

  /// Build prompt for conversational chat
  static String buildChatPrompt(
    String userMessage,
    Map<String, dynamic> contextData,
  ) {
    return '''<|begin_of_text|><|start_header_id|>system<|end_header_id|>

$systemPrompt<|eot_id|><|start_header_id|>user<|end_header_id|>

**Quick Context:**
Budget: \$${_formatMoney(contextData['budget'] as double)}
Spent: \$${_formatMoney(contextData['spent'] as double)}
Remaining: \$${_formatMoney(contextData['remaining'] as double)}
Streak: ${contextData['streak'] as int} days

**User:** $userMessage<|eot_id|><|start_header_id|>assistant<|end_header_id|>''';
  }

  // Helper methods

  static String _formatMoney(double amount) {
    return amount.abs().toStringAsFixed(0);
  }

  static String _formatPercent(double value) {
    return '${(value * 100).toStringAsFixed(0)}%';
  }

  static String _formatCategoryBreakdown(Map<String, double> categories) {
    if (categories.isEmpty) return 'No spending data';

    final buffer = StringBuffer();
    final sortedEntries = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedEntries.take(5)) {
      buffer.writeln('- ${entry.key}: \$${_formatMoney(entry.value)}');
    }

    return buffer.toString().trim();
  }
}
