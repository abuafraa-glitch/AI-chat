import 'package:dio/dio.dart';
import '../models/ai_model.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/subscription.dart';

class ApiService {
  static const String baseUrl = 'https://api.hajeen-ai.com/v1';
  static const Duration timeoutDuration = Duration(seconds: 30);

  late final Dio _dio;
  String? _authToken;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeoutDuration,
        receiveTimeout: timeoutDuration,
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(_AuthInterceptor(this));
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  // AI Models
  Future<List<AIModel>> getAvailableModels() async {
    try {
      final response = await _dio.get('/models');
      return (response.data['data'] as List)
          .map((model) => AIModel.fromJson(model as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Conversations
  Future<List<Conversation>> getConversations({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/conversations',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      return (response.data['data'] as List)
          .map((conv) => Conversation.fromJson(conv as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Conversation> createConversation({
    required String title,
    required String modelId,
  }) async {
    try {
      final response = await _dio.post(
        '/conversations',
        data: {
          'title': title,
          'modelId': modelId,
        },
      );
      return Conversation.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<Conversation> getConversation(String conversationId) async {
    try {
      final response = await _dio.get('/conversations/$conversationId');
      return Conversation.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateConversation({
    required String conversationId,
    String? title,
    bool? isPinned,
    bool? isArchived,
  }) async {
    try {
      await _dio.patch(
        '/conversations/$conversationId',
        data: {
          if (title != null) 'title': title,
          if (isPinned != null) 'isPinned': isPinned,
          if (isArchived != null) 'isArchived': isArchived,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _dio.delete('/conversations/$conversationId');
    } catch (e) {
      rethrow;
    }
  }

  // Messages
  Future<Stream<String>> sendMessage({
    required String conversationId,
    required String content,
    required String modelId,
    List<String>? attachmentIds,
  }) async {
    try {
      final response = await _dio.post(
        '/conversations/$conversationId/messages',
        data: {
          'content': content,
          'modelId': modelId,
          'attachmentIds': attachmentIds,
        },
        options: Options(responseType: ResponseType.stream),
      );
      return response.data.stream.transform(
        _parseServerSentEvents(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateMessageRating({
    required String messageId,
    required bool isPositive,
  }) async {
    try {
      await _dio.post(
        '/messages/$messageId/rating',
        data: {
          'isPositive': isPositive,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> pinMessage(String messageId) async {
    try {
      await _dio.post('/messages/$messageId/pin');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unpinMessage(String messageId) async {
    try {
      await _dio.post('/messages/$messageId/unpin');
    } catch (e) {
      rethrow;
    }
  }

  // Subscriptions
  Future<Subscription?> getCurrentSubscription() async {
    try {
      final response = await _dio.get('/subscriptions/current');
      if (response.data['data'] == null) return null;
      return Subscription.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      final response = await _dio.get('/subscription-plans');
      return (response.data['data'] as List)
          .map((plan) => SubscriptionPlan.fromJson(plan as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> createCheckoutSession({
    required String planId,
  }) async {
    try {
      final response = await _dio.post(
        '/subscriptions/checkout',
        data: {
          'planId': planId,
        },
      );
      return response.data['data']['checkoutUrl'] as String;
    } catch (e) {
      rethrow;
    }
  }

  // File Upload
  Future<String> uploadFile(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post(
        '/files/upload',
        data: formData,
      );
      return response.data['data']['fileId'] as String;
    } catch (e) {
      rethrow;
    }
  }

  StreamTransformer<List<int>, String> _parseServerSentEvents() {
    return StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        final text = String.fromCharCodes(data);
        sink.add(text);
      },
    );
  }
}

class _AuthInterceptor extends Interceptor {
  final ApiService apiService;

  _AuthInterceptor(this.apiService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (apiService._authToken != null) {
      options.headers['Authorization'] = 'Bearer ${apiService._authToken}';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired or invalid - handle refresh or re-authentication
    }
    handler.next(err);
  }
}
