import 'package:ai_chat/data/models/subscription_model.dart';
import 'package:ai_chat/data/repositories/subscription_repository.dart';
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
/// Data is loaded through [SubscriptionRepository], which applies the
/// remote-first / cache-fallback policy. A `null` current subscription
/// simply means the user has not subscribed yet.
final class SubscriptionsCubit extends Cubit<SubscriptionsState> {
  /// Creates a [SubscriptionsCubit] wired to [repository].
  SubscriptionsCubit({required SubscriptionRepository repository})
      : _repository = repository,
        super(const SubscriptionsState());

  final SubscriptionRepository _repository;

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
      final plans = await _repository.getPlans();
      emit(state.copyWith(plans: plans));
    } on Exception catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  /// Loads the active subscription with a local-cache fallback.
  Future<void> _loadCurrentSubscription() async {
    try {
      final subscription = await _repository.getSubscription();
      emit(state.copyWith(currentSubscription: subscription));
    } on Exception {
      // The repository already served the cache or the call failed;
      // a missing subscription is a valid state.
    }
  }
}
