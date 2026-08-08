import 'package:ai_chat/data/datasources/local/local_data_source.dart';
import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:ai_chat/data/models/conversation_model.dart';
import 'package:ai_chat/data/repositories/conversation_repository.dart';

/// Implementation of [ConversationRepository].
///
/// Orchestrates conversation data between the remote and local sources,
/// keeping the local cache in sync after every successful mutation and
/// serving the cache when the network is unavailable.
class ConversationRepositoryImpl implements ConversationRepository {
  /// Creates a [ConversationRepositoryImpl] wired to
  /// [remoteDataSource] and [localDataSource].
  ConversationRepositoryImpl({
    required RemoteDataSource remoteDataSource,
    required LocalDataSource localDataSource,
  })  : _remote = remoteDataSource,
        _local = localDataSource;

  final RemoteDataSource _remote;
  final LocalDataSource _local;

  @override
  Future<List<ConversationModel>> getConversations() async {
    try {
      final conversations = await _remote.getConversations();
      await _local.saveConversations(conversations);
      return conversations;
    } on Exception {
      final cached = await _cachedConversations();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  @override
  Future<ConversationModel> createConversation(
    Map<String, dynamic> data,
  ) async {
    final conversation = await _remote.createConversation(data);
    await _local.updateConversation(conversation);
    return conversation;
  }

  @override
  Future<ConversationModel> updateConversation({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final updated = await _remote.updateConversation(id: id, data: data);
    await _local.updateConversation(updated);
    return updated;
  }

  @override
  Future<void> deleteConversation(String id) async {
    await _remote.deleteConversation(id);
    await _local.deleteConversation(id);
  }

  @override
  Future<List<ConversationModel>> searchConversations(String query) =>
      _remote.searchConversations(query);

  /// Returns the locally cached conversation list, or `null`.
  Future<List<ConversationModel>?> _cachedConversations() async {
    try {
      return await _local.getConversations();
    } on Exception {
      return null;
    }
  }
}
