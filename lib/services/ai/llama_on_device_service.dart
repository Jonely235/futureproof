import 'dart:convert';
import 'package:logging/logging.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/entities/streak_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import 'ai_service.dart';
import 'ai_prompt_builder.dart';
import 'llama_model_manager.dart';
import 'llama_ffi_bindings.dart';

/// On-device implementation of AIService using llama.cpp
/// Runs Llama-3.2-3B-Instruct completely offline on the device
class LlamaOnDeviceService extends AIService {
  static final Logger _logger = Logger('LlamaOnDeviceService');

  final LlamaModelManager _modelManager = LlamaModelManager();
  LlamaFFI? _ffi;
  int? _modelId;
  int? _contextId;

  // Generation parameters
  final double _temperature;
  final double _topP;
  final int _maxTokens;
  final int _contextLength;

  /// Create a new LlamaOnDeviceService
  LlamaOnDeviceService({
    double temperature = 0.7,
    double topP = 0.9,
    int maxTokens = 512,
    int contextLength = 2048,
  })  : _temperature = temperature,
        _topP = topP,
        _maxTokens = maxTokens,
        _contextLength = contextLength;

  @override
  Future<void> initialize() async {
    _logger.info('Initializing LlamaOnDeviceService...');

    try {
      // Check if model is downloaded
      if (!await _modelManager.hasDownloadedModel()) {
        throw AIServiceException(
          'No model found. Please download a model first using LlamaModelManager.',
        );
      }

      // Get or set current model
      if (_modelManager.currentModel == null) {
        final downloadedModels = await _modelManager.getDownloadedModels();
        if (downloadedModels.isEmpty) {
          throw AIServiceException('No downloaded models available');
        }

        // Use the first available model or recommended one
        final model = downloadedModels.firstWhere(
          (m) => m.recommended,
          orElse: () => downloadedModels.first,
        );

        await _modelManager.setCurrentModel(model.id);
      }

      // Initialize FFI bindings
      _ffi = await LlamaFFI.initialize();

      // Load the model
      final modelPath = _modelManager.currentModelPath!;
      _logger.info('Loading model from: $modelPath');

      _modelId = _ffi!.loadModel(
        modelPath,
        contextLength: _contextLength,
        gpuLayers: _getGpuLayerCount(),
      );

      if (_modelId! < 0) {
        throw AIServiceException('Failed to load model. Error code: $_modelId');
      }

      // Initialize generation context
      _contextId = _ffi!.initContext(
        _modelId!,
        temperature: _temperature,
        topP: _topP,
      );

      if (_contextId! < 0) {
        throw AIServiceException('Failed to initialize context. Error code: $_contextId');
      }

      _logger.info('LlamaOnDeviceService initialized successfully');
      _logger.info('Model: ${_modelManager.currentModel?.name}');
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize service', e, stackTrace);
      throw AIServiceException(
        'Failed to initialize LlamaOnDeviceService',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  bool get isReady {
    return _ffi != null && _modelId != null && _contextId != null;
  }

  @override
  Future<String> generateInsights({
    required List transactions,
    required BudgetEntity budget,
    required StreakEntity streak,
    required Map<String, double> categoryBreakdown,
    required double dailyAverage,
  }) async {
    _ensureReady();

    try {
      final topCategoryEntry = categoryBreakdown.entries.isEmpty
          ? MapEntry('None', 0.0)
          : categoryBreakdown.entries.reduce((a, b) => a.value > b.value ? a : b);

      final totalSpent = categoryBreakdown.values.fold(0.0, (sum, v) => sum + v);
      final budgetUsed = totalSpent / (budget.totalAmount + totalSpent);
      final budgetRemaining = budget.getRemaining(totalSpent);

      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final daysRemaining = daysInMonth - now.day;

      final prompt = AIPromptBuilder.buildInsightPrompt(
        categoryBreakdown: categoryBreakdown,
        budgetUsed: budgetUsed,
        budgetRemaining: budgetRemaining,
        currentStreak: streak.currentStreak,
        dailyAverage: dailyAverage,
        dailyBudgetLimit: budget.dailyBudget,
        daysRemaining: daysRemaining,
        topCategoryAmount: topCategoryEntry.value,
        topCategoryName: topCategoryEntry.key,
      );

      return await _generate(prompt);
    } catch (e, stackTrace) {
      _logger.severe('Failed to generate insights', e, stackTrace);
      throw AIServiceException('Failed to generate insights', cause: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<ParsedTransaction?> parseTransaction(String naturalLanguageInput) async {
    _ensureReady();

    try {
      final prompt = AIPromptBuilder.buildTransactionParserPrompt(naturalLanguageInput);
      final response = await _generate(prompt);

      // Extract JSON from response (in case there's extra text)
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response);

      if (jsonMatch == null) {
        _logger.warning('No JSON found in response: $response');
        return null;
      }

      final jsonData = json.decode(jsonMatch.group(0)!) as Map<String, dynamic>;

      return ParsedTransaction(
        amount: (jsonData['amount'] as num).toDouble(),
        category: jsonData['category'] as String,
        description: jsonData['description'] as String,
        isExpense: jsonData['is_expense'] as bool? ?? true,
        confidence: (jsonData['confidence'] as num?)?.toDouble() ?? 0.8,
      );
    } catch (e, stackTrace) {
      _logger.severe('Failed to parse transaction', e, stackTrace);
      return null;
    }
  }

  @override
  Future<String> answerFinancialQuestion(
    String question,
    List transactions,
    BudgetEntity budget,
  ) async {
    _ensureReady();

    try {
      final totalSpent = transactions
          .where((t) => t.isExpense)
          .fold<double>(0, (sum, t) => sum + t.absoluteAmount);

      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final daysRemaining = daysInMonth - now.day;

      // Calculate daily average
      final daysPassed = now.day;
      final dailyAverage = daysPassed > 0 ? totalSpent / daysPassed : 0.0;

      final financialData = {
        'budget': {
          'total': budget.totalAmount,
          'remaining': budget.getRemaining(totalSpent),
          'daysRemaining': daysRemaining,
        },
        'spending': {
          'total': totalSpent,
          'dailyAverage': dailyAverage,
        },
      };

      final prompt = AIPromptBuilder.buildQuestionPrompt(question, financialData);
      return await _generate(prompt);
    } catch (e, stackTrace) {
      _logger.severe('Failed to answer question', e, stackTrace);
      throw AIServiceException('Failed to answer question', cause: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<String> analyzeScenario(
    String scenario,
    List transactions,
    BudgetEntity budget,
  ) async {
    _ensureReady();

    try {
      final categoryBreakdown = <String, double>{};
      for (final transaction in transactions) {
        if (transaction.isExpense) {
          categoryBreakdown[transaction.category] =
              (categoryBreakdown[transaction.category] ?? 0) + transaction.absoluteAmount;
        }
      }

      final totalSpent = categoryBreakdown.values.fold(0.0, (sum, v) => sum + v);

      final currentData = {
        'categories': categoryBreakdown,
        'budget': budget.totalAmount,
        'spent': totalSpent,
      };

      final prompt = AIPromptBuilder.buildScenarioPrompt(scenario, currentData);
      return await _generate(prompt);
    } catch (e, stackTrace) {
      _logger.severe('Failed to analyze scenario', e, stackTrace);
      throw AIServiceException('Failed to analyze scenario', cause: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<String> categorizeTransaction(String description, double amount) async {
    _ensureReady();

    try {
      final prompt = AIPromptBuilder.buildCategorizationPrompt(description, amount);
      final response = await _generate(prompt);

      // Clean up response (remove extra whitespace, newlines, etc.)
      return response.trim().split('\n').first.trim();
    } catch (e, stackTrace) {
      _logger.severe('Failed to categorize transaction', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> chat(String userMessage, FinancialContext context) async {
    _ensureReady();

    try {
      final totalSpent = context.transactions
          .where((t) => t.isExpense)
          .fold<double>(0, (sum, t) => sum + t.absoluteAmount);

      final contextData = {
        'budget': context.budget.totalAmount,
        'spent': totalSpent,
        'remaining': context.budgetRemaining,
        'streak': context.streak.currentStreak,
      };

      final prompt = AIPromptBuilder.buildChatPrompt(userMessage, contextData);
      return await _generate(prompt);
    } catch (e, stackTrace) {
      _logger.severe('Failed to generate chat response', e, stackTrace);
      throw AIServiceException('Failed to generate chat response', cause: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> dispose() async {
    _logger.info('Disposing LlamaOnDeviceService...');

    try {
      if (_contextId != null && _ffi != null) {
        _ffi!.free(_contextId!);
        _contextId = null;
      }

      if (_modelId != null && _ffi != null) {
        _ffi!.freeModel(_modelId!);
        _modelId = null;
      }

      _ffi = null;
      _logger.info('LlamaOnDeviceService disposed successfully');
    } catch (e, stackTrace) {
      _logger.warning('Error during disposal', e, stackTrace);
    }
  }

  // Private helper methods

  Future<String> _generate(String prompt) async {
    if (_ffi == null || _contextId == null) {
      throw AIServiceException('Service not initialized. Call initialize() first.');
    }

    try {
      _logger.fine('Generating with prompt length: ${prompt.length}');

      final response = _ffi!.generate(
        _contextId!,
        prompt,
        maxOutput: _maxTokens,
      );

      _logger.fine('Generated response length: ${response.length}');
      return response;
    } catch (e, stackTrace) {
      _logger.severe('Generation failed', e, stackTrace);
      throw AIServiceException('Generation failed', cause: e, stackTrace: stackTrace);
    }
  }

  void _ensureReady() {
    if (!isReady) {
      throw AIServiceException(
        'Service not ready. Call initialize() and ensure a model is loaded.',
      );
    }
  }

  int _getGpuLayerCount() {
    // For mobile, use CPU only for now
    // Can be enhanced to use Metal on iOS or Vulkan on Android
    return 0;
  }
}
