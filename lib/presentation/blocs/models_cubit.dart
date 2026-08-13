import 'package:ai_chat/data/models/ai_model.dart';
import 'package:ai_chat/data/repositories/ai_repository.dart';
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
  List<Object?> get props => <Object?>[
    models,
    selectedModelId,
    isLoading,
    error,
  ];
}

/// Manages the AI model catalogue and the user's current selection.
///
/// Loads the catalogue through [AIRepository] (which applies the
/// remote-first / cache-fallback policy) and keeps the selected model
/// id in state so the rest of the UI can react to changes.
final class ModelsCubit extends Cubit<ModelsState> {
  /// Creates a [ModelsCubit] wired to [repository].
  ModelsCubit({required AIRepository repository})
    : _repository = repository,
      super(const ModelsState());

  final AIRepository _repository;

  /// Loads the AI model catalogue.
  Future<void> loadModels() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final models = await _repository.getModels();
      emit(state.copyWith(models: models, isLoading: false));
    } on Exception catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
    }
  }

  /// Selects [modelId] as the active model.
  void selectModel(String? modelId) {
    emit(state.copyWith(selectedModelId: modelId));
  }
}
