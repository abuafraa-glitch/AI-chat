import 'dart:convert';

import 'package:ai_chat/core/constants/storage_keys.dart';
import 'package:ai_chat/core/services/local_storage_service.dart';
import 'package:ai_chat/core/services/secure_storage_service.dart';
import 'package:ai_chat/data/datasources/local/local_data_source.dart';
import 'package:ai_chat/data/models/ai_model.dart';
import 'package:ai_chat/data/models/conversation_model.dart';
import 'package:ai_chat/data/models/message_model.dart';
import 'package:ai_chat/data/models/subscription_model.dart';

/// Implementation of [LocalDataSource] that uses [LocalStorageService]
/// and [SecureStorageService] for local data persistence.
class LocalDataSourceImpl implements LocalDataSource {
  final LocalStorageService _localStorageService;
  final SecureStorageService _secureStorageService;

  const LocalDataSourceImpl(
    this._localStorageService,
    this._secureStorageService,
  );

  // ── Authentication ────────────────────────────────────────────────────────

  @override
  Future<void> saveToken(String token) async {
    await _secureStorageService.writeAccessToken(token);
  }

  @override
  Future<String?> getToken() async {
    return _secureStorageService.readAccessToken();
  }

  @override
  Future<void> deleteToken() async {
    await _secureStorageService.clearTokens();
  }

  // ── User ──────────────────────────────────────────────────────────────────

  @override
  Future<void> saveUser(Map<String, dynamic> userJson) async {
    await _localStorageService.setString(
      StorageKeys.currentUser,
      jsonEncode(userJson),
    );
  }

  @override
  Future<Map<String, dynamic>?> getUser() async {
    final String? userJsonString = _localStorageService.getString(
      StorageKeys.currentUser,
    );
    if (userJsonString == null) return null;
    return jsonDecode(userJsonString) as Map<String, dynamic>;
  }

  @override
  Future<void> deleteUser() async {
    await _localStorageService.remove(StorageKeys.currentUser);
  }

  // ── AI Models ─────────────────────────────────────────────────────────────

  @override
  Future<void> saveAIModels(List<AIModel> models) async {
    final List<Map<String, dynamic>> jsonList = models
        .map((model) => model.toJson())
        .toList();
    await _localStorageService.setString(
      _scopedKey(StorageKeys.modelCatalogCache),
      jsonEncode(jsonList),
    );
  }

