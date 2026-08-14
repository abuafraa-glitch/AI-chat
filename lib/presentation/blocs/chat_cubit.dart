import 'dart:async';

import 'package:ai_chat/data/models/message_model.dart';
import 'package:ai_chat/data/repositories/message_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

/// Sentinel used by [ChatState.copyWith] to distinguish "not provided"
/// from an explicit `null` reset for nullable fields.
const Object _sentinel = Object();

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
  ///
  /// Nullable fields ([streamingContent], [error]) use an explicit
  /// optional wrapper so they can be reset to `null` — a plain `??`
  /// default would prevent clearing them.
  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    Object? streamingContent = _sentinel,
    Object? error = _sentinel,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      streamingContent: identical(streamingContent, _sentinel)
          ? this.streamingContent
          : streamingContent as String?,
      error: identical(error, _sentinel) ? this.error : error as String?,
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
  ChatCubit({required MessageRepository repository})
    : _repository = repository,
      super(const ChatState());

  final MessageRepository _repository;

  /// Active streaming subscription, or `null` when no stream is in
  /// flight. Held so [close] can cancel it deterministically.
  StreamSubscription<String>? _streamSubscription;

  /// Cancellation key for the in-flight stream request, or `null` when
  /// no stream is in flight. Passed to the network layer so the
  /// underlying Dio request is aborted on [close] / [stopStreaming].
  String? _cancelToken;

  /// `true` once the cubit has been closed; guards against emitting
  /// on a closed cubit (which would otherwise throw `StateError`).
  bool _isClosed = false;

  /// Sends [content] to [conversationId] using [modelId] and streams
  /// the assistant response.
  ///
  /// A placeholder assistant message is appended immediately, then
  /// token chunks update [ChatState.streamingContent] until the stream
  /// completes, at which point the finalised thread is cached.
  ///
  /// If a stream is already in flight it is cancelled before a new one
  /// starts, preventing duplicate/orphaned streams.
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    required String modelId,
  }) async {
    // Cancel any in-flight stream before starting a new one.
    await _cancelActiveStream();

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
    final thread = <MessageModel>[
      ...state.messages,
      userMessage,
      assistantPlaceholder,
    ];

    _safeEmit(
      state.copyWith(
        messages: thread,
        isLoading: true,
        streamingContent: '',
        error: null,
      ),
    );

    var buffer = '';
    _cancelToken = _newId();

    final completer = Completer<void>();

    _streamSubscription = _repository
        .streamMessage(
          conversationId: conversationId,
          data: <String, dynamic>{'content': content, 'modelId': modelId},
          cancelToken: _cancelToken,
        )
        .listen(
          (chunk) {
            buffer += chunk;
            _safeEmit(
              state.copyWith(
                messages: _updateAssistant(
                  thread,
                  assistantPlaceholder.id,
                  buffer,
                ),
                streamingContent: buffer,
              ),
            );
          },
          onDone: () {
            final finalised = _updateAssistant(
              thread,
              assistantPlaceholder.id,
              buffer,
              isStreaming: false,
            );
            // Persist the finalised thread and clear streaming state.
            _repository
                .cacheMessages(conversationId, finalised)
                .then((_) {
                  _safeEmit(
                    state.copyWith(
                      messages: finalised,
                      isLoading: false,
                      streamingContent: null,
                    ),
                  );
                  _streamSubscription = null;
                  _cancelToken = null;
                  if (!completer.isCompleted) completer.complete();
                })
                .catchError((Object error) {
                  _safeEmit(
                    state.copyWith(
                      isLoading: false,
                      streamingContent: null,
                      error: error.toString(),
                    ),
                  );
                  _streamSubscription = null;
                  _cancelToken = null;
                  if (!completer.isCompleted) completer.complete();
                });
          },
          onError: (Object error) {
            _safeEmit(
              state.copyWith(
                isLoading: false,
                streamingContent: null,
                error: error.toString(),
              ),
            );
            _streamSubscription = null;
            _cancelToken = null;
            if (!completer.isCompleted) completer.complete();
          },
          cancelOnError: true,
        );

    await completer.future;
    // Errors are surfaced via [ChatState.error]; the cubit does not
    // re-throw so callers (and the UI) observe the failure through
    // state, consistent with the Cubit pattern.
  }

  /// Cancels the in-flight stream (if any) without closing the cubit.
  ///
  /// Used when the user manually stops generation or when a new
  /// message supersedes an in-flight one.
  Future<void> stopStreaming() async {
    await _cancelActiveStream();
    _safeEmit(state.copyWith(isLoading: false, streamingContent: null));
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
    _safeEmit(state.copyWith(messages: thread.sublist(0, lastUserIndex + 1)));
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
      _safeEmit(state.copyWith(messages: messages, error: null));
    } on Exception catch (error) {
      _safeEmit(state.copyWith(error: error.toString()));
    }
  }

  @override
  Future<void> close() {
    _isClosed = true;
    _cancelActiveStream();
    return super.close();
  }

  // ── Private helpers ────────────────────────────────────────────────────

  /// Emits [state] only while the cubit is open. After [close] any
  /// emission is silently dropped, preventing `StateError: Cannot use
  /// emit after close` and avoiding orphaned stream emissions.
  void _safeEmit(ChatState newState) {
    if (!_isClosed) emit(newState);
  }

  /// Cancels and clears the active stream subscription + network token.
  ///
  /// Both the local [StreamSubscription] and the upstream Dio request
  /// (via the repository's cancellation API) are aborted, so neither
  /// emissions nor network activity survive [close] / [stopStreaming].
  Future<void> _cancelActiveStream() async {
    final sub = _streamSubscription;
    final token = _cancelToken;
    _streamSubscription = null;
    _cancelToken = null;
    _repository.cancelStream(token);
    await sub?.cancel();
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

  /// Generates a unique local message id (UUID v4).
  static const Uuid _uuid = Uuid();
  static String _newId() => _uuid.v4();
}
