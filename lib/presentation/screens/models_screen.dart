import 'package:ai_chat/core/widgets/app_scaffold.dart';
import 'package:ai_chat/core/widgets/empty_state.dart';
import 'package:ai_chat/core/widgets/error_view.dart';
import 'package:ai_chat/core/widgets/loaders/loading_indicator.dart';
import 'package:ai_chat/data/models/ai_model.dart';
import 'package:ai_chat/presentation/blocs/models_cubit.dart';
import 'package:ai_chat/presentation/dialogs/model_details_dialog.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// AI model catalogue tab.
///
/// Purely presentational: observes [ModelsCubit] and renders loading,
/// error, empty and data states. Selecting a model forwards the choice
/// to the cubit; tapping the info action opens [ModelDetailsDialog].
class ModelsScreen extends StatelessWidget {
  /// Creates a [ModelsScreen].
  const ModelsScreen({super.key});

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
      case AIProvider.custom:
        return Icons.settings_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ModelsCubit>();
    final state = cubit.state;

    return AppScaffold(
      appBar: AppBar(
        title: Text(localizedText(context, 'AI Models', 'نماذج الذكاء الاصطناعي')),
      ),
      body: _buildContent(context, cubit, state),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ModelsCubit cubit,
    ModelsState state,
  ) {
    if (state.isLoading && state.models.isEmpty) {
      return const Center(child: LoadingIndicator());
    }

    if (state.error != null && state.models.isEmpty) {
      return ErrorView(
        description: state.error,
        onRetry: cubit.loadModels,
      );
    }

    if (state.models.isEmpty) {
      return const EmptyState(
        variant: EmptyStateVariant.noData,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.models.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final model = state.models[index];
        final isSelected = model.id == state.selectedModelId;
        return Card(
          child: ListTile(
            leading: Icon(
              _providerIcon(model.provider),
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(model.name),
            subtitle: Text(
              model.description != null && model.description!.isNotEmpty
                  ? model.description!
                  : model.version,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: localizedText(context, 'Details', 'التفاصيل'),
                  onPressed: () => ModelDetailsDialog.show(context, model),
                ),
              ],
            ),
            enabled: model.isAvailable,
            onTap: () => cubit.selectModel(model.id),
          ),
        );
      },
    );
  }
}
