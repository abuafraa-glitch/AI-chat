import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/api_provider.dart';
import '../../config/localization/app_localization.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Create new conversation
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: Strings.search,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Conversations List
          Expanded(
            child: conversationsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
              data: (conversations) {
                final filteredConversations = conversations
                    .where((conv) =>
                        conv.title.toLowerCase().contains(_searchQuery) ||
                        (conv.lastMessage?.toLowerCase().contains(_searchQuery) ?? false))
                    .toList();

                // Sort: pinned first, then by updated date
                filteredConversations.sort((a, b) {
                  if (a.isPinned != b.isPinned) {
                    return b.isPinned ? 1 : -1;
                  }
                  return b.updatedAt.compareTo(a.updatedAt);
                });

                if (filteredConversations.isEmpty) {
                  return Center(
                    child: Text(
                      Strings.noData,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredConversations.length,
                  itemBuilder: (context, index) {
                    final conversation = filteredConversations[index];
                    return FadeInUp(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GestureDetector(
                          onTap: () {
                            // Open conversation
                          },
                          onLongPress: () {
                            _showConversationMenu(context, conversation);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title Row
                                Row(
                                  children: [
                                    if (conversation.isPinned)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: Icon(
                                          Icons.push_pin,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        conversation.title,
                                        style: Theme.of(context).textTheme.titleMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (conversation.isArchived)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8.0),
                                        child: Icon(
                                          Icons.archive,
                                          size: 16,
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Last Message Preview
                                if (conversation.lastMessage != null)
                                  Text(
                                    conversation.lastMessage!,
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                const SizedBox(height: 8),

                                // Footer Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Messages: ${conversation.messageCount}',
                                      style: Theme.of(context).textTheme.labelSmall,
                                    ),
                                    Text(
                                      conversation.updatedAt.toString().split(' ')[0],
                                      style: Theme.of(context).textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showConversationMenu(BuildContext context, dynamic conversation) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                // Show rename dialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.push_pin),
              title: Text(conversation.isPinned ? 'Unpin' : 'Pin'),
              onTap: () {
                Navigator.pop(context);
                // Toggle pin
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: Text(conversation.isArchived ? 'Restore' : 'Archive'),
              onTap: () {
                Navigator.pop(context);
                // Toggle archive
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                // Show delete confirmation
              },
            ),
          ],
        ),
      ),
    );
  }
}
