import 'package:ai_chat/data/models/ai_model.dart';
import 'package:ai_chat/data/models/conversation_model.dart';
import 'package:ai_chat/data/models/message_model.dart';
import 'package:ai_chat/data/models/subscription_model.dart';

/// An abstract interface for managing all local data storage operations.
///
/// This interface defines the contract for local data access, including
/// authentication tokens, user data, AI models, conversations, messages,
/// settings, and subscriptions. It is designed to be storage-engine agnostic.
abstract interface class LocalDataSource {
  // ── Authentication ────────────────────────────────────────────────────────

  /// Persists the authentication token securely.
  Future<void> saveToken(String token);

  /// Retrieves the persisted authentication token.
  Future<String?> getToken();

  /// Removes the persisted authentication token.
  Future<void> deleteToken();

  // ── User ──────────────────────────────────────────────────────────────────

  /// Persists the user profile data.
  Future<void> saveUser(Map<String, dynamic> userJson);

  /// Retrieves the persisted user profile data.
  Future<Map<String, dynamic>?> getUser();

  /// Removes the persisted user profile data.
  Future<void> deleteUser();

  // ── AI Models ─────────────────────────────────────────────────────────────

  /// Persists a list of available AI models.
  Future<void> saveAIModels(List<AIModel> models);

  /// Retrieves the persisted list of AI models.
  Future<List<AIModel>> getAIModels();

  /// Clears the cached AI models.
  Future<void> clearAIModelsCache();

  // ── Conversations ─────────────────────────────────────────────────────────

  /// Persists a list of conversations.
  Future<void> saveConversations(List<ConversationModel> conversations);

  /// Retrieves the persisted list of conversations.
  Future<List<ConversationModel>> getConversations();

  /// Removes a specific conversation by its [id].
  Future<void> deleteConversation(String id);

  /// Updates an existing conversation.
  Future<void> updateConversation(ConversationModel conversation);

  // ── Messages ──────────────────────────────────────────────────────────────

  /// Persists a list of messages for a specific conversation.
  Future<void> saveMessages(String conversationId, List<MessageModel> messages);

  /// Retrieves the persisted messages for a specific conversation.
  Future<List<MessageModel>> getMessages(String conversationId);

  /// Removes all messages for a specific conversation.
  Future<void> deleteMessages(String conversationId);

  /// Updates a specific message.
  Future<void> updateMessage(MessageModel message);

  // ── Settings ──────────────────────────────────────────────────────────────

  /// Persists application settings.
  Future<void> saveSettings(Map<String, dynamic> settings);

  /// Retrieves the persisted application settings.
  Future<Map<String, dynamic>?> getSettings();

  // ── Subscriptions ─────────────────────────────────────────────────────────

  /// Persists the user's subscription details.
  Future<void> saveSubscription(SubscriptionModel subscription);

  /// Retrieves the persisted subscription details.
  Future<SubscriptionModel?> getSubscription();

  // ── Cache Management ──────────────────────────────────────────────────────

  /// Clears a specific item from cache by its [key].
  Future<void> remove(String key);

  /// Checks if an item exists in cache for the given [key].
  Future<bool> exists(String key);

  /// Clears all cached data except for critical authentication tokens.
  Future<void> clearCache();

  /// Destructive operation that clears all local data including tokens.
  Future<void> clearAll();
}
