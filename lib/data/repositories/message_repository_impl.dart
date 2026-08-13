import 'package:ai_chat/data/datasources/local/local_data_source.dart';
import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:ai_chat/data/models/message_model.dart';
import 'package:ai_chat/data/repositories/message_repository.dart';

/// Implementation of [MessageRepository].
///
/// Manages message history, sending, streaming and regeneration while
/// keeping the local thread cache in sync.
class MessageRepositoryImpl implements MessageRepository {
  /// Creates a [MessageRepositoryImpl] wired to [remoteDataSource] and
  /// [localDataSource].
  MessageRepositoryImpl({
    required RemoteDataSource remoteDataSource,
    required LocalDataSource localDataSource,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  final RemoteDataSource _remote;
  final LocalDataSource _local;

  @override
  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      final messages = await _remote.getConversationMessages(conversationId);
      await _local.saveMessages(conversationId, messages);
      return messages;
    } on Exception {
      final cached = await _cachedMessages(conversationId);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required Map<String, dynamic> data,
  }) async {
    final message = await _remote.sendMessage(
      conversationId: conversationId,
      data: data,
    );
    final current =
        await _cachedMessages(conversationId) ?? const <MessageModel>[];
    await _local.saveMessages(conversationId, <MessageModel>[
      ...current,
      message,
    ]);
    return message;
  }

  @override
  Stream<String> streamMessage({
    required String conversationId,
    Map<String, dynamic>? data,
    String? cancelToken,
  }) {
    return _remote.streamMessage(
      conversationId: conversationId,
      data: data,
      cancelToken: cancelToken,
    );
  }

  @override
  void cancelStream(String? cancelToken) => _remote.cancelStream(cancelToken);

  @override
  Future<MessageModel> regenerateMessage({
    required String conversationId,
    required String messageId,
  }) async {
    final message = await _remote.regenerateMessage(
      conversationId: conversationId,
      messageId: messageId,
    );
    await _local.updateMessage(message);
    return message;
  }

  @override
  Future<void> cacheMessages(
    String conversationId,
    List<MessageModel> messages,
  ) {
    return _local.saveMessages(conversationId, messages);
  }

  /// Returns the locally cached thread, or `null`.
  Future<List<MessageModel>?> _cachedMessages(String conversationId) async {
    try {
      return await _local.getMessages(conversationId);
    } on Exception {
      return null;
    }
  }
}
