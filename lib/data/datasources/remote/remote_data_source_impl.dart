import 'package:ai_chat/core/errors/exceptions.dart';
import 'dart:convert';

import 'package:ai_chat/core/network/api_consumer.dart';
import 'package:ai_chat/core/network/endpoints.dart';
import 'package:ai_chat/core/network/network_response.dart' as net;
import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:ai_chat/data/models/agent_model.dart';
import 'package:ai_chat/data/models/ai_model.dart';
import 'package:ai_chat/data/models/conversation_model.dart';
import 'package:ai_chat/data/models/file_model.dart';
import 'package:ai_chat/data/models/message_model.dart';
import 'package:ai_chat/data/models/notification_model.dart';
import 'package:ai_chat/data/models/payment_model.dart';
import 'package:ai_chat/data/models/subscription_model.dart';
import 'package:ai_chat/data/models/subscription_plan_model.dart';

/// Official implementation of [RemoteDataSource] for the Hajeen AI project.
///
/// This implementation uses [ApiConsumer] to perform network requests.
/// It strictly adheres to the project's architecture by using [NetworkResponse]
/// and mapping [NetworkException] to [AppException] to be handled by the
/// repository layer.
class RemoteDataSourceImpl implements RemoteDataSource {
  const RemoteDataSourceImpl({required ApiConsumer apiConsumer})
    : _apiConsumer = apiConsumer;

  final ApiConsumer _apiConsumer;

