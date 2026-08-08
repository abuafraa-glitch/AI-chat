import 'package:ai_chat/data/models/message_model.dart';

/// Contract for the message repository.
///
/// Implementations orchestrate remote streaming, persistence and local
/// caching for a single conversation thread. Failures are surfaced as
/// [AppException] subtypes.
abstract interface class MessageRepository {
  /// Returns the message history for [conversationId], remote-first
  /// with a local-cache fallback when the network is unavailable.
  Future<List<MessageModel>> getMessages(String conversationId);

  /// Sends a message payload to [conversationId] and caches the
  /// server-recorded message locally.
  Future<MessageModel> sendMessage({
    required String conversationId,
    required Map<String, dynamic> data,
  });

  /// Opens the SSE stream for [conversationId], yielding decoded
  /// UTF-8 chunks as they arrive.
  Stream<String> streamMessage({
    required String conversationId,
    Map<String, dynamic>? data,
  });

  /// Triggers a new model generation for an existing message.
  Future<MessageModel> regenerateMessage({
    required String conversationId,
    required String messageId,
  });

  /// Persists a complete [messages] thread for [conversationId] into
  /// the local cache (used after streaming finalises).
  Future<void> cacheMessages(String conversationId, List<MessageModel> messages);
}
