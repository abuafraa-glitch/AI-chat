import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/conversation.dart';
import '../models/message.dart';

class StorageService {
  static const String _authTokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _conversationsKey = 'conversations';
  static const String _messagesKey = 'messages_';
  static const String _selectedModelKey = 'selected_model';

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Authentication
  Future<void> saveAuthToken(String token) async {
    await _prefs.setString(_authTokenKey, token);
  }

  String? getAuthToken() {
    return _prefs.getString(_authTokenKey);
  }

  Future<void> clearAuthToken() async {
    await _prefs.remove(_authTokenKey);
  }

  // User ID
  Future<void> saveUserId(String userId) async {
    await _prefs.setString(_userIdKey, userId);
  }

  String? getUserId() {
    return _prefs.getString(_userIdKey);
  }

  // Conversations Cache
  Future<void> cacheConversations(List<Conversation> conversations) async {
    final jsonList = conversations.map((c) => jsonEncode(c.toJson())).toList();
    await _prefs.setStringList(_conversationsKey, jsonList);
  }

  List<Conversation> getCachedConversations() {
    final jsonList = _prefs.getStringList(_conversationsKey) ?? [];
    return jsonList
        .map((json) => Conversation.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  // Messages Cache
  Future<void> cacheMessages(String conversationId, List<Message> messages) async {
    final key = '$_messagesKey$conversationId';
    final jsonList = messages.map((m) => jsonEncode(m.toJson())).toList();
    await _prefs.setStringList(key, jsonList);
  }

  List<Message> getCachedMessages(String conversationId) {
    final key = '$_messagesKey$conversationId';
    final jsonList = _prefs.getStringList(key) ?? [];
    return jsonList
        .map((json) => Message.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  Future<void> clearMessagesCache(String conversationId) async {
    final key = '$_messagesKey$conversationId';
    await _prefs.remove(key);
  }

  // Selected Model
  Future<void> saveSelectedModel(String modelId) async {
    await _prefs.setString(_selectedModelKey, modelId);
  }

  String? getSelectedModel() {
    return _prefs.getString(_selectedModelKey);
  }

  // Clear All
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
