import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:logging/logging.dart';

// Native function type definitions (must be top-level)
typedef _llama_load_model_from_file_native = Int32 Function(
  Pointer<Utf8> modelPath,
  Int32 nCtx,
  Int32 nGpuLayers,
);
typedef _llama_load_model_from_file_dart = int Function(
  Pointer<Utf8> modelPath,
  int nCtx,
  int nGpuLayers,
);

typedef _llama_free_model_native = Void Function(Int32 modelId);
typedef _llama_free_model_dart = void Function(int modelId);

typedef _llama_init_context_native = Int32 Function(
  Int32 modelId,
  Float temp,
  Float topP,
);
typedef _llama_init_context_dart = int Function(
  int modelId,
  double temp,
  double topP,
);

typedef _llama_free_native = Void Function(Int32 ctxId);
typedef _llama_free_dart = void Function(int ctxId);

typedef _llama_generate_native = Int32 Function(
  Int32 ctxId,
  Pointer<Utf8> prompt,
  Pointer<Utf8> output,
  Int32 maxOutput,
);
typedef _llama_generate_dart = int Function(
  int ctxId,
  Pointer<Utf8> prompt,
  Pointer<Utf8> output,
  int maxOutput,
);

typedef _llama_tokenize_native = Int32 Function(
  Int32 ctxId,
  Pointer<Utf8> text,
  Pointer<Int32> tokens,
  Int32 maxTokens,
);
typedef _llama_tokenize_dart = int Function(
  Int32 ctxId,
  Pointer<Utf8> text,
  Pointer<Int32> tokens,
  int maxTokens,
);

typedef _llama_get_embeddings_native = Int32 Function(
  Int32 ctxId,
  Pointer<Float> embeddings,
  Int32 size,
);
typedef _llama_get_embeddings_dart = int Function(
  Int32 ctxId,
  Pointer<Float> embeddings,
  int size,
);

/// FFI bindings for llama.cpp
/// This provides the Dart interface to the native llama.cpp library
class LlamaFFI {
  static final Logger _logger = Logger('LlamaFFI');
  static DynamicLibrary? _llamaLib;
  static bool _initialized = false;

  // Native function signatures
  late final _llama_load_model_from_file_native _llama_load_model_from_file;
  late final _llama_free_model_native _llama_free_model;
  late final _llama_init_context_native _llama_init_context;
  late final _llama_free_native _llama_free;
  late final _llama_generate_native _llama_generate;
  late final _llama_tokenize_native _llama_tokenize;
  late final _llama_get_embeddings_native _llama_get_embeddings;

  /// Initialize the FFI bindings and load the native library
  static Future<LlamaFFI> initialize() async {
    if (_initialized && _llamaLib != null) {
      return LlamaFFI._(_llamaLib!);
    }

    _logger.info('Initializing llama.cpp FFI bindings...');

    // Load the appropriate library based on platform
    DynamicLibrary lib;

    try {
      if (Platform.isAndroid) {
        // Android: Load from included .so file
        lib = DynamicLibrary.open('libllama.so');
        _logger.info('Loaded libllama.so for Android');
      } else if (Platform.isIOS) {
        // iOS: Load from framework
        lib = DynamicLibrary.executable();
        _logger.info('Loaded llama library for iOS');
      } else if (Platform.isLinux || Platform.isMacOS) {
        // Desktop: For development/testing
        lib = DynamicLibrary.open('libllama.so');
        _logger.info('Loaded libllama.so for desktop');
      } else if (Platform.isWindows) {
        // Windows: Load DLL
        lib = DynamicLibrary.open('llama.dll');
        _logger.info('Loaded llama.dll for Windows');
      } else {
        throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
      }
    } catch (e) {
      _logger.severe('Failed to load llama library: $e');
      throw AIServiceException(
        'Failed to load llama.cpp native library. '
        'Make sure the native library is bundled with the app.',
        cause: e,
      );
    }

    _llamaLib = lib;
    _initialized = true;

    final ffi = LlamaFFI._(lib);
    _logger.info('Llama FFI bindings initialized successfully');
    return ffi;
  }

  LlamaFFI._(DynamicLibrary lib) {
    // Load native functions
    _llama_load_model_from_file = lib.lookupFunction<_llama_load_model_from_file_native, _llama_load_model_from_file_dart>('llama_load_model_from_file');
    _llama_free_model = lib.lookupFunction<_llama_free_model_native, _llama_free_model_dart>('llama_free_model');
    _llama_init_context = lib.lookupFunction<_llama_init_context_native, _llama_init_context_dart>('llama_init_context');
    _llama_free = lib.lookupFunction<_llama_free_native, _llama_free_dart>('llama_free');
    _llama_generate = lib.lookupFunction<_llama_generate_native, _llama_generate_dart>('llama_generate');
    _llama_tokenize = lib.lookupFunction<_llama_tokenize_native, _llama_tokenize_dart>('llama_tokenize');
    _llama_get_embeddings = lib.lookupFunction<_llama_get_embeddings_native, _llama_get_embeddings_dart>('llama_get_embeddings');
  }

  // Wrapper methods for safer Dart API
  int loadModel(String modelPath, {int contextLength = 2048, int gpuLayers = 0}) {
    final pathPtr = modelPath.toNativeUtf8();
    try {
      return _llama_load_model_from_file(pathPtr, contextLength, gpuLayers);
    } finally {
      calloc.free(pathPtr);
    }
  }

  void freeModel(int modelId) {
    _llama_free_model(modelId);
  }

  int initContext(int modelId, {double temperature = 0.7, double topP = 0.9}) {
    return _llama_init_context(modelId, temperature, topP);
  }

  void free(int ctxId) {
    _llama_free(ctxId);
  }

  String generate(int ctxId, String prompt, {int maxOutput = 512}) {
    final promptPtr = prompt.toNativeUtf8();
    final outputPtr = calloc<Utf8>(maxOutput);

    try {
      final result = _llama_generate(ctxId, promptPtr, outputPtr, maxOutput);

      if (result < 0) {
        throw AIServiceException('Generation failed with code: $result');
      }

      return outputPtr.toDartString();
    } finally {
      calloc.free(promptPtr);
      calloc.free(outputPtr);
    }
  }

  List<int> tokenize(int ctxId, String text, {int maxTokens = 2048}) {
    final textPtr = text.toNativeUtf8();
    final tokensPtr = calloc<Int32>(maxTokens);

    try {
      final count = _llama_tokenize(ctxId, textPtr, tokensPtr, maxTokens);

      if (count < 0) {
        throw AIServiceException('Tokenization failed with code: $count');
      }

      return tokensPtr.asTypedList(count).toList();
    } finally {
      calloc.free(textPtr);
      calloc.free(tokensPtr);
    }
  }

  List<double> getEmbeddings(int ctxId, int size) {
    final embeddingsPtr = calloc<Float>(size);

    try {
      final result = _llama_get_embeddings(ctxId, embeddingsPtr, size);

      if (result < 0) {
        throw AIServiceException('Failed to get embeddings: $result');
      }

      return embeddingsPtr.asTypedList(size).toList();
    } finally {
      calloc.free(embeddingsPtr);
    }
  }
}

/// AI Service exception for errors during inference
class _FfiAIServiceException implements Exception {
  final String message;
  final Object? cause;

  const _FfiAIServiceException(
    this.message, {
    this.cause,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('_FfiAIServiceException: $message');
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    return buffer.toString();
  }
}
