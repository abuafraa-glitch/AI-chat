import 'package:ai_chat/data/models/ai_model.dart';
import 'package:ai_chat/data/models/conversation_model.dart';
import 'package:ai_chat/data/models/message_model.dart';
import 'package:ai_chat/data/models/subscription_model.dart';

/// Abstract interface defining all remote server operations.
///
/// This data source is the single point of truth for network interactions.
/// It supports REST, SSE, and future streaming protocols.
abstract interface class RemoteDataSource {
  // ── Authentication ────────────────────────────────────────────────────────

  /// Authenticates a user and returns a token pair.
  Future<Map<String, dynamic>> login(String email, String password);

  /// Invalidates the current session on the server.
  Future<void> logout();

  /// Refreshes the access token using a refresh token.
  Future<String> refreshToken(String refreshToken);

  /// Fetches the current authenticated user profile.
  Future<Map<String, dynamic>> getCurrentUser();

  // ── AI Models ─────────────────────────────────────────────────────────────

  /// Retrieves all available AI models.
  Future<List<AIModel>> getModels();

  /// Fetches detailed information for a specific AI model.
  Future<AIModel> getModelDetails(String modelId);

  // ── Conversations ─────────────────────────────────────────────────────────

  /// Lists all conversations for the current user.
  Future<List<ConversationModel>> getConversations();

  /// Creates a new conversation.
  Future<ConversationModel> createConversation(Map<String, dynamic> data);

  /// Updates an existing conversation's metadata.
  Future<ConversationModel> updateConversation(
    String id,
    Map<String, dynamic> data,
  );

  /// Deletes a conversation and all its messages.
  Future<void> deleteConversation(String id);

  // ── Messages ──────────────────────────────────────────────────────────────

  /// Sends a message and receives a full response.
  Future<MessageModel> sendMessage(String conversationId, Map<String, dynamic> data);

  /// Streams message tokens in real-time via SSE or WebSockets.
  Stream<String> streamMessage(String conversationId, Map<String, dynamic> data);

  /// Retries a failed message.
  Future<MessageModel> retryMessage(String messageId);

  /// Triggers a new generation for an existing user message.
  Future<MessageModel> regenerateMessage(String conversationId, String messageId);

  /// Fetches all messages for a specific conversation.
  Future<List<MessageModel>> getConversationMessages(String conversationId);

  // ── Files ─────────────────────────────────────────────────────────────────

  /// Uploads a file to the server.
  Future<Map<String, dynamic>> uploadFile(String filePath, String purpose);

  /// Deletes a previously uploaded file.
  Future<void> deleteFile(String fileId);

  /// Generates a download URL for a file.
  Future<String> downloadFile(String fileId);

  // ── Subscriptions ─────────────────────────────────────────────────────────

  /// Lists all available subscription plans.
  Future<List<Map<String, dynamic>>> getPlans();

  /// Fetches the user's active subscription.
  Future<SubscriptionModel> getSubscription();

  /// Initiates a purchase for a plan.
  Future<Map<String, dynamic>> purchase(String planId);

  /// Cancels an active subscription.
  Future<void> cancelSubscription(String subscriptionId);

  // ── Search ────────────────────────────────────────────────────────────────

  /// Searches within conversations for specific terms.
  Future<List<ConversationModel>> searchConversations(String query);

  // ── Settings ──────────────────────────────────────────────────────────────

  /// Synchronizes user settings with the server.
  Future<void> syncSettings(Map<String, dynamic> settings);
}
