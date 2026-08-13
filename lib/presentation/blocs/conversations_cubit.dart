import 'package:ai_chat/data/models/conversation_model.dart';
import 'package:ai_chat/data/repositories/conversation_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Immutable state for the conversation list and search.
final class ConversationsState extends Equatable {
  /// Creates a [ConversationsState].
  const ConversationsState({
    this.conversations = const <ConversationModel>[],
    this.searchResults = const <ConversationModel>[],
    this.isLoading = false,
    this.isSearching = false,
    this.error,
  });

  /// Conversations loaded for the current user.
  final List<ConversationModel> conversations;

  /// Results of the most recent remote search.
  final List<ConversationModel> searchResults;

  /// `true` while the list is being fetched.
  final bool isLoading;

  /// `true` while a remote search is in flight.
  final bool isSearching;

  /// Human-readable error message, or `null` when healthy.
  final String? error;

  /// Returns a copy with the given fields replaced.
  ConversationsState copyWith({
    List<ConversationModel>? conversations,
    List<ConversationModel>? searchResults,
    bool? isLoading,
    bool? isSearching,
    String? error,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    conversations,
    searchResults,
    isLoading,
    isSearching,
    error,
  ];
}

/// Manages the user's conversation list and search.
///
/// Loads the list through [ConversationRepository] (remote-first with a
/// cache fallback) and exposes pure filtering/sorting helpers so the
/// presentation layer stays free of logic. Remote search results are
/// stored separately in [ConversationsState.searchResults].
final class ConversationsCubit extends Cubit<ConversationsState> {
  /// Creates a [ConversationsCubit] wired to [repository].
  ConversationsCubit({required ConversationRepository repository})
    : _repository = repository,
      super(const ConversationsState());

  final ConversationRepository _repository;

  /// Loads the conversation list.
  Future<void> loadConversations() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final conversations = await _repository.getConversations();
      emit(state.copyWith(conversations: conversations, isLoading: false));
    } on Exception catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
    }
  }

  /// Runs a remote search for [query] and stores the results.
  ///
  /// Empty queries clear the results and are a no-op for the server.
  Future<void> search(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      emit(
        state.copyWith(
          searchResults: const <ConversationModel>[],
          isSearching: false,
        ),
      );
      return;
    }
    emit(state.copyWith(isSearching: true, error: null));
    try {
      final results = await _repository.searchConversations(normalized);
      emit(state.copyWith(searchResults: results, isSearching: false));
    } on Exception catch (error) {
      emit(state.copyWith(isSearching: false, error: error.toString()));
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
      final snippet = conversation.lastMessageSnippet?.toLowerCase() ?? '';
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
