import 'package:ai_chat/data/datasources/local/local_data_source.dart';
import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:ai_chat/data/models/conversation_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Immutable state for the conversation list.
final class ConversationsState extends Equatable {
  /// Creates a [ConversationsState].
  const ConversationsState({
    this.conversations = const <ConversationModel>[],
    this.isLoading = false,
    this.error,
  });

  /// Conversations loaded for the current user.
  final List<ConversationModel> conversations;

  /// `true` while the list is being fetched.
  final bool isLoading;

  /// Human-readable error message, or `null` when healthy.
  final String? error;

  /// Returns a copy with the given fields replaced.
  ConversationsState copyWith({
    List<ConversationModel>? conversations,
    bool? isLoading,
    String? error,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => <Object?>[conversations, isLoading, error];
}

/// Manages the user's conversation list.
///
/// Fetches remote-first with a local-cache fallback, mirroring the
/// repository contract. Filtering and sorting helpers are exposed here
/// (not in widgets) so the presentation layer stays free of logic.
final class ConversationsCubit extends Cubit<ConversationsState> {
  /// Creates a [ConversationsCubit] wired to [remoteDataSource] and
  /// [localDataSource].
  ConversationsCubit({
    required RemoteDataSource remoteDataSource,
    required LocalDataSource localDataSource,
  })  : _remote = remoteDataSource,
        _local = localDataSource,
        super(const ConversationsState());

  final RemoteDataSource _remote;
  final LocalDataSource _local;

  /// Loads the conversation list.
  Future<void> loadConversations() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final conversations = await _remote.getConversations();
      await _local.saveConversations(conversations);
      emit(state.copyWith(conversations: conversations, isLoading: false));
    } on Exception catch (error) {
      final cached = await _safeCachedConversations();
      if (cached != null && cached.isNotEmpty) {
        emit(state.copyWith(conversations: cached, isLoading: false));
      } else {
        emit(state.copyWith(isLoading: false, error: error.toString()));
      }
    }
  }

  /// Returns the cached conversation list, or `null` when unavailable.
  Future<List<ConversationModel>?> _safeCachedConversations() async {
    try {
      return await _local.getConversations();
    } on Exception {
      return null;
    }
  }

  /// Filters [state.conversations] by [query] against the title and
  /// last-message snippet, then sorts pinned conversations first and
  /// the remainder by most recently updated.
  List<ConversationModel> filterAndSort(String query) {
    final normalized = query.trim().toLowerCase();
    final filtered = state.conversations.where((conversation) {
      if (normalized.isEmpty) {
        return true;
      }
      final title = conversation.title.toLowerCase();
      final snippet =
          conversation.lastMessageSnippet?.toLowerCase() ?? '';
      return title.contains(normalized) || snippet.contains(normalized);
    }).toList();

    filtered.sort((a, b) {
      final aPinned = a.status == ConversationStatus.pinned;
      final bPinned = b.status == ConversationStatus.pinned;
      if (aPinned != bPinned) {
        return aPinned ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return filtered;
  }
}
