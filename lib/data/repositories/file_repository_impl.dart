import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:ai_chat/data/models/file_model.dart';
import 'package:ai_chat/data/repositories/file_repository.dart';

/// Implementation of [FileRepository] backed by [RemoteDataSource].
class FileRepositoryImpl implements FileRepository {
  /// Creates a [FileRepositoryImpl] wired to [remoteDataSource].
  FileRepositoryImpl({required RemoteDataSource remoteDataSource})
    : _remote = remoteDataSource;

  final RemoteDataSource _remote;

  @override
  Future<List<FileModel>> getFiles() => _remote.getFiles();

  @override
  Future<FileModel> uploadFile({
    required String filePath,
    required String fileFieldName,
    Map<String, String>? additionalFields,
  }) {
    return _remote.uploadFile(
      filePath: filePath,
      fileFieldName: fileFieldName,
      additionalFields: additionalFields,
    );
  }

  @override
  Future<void> deleteFile(String fileId) => _remote.deleteFile(fileId);
}
