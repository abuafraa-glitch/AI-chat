import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/routes/route_names.dart';
import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/core/widgets/app_scaffold.dart';
import 'package:ai_chat/core/widgets/empty_state.dart';
import 'package:ai_chat/core/widgets/error_view.dart';
import 'package:ai_chat/core/widgets/inputs/app_text_field.dart';
import 'package:ai_chat/core/widgets/loaders/loading_indicator.dart';
import 'package:ai_chat/data/models/conversation_model.dart';
import 'package:ai_chat/presentation/blocs/conversations_cubit.dart';
import 'package:ai_chat/presentation/screens/chat_screen.dart';
import 'package:ai_chat/presentation/screens/home_screen.dart';
import 'package:ai_chat/presentation/widgets/formatters.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

/// Chat tab — the conversation list of the application.
///
/// Purely presentational: it observes [ConversationsCubit], derives the
/// filtered list through [ConversationsCubit.filterAndSort] (the logic
/// lives in the cubit, not the widget), and renders loading, error,
/// empty and data states. When there are no conversations yet, the
/// [HomeScreen] welcome hub is shown instead. Opening a conversation
/// navigates through go_router.
class ConversationsScreen extends StatefulWidget {
  /// Creates a [ConversationsScreen].
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _query = '';
    });
  }

  void _startConversation(BuildContext context) {
    final conversationId = const Uuid().v4();
    context.pushTo(
      RouteNames.conversationPath(conversationId),
      extra: const ChatLaunchData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ConversationsCubit>();
    final state = cubit.state;
    final filtered = cubit.filterAndSort(_query);

    return AppScaffold(
      appBar: AppBar(title: Text(localizedText(context, 'Chats', 'المحادثات'))),
      floatingActionButton: FloatingActionButton(
        tooltip: localizedText(context, 'New conversation', 'محادثة جديدة'),
        onPressed: () => _startConversation(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: AppSpacing.all4,
            child: AppTextField(
              controller: _searchController,
              isSearch: true,
              hintText: localizedText(
                context,
                'Search conversations…',
                'ابحث في المحادثات…',
              ),
              onClear: _clearSearch,
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
            ),
          ),
          Expanded(child: _buildContent(context, state, filtered)),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ConversationsState state,
    List<ConversationModel> conversations,
  ) {
    final cubit = context.read<ConversationsCubit>();

    if (state.isLoading && state.conversations.isEmpty) {
      return const Center(child: LoadingIndicator());
    }

    if (state.error != null && state.conversations.isEmpty) {
      return ErrorView(
        description: state.error,
        onRetry: cubit.loadConversations,
      );
    }

    if (conversations.isEmpty && _query.isEmpty) {
      return const HomeScreen();
    }

    if (conversations.isEmpty) {
      return const EmptyState(variant: EmptyStateVariant.noResults);
    }

    return ListView.builder(
      padding: AppSpacing.h4,
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final isPinned = conversation.status == ConversationStatus.pinned;
        return Card(
          margin: AppSpacing.bottom3,
          child: ListTile(
            leading: Icon(
              isPinned ? Icons.push_pin : Icons.chat_bubble_outline,
              color: isPinned ? Theme.of(context).colorScheme.primary : null,
            ),
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
                  AppSpacing.gap1,
                ],
                Text(
                  formatAppDate(conversation.updatedAt),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            onTap: () => context.goToConversation(conversation.id),
          ),
        );
      },
    );
  }
}
