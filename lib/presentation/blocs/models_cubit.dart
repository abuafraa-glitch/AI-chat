import 'package:ai_chat/data/datasources/local/local_data_source.dart';
import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:ai_chat/data/models/ai_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Immutable state for the AI model catalogue and current selection.
final class ModelsState extends Equatable {
  /// Creates a [ModelsState].
  const ModelsState({
    this.models = const <AIModel>[],
    this.selectedModelId,
    this.isLoading = false,
    this.error,
  });

  /// Available AI models.
  final List<AIModel> models;

  /// Identifier of the currently selected model, or `null`.
  final String? selectedModelId;

  /// `true` while the catalogue is being fetched.
  final bool isLoading;

  /// Human-readable error message, or `null` when healthy.
  final String? error;

  /// Returns a copy with the given fields replaced.
  ModelsState copyWith({
    List<AIModel>? models,
    String? selectedModelId,
    bool? isLoading,
    String? error,
  }) {
    return ModelsState(
      models: models ?? this.models,
      selectedModelId: selectedModelId ?? this.selectedModelId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => <Object?>[models, selectedModelId, isLoading, error];
}

/// Manages the AI model catalogue and the user's current selection.
///
/// Fetches the catalogue remote-first and falls back to the locally
/// cached catalogue when the network is unavailable, mirroring the
/// repository contract. The selected model id is kept in state so the
/// rest of the UI can react to changes.
final class ModelsCubit extends Cubit<ModelsState> {
  /// Creates a [ModelsCubit] wired to [remoteDataSource] and
  /// [localDataSource].
  ModelsCubit({
    required RemoteDataSource remoteDataSource,
    required LocalDataSource localDataSource,
  })  : _remote = remoteDataSource,
        _local = localDataSource,
        super(const ModelsState());

  final RemoteDataSource _remote;
  final LocalDataSource _local;

  /// Loads the AI model catalogue.
  ///
  /// On success the catalogue is cached locally. On failure the cached
  /// catalogue is served when available; otherwise the error is
  /// surfaced in the state.
  Future<void> loadModels() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final models = await _remote.getModels();
      await _local.saveAIModels(models);
      emit(state.copyWith(models: models, isLoading: false));
    } on Exception catch (error) {
      final cached = await _safeCachedModels();
      if (cached != null && cached.isNotEmpty) {
        emit(state.copyWith(models: cached, isLoading: false));
      } else {
        emit(state.copyWith(isLoading: false, error: error.toString()));
      }
    }
  }

  /// Selects [modelId] as the active model.
  void selectModel(String? modelId) {
    emit(state.copyWith(selectedModelId: modelId));
  }

  /// Returns the cached catalogue, or `null` when unavailable.
  Future<List<AIModel>?> _safeCachedModels() async {
    try {
      return await _local.getAIModels();
    } on Exception {
      return null;
    }
  }
}
