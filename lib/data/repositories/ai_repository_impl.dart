import 'package:dartz/dartz.dart';

import 'package:ai_chat/core/errors/error_handler.dart';
import 'package:ai_chat/core/errors/failures.dart';
import 'package:ai_chat/data/datasources/local/local_data_source.dart';
import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:ai_chat/data/models/ai_model.dart';

/// Implementation of AI repository.
///
/// Handles AI model retrieval with local caching support.
class AIRepositoryImpl {
  final RemoteDataSource _remoteDataSource;
  final LocalDataSource _localDataSource;

  AIRepositoryImpl({
    required RemoteDataSource remoteDataSource,
    required LocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  /// Fetches all available AI models.
  ///
  /// Tries to fetch from remote first, updates local cache on success.
  /// If remote fails, falls back to local cache.
  Future<Either<Failure, List<AIModel>>> getModels() async {
    try {
      final models = await _remoteDataSource.getModels();
      await _localDataSource.saveAIModels(models);
      return Right(models);
    } catch (e) {
      try {
        final cachedModels = await _localDataSource.getAIModels();
        if (cachedModels.isNotEmpty) {
          return Right(cachedModels);
        }
        return Left(ErrorHandler.handle(e).failure);
      } catch (_) {
        return Left(ErrorHandler.handle(e).failure);
      }
    }
  }

  /// Fetches details for a specific AI model.
  Future<Either<Failure, AIModel>> getModelDetails(String modelId) async {
    try {
      final model = await _remoteDataSource.getModelDetails(modelId);
      return Right(model);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }
}
