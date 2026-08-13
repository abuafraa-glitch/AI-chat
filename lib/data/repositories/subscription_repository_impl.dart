import 'package:ai_chat/data/datasources/local/local_data_source.dart';
import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:ai_chat/data/models/subscription_model.dart';
import 'package:ai_chat/data/models/subscription_plan_model.dart';
import 'package:ai_chat/data/repositories/subscription_repository.dart';

/// Implementation of [SubscriptionRepository].
///
/// Handles subscription plans and the user's active subscription,
/// serving the cached subscription when the network is unavailable.
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  /// Creates a [SubscriptionRepositoryImpl] wired to
  /// [remoteDataSource] and [localDataSource].
  SubscriptionRepositoryImpl({
    required RemoteDataSource remoteDataSource,
    required LocalDataSource localDataSource,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  final RemoteDataSource _remote;
  final LocalDataSource _local;

  @override
  Future<List<SubscriptionPlanModel>> getPlans() =>
      _remote.getSubscriptionPlans();

  @override
  Future<SubscriptionModel> getSubscription() async {
    try {
      final subscription = await _remote.getSubscription();
      await _local.saveSubscription(subscription);
      return subscription;
    } on Exception {
      final cached = await _cachedSubscription();
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  @override
  Future<void> cancelSubscription(String subscriptionId) =>
      _remote.cancelSubscription(subscriptionId);

  /// Returns the locally cached subscription, or `null`.
  Future<SubscriptionModel?> _cachedSubscription() async {
    try {
      return await _local.getSubscription();
    } on Exception {
      return null;
    }
  }
}
