import 'package:ai_chat/data/models/file_model.dart';

/// Contract for the file management repository.
///
/// Implementations orchestrate remote file operations. Failures are
/// surfaced as [AppException] subtypes.
abstract interface class FileRepository {
  /// Lists the files uploaded by the current user.
  Future<List<FileModel>> getFiles();

  /// Uploads the file at [filePath] under the form field
  /// [fileFieldName] and returns the created file.
  Future<FileModel> uploadFile({
    required String filePath,
    required String fileFieldName,
    Map<String, String>? additionalFields,
  });

  /// Deletes a previously uploaded file.
  Future<void> deleteFile(String fileId);
}
