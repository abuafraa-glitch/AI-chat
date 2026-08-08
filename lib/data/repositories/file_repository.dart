/// Contract for the file management repository.
///
/// Implementations orchestrate remote file operations. Failures are
/// surfaced as [AppException] subtypes.
abstract interface class FileRepository {
  /// Lists the files uploaded by the current user.
  Future<List<Map<String, dynamic>>> getFiles();

  /// Uploads the file at [filePath] under the form field
  /// [fileFieldName] and returns the server payload.
  Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    required String fileFieldName,
    Map<String, String>? additionalFields,
  });

  /// Deletes a previously uploaded file.
  Future<void> deleteFile(String fileId);
}
