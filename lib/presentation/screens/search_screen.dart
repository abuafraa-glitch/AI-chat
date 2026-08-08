import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/widgets/app_scaffold.dart';
import 'package:ai_chat/core/widgets/empty_state.dart';
import 'package:ai_chat/core/widgets/error_view.dart';
import 'package:ai_chat/core/widgets/inputs/search_field.dart';
import 'package:ai_chat/core/widgets/loaders/loading_indicator.dart';
import 'package:ai_chat/data/models/conversation_model.dart';
import 'package:ai_chat/presentation/blocs/conversations_cubit.dart';
import 'package:ai_chat/presentation/blocs/data_sources.dart';
import 'package:ai_chat/presentation/widgets/formatters.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Global conversation search screen.
///
/// This screen is a self-contained route pushed above the main shell,
/// so it provides its own [ConversationsCubit]. The debounced query is
/// forwarded to [ConversationsCubit.search]; results are rendered with
/// loading, error and empty states. No business logic lives here.
class SearchScreen extends StatelessWidget {
  /// Creates a [SearchScreen].
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ConversationsCubit>(
      create: (context) => ConversationsCubit(
        repository: buildConversationRepository(),
      ),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  String _query = '';

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
    });
    context.read<ConversationsCubit>().search(value);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ConversationsCubit>();
    final state = cubit.state;
    final results = state.searchResults;

    return AppScaffold(
      appBar: AppBar(
        title: Text(localizedText(context, 'Search', 'البحث')),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchField(
              hintText: localizedText(context, 'Search conversations…', 'ابحث في المحادثات…'),
              onChanged: _onQueryChanged,
            ),
          ),
          Expanded(child: _buildContent(context, state, results)),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ConversationsState state,
    List<ConversationModel> results,
  ) {
    if (state.isSearching) {
      return const Center(child: LoadingIndicator());
    }

    if (state.error != null && _query.isNotEmpty) {
      return ErrorView(
        description: state.error,
        onRetry: () => cubitOf(context).search(_query),
      );
    }

    if (results.isEmpty) {
      return EmptyState(
        variant: _query.isEmpty
            ? EmptyStateVariant.custom
            : EmptyStateVariant.noResults,
        title: _query.isEmpty
            ? localizedText(
                context,
                'Type to search your conversations',
                'اكتب للبحث في محادثاتك',
              )
            : null,
        icon: _query.isEmpty ? Icons.search : null,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: results.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final conversation = results[index];
        return ListTile(
          leading: const Icon(Icons.chat_bubble_outline),
          title: Text(
            conversation.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (conversation.lastMessageSnippet != null &&
                  conversation.lastMessageSnippet!.isNotEmpty) ...<Widget>[
                Text(
                  conversation.lastMessageSnippet!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
              ],
              Text(
                formatAppDate(conversation.updatedAt),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          onTap: () => context.goToConversation(conversation.id),
        );
      },
    );
  }

  ConversationsCubit cubitOf(BuildContext context) =>
      context.read<ConversationsCubit>();
}
