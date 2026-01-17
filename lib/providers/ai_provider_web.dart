import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../services/ai/ai_service.dart';
import '../services/ai/llama_model_manager.dart';

/// Web stub implementation of AIProvider
/// Used when running on web platform where dart:ffi is not available
class AIProvider with ChangeNotifier {
  static final Logger _logger = Logger('AIProvider');

  bool get isReady => false;
  bool get isInitializing => false;
  String? get errorMessage => 'AI features are not available on web. Please use the mobile or desktop app.';
  AIService? get aiService => null;
  ModelSpec? get currentModel => null;

  Future<void> initialize({String? modelId}) async {
    _logger.warning('AI Service is not available on web platform');
  }

  Future<void> reset() async {}

  Future<void> dispose() async {
    super.dispose();
  }

  // Chat methods - throw appropriate errors for web
  Future<String> chat(String message, FinancialContext context) async {
    _ensureReady();
    return '';
  }

  // Model management methods - return stub values or throw errors
  Future<bool> hasModel() async => false;
  Future<List<ModelSpec>> getAvailableModels() async => const [];
  Future<int> getModelsStorageSize() async => 0;
  Future<void> deleteModel(String modelId) async {}
  Future<void> clearAllModels() async {}

  void _ensureReady() {
    throw Exception(
      'AI features are not available on web. '
      'Please use the mobile or desktop app for AI functionality.',
    );
  }
}
