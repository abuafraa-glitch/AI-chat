import 'package:ai_chat/core/theme/app_radius.dart';
import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/core/widgets/loaders/loading_indicator.dart';
import 'package:ai_chat/data/models/ai_model.dart';
import 'package:ai_chat/presentation/blocs/models_cubit.dart';
import 'package:ai_chat/presentation/dialogs/model_details_dialog.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Lets the user pick the active AI model.
///
/// Consumes [ModelsCubit] for the catalogue and the current selection,
/// and forwards selections straight back into the cubit. It never
/// fetches data itself — loading, error and empty states are derived
/// from the cubit state.
class ModelSelector extends StatelessWidget {
  /// Creates a [ModelSelector].
  const ModelSelector({super.key});

  IconData _providerIcon(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return Icons.smart_toy_outlined;
      case AIProvider.anthropic:
        return Icons.psychology_outlined;
      case AIProvider.gemini:
        return Icons.auto_awesome_outlined;
      case AIProvider.qwen:
        return Icons.language_outlined;
      case AIProvider.hajeenLocal:
        return Icons.home_outlined;
      case AIProvider.ollama:
        return Icons.bolt_outlined;
      case AIProvider.vllm:
        return Icons.memory_outlined;
      case AIProvider.openRouter:
        return Icons.route_outlined;
      case AIProvider.groq:
        return Icons.cloud_outlined;
      case AIProvider.custom:
        return Icons.settings_outlined;
    }
  }

  String _providerLabel(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return 'OpenAI';
      case AIProvider.anthropic:
        return 'Claude';
      case AIProvider.gemini:
        return 'Gemini';
      case AIProvider.qwen:
        return 'Qwen';
      case AIProvider.hajeenLocal:
        return 'Hajeen Local';
      case AIProvider.ollama:
        return 'Ollama';
      case AIProvider.vllm:
        return 'vLLM';
      case AIProvider.openRouter:
        return 'OpenRouter';
      case AIProvider.groq:
        return 'Groq';
      case AIProvider.custom:
        return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.watch<ModelsCubit>();
    final state = cubit.state;

    return Padding(
      padding: AppSpacing.h4,
      child: Container(
        padding: AppSpacing.inputField,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: AppRadius.md,
          border: Border.all(color: theme.dividerColor),
        ),
        child: _buildContent(context, cubit, state),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ModelsCubit cubit,
    ModelsState state,
  ) {
    final theme = Theme.of(context);

    if (state.isLoading && state.models.isEmpty) {
      return Row(
        children: <Widget>[
          const SizedBox(
            width: 20,
            height: 20,
            child: LoadingIndicator(strokeWidth: 2),
          ),
          AppSpacing.gap3,
          Text(
            localizedText(context, 'Loading models…', 'جارٍ تحميل النماذج…'),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      );
    }

    if (state.error != null && state.models.isEmpty) {
      return Row(
        children: <Widget>[
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          AppSpacing.gap3,
          Expanded(
            child: Text(
              localizedText(
                context,
                'Failed to load models',
                'تعذّر تحميل النماذج',
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: localizedText(context, 'Retry', 'إعادة المحاولة'),
            onPressed: cubit.loadModels,
          ),
        ],
      );
    }

    if (state.models.isEmpty) {
      return Text(
        localizedText(context, 'No models available', 'لا توجد نماذج متاحة'),
        style: theme.textTheme.bodyMedium,
      );
    }

    final selected = _selectedModel(state);
    return GestureDetector(
      onTap: () => _showModelSheet(context),
      child: Row(
        children: <Widget>[
          if (selected != null) ...<Widget>[
            Icon(
              _providerIcon(selected.provider),
              color: theme.colorScheme.primary,
            ),
            AppSpacing.gap3,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(selected.name, style: theme.textTheme.titleMedium),
                  Text(
                    _providerLabel(selected.provider),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, size: 20),
              tooltip: localizedText(
                context,
                'Model details',
                'تفاصيل النموذج',
              ),
              onPressed: () => ModelDetailsDialog.show(context, selected),
            ),
          ] else
            Expanded(
              child: Text(
                localizedText(context, 'Select a model', 'اختر نموذجاً'),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          Icon(Icons.expand_more, color: theme.colorScheme.primary),
        ],
      ),
    );
  }

  AIModel? _selectedModel(ModelsState state) {
    for (final model in state.models) {
      if (model.id == state.selectedModelId) {
        return model;
      }
    }
    return null;
  }

  void _showModelSheet(BuildContext context) {
    final cubit = context.read<ModelsCubit>();
    final state = cubit.state;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.topXxl),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: AppSpacing.all4,
              child: Text(
                localizedText(sheetContext, 'Select Model', 'اختر النموذج'),
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: state.models.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final model = state.models[index];
                  final isSelected = model.id == state.selectedModelId;
                  return ListTile(
                    leading: Icon(
                      _providerIcon(model.provider),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(model.name),
                    subtitle: Text(_providerLabel(model.provider)),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    enabled: model.isAvailable,
                    onTap: () {
                      cubit.selectModel(model.id);
                      Navigator.of(sheetContext).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
