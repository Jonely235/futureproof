import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';

/// Manages Llama model files (downloading, storage, verification)
class LlamaModelManager {
  static final Logger _logger = Logger('LlamaModelManager');

  /// Model variants available for download
  static const Map<String, ModelSpec> availableModels = {
    '1B-Q4': ModelSpec(
      id: 'Llama-3.2-1B-Instruct-Q4_K_M.gguf',
      name: 'Llama 3.2 1B (Q4 Quantized)',
      downloadUrl: 'https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf',
      fileSize: 768 * 1024 * 1024, // ~768MB
      recommended: true,
      contextLength: 128000,
    ),
    '3B-Q4': ModelSpec(
      id: 'Llama-3.2-3B-Instruct-Q4_K_M.gguf',
      name: 'Llama 3.2 3B (Q4 Quantized)',
      downloadUrl: 'https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf',
      fileSize: 1900 * 1024 * 1024, // ~1.9GB
      recommended: true,
      contextLength: 128000,
    ),
  };

  String? _currentModelPath;
  ModelSpec? _currentModel;

  /// Get the directory where models are stored
  Future<Directory> _getModelDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory(path.join(appDir.path, 'llama_models'));

    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
      _logger.info('Created model directory: ${modelDir.path}');
    }

    return modelDir;
  }

  /// Get list of downloaded models
  Future<List<ModelSpec>> getDownloadedModels() async {
    final modelDir = await _getModelDirectory();
    final models = <ModelSpec>[];

    if (await modelDir.exists()) {
      await for (final entity in modelDir.list()) {
        if (entity is File) {
          final fileName = path.basename(entity.path);
          final fileSize = await entity.length();
          final spec = availableModels.values.firstWhere(
            (m) => m.id == fileName,
            orElse: () => ModelSpec(
              id: fileName,
              name: 'Unknown Model',
              downloadUrl: '',
              fileSize: fileSize,
              recommended: false,
              contextLength: 0,
            ),
          );
          models.add(spec);
        }
      }
    }

    return models;
  }

  /// Check if any model is downloaded
  Future<bool> hasDownloadedModel() async {
    final models = await getDownloadedModels();
    return models.isNotEmpty;
  }

  /// Get the currently loaded model path
  String? get currentModelPath => _currentModelPath;

  /// Get the currently loaded model spec
  ModelSpec? get currentModel => _currentModel;

  /// Set the current model (must be already downloaded)
  Future<void> setCurrentModel(String modelId) async {
    final modelDir = await _getModelDirectory();
    final modelPath = path.join(modelDir.path, modelId);

    if (!await File(modelPath).exists()) {
      throw ModelNotFoundException('Model not found: $modelId. Download it first.');
    }

    _currentModelPath = modelPath;
    _currentModel = availableModels[modelId.split('-')[0]] ??
        availableModels.values.firstWhere(
          (m) => m.id == modelId,
          orElse: () => ModelSpec(
            id: modelId,
            name: 'Custom Model',
            downloadUrl: '',
            fileSize: 0,
            recommended: false,
            contextLength: 128000,
          ),
        );

    _logger.info('Current model set to: $modelId');
  }

  /// Delete a model file
  Future<void> deleteModel(String modelId) async {
    final modelDir = await _getModelDirectory();
    final modelPath = path.join(modelDir.path, modelId);
    final file = File(modelPath);

    if (await file.exists()) {
      await file.delete();
      _logger.info('Deleted model: $modelId');

      // Clear current model if it was the deleted one
      if (_currentModelPath == modelPath) {
        _currentModelPath = null;
        _currentModel = null;
      }
    }
  }

  /// Get total storage used by models
  Future<int> getModelsStorageSize() async {
    final models = await getDownloadedModels();
    return models.fold<int>(0, (sum, model) => sum + model.fileSize);
  }

  /// Verify model file integrity (basic check)
  Future<bool> verifyModel(String modelId) async {
    try {
      final modelDir = await _getModelDirectory();
      final modelPath = path.join(modelDir.path, modelId);
      final file = File(modelPath);

      if (!await file.exists()) return false;

      // Basic check: file should be at least 100MB
      final fileSize = await file.length();
      if (fileSize < 100 * 1024 * 1024) {
        _logger.warning('Model file seems too small: ${fileSize} bytes');
        return false;
      }

      return true;
    } catch (e) {
      _logger.severe('Error verifying model: $e');
      return false;
    }
  }

  /// Get recommended model for device based on available memory
  Future<ModelSpec> getRecommendedModel() async {
    // For now, recommend the 1B model for better mobile performance
    // In production, you'd check device RAM and recommend accordingly
    return availableModels['1B-Q4']!;
  }

  /// Clear all downloaded models
  Future<void> clearAllModels() async {
    final modelDir = await _getModelDirectory();

    if (await modelDir.exists()) {
      await modelDir.delete(recursive: true);
      await modelDir.create(recursive: true);
      _logger.info('Cleared all models');
    }

    _currentModelPath = null;
    _currentModel = null;
  }
}

/// Model specification
class ModelSpec {
  final String id;
  final String name;
  final String downloadUrl;
  final int fileSize;
  final bool recommended;
  final int contextLength;

  const ModelSpec({
    required this.id,
    required this.name,
    required this.downloadUrl,
    required this.fileSize,
    required this.recommended,
    required this.contextLength,
  });

  String get fileSizeFormatted {
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(0)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(0)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  @override
  String toString() => name;
}

/// Model not found exception
class ModelNotFoundException implements Exception {
  final String message;
  const ModelNotFoundException(this.message);

  @override
  String toString() => 'ModelNotFoundException: $message';
}
