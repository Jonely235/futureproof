import 'package:futureproof/domain/entities/transaction_entity.dart';
import 'package:futureproof/services/ai/ai_service_interface.dart';

/// Web-compatible stub implementation of AIService
/// Used when running on web platform where dart:ffi is not available
class AIServiceStub implements AIServiceInterface {
  @override
  bool get isInitialized => false;

  @override
  Future<void> initialize() async {
    throw UnimplementedError('AI Service is not available on web platform. Please use mobile or desktop app.');
  }

  @override
  Future<void> downloadModel(String modelId, {void Function(double)? onProgress}) async {
    throw UnimplementedError('AI Service is not available on web platform.');
  }

  @override
  Future<List<String>> getDownloadedModels() async => [];

  @override
  Future<void> deleteModel(String modelId) async {
    throw UnimplementedError('AI Service is not available on web platform.');
  }

  @override
  Future<String> generateInsights({
    required List<TransactionEntity> transactions,
    required Map<String, dynamic> budget,
    required Map<String, dynamic> streak,
  }) async {
    throw UnimplementedError('AI Service is not available on web platform. Please use mobile or desktop app.');
  }

  @override
  Future<String> askQuestion(String question, Map<String, dynamic> budget) async {
    throw UnimplementedError('AI Service is not available on web platform. Please use mobile or desktop app.');
  }

  @override
  Future<String> analyzeScenario(String scenario, List<TransactionEntity> transactions, Map<String, dynamic> budget) async {
    throw UnimplementedError('AI Service is not available on web platform. Please use mobile or desktop app.');
  }

  @override
  Future<String> chat(String message, Map<String, dynamic> context) async {
    throw UnimplementedError('AI Service is not available on web platform. Please use mobile or desktop app.');
  }
}
