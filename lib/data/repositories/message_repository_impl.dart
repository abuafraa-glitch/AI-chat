import 'package:dartz/dartz.dart';

import 'package:ai_chat/core/errors/error_handler.dart';
import 'package:ai_chat/core/errors/failures.dart';
import 'package:ai_chat/data/datasources/local/local_data_source.dart';
import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:ai_chat/data/models/message_model.dart';

/// Implementation of Message repository.
///
/// Manages message sending, streaming, and retrieval.
class MessageRepositoryImpl {
  final RemoteDataSource _remoteDataSource;
  final LocalDataSource _localDataSource;

  MessageRepositoryImpl({
    required RemoteDataSource remoteDataSource,
    required LocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  /// Fetches messages for a specific conversation.
  Future<Either<Failure, List<MessageModel>>> getMessages(
    String conversationId,
  ) async {
    try {
      final messages = await _remoteDataSource.getConversationMessages(conversationId);
      await _localDataSource.saveMessages(conversationId, messages);
      return Right(messages);
    } catch (e) {
      try {
        final cached = await _localDataSource.getMessages(conversationId);
        return Right(cached);
      } catch (_) {
        return Left(ErrorHandler.handle(e).failure);
      }
    }
  }

  /// Sends a message and updates local cache.
  Future<Either<Failure, MessageModel>> sendMessage(
    String conversationId,
    Map<String, dynamic> data,
  ) async {
    try {
      final message = await _remoteDataSource.sendMessage(conversationId, data);
      final current = await _localDataSource.getMessages(conversationId);
      await _localDataSource.saveMessages(conversationId, [...current, message]);
      return Right(message);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  /// Streams message tokens.
  Stream<String> streamMessage(String conversationId, Map<String, dynamic> data) {
    return _remoteDataSource.streamMessage(conversationId, data);
  }

  /// Regenerates a message.
  Future<Either<Failure, MessageModel>> regenerateMessage(
    String conversationId,
    String messageId,
  ) async {
    try {
      final newMessage = await _remoteDataSource.regenerateMessage(
        conversationId,
        messageId,
      );
      // Update the specific message in local storage
      await _localDataSource.updateMessage(newMessage);
      return Right(newMessage);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  /// Retries a failed message.
  Future<Either<Failure, MessageModel>> retryMessage(String messageId) async {
    try {
      final message = await _remoteDataSource.retryMessage(messageId);
      await _localDataSource.updateMessage(message);
      return Right(message);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }
}
