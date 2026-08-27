import 'package:ai_chat/core/constants/storage_keys.dart';
import 'package:ai_chat/core/services/local_storage_service.dart';
import 'package:ai_chat/core/services/secure_storage_service.dart';
import 'package:ai_chat/data/datasources/local/local_data_source_impl.dart';
import 'package:ai_chat/data/models/conversation_model.dart';
import 'package:ai_chat/data/models/message_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStorageService storage;
  late LocalDataSourceImpl local;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    storage = await LocalStorageService.create();
    local = LocalDataSourceImpl(
      storage,
      SecureStorageService(storage: const FlutterSecureStorage()),
    );
  });

  ConversationModel conversation(String id) {
    final now = DateTime.utc(2026, 1, 1);
    return ConversationModel(
      id: id,
      title: 'Conversation $id',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('conversation cache is isolated by the authenticated user id', () async {
    await storage.setString(StorageKeys.currentUserId, 'facebook-101');
    await local.saveConversations(<ConversationModel>[conversation('fb')]);

    await storage.setString(StorageKeys.currentUserId, 'google-202');
    expect(await local.getConversations(), isEmpty);

    await local.saveConversations(<ConversationModel>[conversation('google')]);
    expect((await local.getConversations()).single.id, 'google');

    await storage.setString(StorageKeys.currentUserId, 'facebook-101');
    expect((await local.getConversations()).single.id, 'fb');
  });

  test('legacy unscoped conversation cache is not visible to an account', () async {
    await storage.setString(StorageKeys.conversationsCache, '[{"id":"legacy"}]');
    await storage.setString(StorageKeys.currentUserId, 'email:user@example.com');

    expect(await local.getConversations(), isEmpty);
  });

  test('clearCache removes scoped conversation threads', () async {
    await storage.setString(StorageKeys.currentUserId, 'account-a');
    await local.saveConversations(<ConversationModel>[conversation('thread-a')]);
    await local.saveMessages(
      'thread-a',
      <MessageModel>[
        MessageModel(
          id: 'message-a',
          conversationId: 'thread-a',
          role: MessageRole.user,
          content: 'private',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      ],
    );

    await local.clearCache();

    expect(await local.getConversations(), isEmpty);
    expect(await local.getMessages('thread-a'), isEmpty);
  });
}
