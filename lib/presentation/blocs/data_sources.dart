import 'package:ai_chat/core/di/injection.dart';
import 'package:ai_chat/core/network/api_consumer.dart';
import 'package:ai_chat/core/services/local_storage_service.dart';
import 'package:ai_chat/core/services/secure_storage_service.dart';
import 'package:ai_chat/data/datasources/local/local_data_source.dart';
import 'package:ai_chat/data/datasources/local/local_data_source_impl.dart';
import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:ai_chat/data/datasources/remote/remote_data_source_impl.dart';

/// Composition root for the presentation state-management layer.
///
/// Resolves the concrete data-source implementations from the DI
/// container (`sl`) and hands them to the feature cubits. Widgets must
/// never construct data sources directly — they obtain state through
/// a cubit, which is wired here.
///
/// ```dart
/// final cubit = ChatCubit(
///   remoteDataSource: buildRemoteDataSource(),
///   localDataSource: buildLocalDataSource(),
/// );
/// ```
RemoteDataSource buildRemoteDataSource() {
  return RemoteDataSourceImpl(apiConsumer: sl<ApiConsumer>());
}

/// Builds the [LocalDataSource] backed by the shared local and secure
/// storage services registered in the DI container.
LocalDataSource buildLocalDataSource() {
  return LocalDataSourceImpl(
    sl<LocalStorageService>(),
    sl<SecureStorageService>(),
  );
}
