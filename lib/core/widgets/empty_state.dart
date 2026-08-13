import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/core/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';

enum EmptyStateVariant {
  noData,
  noConversations,
  noConnection,
  noResults,
  custom,
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.variant = EmptyStateVariant.noData,
    this.icon,
    this.imagePath,
    this.title,
    this.description,
    this.buttonText,
    this.onButtonPressed,
    this.customWidget,
  });
  final EmptyStateVariant variant;
  final IconData? icon;
  final String? imagePath;
  final String? title;
  final String? description;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Widget? customWidget;

  @override
  Widget build(BuildContext context) {
    final String effectiveTitle = title ?? _getTitle(context, variant);
    final String effectiveDescription =
        description ?? _getDescription(context, variant);
    final IconData? effectiveIcon = icon ?? _getIcon(variant);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (customWidget != null) ...[
              customWidget!,
              const SizedBox(height: AppSpacing.md),
            ] else if (imagePath != null) ...[
              Image.asset(imagePath!, height: 120),
              const SizedBox(height: AppSpacing.md),
            ] else if (effectiveIcon != null) ...[
              Icon(
                effectiveIcon,
                size: 80,
                color: context.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              effectiveTitle,
              style: context.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              effectiveDescription,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(text: buttonText!, onPressed: onButtonPressed!),
            ],
          ],
        ),
      ),
    );
  }

  String _getTitle(BuildContext context, EmptyStateVariant variant) {
    switch (variant) {
      case EmptyStateVariant.noData:
        return 'لا توجد بيانات';
      case EmptyStateVariant.noConversations:
        return 'لا توجد محادثات';
      case EmptyStateVariant.noConnection:
        return 'لا يوجد اتصال بالإنترنت';
      case EmptyStateVariant.noResults:
        return 'لا توجد نتائج';
      case EmptyStateVariant.custom:
        return 'حدث خطأ ما';
    }
  }

  String _getDescription(BuildContext context, EmptyStateVariant variant) {
    switch (variant) {
      case EmptyStateVariant.noData:
        return 'يبدو أنه لا توجد بيانات لعرضها في الوقت الحالي.';
      case EmptyStateVariant.noConversations:
        return 'ابدأ محادثة جديدة لتظهر هنا.';
      case EmptyStateVariant.noConnection:
        return 'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';
      case EmptyStateVariant.noResults:
        return 'لم يتم العثور على نتائج مطابقة لبحثك.';
      case EmptyStateVariant.custom:
        return 'يرجى المحاولة مرة أخرى لاحقًا.';
    }
  }

  IconData? _getIcon(EmptyStateVariant variant) {
    switch (variant) {
      case EmptyStateVariant.noData:
        return Icons.inbox_outlined;
      case EmptyStateVariant.noConversations:
        return Icons.chat_bubble_outline;
      case EmptyStateVariant.noConnection:
        return Icons.wifi_off;
      case EmptyStateVariant.noResults:
        return Icons.search_off;
      case EmptyStateVariant.custom:
        return Icons.info_outline;
    }
  }
}
