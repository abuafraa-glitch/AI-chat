import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Immutable state for the notification feed.
final class NotificationsState extends Equatable {
  /// Creates a [NotificationsState].
  const NotificationsState({
    this.items = const <Map<String, dynamic>>[],
    this.isLoading = false,
    this.error,
  });

  /// Notification payloads (raw server maps).
  final List<Map<String, dynamic>> items;

  /// `true` while the feed is being fetched.
  final bool isLoading;

  /// Human-readable error message, or `null` when healthy.
  final String? error;

  /// Returns a copy with the given fields replaced.
  NotificationsState copyWith({
    List<Map<String, dynamic>>? items,
    bool? isLoading,
    String? error,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => <Object?>[items, isLoading, error];
}

/// Manages the in-app notification feed.
final class NotificationsCubit extends Cubit<NotificationsState> {
  /// Creates a [NotificationsCubit] wired to [remoteDataSource].
  NotificationsCubit({required RemoteDataSource remoteDataSource})
    : _remote = remoteDataSource,
      super(const NotificationsState());

  final RemoteDataSource _remote;

  /// Loads the notification feed.
  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final items = await _remote.getNotifications();
      emit(state.copyWith(items: items, isLoading: false));
    } on Exception catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
    }
  }
}
