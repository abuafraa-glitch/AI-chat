import 'package:ai_chat/data/models/file_model.dart';
import 'package:ai_chat/data/repositories/file_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Immutable state for the file management screen.
final class FilesState extends Equatable {
  /// Creates a [FilesState].
  const FilesState({
    this.files = const <FileModel>[],
    this.isLoading = false,
    this.isUploading = false,
    this.error,
  });

  /// Files belonging to the current user.
  final List<FileModel> files;

  /// `true` while the file list is being fetched.
  final bool isLoading;

  /// `true` while a file upload is in flight.
  final bool isUploading;

  /// Human-readable error message, or `null` when healthy.
  final String? error;

  /// Returns a copy with the given fields replaced.
  FilesState copyWith({
    List<FileModel>? files,
    bool? isLoading,
    bool? isUploading,
    String? error,
  }) {
    return FilesState(
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => <Object?>[files, isLoading, isUploading, error];
}

/// Manages file listing, upload and deletion through [FileRepository].
final class FilesCubit extends Cubit<FilesState> {
  /// Creates a [FilesCubit] wired to [repository].
  FilesCubit({required FileRepository repository})
    : _repository = repository,
      super(const FilesState());

  final FileRepository _repository;

  /// Loads the file list.
  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final files = await _repository.getFiles();
      emit(state.copyWith(files: files, isLoading: false));
    } on Exception catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
    }
  }

  /// Uploads the file at [filePath] under the display [fileName].
  Future<void> upload({
    required String filePath,
    required String fileName,
  }) async {
    emit(state.copyWith(isUploading: true, error: null));
    try {
      final uploaded = await _repository.uploadFile(
        filePath: filePath,
        fileFieldName: 'file',
        additionalFields: <String, String>{'name': fileName},
      );
      emit(
        state.copyWith(
          files: <FileModel>[uploaded, ...state.files],
          isUploading: false,
        ),
      );
    } on Exception catch (error) {
      emit(state.copyWith(isUploading: false, error: error.toString()));
    }
  }

  /// Deletes the file with [fileId].
  Future<void> delete(String fileId) async {
    try {
      await _repository.deleteFile(fileId);
      emit(
        state.copyWith(
          files: state.files.where((file) => file.id != fileId).toList(),
        ),
      );
    } on Exception catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }
}
