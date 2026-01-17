/// Web stub for LlamaModelManager
class ModelSpec {
  final String id;
  final String name;
  final int fileSize;

  ModelSpec({
    required this.id,
    required this.name,
    required this.fileSize,
  });
}

class LlamaModelManager {
  LlamaModelManager();

  Future<List<ModelSpec>> getDownloadedModels() async => [];
  Future<ModelSpec> getRecommendedModel() async => ModelSpec(
    id: 'stub',
    name: 'Not Available on Web',
    fileSize: 0,
  );
  Future<bool> hasDownloadedModel() async => false;
  Future<void> setCurrentModel(String modelId) async {}
  Future<void> deleteModel(String modelId) async {}
  Future<int> getModelsStorageSize() async => 0;
  Future<void> clearAllModels() async {}
}