  // ── Authentication ────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiConsumer.post<Map<String, dynamic>>(
      path: Endpoints.login,
      data: {'email': email, 'password': password},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return _handleResponse(response);
  }

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _apiConsumer.post<Map<String, dynamic>>(
      path: Endpoints.register,
      data: <String, String>{
        'name': name,
        'email': email,
        'password': password,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return _handleResponse(response);
  }

  @override
  Future<void> logout() async {
    final response = await _apiConsumer.post<void>(
      path: Endpoints.logout,
      fromJson: (_) {},
    );
    return _handleResponse(response);
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _apiConsumer.get<Map<String, dynamic>>(
      path: Endpoints.me,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return _handleResponse(response);
  }

  @override
  Future<void> forgotPassword(String email) async {
    final response = await _apiConsumer.post<void>(
      path: Endpoints.forgotPassword,
      data: <String, String>{'email': email},
      fromJson: (_) {},
    );
    return _handleResponse(response);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    final response = await _apiConsumer.post<void>(
      path: Endpoints.resetPassword,
      data: <String, String>{
        'email': email,
        'token': token,
        'password': password,
      },
      fromJson: (_) {},
    );
    return _handleResponse(response);
  }

  @override
  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await _apiConsumer.post<void>(
      path: Endpoints.verifyEmail,
      data: <String, String>{'email': email, 'code': code},
      fromJson: (_) {},
    );
    return _handleResponse(response);
  }

  // ── AI Models ─────────────────────────────────────────────────────────────

  @override
  Future<List<AIModel>> getModels() async {
    final response = await _apiConsumer.get<List<AIModel>>(
      path: Endpoints.models,
      fromJson: (json) {
        final payload = json as Map<String, dynamic>;
        final items = payload['models'] ?? payload['data'] ?? const <dynamic>[];
        return (items as List)
            .whereType<Map<String, dynamic>>()
            .map(AIModel.fromJson)
            .toList(growable: false);
      },
    );
    return _handleResponse(response);
  }

  @override
  Future<AIModel> getModelDetails(String modelId) async {
    final response = await _apiConsumer.get<AIModel>(
      path: Endpoints.model(modelId),
      fromJson: (json) => AIModel.fromJson(json as Map<String, dynamic>),
    );
    return _handleResponse(response);
  }

  // ── Conversations ─────────────────────────────────────────────────────────

  @override
  Future<List<ConversationModel>> getConversations() async {
    final response = await _apiConsumer.get<List<ConversationModel>>(
      path: Endpoints.conversations,
      fromJson: (json) => (json as List)
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return _handleResponse(response);
  }

  @override
  Future<ConversationModel> createConversation(
    Map<String, dynamic> data,
  ) async {
    final response = await _apiConsumer.post<ConversationModel>(
      path: Endpoints.conversations,
      data: data,
      fromJson: (json) =>
          ConversationModel.fromJson(json as Map<String, dynamic>),
    );
    return _handleResponse(response);
  }

  @override
  Future<ConversationModel> updateConversation({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final response = await _apiConsumer.patch<ConversationModel>(
      path: Endpoints.conversation(id),
      data: data,
      fromJson: (json) =>
          ConversationModel.fromJson(json as Map<String, dynamic>),
    );
    return _handleResponse(response);
  }

  @override
  Future<void> deleteConversation(String id) async {
    final response = await _apiConsumer.delete(
      path: Endpoints.conversation(id),
    );
    return _handleResponse(response);
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _apiConsumer.post<MessageModel>(
      path: Endpoints.conversationMessages(conversationId),
      data: data,
      fromJson: (json) => MessageModel.fromJson(json as Map<String, dynamic>),
    );
    return _handleResponse(response);
  }

  @override
  Stream<String> streamMessage({
    required String conversationId,
    Map<String, dynamic>? data,
    String? cancelToken,
  }) async* {
    try {
      await for (final event in _apiConsumer.streamRequest(
        path: Endpoints.streamMessage(conversationId),
        data: data,
        cancelToken: cancelToken,
      )) {
        final text = event.trim();
        if (text.isEmpty || text == '[DONE]') continue;
        try {
          final decoded = jsonDecode(text);
          if (decoded is! Map<String, dynamic>) {
            if (decoded is String && decoded.isNotEmpty) yield decoded;
            continue;
          }
          if (decoded['event'] == 'error') {
            final message = decoded['error']?.toString() ?? 'حدث خطأ أثناء التوليد';
            yield '[خطأ: $message]';
            continue;
          }
          final choices = decoded['choices'];
          if (choices is List && choices.isNotEmpty) {
            final delta = choices.first['delta'];
            final content = delta is Map ? delta['content'] : null;
            if (content is String && content.isNotEmpty) yield content;
          } else if (decoded['response'] is String) {
            yield decoded['response'] as String;
          }
        } on FormatException {
          if (!text.startsWith('{') && !text.startsWith('[')) yield text;
        }
      }
    } catch (error) {
      yield '[خطأ اتصال: $error]';
    }
  }

  @override
  void cancelStream(String? cancelToken) {
    if (cancelToken == null) return;
    _apiConsumer.cancelRequest(cancelToken);
  }

  @override
  Future<MessageModel> regenerateMessage({
    required String conversationId,
    required String messageId,
  }) async {
    final response = await _apiConsumer.post<MessageModel>(
      path: Endpoints.regenerateMessage(conversationId, messageId),
      fromJson: (json) => MessageModel.fromJson(json as Map<String, dynamic>),
    );
    return _handleResponse(response);
  }

  @override
  Future<List<MessageModel>> getConversationMessages(
    String conversationId,
  ) async {
    final response = await _apiConsumer.get<List<MessageModel>>(
      path: Endpoints.conversationMessages(conversationId),
      fromJson: (json) => (json as List)
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return _handleResponse(response);
  }

  // ── Files ─────────────────────────────────────────────────────────────────

  @override
  Future<List<FileModel>> getFiles() async {
    final response = await _apiConsumer.get<List<Map<String, dynamic>>>(
      path: Endpoints.files,
      fromJson: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
    final raw = _handleResponse(response);
    return raw.map(FileModel.fromJson).toList(growable: false);
  }

  @override
  Future<FileModel> uploadFile({
    required String filePath,
    required String fileFieldName,
    Map<String, String>? additionalFields,
  }) async {
    final response = await _apiConsumer.uploadFile<Map<String, dynamic>>(
      path: Endpoints.files,
      filePath: filePath,
      fileFieldName: fileFieldName,
      additionalFields: additionalFields,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return FileModel.fromJson(_handleResponse(response));
  }

  @override
  Future<void> deleteFile(String fileId) async {
    final response = await _apiConsumer.delete(path: Endpoints.file(fileId));
    return _handleResponse(response);
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  @override
  Future<List<NotificationModel>> getNotifications() async {
    final response = await _apiConsumer.get<List<Map<String, dynamic>>>(
      path: Endpoints.notifications,
      fromJson: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
    final raw = _handleResponse(response);
    return raw.map(NotificationModel.fromJson).toList(growable: false);
  }

  // ── Agents ────────────────────────────────────────────────────────────────

  @override
  Future<List<AgentModel>> getAgents() async {
    final response = await _apiConsumer.get<List<Map<String, dynamic>>>(
      path: Endpoints.agents,
      fromJson: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
    final raw = _handleResponse(response);
    return raw.map(AgentModel.fromJson).toList(growable: false);
  }

  // ── Payments ──────────────────────────────────────────────────────────────

  @override
  Future<List<PaymentModel>> getPaymentHistory() async {
    final response = await _apiConsumer.get<List<Map<String, dynamic>>>(
      path: Endpoints.paymentHistory,
      fromJson: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
    final raw = _handleResponse(response);
    return raw.map(PaymentModel.fromJson).toList(growable: false);
  }

  // ── Subscriptions ─────────────────────────────────────────────────────────

  @override
  Future<List<SubscriptionPlanModel>> getSubscriptionPlans() async {
    final response = await _apiConsumer.get<List<Map<String, dynamic>>>(
      path: Endpoints.subscriptionPlans,
      fromJson: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
    final raw = _handleResponse(response);
    return raw.map(SubscriptionPlanModel.fromJson).toList(growable: false);
  }

  @override
  Future<SubscriptionModel> getSubscription() async {
    final response = await _apiConsumer.get<SubscriptionModel>(
      path: Endpoints.currentSubscription,
      fromJson: (json) =>
          SubscriptionModel.fromJson(json as Map<String, dynamic>),
    );
    return _handleResponse(response);
  }

  @override
  Future<void> cancelSubscription(String subscriptionId) async {
    final response = await _apiConsumer.post<void>(
      path: Endpoints.cancelSubscription(subscriptionId),
      fromJson: (_) {},
    );
    return _handleResponse(response);
  }

  // ── Search ────────────────────────────────────────────────────────────────

  @override
  Future<List<ConversationModel>> searchConversations(String query) async {
    final response = await _apiConsumer.get<List<ConversationModel>>(
      path: Endpoints.searchConversations,
      queryParameters: {'q': query},
      fromJson: (json) => (json as List)
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return _handleResponse(response);
  }

  // ── Private Helpers ────────────────────────────────────────────────────

  /// Unwraps [net.NetworkResponse] and maps [net.NetworkException] to
  /// [AppException].
  T _handleResponse<T>(net.NetworkResponse<T> response) {
    return response.fold(
      onSuccess: (data) => data,
      onError: (exception) => throw _mapToAppException(exception),
    );
  }

  /// Maps a network-layer [net.NetworkException] to the application-layer
  /// [AppException] consumed by the repository/presentation layers. The
  /// network hierarchy lives in `network_response.dart` (prefixed `net`);
  /// the app hierarchy lives in `core/errors/exceptions.dart` (unqualified).
  AppException _mapToAppException(net.NetworkException exception) {
    final message = exception.message;

    return switch (exception) {
      net.NoConnectionException() => NetworkException(message: message),
      net.RequestTimeoutException() => TimeoutException(message: message),
      net.UnauthorizedException() => UnauthorizedException(message: message),
      net.ForbiddenException() => ForbiddenException(message: message),
      net.NotFoundException() => NotFoundException(message: message),
      net.UnprocessableEntityException() ||
      net.BadRequestException() => ValidationException(message: message),
      net.RateLimitException() => RateLimitException(message: message),
      net.ServerException() => ServerException(message: message),
      net.RequestCancelledException() => NetworkException(message: message),
      _ => UnknownException(message: message),
    };
  }
}