  @override
  Future<List<AIModel>> getAIModels() async {
    final String? jsonString = _localStorageService.getString(
      _scopedKey(StorageKeys.modelCatalogCache),
    );
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => AIModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> clearAIModelsCache() async {
    await _localStorageService.remove(
      _scopedKey(StorageKeys.modelCatalogCache),
    );
  }

  // ── Conversations ─────────────────────────────────────────────────────────

  @override
  Future<void> saveConversations(List<ConversationModel> conversations) async {
    final List<Map<String, dynamic>> jsonList = conversations
        .map((conv) => conv.toJson())
        .toList();
    await _localStorageService.setString(
      _scopedKey(StorageKeys.conversationsCache),
      jsonEncode(jsonList),
    );
  }

  @override
  Future<List<ConversationModel>> getConversations() async {
    final String? jsonString = _localStorageService.getString(
      _scopedKey(StorageKeys.conversationsCache),
    );
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> deleteConversation(String id) async {
    List<ConversationModel> conversations = await getConversations();
    conversations.removeWhere((conv) => conv.id == id);
    await saveConversations(conversations);
  }

  @override
  Future<void> updateConversation(ConversationModel conversation) async {
    List<ConversationModel> conversations = await getConversations();
    final int index = conversations.indexWhere(
      (conv) => conv.id == conversation.id,
    );
    if (index != -1) {
      conversations[index] = conversation;
    } else {
      conversations.add(conversation);
    }
    await saveConversations(conversations);
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  @override
  Future<void> saveMessages(
    String conversationId,
    List<MessageModel> messages,
  ) async {
    final List<Map<String, dynamic>> jsonList = messages
        .map((msg) => msg.toJson())
        .toList();
    await _localStorageService.setString(
      _scopedKey(CacheKeys.conversationMessages(conversationId)),
      jsonEncode(jsonList),
    );
  }

  @override
  Future<List<MessageModel>> getMessages(String conversationId) async {
    final String? jsonString = _localStorageService.getString(
      _scopedKey(CacheKeys.conversationMessages(conversationId)),
    );
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> deleteMessages(String conversationId) async {
    await _localStorageService.remove(
      _scopedKey(CacheKeys.conversationMessages(conversationId)),
    );
  }

  @override
  Future<void> updateMessage(MessageModel message) async {
    List<MessageModel> messages = await getMessages(message.conversationId);
    final int index = messages.indexWhere((msg) => msg.id == message.id);
    if (index != -1) {
      messages[index] = message;
    } else {
      messages.add(message);
    }
    await saveMessages(message.conversationId, messages);
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  @override
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    // Assuming a generic settings key for now, or specific keys can be added to StorageKeys
    await _localStorageService.setString('app.settings', jsonEncode(settings));
  }

  @override
  Future<Map<String, dynamic>?> getSettings() async {
    final String? settingsJsonString = _localStorageService.getString(
      'app.settings',
    );
    if (settingsJsonString == null) return null;
    return jsonDecode(settingsJsonString) as Map<String, dynamic>;
  }

  // ── Subscriptions ─────────────────────────────────────────────────────────

  @override
  Future<void> saveSubscription(SubscriptionModel subscription) async {
    await _localStorageService.setString(
      _scopedKey(StorageKeys.subscriptionCache),
      jsonEncode(subscription.toJson()),
    );
  }

  @override
  Future<SubscriptionModel?> getSubscription() async {
    final String? jsonString = _localStorageService.getString(
      _scopedKey(StorageKeys.subscriptionCache),
    );
    if (jsonString == null) return null;
    return SubscriptionModel.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  // ── Cache Management ──────────────────────────────────────────────────────

  @override
  Future<void> remove(String key) async {
    await _localStorageService.remove(key);
  }

  @override
  Future<bool> exists(String key) async {
    return _localStorageService.containsKey(key);
  }

  @override
  Future<void> clearCache() async {
    // Clear the well-known aggregate caches.
    await _localStorageService.remove(
      _scopedKey(StorageKeys.modelCatalogCache),
    );
    await _localStorageService.remove(
      _scopedKey(StorageKeys.modelCatalogSyncedAt),
    );
    await _localStorageService.remove(
      _scopedKey(StorageKeys.conversationsCache),
    );
    await _localStorageService.remove(
      _scopedKey(StorageKeys.subscriptionCache),
    );
    // Remove legacy unscoped keys as well; otherwise data written by an older
    // app version could remain visible after an account switch.
    await _localStorageService.remove(StorageKeys.modelCatalogCache);
    await _localStorageService.remove(StorageKeys.modelCatalogSyncedAt);
    await _localStorageService.remove(StorageKeys.conversationsCache);
    await _localStorageService.remove(StorageKeys.subscriptionCache);

    // Clear every cached conversation message thread. Conversation
    // message threads are keyed dynamically
    // (CacheKeys.conversationMessages(id)) and their ids are not known
    // up front, so we iterate all stored keys and remove those that
    // match the message-thread prefix. This is the robust strategy
    // required so clearCache actually evicts all managed cached data
    // rather than silently leaving message threads behind.
    const messageThreadPrefix = 'memory.conversation.';
    for (final key in _localStorageService.allKeys) {
      if (key.startsWith(messageThreadPrefix) ||
          key.startsWith('user.') ||
          key.startsWith('cache.')) {
        await _localStorageService.remove(key);
      }
    }
  }

  /// Prefixes persistent cache keys with the authenticated user id. The
  /// anonymous namespace is deliberately separate from every account.
  String _scopedKey(String key) {
    final userId = _localStorageService.getString(StorageKeys.currentUserId);
    final namespace = userId == null || userId.isEmpty ? 'anonymous' : userId;
    return 'user.$namespace.$key';
  }

  @override
  Future<void> clearAll() async {
    // Clear all local storage data, including sensitive tokens
    await _localStorageService.clearAll();
    await _secureStorageService.deleteAll();
  }
}
