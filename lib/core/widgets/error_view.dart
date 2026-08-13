import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/core/widgets/buttons/app_button.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  final String? title;
  final String? description;
  final String? errorCode;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final Widget? customActions;
  final dynamic errorDetails;

  const ErrorView({
    super.key,
    this.title,
    this.description,
    this.errorCode,
    this.onRetry,
    this.retryButtonText,
    this.customActions,
    this.errorDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: context.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title ??
                  localizedTextRead(
                    context,
                    'Something went wrong!',
                    'حدث خطأ ما!',
                  ),
              style: context.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description ??
                  localizedTextRead(
                    context,
                    'Sorry, an unexpected error occurred. Please try again.',
                    'نعتذر، حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.',
                  ),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (errorCode != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                localizedTextRead(
                  context,
                  'Error code: $errorCode',
                  'رمز الخطأ: $errorCode',
                ),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text:
                    retryButtonText ??
                    localizedTextRead(context, 'Retry', 'إعادة المحاولة'),
                onPressed: onRetry!,
              ),
            ],
            if (customActions != null) ...[
              const SizedBox(height: AppSpacing.lg),
              customActions!,
            ],
            if (kDebugMode && errorDetails != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ExpansionTile(
                title: Text(
                  localizedTextRead(
                    context,
                    'Error details (developers)',
                    'تفاصيل الخطأ (للمطورين)',
                  ),
                  style: context.textTheme.bodySmall,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      errorDetails.toString(),
                      style: context.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
