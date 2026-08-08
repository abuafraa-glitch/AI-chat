import 'package:ai_chat/data/models/message_model.dart';
import 'package:ai_chat/data/repositories/message_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Immutable state for a chat conversation.
final class ChatState extends Equatable {
  /// Creates a [ChatState].
  const ChatState({
    this.messages = const <MessageModel>[],
    this.isLoading = false,
    this.streamingContent,
    this.error,
  });

  /// Messages rendered in the conversation.
  final List<MessageModel> messages;

  /// `true` while a response is being generated.
  final bool isLoading;

  /// Partial assistant response accumulated so far during streaming.
  final String? streamingContent;

  /// Human-readable error message, or `null` when healthy.
  final String? error;

  /// Returns a copy with the given fields replaced.
  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    String? streamingContent,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      streamingContent: streamingContent ?? this.streamingContent,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        messages,
        isLoading,
        streamingContent,
        error,
      ];
}

/// Manages a chat conversation: message history, sending, streaming
/// and regeneration.
///
/// All network and storage orchestration is delegated to
/// [MessageRepository]; widgets only observe the state and forward
/// user intents. Streaming chunks are accumulated into
/// [ChatState.streamingContent] and the finalised thread is persisted
/// through the repository's cache.
final class ChatCubit extends Cubit<ChatState> {
  /// Creates a [ChatCubit] wired to [repository].
  ChatCubit({required MessageRepository repository}) : _repository = repository,
        super(const ChatState());

  final MessageRepository _repository;

  /// Sends [content] to [conversationId] using [modelId] and streams
  /// the assistant response.
  ///
  /// A placeholder assistant message is appended immediately, then
  /// token chunks update [ChatState.streamingContent] until the stream
  /// completes, at which point the finalised thread is cached.
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    required String modelId,
  }) async {
    final now = DateTime.now();
    final userMessage = MessageModel(
      id: _newId(),
      conversationId: conversationId,
      role: MessageRole.user,
      content: content,
      createdAt: now,
      updatedAt: now,
    );
    final assistantPlaceholder = MessageModel(
      id: _newId(),
      conversationId: conversationId,
      role: MessageRole.assistant,
      content: '',
      createdAt: now,
      updatedAt: now,
      isStreaming: true,
    );
    final thread = <MessageModel>[...state.messages, userMessage, assistantPlaceholder];

    emit(
      state.copyWith(
        messages: thread,
        isLoading: true,
        streamingContent: '',
        error: null,
      ),
    );

    var buffer = '';
    try {
      final stream = _repository.streamMessage(
        conversationId: conversationId,
        data: <String, dynamic>{'content': content, 'modelId': modelId},
      );
      await for (final chunk in stream) {
        buffer += chunk;
        emit(
          state.copyWith(
            messages: _updateAssistant(thread, assistantPlaceholder.id, buffer),
            streamingContent: buffer,
          ),
        );
      }

      final finalised = _updateAssistant(
        thread,
        assistantPlaceholder.id,
        buffer,
        isStreaming: false,
      );
      await _repository.cacheMessages(conversationId, finalised);
      emit(
        state.copyWith(
          messages: finalised,
          isLoading: false,
          streamingContent: null,
        ),
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          streamingContent: null,
          error: error.toString(),
        ),
      );
    }
  }

  /// Regenerates the last assistant response.
  ///
  /// Removes the trailing assistant message(s) and re-sends the most
  /// recent user message using [modelId].
  Future<void> regenerate({
    required String conversationId,
    required String modelId,
  }) async {
    final thread = state.messages;
    final lastUserIndex = _lastUserIndex(thread);
    if (lastUserIndex == -1) {
      return;
    }
    final content = thread[lastUserIndex].content;
    emit(state.copyWith(messages: thread.sublist(0, lastUserIndex + 1)));
    await sendMessage(
      conversationId: conversationId,
      content: content,
      modelId: modelId,
    );
  }

  /// Loads the message history for [conversationId].
  ///
  /// Serves the locally cached thread first, then refreshes from the
  /// remote source (both handled by the repository).
  Future<void> loadMessages(String conversationId) async {
    try {
      final messages = await _repository.getMessages(conversationId);
      emit(state.copyWith(messages: messages, error: null));
    } on Exception catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  /// Returns the index of the last user message, or `-1`.
  int _lastUserIndex(List<MessageModel> messages) {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].role == MessageRole.user) {
        return i;
      }
    }
    return -1;
  }

  /// Returns a copy of [messages] with the assistant message matching
  /// [id] updated to [content] and [isStreaming].
  List<MessageModel> _updateAssistant(
    List<MessageModel> messages,
    String id,
    String content, {
    bool? isStreaming,
  }) {
    return messages.map((message) {
      if (message.id != id) {
        return message;
      }
      return message.copyWith(
        content: content,
        isStreaming: isStreaming ?? message.isStreaming,
      );
    }).toList();
  }

  /// Generates a unique message id.
  static String _newId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
