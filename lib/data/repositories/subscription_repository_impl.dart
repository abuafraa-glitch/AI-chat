import 'package:dartz/dartz.dart';

import 'package:ai_chat/core/errors/error_handler.dart';
import 'package:ai_chat/core/errors/failures.dart';
import 'package:ai_chat/data/datasources/local/local_data_source.dart';
import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:ai_chat/data/models/subscription_model.dart';

/// Implementation of Subscription repository.
///
/// Handles subscription plans and user subscription status.
class SubscriptionRepositoryImpl {
  final RemoteDataSource _remoteDataSource;
  final LocalDataSource _localDataSource;

  SubscriptionRepositoryImpl({
    required RemoteDataSource remoteDataSource,
    required LocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  /// Fetches available subscription plans.
  Future<Either<Failure, List<Map<String, dynamic>>>> getPlans() async {
    try {
      final plans = await _remoteDataSource.getPlans();
      return Right(plans);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  /// Fetches the user's current subscription.
  Future<Either<Failure, SubscriptionModel>> getSubscription() async {
    try {
      final subscription = await _remoteDataSource.getSubscription();
      await _localDataSource.saveSubscription(subscription);
      return Right(subscription);
    } catch (e) {
      try {
        final cached = await _localDataSource.getSubscription();
        if (cached != null) {
          return Right(cached);
        }
        return Left(ErrorHandler.handle(e).failure);
      } catch (_) {
        return Left(ErrorHandler.handle(e).failure);
      }
    }
  }

  /// Initiates a purchase.
  Future<Either<Failure, Map<String, dynamic>>> purchase(String planId) async {
    try {
      final result = await _remoteDataSource.purchase(planId);
      return Right(result);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  /// Cancels the current subscription.
  Future<Either<Failure, void>> cancelSubscription(String subscriptionId) async {
    try {
      await _remoteDataSource.cancelSubscription(subscriptionId);
      // Optionally update local cache to reflect cancellation
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }
}
