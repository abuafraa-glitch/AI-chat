import 'package:dartz/dartz.dart';

import 'package:ai_chat/core/errors/error_handler.dart';
import 'package:ai_chat/core/errors/failures.dart';
import 'package:ai_chat/data/datasources/local/local_data_source.dart';
import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:ai_chat/data/models/conversation_model.dart';

/// Implementation of Conversation repository.
///
/// Orchestrates conversation data between remote and local sources.
class ConversationRepositoryImpl {
  final RemoteDataSource _remoteDataSource;
  final LocalDataSource _localDataSource;

  ConversationRepositoryImpl({
    required RemoteDataSource remoteDataSource,
    required LocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  /// Retrieves all conversations.
  ///
  /// Syncs remote data with local storage.
  Future<Either<Failure, List<ConversationModel>>> getConversations() async {
    try {
      final conversations = await _remoteDataSource.getConversations();
      await _localDataSource.saveConversations(conversations);
      return Right(conversations);
    } catch (e) {
      try {
        final cached = await _localDataSource.getConversations();
        return Right(cached);
      } catch (_) {
        return Left(ErrorHandler.handle(e).failure);
      }
    }
  }

  /// Creates a new conversation.
  Future<Either<Failure, ConversationModel>> createConversation(
    Map<String, dynamic> data,
  ) async {
    try {
      final conversation = await _remoteDataSource.createConversation(data);
      // Update local cache with the new conversation
      final current = await _localDataSource.getConversations();
      await _localDataSource.saveConversations([conversation, ...current]);
      return Right(conversation);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  /// Updates an existing conversation.
  Future<Either<Failure, ConversationModel>> updateConversation(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final updated = await _remoteDataSource.updateConversation(id, data);
      await _localDataSource.updateConversation(updated);
      return Right(updated);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  /// Deletes a conversation.
  Future<Either<Failure, void>> deleteConversation(String id) async {
    try {
      await _remoteDataSource.deleteConversation(id);
      await _localDataSource.deleteConversation(id);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  /// Searches conversations.
  Future<Either<Failure, List<ConversationModel>>> searchConversations(
    String query,
  ) async {
    try {
      final results = await _remoteDataSource.searchConversations(query);
      return Right(results);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }
}
