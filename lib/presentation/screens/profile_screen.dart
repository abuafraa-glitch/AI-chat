import 'package:ai_chat/core/constants/app_values.dart';
import 'package:ai_chat/core/constants/storage_keys.dart';
import 'package:ai_chat/core/di/injection.dart';
import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/routes/route_names.dart';
import 'package:ai_chat/core/services/local_storage_service.dart';
import 'package:ai_chat/core/widgets/app_scaffold.dart';
import 'package:ai_chat/core/widgets/buttons/app_button.dart';
import 'package:ai_chat/core/widgets/dialogs/confirmation_dialog.dart';
import 'package:ai_chat/presentation/blocs/auth_controller.dart';
import 'package:ai_chat/presentation/blocs/data_sources.dart';
import 'package:ai_chat/presentation/blocs/subscriptions_cubit.dart';
import 'package:ai_chat/presentation/widgets/formatters.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Profile tab.
///
/// The profile owns workspace shortcuts and displays the current subscription
/// status. Notifications and payment history live only in Settings.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return AppValues.defaultAvatarInitials;
    }
    final first = parts.first[0].toUpperCase();
    final last = parts.length > 1
        ? parts[parts.length - 1][0].toUpperCase()
        : '';
    return '$first$last';
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: localizedTextRead(context, 'Sign out', 'تسجيل الخروج'),
      description: localizedTextRead(
        context,
        'Are you sure you want to sign out?',
        'هل أنت متأكد أنك تريد تسجيل الخروج؟',
      ),
      confirmText: localizedTextRead(context, 'Sign out', 'تسجيل الخروج'),
      cancelText: localizedTextRead(context, 'Cancel', 'إلغاء'),
      isDestructive: true,
    );
    if (confirmed == true) {
      await sl<AuthController>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = sl<LocalStorageService>();
    final displayName =
        storage.getString(StorageKeys.currentUserDisplayName) ??
        AppValues.defaultDisplayName;
    final email =
        storage.getString(StorageKeys.currentUserEmail) ??
        AppValues.defaultEmail;

    return BlocProvider<SubscriptionsCubit>(
      create: (_) =>
          SubscriptionsCubit(repository: buildSubscriptionRepository())..load(),
      child: AppScaffold(
        appBar: AppBar(
          title: Text(localizedText(context, 'Profile', 'الملف الشخصي')),
        ),
        body: _ProfileBody(
          displayName: displayName,
          email: email,
          initials: _initialsOf(displayName),
          confirmSignOut: () => _confirmSignOut(context),
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.displayName,
    required this.email,
    required this.initials,
    required this.confirmSignOut,
  });

  final String displayName;
  final String email;
  final String initials;
  final Future<void> Function() confirmSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subscriptionState = context.watch<SubscriptionsCubit>().state;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      initials,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(displayName, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _ProfileSection(
            title: localizedText(context, 'Workspace', 'مساحة العمل'),
            children: <Widget>[
              _ProfileTile(
                icon: Icons.folder_outlined,
                title: localizedText(context, 'Files', 'الملفات'),
                onTap: () => context.pushTo(RouteNames.files),
              ),
              _ProfileTile(
                icon: Icons.smart_toy_outlined,
                title: localizedText(context, 'Agents', 'الوكلاء'),
                onTap: () => context.pushTo(RouteNames.agents),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ProfileSection(
            title: localizedText(context, 'Subscription', 'الاشتراك'),
            children: <Widget>[
              _CurrentSubscriptionTile(state: subscriptionState),
            ],
          ),
          const SizedBox(height: 24),
          AppButton(
            text: localizedText(context, 'Sign out', 'تسجيل الخروج'),
            onPressed: confirmSignOut,
            type: AppButtonType.destructive,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _CurrentSubscriptionTile extends StatelessWidget {
  const _CurrentSubscriptionTile({required this.state});

  final SubscriptionsState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.currentSubscription == null) {
      return ListTile(
        leading: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text(localizedText(context, 'Loading...', 'جارٍ التحميل...')),
      );
    }

    final subscription = state.currentSubscription;
    if (subscription == null) {
      return ListTile(
        leading: const Icon(Icons.card_membership_outlined),
        title: Text(
          localizedText(
            context,
            'No active subscription',
            'لا يوجد اشتراك نشط',
          ),
        ),
        subtitle: Text(
          localizedText(
            context,
            'Your current subscription status appears here',
            'تظهر حالة اشتراكك الحالية هنا',
          ),
        ),
      );
    }

    final endDate = subscription.endDate;
    return ListTile(
      leading: const Icon(Icons.card_membership_outlined),
      title: Text(subscription.planType.name),
      subtitle: Text(
        endDate == null
            ? subscription.status.name
            : '${subscription.status.name} · ${localizedText(context, 'Until', 'حتى')} ${formatAppDate(endDate)}',
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: List<Widget>.generate(
              children.length,
              (index) => Column(
                children: <Widget>[
                  children[index],
                  if (index < children.length - 1) const Divider(height: 1),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
