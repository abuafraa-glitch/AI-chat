import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/api_service.dart';
import '../data/models/ai_model.dart';
import '../data/models/conversation.dart';
import '../data/models/subscription.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// AI Models
final aiModelsProvider = FutureProvider<List<AIModel>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getAvailableModels();
});

// Conversations
final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getConversations();
});

final conversationProvider = FutureProviderFamily<Conversation, String>((ref, conversationId) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getConversation(conversationId);
});

// Subscription Plans
final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getSubscriptionPlans();
});

// Current Subscription
final currentSubscriptionProvider = FutureProvider<Subscription?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getCurrentSubscription();
});
