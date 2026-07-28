import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/api_provider.dart';
import '../../config/localization/app_localization.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final currentSubAsync = ref.watch(currentSubscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (plans) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Subscription Info
              currentSubAsync.when(
                data: (currentSub) {
                  if (currentSub != null && currentSub.isActive) {
                    return FadeInUp(
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Plan',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentSub.plan.name,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Active until ${currentSub.endDate}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // Plans Grid
              Text(
                'Choose Your Plan',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              Column(
                children: List.generate(
                  plans.length,
                  (index) => FadeInUp(
                    delay: Duration(milliseconds: index * 100),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _PlanCard(
                        plan: plans[index],
                        isCurrentPlan: currentSubAsync.maybeWhen(
                          data: (currentSub) => currentSub?.planId == plans[index].id,
                          orElse: () => false,
                        ),
                        onSubscribe: () => _handleSubscribe(plans[index]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubscribe(dynamic plan) async {
    // TODO: Implement checkout flow
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Subscribe to ${plan.name}')),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final dynamic plan;
  final bool isCurrentPlan;
  final VoidCallback onSubscribe;

  const _PlanCard({
    required this.plan,
    required this.isCurrentPlan,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlan
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor,
          width: isCurrentPlan ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (isCurrentPlan)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Current',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Price
          Row(
            baseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              Text(
                '\$${plan.price}',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(width: 4),
              Text(
                '/${plan.billingCycleDays}days',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Features List
          ...plan.features.map<Widget>((feature) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isCurrentPlan ? null : onSubscribe,
              child: Text(isCurrentPlan ? Strings.currentPlan : Strings.subscribe_now),
            ),
          ),
        ],
      ),
    );
  }
}
