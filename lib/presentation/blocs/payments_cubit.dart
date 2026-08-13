import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Immutable state for the payment history screen.
final class PaymentsState extends Equatable {
  /// Creates a [PaymentsState].
  const PaymentsState({
    this.items = const <Map<String, dynamic>>[],
    this.isLoading = false,
    this.error,
  });

  /// Payment records (raw server maps).
  final List<Map<String, dynamic>> items;

  /// `true` while the history is being fetched.
  final bool isLoading;

  /// Human-readable error message, or `null` when healthy.
  final String? error;

  /// Returns a copy with the given fields replaced.
  PaymentsState copyWith({
    List<Map<String, dynamic>>? items,
    bool? isLoading,
    String? error,
  }) {
    return PaymentsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => <Object?>[items, isLoading, error];
}

/// Manages the user's payment history.
final class PaymentsCubit extends Cubit<PaymentsState> {
  /// Creates a [PaymentsCubit] wired to [remoteDataSource].
  PaymentsCubit({required RemoteDataSource remoteDataSource})
    : _remote = remoteDataSource,
      super(const PaymentsState());

  final RemoteDataSource _remote;

  /// Loads the payment history.
  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final items = await _remote.getPaymentHistory();
      emit(state.copyWith(items: items, isLoading: false));
    } on Exception catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
    }
  }
}
