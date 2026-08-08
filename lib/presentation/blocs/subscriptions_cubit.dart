import 'package:ai_chat/data/datasources/local/local_data_source.dart';
import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:ai_chat/data/models/subscription_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Immutable state for subscription plans and the active subscription.
final class SubscriptionsState extends Equatable {
  /// Creates a [SubscriptionsState].
  const SubscriptionsState({
    this.plans = const <Map<String, dynamic>>[],
    this.currentSubscription,
    this.isLoading = false,
    this.error,
  });

  /// Available subscription plans (raw server payloads).
  final List<Map<String, dynamic>> plans;

  /// The user's active subscription, or `null` when none exists.
  final SubscriptionModel? currentSubscription;

  /// `true` while data is being fetched.
  final bool isLoading;

  /// Human-readable error message, or `null` when healthy.
  final String? error;

  /// Returns a copy with the given fields replaced.
  SubscriptionsState copyWith({
    List<Map<String, dynamic>>? plans,
    SubscriptionModel? currentSubscription,
    bool? isLoading,
    String? error,
  }) {
    return SubscriptionsState(
      plans: plans ?? this.plans,
      currentSubscription: currentSubscription ?? this.currentSubscription,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        plans,
        currentSubscription,
        isLoading,
        error,
      ];
}

/// Manages subscription plans and the user's active subscription.
///
/// Plans are fetched from the remote data source; the active
/// subscription is served from the remote source when available and
/// falls back to the locally cached subscription. A `null` current
/// subscription simply means the user has not subscribed yet.
final class SubscriptionsCubit extends Cubit<SubscriptionsState> {
  /// Creates a [SubscriptionsCubit] wired to [remoteDataSource] and
  /// [localDataSource].
  SubscriptionsCubit({
    required RemoteDataSource remoteDataSource,
    required LocalDataSource localDataSource,
  })  : _remote = remoteDataSource,
        _local = localDataSource,
        super(const SubscriptionsState());

  final RemoteDataSource _remote;
  final LocalDataSource _local;

  /// Loads subscription plans and the active subscription.
  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));

    await _loadPlans();
    await _loadCurrentSubscription();

    emit(state.copyWith(isLoading: false));
  }

  /// Loads the available plans; failures are surfaced in the state.
  Future<void> _loadPlans() async {
    try {
      final plans = await _remote.getSubscriptionPlans();
      emit(state.copyWith(plans: plans));
    } on Exception catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  /// Loads the active subscription with a local-cache fallback.
  Future<void> _loadCurrentSubscription() async {
    try {
      final subscription = await _remote.getSubscription();
      await _local.saveSubscription(subscription);
      emit(state.copyWith(currentSubscription: subscription));
    } on Exception {
      final cached = await _safeCachedSubscription();
      if (cached != null) {
        emit(state.copyWith(currentSubscription: cached));
      }
    }
  }

  /// Returns the cached subscription, or `null` when unavailable.
  Future<SubscriptionModel?> _safeCachedSubscription() async {
    try {
      return await _local.getSubscription();
    } on Exception {
      return null;
    }
  }
}
