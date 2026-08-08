import 'package:ai_chat/data/models/subscription_model.dart';

/// Contract for the subscription repository.
///
/// Implementations orchestrate remote and local data sources. Failures
/// are surfaced as [AppException] subtypes.
abstract interface class SubscriptionRepository {
  /// Returns the available subscription plans (raw server payloads).
  Future<List<Map<String, dynamic>>> getPlans();

  /// Returns the user's active subscription, remote-first with a
  /// local-cache fallback when the network is unavailable.
  Future<SubscriptionModel> getSubscription();

  /// Cancels the active subscription on the server.
  Future<void> cancelSubscription(String subscriptionId);
}
