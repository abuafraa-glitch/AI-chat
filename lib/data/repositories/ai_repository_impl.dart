import 'package:ai_chat/data/datasources/local/local_data_source.dart';
import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:ai_chat/data/models/ai_model.dart';
import 'package:ai_chat/data/repositories/ai_repository.dart';

/// Implementation of [AIRepository].
///
/// Retrieves the AI model catalogue remote-first and keeps the local
/// cache in sync; when the network is unavailable the cached catalogue
/// is served instead of failing.
class AIRepositoryImpl implements AIRepository {
  /// Creates an [AIRepositoryImpl] wired to [remoteDataSource] and
  /// [localDataSource].
  AIRepositoryImpl({
    required RemoteDataSource remoteDataSource,
    required LocalDataSource localDataSource,
  })  : _remote = remoteDataSource,
        _local = localDataSource;

  final RemoteDataSource _remote;
  final LocalDataSource _local;

  @override
  Future<List<AIModel>> getModels() async {
    try {
      final models = await _remote.getModels();
      await _local.saveAIModels(models);
      return models;
    } on Exception {
      final cached = await _cachedModels();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  @override
  Future<AIModel> getModelDetails(String modelId) =>
      _remote.getModelDetails(modelId);

  /// Returns the locally cached catalogue, or `null` when unavailable.
  Future<List<AIModel>?> _cachedModels() async {
    try {
      return await _local.getAIModels();
    } on Exception {
      return null;
    }
  }
}
