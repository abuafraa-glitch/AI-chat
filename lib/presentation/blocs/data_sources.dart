import 'package:ai_chat/core/di/injection.dart';
import 'package:ai_chat/data/datasources/local/local_data_source.dart';
import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:ai_chat/data/repositories/ai_repository.dart';
import 'package:ai_chat/data/repositories/conversation_repository.dart';
import 'package:ai_chat/data/repositories/file_repository.dart';
import 'package:ai_chat/data/repositories/message_repository.dart';
import 'package:ai_chat/data/repositories/subscription_repository.dart';

/// Composition root for the presentation state-management layer.
///
/// Resolves repository implementations (and, where a repository is not
/// warranted, the raw data sources) from the DI container (`sl`) and
/// hands them to the feature cubits. Widgets must never construct data
/// sources or repositories directly — they obtain state through a
/// cubit, which is wired here.
///
/// ```dart
/// final cubit = ChatCubit(repository: buildMessageRepository());
/// ```

/// Builds the [RemoteDataSource] registered in the DI container.
RemoteDataSource buildRemoteDataSource() => sl<RemoteDataSource>();

/// Builds the [LocalDataSource] registered in the DI container.
LocalDataSource buildLocalDataSource() => sl<LocalDataSource>();

/// Builds the [AIRepository] registered in the DI container.
AIRepository buildAIRepository() => sl<AIRepository>();

/// Builds the [ConversationRepository] registered in the DI container.
ConversationRepository buildConversationRepository() =>
    sl<ConversationRepository>();

/// Builds the [MessageRepository] registered in the DI container.
MessageRepository buildMessageRepository() => sl<MessageRepository>();

/// Builds the [SubscriptionRepository] registered in the DI container.
SubscriptionRepository buildSubscriptionRepository() =>
    sl<SubscriptionRepository>();

/// Builds the [FileRepository] registered in the DI container.
FileRepository buildFileRepository() => sl<FileRepository>();
