import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Immutable state for the agents catalogue.
final class AgentsState extends Equatable {
  /// Creates an [AgentsState].
  const AgentsState({
    this.items = const <Map<String, dynamic>>[],
    this.isLoading = false,
    this.error,
  });

  /// Agent definitions (raw server maps).
  final List<Map<String, dynamic>> items;

  /// `true` while the catalogue is being fetched.
  final bool isLoading;

  /// Human-readable error message, or `null` when healthy.
  final String? error;

  /// Returns a copy with the given fields replaced.
  AgentsState copyWith({
    List<Map<String, dynamic>>? items,
    bool? isLoading,
    String? error,
  }) {
    return AgentsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => <Object?>[items, isLoading, error];
}

/// Manages the AI agent catalogue.
final class AgentsCubit extends Cubit<AgentsState> {
  /// Creates an [AgentsCubit] wired to [remoteDataSource].
  AgentsCubit({required RemoteDataSource remoteDataSource})
    : _remote = remoteDataSource,
      super(const AgentsState());

  final RemoteDataSource _remote;

  /// Loads the agent catalogue.
  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final items = await _remote.getAgents();
      emit(state.copyWith(items: items, isLoading: false));
    } on Exception catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
    }
  }
}
