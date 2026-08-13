import 'dart:async';

import 'package:ai_chat/data/models/message_model.dart';
import 'package:ai_chat/data/repositories/message_repository.dart';
import 'package:ai_chat/presentation/blocs/chat_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMessageRepository implements MessageRepository {
  _FakeMessageRepository({this.chunks = const ['Hel', 'lo', '!']});

  final List<String> chunks;
  Map<String, dynamic>? lastStreamData;
  String? lastCachedConversationId;

  @override
  Stream<String> streamMessage({
    required String conversationId,
    Map<String, dynamic>? data,
  }) async* {
    lastStreamData = data;
    for (final chunk in chunks) {
      yield chunk;
    }
  }

  @override
  Future<List<MessageModel>> getMessages(String conversationId) async {
    return const <MessageModel>[];
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required Map<String, dynamic> data,
  }) async {
    return MessageModel(
      id: 'sent',
      conversationId: conversationId,
      role: MessageRole.assistant,
      content: data['content'] as String,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<MessageModel> regenerateMessage({
    required String conversationId,
    required String messageId,
  }) async {
    return MessageModel(
      id: messageId,
      conversationId: conversationId,
      role: MessageRole.assistant,
      content: 'regenerated',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> cacheMessages(
    String conversationId,
    List<MessageModel> messages,
  ) async {
    lastCachedConversationId = conversationId;
  }
}

class _ThrowingMessageRepository implements MessageRepository {
  @override
  Stream<String> streamMessage({
    required String conversationId,
    Map<String, dynamic>? data,
  }) async* {
    throw Exception('network down');
  }

  @override
  Future<List<MessageModel>> getMessages(String conversationId) async {
    return const <MessageModel>[];
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required Map<String, dynamic> data,
  }) async {
    throw Exception('network down');
  }

  @override
  Future<MessageModel> regenerateMessage({
    required String conversationId,
    required String messageId,
  }) async {
    throw Exception('network down');
  }

  @override
  Future<void> cacheMessages(
    String conversationId,
    List<MessageModel> messages,
  ) async {}
}

/// Repository whose stream never produces data on its own — used to
/// verify that [ChatCubit.close] cancels the subscription.
class _SlowMessageRepository implements MessageRepository {
  bool subscriptionCancelled = false;

  @override
  Stream<String> streamMessage({
    required String conversationId,
    Map<String, dynamic>? data,
  }) {
    // A controller that stays open; the test relies on cancel() being
    // called, which we detect via the onListen/cancel callbacks.
    final controller = StreamController<String>(
      onCancel: () => subscriptionCancelled = true,
    );
    return controller.stream;
  }

  @override
  Future<List<MessageModel>> getMessages(String conversationId) async {
    return const <MessageModel>[];
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required Map<String, dynamic> data,
  }) async {
    return MessageModel(
      id: 'sent',
      conversationId: conversationId,
      role: MessageRole.assistant,
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<MessageModel> regenerateMessage({
    required String conversationId,
    required String messageId,
  }) async {
    return MessageModel(
      id: messageId,
      conversationId: conversationId,
      role: MessageRole.assistant,
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> cacheMessages(
    String conversationId,
    List<MessageModel> messages,
  ) async {}
}

void main() {
  group('ChatCubit', () {
    test('initial state is empty and idle', () {
      final cubit = ChatCubit(repository: _FakeMessageRepository());
      expect(cubit.state.messages, isEmpty);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.streamingContent, isNull);
      expect(cubit.state.error, isNull);
      cubit.close();
    });

    test('sendMessage appends user + assistant and streams content', () async {
      final repo = _FakeMessageRepository();
      final cubit = ChatCubit(repository: repo);

      await cubit.sendMessage(
        conversationId: 'c1',
        content: 'hi',
        modelId: 'gpt',
      );

      expect(cubit.state.messages.length, 2);
      expect(cubit.state.messages.first.role, MessageRole.user);
      expect(cubit.state.messages.first.content, 'hi');
      expect(cubit.state.messages.last.role, MessageRole.assistant);
      expect(cubit.state.messages.last.content, 'Hello!');
      expect(cubit.state.messages.last.isStreaming, isFalse);

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.streamingContent, isNull);
      expect(cubit.state.error, isNull);

      expect(repo.lastCachedConversationId, 'c1');
      cubit.close();
    });

    test('sendMessage surfaces errors via state.error', () async {
      final cubit = ChatCubit(repository: _ThrowingMessageRepository());

      await cubit.sendMessage(
        conversationId: 'c1',
        content: 'hi',
        modelId: 'gpt',
      );

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.streamingContent, isNull);
      expect(cubit.state.error, isNotNull);
      cubit.close();
    });

    test('close cancels in-flight stream without leaking emissions', () async {
      final repo = _SlowMessageRepository();
      final cubit = ChatCubit(repository: repo);

      // Kick off a slow stream but do not await it.
      unawaited(
        cubit.sendMessage(conversationId: 'c1', content: 'hi', modelId: 'gpt'),
      );

      // Close while streaming; no error should propagate.
      await cubit.close();

      expect(cubit.isClosed, isTrue);
      expect(repo.subscriptionCancelled, isTrue);
    });
  });
}
