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
      // A stalled proxy/auth refresh must never leave the models screen
      // spinning forever. The fallback is the Groq model configured by the
      // local backend and is only used when the catalogue request fails.
      final models = await _repository.getModels().timeout(
        const Duration(seconds: 12),
      );
      final currentIsAvailable = models.any(
        (model) => model.id == state.selectedModelId && model.isAvailable,
      );
      String? selectedModelId = currentIsAvailable
          ? state.selectedModelId
          : null;
      if (selectedModelId == null) {
        for (final model in models) {
          if (model.isAvailable && model.provider == AIProvider.groq) {
            selectedModelId = model.id;
            break;
          }
        }
      }
      selectedModelId ??= _firstAvailableModelId(models);
      emit(
        state.copyWith(
          models: models,
          selectedModelId: selectedModelId,
          isLoading: false,
        ),
      );
    } catch (error) {
      const fallback = _groqFallbackModels;
      if (fallback.isNotEmpty) {
        final selectedModelId =
            state.selectedModelId != null &&
                fallback.any((model) => model.id == state.selectedModelId)
            ? state.selectedModelId
            : fallback.first.id;
        emit(
          state.copyWith(
            models: fallback,
            selectedModelId: selectedModelId,
            isLoading: false,
            // Keep the catalogue usable. The network failure is visible in
            // logs through the repository/client and should not block chat.
          ),
        );
      } else {
        emit(state.copyWith(isLoading: false, error: error.toString()));
      }
    }
  }

  /// Selects [modelId] as the active model.
  void selectModel(String? modelId) {
    emit(state.copyWith(selectedModelId: modelId));
  }

  /// Returns the active model, choosing Groq or the first available model
  /// when no valid selection exists yet.
  String? ensureDefaultSelection() {
    final current = state.selectedModelId;
    if (current != null &&
        state.models.any((model) => model.id == current && model.isAvailable)) {
      return current;
    }
    final groq = state.models.where(
      (model) => model.isAvailable && model.provider == AIProvider.groq,
    );
    final selected = groq.isNotEmpty
        ? groq.first.id
        : _firstAvailableModelId(state.models);
    if (selected != null && selected != current) {
      selectModel(selected);
    }
    return selected;
  }

  static const List<AIModel> _groqFallbackModels = <AIModel>[
    AIModel(
      id: 'openai/gpt-oss-20b',
      name: 'Groq — GPT OSS 20B',
      description: 'نموذج Groq الافتراضي المتصل بالباكيند المحلي.',
      version: '1.0',
      provider: AIProvider.groq,
      type: AIModelType.cloud,
      contextWindow: 32768,
      maxOutputTokens: 1024,
      capabilities: AIModelCapabilities(supportsStreaming: true),
      isAvailable: true,
    ),
  ];

  String? _firstAvailableModelId(List<AIModel> models) {
    for (final model in models) {
      if (model.isAvailable) return model.id;
    }
    return null;
  }
}
