import 'package:ai_chat/core/widgets/app_scaffold.dart';
import 'package:ai_chat/core/widgets/empty_state.dart';
import 'package:ai_chat/core/widgets/error_view.dart';
import 'package:ai_chat/core/widgets/loaders/loading_indicator.dart';
import 'package:ai_chat/presentation/blocs/data_sources.dart';
import 'package:ai_chat/presentation/blocs/notifications_cubit.dart';
import 'package:ai_chat/presentation/widgets/formatters.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// In-app notification feed.
///
/// Self-contained route providing its own [NotificationsCubit]; renders
/// the payloads defensively with loading, error and empty states.
class NotificationsScreen extends StatelessWidget {
  /// Creates a [NotificationsScreen].
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationsCubit>(
      create: (context) =>
          NotificationsCubit(remoteDataSource: buildRemoteDataSource())..load(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  String _stringOf(Map<String, dynamic> map, String key) {
    final value = map[key];
    return value is String ? value : '';
  }

  DateTime? _dateOf(Map<String, dynamic> map) {
    final raw = map['createdAt'];
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<NotificationsCubit>();
    final state = cubit.state;

    return AppScaffold(
      appBar: AppBar(
        title: Text(localizedText(context, 'Notifications', 'الإشعارات')),
      ),
      body: _buildContent(context, cubit, state),
    );
  }

  Widget _buildContent(
    BuildContext context,
    NotificationsCubit cubit,
    NotificationsState state,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: LoadingIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return ErrorView(
        description: state.error,
        onRetry: cubit.load,
      );
    }

    if (state.items.isEmpty) {
      return EmptyState(
        variant: EmptyStateVariant.custom,
        icon: Icons.notifications_none,
        title: localizedText(context, 'You are all caught up', 'لا إشعارات جديدة'),
        description: localizedText(
          context,
          'No new notifications right now.',
          'لا توجد إشعارات جديدة حالياً.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = state.items[index];
        final title = _stringOf(item, 'title');
        final body = _stringOf(item, 'body');
        final date = _dateOf(item);
        final read = item['read'] == true;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              read ? Icons.notifications_outlined : Icons.notifications_active,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(
            title.isEmpty
                ? localizedText(context, 'Notification', 'إشعار')
                : title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (body.isNotEmpty) ...<Widget>[
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
              ],
              if (date != null)
                Text(
                  formatAppDate(date),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
        );
      },
    );
  }
}
