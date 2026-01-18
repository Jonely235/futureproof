import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../domain/entities/budget_entity.dart';
import '../domain/entities/streak_entity.dart';
import '../domain/entities/transaction_entity.dart';
import '../services/ai/ai_service.dart';
import '../services/ai/llama_on_device_service.dart'
    if (dart.library.html) '../services/ai/ai_service_stub.dart';
import '../services/ai/llama_model_manager.dart'
    if (dart.library.html) '../services/ai/llama_model_manager_web.dart';

/// Provider for AI service state management
/// Manages the lifecycle of the on-device AI service
class AIProvider with ChangeNotifier {
  static final Logger _logger = Logger('AIProvider');

  AIService? _aiService;
  ModelSpec? _currentModel;
  bool _isInitializing = false;
  bool _isReady = false;
  String? _errorMessage;

  final LlamaModelManager _modelManager = LlamaModelManager();

  /// Get the current AI service instance
  AIService? get aiService => _aiService;

  /// Get the current model specification
  ModelSpec? get currentModel => _currentModel;

  /// Is the service currently initializing?
  bool get isInitializing => _isInitializing;

  /// Is the service ready to process requests?
  bool get isReady => _isReady;

  /// Get the last error message
  String? get errorMessage => _errorMessage;

  /// Get available models
  Future<List<ModelSpec>> getAvailableModels() => _modelManager.getDownloadedModels();

  /// Get recommended model for this device
  Future<ModelSpec> getRecommendedModel() => _modelManager.getRecommendedModel();

  /// Check if any model is downloaded
  Future<bool> hasModel() => _modelManager.hasDownloadedModel();

  /// Initialize the AI service with a specific model
  Future<void> initialize({String? modelId}) async {
    if (_isInitializing || _isReady) {
      _logger.info('Service already initializing or ready');
      return;
    }

    _isInitializing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _logger.info('Initializing AI provider...');

      // Check if a model is available
      final hasDownloadedModel = await _modelManager.hasDownloadedModel();

      if (!hasDownloadedModel) {
        throw Exception(
          'No model downloaded. Please download a model first. '
          'Use the AI Settings screen to download a model.',
        );
      }

      // Set the model if specified, otherwise use the current one
      if (modelId != null) {
        await _modelManager.setCurrentModel(modelId);
      }

      _currentModel = _modelManager.currentModel;

      // Create and initialize the service
      _aiService = LlamaOnDeviceService(
        temperature: 0.7,
        topP: 0.9,
        maxTokens: 512,
        contextLength: 2048,
      );

      await _aiService!.initialize();

      _isReady = true;
      _logger.info('AI provider initialized successfully with model: ${_currentModel?.name}');
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize AI provider', e, stackTrace);
      _errorMessage = e.toString();
      _isReady = false;
      rethrow;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Generate financial insights
  Future<String> generateInsights({
    required List<TransactionEntity> transactions,
    required BudgetEntity budget,
    required StreakEntity streak,
    required Map<String, double> categoryBreakdown,
    required double dailyAverage,
  }) async {
    _ensureReady();

    try {
      return await _aiService!.generateInsights(
        transactions: transactions,
        budget: budget,
        streak: streak,
        categoryBreakdown: categoryBreakdown,
        dailyAverage: dailyAverage,
      );
    } catch (e, stackTrace) {
      _logger.severe('Failed to generate insights', e, stackTrace);
      _errorMessage = 'Failed to generate insights: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Parse natural language transaction input
  Future<ParsedTransaction?> parseTransaction(String input) async {
    _ensureReady();

    try {
      return await _aiService!.parseTransaction(input);
    } catch (e, stackTrace) {
      _logger.severe('Failed to parse transaction', e, stackTrace);
      return null;
    }
  }

  /// Answer a financial question
  Future<String> answerQuestion(
    String question,
    List<TransactionEntity> transactions,
    BudgetEntity budget,
  ) async {
    _ensureReady();

    try {
      return await _aiService!.answerFinancialQuestion(
        question,
        transactions,
        budget,
      );
    } catch (e, stackTrace) {
      _logger.severe('Failed to answer question', e, stackTrace);
      rethrow;
    }
  }

  /// Analyze a "what-if" scenario
  Future<String> analyzeScenario(
    String scenario,
    List transactions,
    dynamic budget,
  ) async {
    _ensureReady();

    try {
      return await _aiService!.analyzeScenario(scenario, transactions, budget);
    } catch (e, stackTrace) {
      _logger.severe('Failed to analyze scenario', e, stackTrace);
      rethrow;
    }
  }

  /// Categorize a transaction
  Future<String> categorizeTransaction(String description, double amount) async {
    _ensureReady();

    try {
      return await _aiService!.categorizeTransaction(description, amount);
    } catch (e, stackTrace) {
      _logger.severe('Failed to categorize transaction', e, stackTrace);
      rethrow;
    }
  }

  /// Chat with the AI
  Future<String> chat(String message, FinancialContext context) async {
    _ensureReady();

    try {
      return await _aiService!.chat(message, context);
    } catch (e, stackTrace) {
      _logger.severe('Failed to chat', e, stackTrace);
      rethrow;
    }
  }

  /// Reset the service (clear error, reinitialize)
  Future<void> reset() async {
    _logger.info('Resetting AI provider...');

    await dispose();

    _errorMessage = null;
    _isInitializing = false;
    _isReady = false;
    notifyListeners();
  }

  /// Clean up resources
  Future<void> dispose() async {
    _logger.info('Disposing AI provider...');

    try {
      if (_aiService != null) {
        await _aiService!.dispose();
        _aiService = null;
      }
    } catch (e, stackTrace) {
      _logger.warning('Error disposing AI service', e, stackTrace);
    }

    _isReady = false;
    super.dispose();
  }

  void _ensureReady() {
    if (!_isReady || _aiService == null) {
      throw Exception(
        'AI service not ready. Please wait for initialization to complete '
        'or download a model in settings.',
      );
    }
  }

  /// Model management methods

  /// Delete a model
  Future<void> deleteModel(String modelId) async {
    await _modelManager.deleteModel(modelId);

    // If the deleted model was in use, reset the service
    if (_currentModel?.id == modelId) {
      await reset();
    }

    notifyListeners();
  }

  /// Get total storage used by models
  Future<int> getModelsStorageSize() => _modelManager.getModelsStorageSize();

  /// Clear all downloaded models
  Future<void> clearAllModels() async {
    await _modelManager.clearAllModels();
    await reset();
    notifyListeners();
  }
}
