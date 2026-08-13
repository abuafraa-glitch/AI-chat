import 'package:ai_chat/data/models/ai_model.dart';
import 'package:ai_chat/data/models/conversation_model.dart';
import 'package:ai_chat/data/models/message_model.dart';
import 'package:ai_chat/data/models/subscription_model.dart';

/// Abstract interface defining all remote server operations for Hajeen AI.
///
/// This data source acts as a contract for network interactions, focusing on
/// raw data retrieval and transmission. It follows Clean Architecture principles
/// by remaining agnostic of implementation details (Dio, HTTP, etc.).
abstract interface class RemoteDataSource {
  // ── Authentication ────────────────────────────────────────────────────────

  /// Authenticates a user and returns the raw response containing tokens.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });

  /// Registers a new account and returns the raw response containing
  /// tokens when the server auto-signs-in the new user.
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  });

  /// Invalidates the current session on the server.
  Future<void> logout();

  /// Fetches the current authenticated user profile.
  Future<Map<String, dynamic>> getCurrentUser();

  /// Initiates the password-recovery flow for [email].
  Future<void> forgotPassword(String email);

  /// Completes the password-reset flow with the emailed [token] and a
  /// new [password].
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
  });

  /// Confirms the email address with the emailed verification [code].
  Future<void> verifyEmail({required String email, required String code});

  // ── AI Models ─────────────────────────────────────────────────────────────

  /// Retrieves all available AI models.
  Future<List<AIModel>> getModels();

  /// Fetches detailed information for a specific AI model.
  Future<AIModel> getModelDetails(String modelId);

  // ── Conversations ─────────────────────────────────────────────────────────

  /// Lists all conversations for the current user.
  Future<List<ConversationModel>> getConversations();

  /// Creates a new conversation with the provided [data].
  Future<ConversationModel> createConversation(Map<String, dynamic> data);

  /// Updates an existing conversation's metadata.
  Future<ConversationModel> updateConversation({
    required String id,
    required Map<String, dynamic> data,
  });

  /// Deletes a conversation and all its messages.
  Future<void> deleteConversation(String id);

  // ── Messages ──────────────────────────────────────────────────────────────

  /// Sends a message to a specific conversation.
  Future<MessageModel> sendMessage({
    required String conversationId,
    required Map<String, dynamic> data,
  });

  /// Streams message tokens in real-time via SSE.
  Stream<String> streamMessage({
    required String conversationId,
    Map<String, dynamic>? data,
  });

  /// Triggers a new model generation for an existing user message.
  Future<MessageModel> regenerateMessage({
    required String conversationId,
    required String messageId,
  });

  /// Fetches all messages for a specific conversation.
  Future<List<MessageModel>> getConversationMessages(String conversationId);

  // ── Files ─────────────────────────────────────────────────────────────────

  /// Lists the files uploaded by the current user.
  Future<List<Map<String, dynamic>>> getFiles();

  /// Uploads a file to the server.
  Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    required String fileFieldName,
    Map<String, String>? additionalFields,
  });

  /// Deletes a previously uploaded file.
  Future<void> deleteFile(String fileId);

  // ── Notifications ─────────────────────────────────────────────────────────

  /// Lists the in-app notifications for the current user.
  Future<List<Map<String, dynamic>>> getNotifications();

  // ── Agents ────────────────────────────────────────────────────────────────

  /// Lists the AI agent definitions available to the current user.
  Future<List<Map<String, dynamic>>> getAgents();

  // ── Payments ──────────────────────────────────────────────────────────────

  /// Lists the payment history of the current user.
  Future<List<Map<String, dynamic>>> getPaymentHistory();

  // ── Subscriptions ─────────────────────────────────────────────────────────

  /// Lists all available subscription plans.
  Future<List<Map<String, dynamic>>> getSubscriptionPlans();

  /// Fetches the user's active subscription.
  Future<SubscriptionModel> getSubscription();

  /// Cancels an active subscription.
  Future<void> cancelSubscription(String subscriptionId);

  // ── Search ────────────────────────────────────────────────────────────────

  /// Searches within conversations for specific terms.
  Future<List<ConversationModel>> searchConversations(String query);
}
