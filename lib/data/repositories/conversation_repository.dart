import 'package:ai_chat/data/models/conversation_model.dart';

/// Contract for the conversation repository.
///
/// Implementations orchestrate remote and local data sources, keeping
/// the local cache in sync after every successful remote mutation.
/// Failures are surfaced as [AppException] subtypes.
abstract interface class ConversationRepository {
  /// Returns the user's conversations, remote-first with a local-cache
  /// fallback when the network is unavailable.
  Future<List<ConversationModel>> getConversations();

  /// Creates a conversation from [data] and caches the result locally.
  Future<ConversationModel> createConversation(Map<String, dynamic> data);

  /// Updates an existing conversation's metadata.
  Future<ConversationModel> updateConversation({
    required String id,
    required Map<String, dynamic> data,
  });

  /// Deletes a conversation both remotely and from the local cache.
  Future<void> deleteConversation(String id);

  /// Searches conversations for [query] on the server.
  Future<List<ConversationModel>> searchConversations(String query);
}
