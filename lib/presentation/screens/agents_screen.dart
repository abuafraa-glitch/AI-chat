import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/core/widgets/app_scaffold.dart';
import 'package:ai_chat/core/widgets/empty_state.dart';
import 'package:ai_chat/core/widgets/error_view.dart';
import 'package:ai_chat/core/widgets/loaders/loading_indicator.dart';
import 'package:ai_chat/presentation/blocs/agents_cubit.dart';
import 'package:ai_chat/presentation/blocs/data_sources.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// AI agents catalogue screen.
///
/// Self-contained route providing its own [AgentsCubit]; renders the
/// agent definitions defensively with loading, error and empty states.
class AgentsScreen extends StatelessWidget {
  /// Creates an [AgentsScreen].
  const AgentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AgentsCubit>(
      create: (context) =>
          AgentsCubit(remoteDataSource: buildRemoteDataSource())..load(),
      child: const _AgentsView(),
    );
  }
}

class _AgentsView extends StatelessWidget {
  const _AgentsView();

  String _stringOf(Map<String, dynamic> map, String key) {
    final value = map[key];
    return value is String ? value : '';
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<AgentsCubit>();
    final state = cubit.state;

    return AppScaffold(
      appBar: AppBar(title: Text(localizedText(context, 'Agents', 'الوكلاء'))),
      body: _buildContent(context, cubit, state),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AgentsCubit cubit,
    AgentsState state,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: LoadingIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return ErrorView(description: state.error, onRetry: cubit.load);
    }

    if (state.items.isEmpty) {
      return EmptyState(
        variant: EmptyStateVariant.custom,
        icon: Icons.smart_toy_outlined,
        title: localizedText(context, 'No agents yet', 'لا توجد وكلاء بعد'),
        description: localizedText(
          context,
          'Agents that run tasks on your behalf will appear here.',
          'ستظهر هنا الوكلاء الذين ينفّذون المهام نيابة عنك.',
        ),
      );
    }

    return ListView.separated(
      padding: AppSpacing.buttonSm,
      itemCount: state.items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final agent = state.items[index];
        final name = _stringOf(agent, 'name');
        final description = _stringOf(agent, 'description');
        final status = _stringOf(agent, 'status');
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.smart_toy_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(
            name.isEmpty ? localizedText(context, 'Agent', 'وكيل') : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (description.isNotEmpty) ...<Widget>[
                Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
              ],
              if (status.isNotEmpty)
                Text(
                  status,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
