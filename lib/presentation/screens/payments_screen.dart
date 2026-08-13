import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/core/widgets/app_scaffold.dart';
import 'package:ai_chat/core/widgets/empty_state.dart';
import 'package:ai_chat/core/widgets/error_view.dart';
import 'package:ai_chat/core/widgets/loaders/loading_indicator.dart';
import 'package:ai_chat/presentation/blocs/data_sources.dart';
import 'package:ai_chat/presentation/blocs/payments_cubit.dart';
import 'package:ai_chat/presentation/widgets/formatters.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Payment history screen.
///
/// Self-contained route providing its own [PaymentsCubit]; renders the
/// payment records defensively with loading, error and empty states.
class PaymentsScreen extends StatelessWidget {
  /// Creates a [PaymentsScreen].
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PaymentsCubit>(
      create: (context) =>
          PaymentsCubit(remoteDataSource: buildRemoteDataSource())..load(),
      child: const _PaymentsView(),
    );
  }
}

class _PaymentsView extends StatelessWidget {
  const _PaymentsView();

  String _stringOf(Map<String, dynamic> map, String key) {
    final value = map[key];
    return value is String ? value : '';
  }

  double _amountOf(Map<String, dynamic> map) {
    final amount = map['amount'];
    return amount is num ? amount.toDouble() : 0;
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
    final cubit = context.watch<PaymentsCubit>();
    final state = cubit.state;

    return AppScaffold(
      appBar: AppBar(
        title: Text(localizedText(context, 'Payments', 'المدفوعات')),
      ),
      body: _buildContent(context, cubit, state),
    );
  }

  Widget _buildContent(
    BuildContext context,
    PaymentsCubit cubit,
    PaymentsState state,
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
        icon: Icons.receipt_long_outlined,
        title: localizedText(context, 'No payments yet', 'لا توجد مدفوعات بعد'),
        description: localizedText(
          context,
          'Your billing history will appear here.',
          'سيظهر سجل الفوترة الخاص بك هنا.',
        ),
      );
    }

    return ListView.separated(
      padding: AppSpacing.buttonSm,
      itemCount: state.items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = state.items[index];
        final status = _stringOf(item, 'status');
        final date = _dateOf(item);
        return ListTile(
          leading: const Icon(Icons.payment_outlined),
          title: Text(
            _stringOf(item, 'description').isEmpty
                ? localizedText(context, 'Payment', 'عملية دفع')
                : _stringOf(item, 'description'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (date != null)
                Text(
                  formatAppDate(date),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              if (status.isNotEmpty)
                Text(
                  status,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
            ],
          ),
          trailing: Text(
            '\$${_amountOf(item).toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        );
      },
    );
  }
}
