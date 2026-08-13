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
  ///
  /// Pass a [cancelToken] to make the stream cancellable via the
  /// network layer's cancellation API.
  Stream<String> streamMessage({
    required String conversationId,
    Map<String, dynamic>? data,
    String? cancelToken,
  });

  /// Cancels the in-flight stream/request bound to [cancelToken].
  ///
  /// Call this from a Cubit's [close] or an explicit stop action so the
  /// upstream Dio request is aborted, not merely the local subscription
  /// dropped. No-op for `null` or unknown tokens.
  void cancelStream(String? cancelToken);

  /// Triggers a new model generation for an existing message.
  Future<MessageModel> regenerateMessage({
    required String conversationId,
    required String messageId,
  });

  /// Persists a complete [messages] thread for [conversationId] into
  /// the local cache (used after streaming finalises).
  Future<void> cacheMessages(
    String conversationId,
    List<MessageModel> messages,
  );
}
