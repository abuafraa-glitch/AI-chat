import 'package:ai_chat/core/di/injection.dart';
import 'package:ai_chat/core/network/api_consumer.dart';
import 'package:ai_chat/data/datasources/local/local_data_source.dart';
import 'package:ai_chat/data/datasources/local/local_data_source_impl.dart';
import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:ai_chat/data/datasources/remote/remote_data_source_impl.dart';
import 'package:ai_chat/data/models/ai_model.dart';
import 'package:ai_chat/data/models/conversation_model.dart';
import 'package:ai_chat/data/models/subscription_model.dart';
import 'package:ai_chat/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Data-source providers
// ---------------------------------------------------------------------------

/// Riverpod provider exposing the [RemoteDataSource] singleton.
///
/// The concrete [RemoteDataSourceImpl] is wired to the [ApiConsumer]
/// resolved from the GetIt container, so it inherits the auth, retry
/// and logging interceptors configured by `DioFactory`.
final remoteDataSourceProvider = Provider<RemoteDataSource>((ref) {
  return RemoteDataSourceImpl(apiConsumer: sl<ApiConsumer>());
});

/// Riverpod provider exposing the [LocalDataSource] singleton.
///
/// The concrete [LocalDataSourceImpl] is backed by the local and
/// secure storage services exposed through [storage_provider].
final localDataSourceProvider = Provider<LocalDataSource>((ref) {
  return LocalDataSourceImpl(
    ref.watch(localStorageServiceProvider),
    ref.watch(secureStorageServiceProvider),
  );
});

// ---------------------------------------------------------------------------
// Chat streaming facade
// ---------------------------------------------------------------------------

/// Lightweight chat facade over [RemoteDataSource].
///
/// Exposed through [apiServiceProvider] so screens that only need to
/// stream a model response do not depend on the full data-source
/// contract.
final class ApiService {
  ApiService({required RemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  /// Remote source that performs the actual streaming request.
  final RemoteDataSource _remoteDataSource;

  /// Streams the assistant response for [content] sent to
  /// [conversationId] using [modelId].
  ///
  /// The returned stream yields decoded token chunks as they arrive.
  Stream<String> sendMessage({
    required String conversationId,
    required String content,
    required String modelId,
  }) {
    return _remoteDataSource.streamMessage(
      conversationId: conversationId,
      data: <String, dynamic>{
        'content': content,
        'modelId': modelId,
      },
    );
  }
}

/// Riverpod provider exposing the chat streaming facade.
///
/// ```dart
/// final apiService = ref.read(apiServiceProvider);
/// final stream = apiService.sendMessage(
///   conversationId: id,
///   content: message,
///   modelId: modelId,
/// );
/// ```
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(remoteDataSource: ref.watch(remoteDataSourceProvider));
});

// ---------------------------------------------------------------------------
// Domain providers
// ---------------------------------------------------------------------------

/// Riverpod provider exposing the AI model catalogue.
///
/// Remote-first with a fallback to the locally cached catalogue so the
/// model selector keeps working while offline.
///
/// ```dart
/// final modelsAsync = ref.watch(aiModelsProvider);
/// ```
final aiModelsProvider = FutureProvider<List<AIModel>>((ref) async {
  final remote = ref.watch(remoteDataSourceProvider);
  final local = ref.watch(localDataSourceProvider);
  try {
    final models = await remote.getModels();
    await local.saveAIModels(models);
    return models;
  } on Exception {
    final cached = await local.getAIModels();
    if (cached.isNotEmpty) {
      return cached;
    }
    rethrow;
  }
});

/// Riverpod provider holding the currently selected AI model id.
///
/// `null` means no model has been selected yet.
///
/// ```dart
/// final selectedId = ref.watch(selectedModelProvider);
/// ref.read(selectedModelProvider.notifier).state = model.id;
/// ```
final selectedModelProvider = StateProvider<String?>((ref) => null);

/// Riverpod provider exposing the user's conversation list.
///
/// Remote-first with a fallback to the locally cached list so the
/// conversations screen keeps rendering while offline.
///
/// ```dart
/// final conversationsAsync = ref.watch(conversationsProvider);
/// ```
final conversationsProvider = FutureProvider<List<ConversationModel>>((ref) async {
  final remote = ref.watch(remoteDataSourceProvider);
  final local = ref.watch(localDataSourceProvider);
  try {
    final conversations = await remote.getConversations();
    await local.saveConversations(conversations);
    return conversations;
  } on Exception {
    final cached = await local.getConversations();
    if (cached.isNotEmpty) {
      return cached;
    }
    rethrow;
  }
});

/// Riverpod provider exposing the available subscription plans.
///
/// Plans are returned as raw maps because the server payload is not
/// yet modelled; introduce a typed `SubscriptionPlan` model when the
/// subscription screen is adopted.
///
/// ```dart
/// final plansAsync = ref.watch(subscriptionPlansProvider);
/// ```
final subscriptionPlansProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(remoteDataSourceProvider).getSubscriptionPlans();
});

/// Riverpod provider exposing the current user's subscription.
///
/// Resolves to `null` when the user has no active subscription or the
/// server reports none, so callers can branch on `null` safely.
///
/// ```dart
/// final currentSubAsync = ref.watch(currentSubscriptionProvider);
/// ```
final currentSubscriptionProvider =
    FutureProvider<SubscriptionModel?>((ref) async {
  try {
    return await ref.watch(remoteDataSourceProvider).getSubscription();
  } on Exception {
    return null;
  }
});
