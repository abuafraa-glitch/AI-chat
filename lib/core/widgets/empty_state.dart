import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/core/widgets/buttons/app_button.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';

enum EmptyStateVariant {
  noData,
  noConversations,
  noConnection,
  noResults,
  custom,
}

class EmptyState extends StatelessWidget {
  final EmptyStateVariant variant;
  final IconData? icon;
  final String? imagePath;
  final String? title;
  final String? description;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Widget? customWidget;

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

  @override
  Widget build(BuildContext context) {
    String effectiveTitle = title ?? _getTitle(context, variant);
    String effectiveDescription =
        description ?? _getDescription(context, variant);
    IconData? effectiveIcon = icon ?? _getIcon(variant);

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
        return localizedTextRead(context, 'No data', 'لا توجد بيانات');
      case EmptyStateVariant.noConversations:
        return localizedTextRead(
          context,
          'No conversations',
          'لا توجد محادثات',
        );
      case EmptyStateVariant.noConnection:
        return localizedTextRead(
          context,
          'No internet connection',
          'لا يوجد اتصال بالإنترنت',
        );
      case EmptyStateVariant.noResults:
        return localizedTextRead(context, 'No results', 'لا توجد نتائج');
      case EmptyStateVariant.custom:
        return localizedTextRead(context, 'Something went wrong', 'حدث خطأ ما');
    }
  }

  String _getDescription(BuildContext context, EmptyStateVariant variant) {
    switch (variant) {
      case EmptyStateVariant.noData:
        return localizedTextRead(
          context,
          'There is no data to show right now.',
          'يبدو أنه لا توجد بيانات لعرضها في الوقت الحالي.',
        );
      case EmptyStateVariant.noConversations:
        return localizedTextRead(
          context,
          'Start a new conversation to see it here.',
          'ابدأ محادثة جديدة لتظهر هنا.',
        );
      case EmptyStateVariant.noConnection:
        return localizedTextRead(
          context,
          'Please check your internet connection and try again.',
          'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.',
        );
      case EmptyStateVariant.noResults:
        return localizedTextRead(
          context,
          'No matching results were found.',
          'لم يتم العثور على نتائج مطابقة لبحثك.',
        );
      case EmptyStateVariant.custom:
        return localizedTextRead(
          context,
          'Please try again later.',
          'يرجى المحاولة مرة أخرى لاحقًا.',
        );
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
