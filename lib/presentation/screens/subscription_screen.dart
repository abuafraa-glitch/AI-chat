import 'package:ai_chat/core/theme/app_radius.dart';
import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/core/widgets/app_scaffold.dart';
import 'package:ai_chat/core/widgets/empty_state.dart';
import 'package:ai_chat/core/widgets/error_view.dart';
import 'package:ai_chat/core/widgets/loaders/loading_indicator.dart';
import 'package:ai_chat/data/models/subscription_model.dart';
import 'package:ai_chat/presentation/blocs/data_sources.dart';
import 'package:ai_chat/presentation/blocs/subscriptions_cubit.dart';
import 'package:ai_chat/presentation/widgets/formatters.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Subscription plans page.
///
/// This screen is a self-contained route pushed above the main shell,
/// so it provides its own [SubscriptionsCubit]. It renders the plan
/// catalogue (raw server payloads, accessed defensively) and the typed
/// current [SubscriptionModel]. Purchase flows are out of scope for the
/// presentation layer, so no subscribe handlers live here.
class SubscriptionScreen extends StatelessWidget {
  /// Creates a [SubscriptionScreen].
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SubscriptionsCubit>(
      create: (context) =>
          SubscriptionsCubit(repository: buildSubscriptionRepository())..load(),
      child: const _SubscriptionView(),
    );
  }
}

class _SubscriptionView extends StatelessWidget {
  const _SubscriptionView();

  String _stringOf(Map<String, dynamic> map, String key) {
    final value = map[key];
    return value is String ? value : '';
  }

  String _priceOf(Map<String, dynamic> map) {
    final price = map['price'];
    return price is num ? price.toString() : '';
  }

  List<String> _featuresOf(Map<String, dynamic> map) {
    final features = map['features'];
    if (features is List) {
      return features.whereType<String>().toList();
    }
    return const <String>[];
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SubscriptionsCubit>();
    final state = cubit.state;

    return AppScaffold(
      appBar: AppBar(
        title: Text(
          localizedText(context, 'Subscription Plans', 'خطط الاشتراك'),
        ),
      ),
      body: _buildContent(context, cubit, state),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SubscriptionsCubit cubit,
    SubscriptionsState state,
  ) {
    if (state.isLoading && state.plans.isEmpty) {
      return const Center(child: LoadingIndicator());
    }

    if (state.error != null && state.plans.isEmpty) {
      return ErrorView(description: state.error, onRetry: cubit.load);
    }

    if (state.plans.isEmpty) {
      return const EmptyState(variant: EmptyStateVariant.noData);
    }

    return ListView(
      padding: AppSpacing.all4,
      children: <Widget>[
        if (state.currentSubscription != null) ...<Widget>[
          _CurrentSubscriptionCard(
            subscription: state.currentSubscription!,
            formatDate: formatAppDate,
            localized: (en, ar) => localizedText(context, en, ar),
          ),
          AppSpacing.gap6,
        ],
        Text(
          localizedText(context, 'Choose your plan', 'اختر خطتك'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        AppSpacing.gap4,
        for (final plan in state.plans)
          Padding(
            padding: AppSpacing.bottom4,
            child: _PlanCard(
              name: _stringOf(plan, 'name'),
              description: _stringOf(plan, 'description'),
              price: _priceOf(plan),
              features: _featuresOf(plan),
              localized: (en, ar) => localizedText(context, en, ar),
            ),
          ),
      ],
    );
  }
}

class _CurrentSubscriptionCard extends StatelessWidget {
  const _CurrentSubscriptionCard({
    required this.subscription,
    required this.formatDate,
    required this.localized,
  });

  final SubscriptionModel subscription;
  final String Function(DateTime) formatDate;
  final String Function(String, String) localized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final planName = subscription.planType.name;
    final status = subscription.status.name;
    final endDate = subscription.endDate;

    return Container(
      padding: AppSpacing.all4,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: AppRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            localized('Current Plan', 'الخطة الحالية'),
            style: theme.textTheme.titleMedium,
          ),
          AppSpacing.gap2,
          Text(planName, style: theme.textTheme.headlineMedium),
          AppSpacing.gap2,
          Text(
            '${subscription.price} ${subscription.currency}',
            style: theme.textTheme.bodyLarge,
          ),
          AppSpacing.gap1,
          Text(
            endDate != null
                ? '${localized('Active until', 'نشطة حتى')} ${formatDate(endDate)}'
                : localized('Status', 'الحالة'),
            style: theme.textTheme.bodySmall,
          ),
          AppSpacing.gap1,
          Text(status, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.description,
    required this.price,
    required this.features,
    required this.localized,
  });

  final String name;
  final String description;
  final String price;
  final List<String> features;
  final String Function(String, String) localized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppSpacing.all5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(name, style: theme.textTheme.headlineSmall),
            if (description.isNotEmpty) ...<Widget>[
              AppSpacing.gap1,
              Text(description, style: theme.textTheme.bodySmall),
            ],
            AppSpacing.gap4,
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Text(
                  price.isEmpty
                      ? localized('Contact us', 'تواصل معنا')
                      : '\$$price',
                  style: theme.textTheme.displaySmall,
                ),
              ],
            ),
            AppSpacing.gap4,
            for (final feature in features)
              Padding(
                padding: AppSpacing.v1Insets,
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    AppSpacing.gap3,
                    Expanded(
                      child: Text(feature, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
