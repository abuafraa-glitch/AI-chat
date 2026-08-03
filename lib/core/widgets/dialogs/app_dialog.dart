
import 'package:flutter/material.dart';
import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/core/widgets/cards/app_card.dart';

enum InfoCardStatus {
  info,
  success,
  warning,
  error,
}

class InfoCard extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;
  final Widget? badge;
  final InfoCardStatus status;
  final List<Widget>? actions;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const InfoCard({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.badge,
    this.status = InfoCardStatus.info,
    this.actions,
    this.showCloseButton = false,
    this.onClose,
  });

  Color _getStatusColor(BuildContext context) {
    switch (status) {
      case InfoCardStatus.info:
        return context.colorScheme.primary;
      case InfoCardStatus.success:
        return context.colorScheme.secondary;
      case InfoCardStatus.warning:
        return context.colorScheme.tertiary;
      case InfoCardStatus.error:
        return context.colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _getStatusColor(context);

    return AppCard(
      backgroundColor: statusColor.withOpacity(0.1),
      border: Border.all(color: statusColor.withOpacity(0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Icon(
                  icon,
                  color: statusColor,
                  size: 24,
                ),
              if (icon != null) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: AppSpacing.sm),
                badge!,
              ],
              if (showCloseButton)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  color: context.colorScheme.onSurface.withOpacity(0.6),
                ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              description!,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }
}
