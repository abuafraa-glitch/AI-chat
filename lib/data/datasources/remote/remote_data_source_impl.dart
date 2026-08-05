import 'dart:async';

import 'package:ai_chat/core/network/api_client.dart';
import 'package:ai_chat/core/network/endpoints.dart';
import 'package:ai_chat/core/network/network_response.dart';
import 'package:ai_chat/data/models/ai_model.dart';
import 'package:ai_chat/data/models/conversation_model.dart';
import 'package:ai_chat/data/models/message_model.dart';
import 'package:ai_chat/data/models/subscription_model.dart';
import 'remote_data_source.dart';

/// Production-ready implementation of [RemoteDataSource].
///
/// This implementation relies on [ApiClient] for network requests and
/// handles error mapping via the core network layer.
class RemoteDataSourceImpl implements RemoteDataSource {
  final ApiClient _apiClient;

  RemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  // ── Authentication ────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      path: Endpoints.login,
      data: {'email': email, 'password': password},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return _handleResponse(response);
  }

  @override
  Future<void> logout() async {
    final response = await _apiClient.post<void>(
      path: Endpoints.logout,
      fromJson: (_) {},
    );
    return _handleResponse(response);
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      path: Endpoints.refresh,
      data: {'refresh_token': refreshToken},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    final data = _handleResponse(response);
    return data['access_token'] as String;
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      path: Endpoints.me,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return _handleResponse(response);
  }

  // ── AI Models ─────────────────────────────────────────────────────────────

  @override
  Future<List<AIModel>> getModels() async {
    final response = await _apiClient.get<List<AIModel>>(
      path: Endpoints.models,
      fromJson: (json) => (json as List)
          .map((e) => AIModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return _handleResponse(response);
  }

  @override
  Future<AIModel> getModelDetails(String modelId) async {
    final response = await _apiClient.get<AIModel>(
      path: Endpoints.model(modelId),
      fromJson: (json) => AIModel.fromJson(json as Map<String, dynamic>),
    );
    return _handleResponse(response);
  }

  // ── Conversations ─────────────────────────────────────────────────────────

  @override
  Future<List<ConversationModel>> getConversations() async {
    final response = await _apiClient.get<List<ConversationModel>>(
      path: Endpoints.conversations,
      fromJson: (json) => (json as List)
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return _handleResponse(response);
  }

  @override
  Future<ConversationModel> createConversation(Map<String, dynamic> data) async {
    final response = await _apiClient.post<ConversationModel>(
      path: Endpoints.conversations,
      data: data,
      fromJson: (json) => ConversationModel.fromJson(json as Map<String, dynamic>),
    );
    return _handleResponse(response);
  }

  @override
  Future<ConversationModel> updateConversation(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.patch<ConversationModel>(
      path: Endpoints.conversation(id),
      data: data,
      fromJson: (json) => ConversationModel.fromJson(json as Map<String, dynamic>),
    );
    return _handleResponse(response);
  }

  @override
  Future<void> deleteConversation(String id) async {
    final response = await _apiClient.delete(
      path: Endpoints.conversation(id),
    );
    return _handleResponse(response);
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  @override
  Future<MessageModel> sendMessage(
    String conversationId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.post<MessageModel>(
      path: Endpoints.conversationMessages(conversationId),
      data: data,
      fromJson: (json) => MessageModel.fromJson(json as Map<String, dynamic>),
    );
    return _handleResponse(response);
  }

  @override
  Stream<String> streamMessage(
    String conversationId,
    Map<String, dynamic> data,
  ) {
    return _apiClient.streamRequest(
      path: Endpoints.streamMessage(conversationId),
      data: data,
    );
  }

  @override
  Future<MessageModel> retryMessage(String messageId) async {
    // Assuming retry logic is a POST to a specific message endpoint
    final response = await _apiClient.post<MessageModel>(
      path: '/messages/$messageId/retry',
      fromJson: (json) => MessageModel.fromJson(json as Map<String, dynamic>),
    );
    return _handleResponse(response);
  }

  @override
  Future<MessageModel> regenerateMessage(
    String conversationId,
    String messageId,
  ) async {
    final response = await _apiClient.post<MessageModel>(
      path: Endpoints.regenerateMessage(conversationId, messageId),
      fromJson: (json) => MessageModel.fromJson(json as Map<String, dynamic>),
    );
    return _handleResponse(response);
  }

  @override
  Future<List<MessageModel>> getConversationMessages(String conversationId) async {
    final response = await _apiClient.get<List<MessageModel>>(
      path: Endpoints.conversationMessages(conversationId),
      fromJson: (json) => (json as List)
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return _handleResponse(response);
  }

  // ── Files ─────────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> uploadFile(String filePath, String purpose) async {
    final response = await _apiClient.uploadFile<Map<String, dynamic>>(
      path: Endpoints.files,
      filePath: filePath,
      fileFieldName: 'file',
      additionalFields: {'purpose': purpose},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return _handleResponse(response);
  }

  @override
  Future<void> deleteFile(String fileId) async {
    final response = await _apiClient.delete(
      path: Endpoints.file(fileId),
    );
    return _handleResponse(response);
  }

  @override
  Future<String> downloadFile(String fileId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      path: Endpoints.fileDownload(fileId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    final data = _handleResponse(response);
    return data['url'] as String;
  }

  // ── Subscriptions ─────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getPlans() async {
    final response = await _apiClient.get<List<Map<String, dynamic>>>(
      path: Endpoints.subscriptionPlans,
      fromJson: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
    return _handleResponse(response);
  }

  @override
  Future<SubscriptionModel> getSubscription() async {
    final response = await _apiClient.get<SubscriptionModel>(
      path: Endpoints.currentSubscription,
      fromJson: (json) => SubscriptionModel.fromJson(json as Map<String, dynamic>),
    );
    return _handleResponse(response);
  }

  @override
  Future<Map<String, dynamic>> purchase(String planId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      path: Endpoints.paymentIntent,
      data: {'plan_id': planId},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return _handleResponse(response);
  }

  @override
  Future<void> cancelSubscription(String subscriptionId) async {
    final response = await _apiClient.post<void>(
      path: Endpoints.cancelSubscription(subscriptionId),
      fromJson: (_) {},
    );
    return _handleResponse(response);
  }

  // ── Search ────────────────────────────────────────────────────────────────

  @override
  Future<List<ConversationModel>> searchConversations(String query) async {
    final response = await _apiClient.get<List<ConversationModel>>(
      path: Endpoints.searchConversations,
      queryParameters: {'q': query},
      fromJson: (json) => (json as List)
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return _handleResponse(response);
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  @override
  Future<void> syncSettings(Map<String, dynamic> settings) async {
    final response = await _apiClient.post<void>(
      path: '/settings/sync',
      data: settings,
      fromJson: (_) {},
    );
    return _handleResponse(response);
  }

  // ── Private helpers ────────────────────────────────────────────────────

  /// Unwraps [NetworkResponse] and throws the underlying exception on error.
  T _handleResponse<T>(NetworkResponse<T> response) {
    if (response is NetworkSuccess<T>) {
      return response.data;
    } else if (response is NetworkError<T>) {
      throw response.exception;
    }
    throw Exception('Unknown NetworkResponse type');
  }
}
