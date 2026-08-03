
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/core/widgets/buttons/app_button.dart';

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
              title ?? 'حدث خطأ ما!',
              style: context.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description ?? 'نعتذر، حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (errorCode != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'رمز الخطأ: $errorCode',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: retryButtonText ?? 'إعادة المحاولة',
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
                title: Text('تفاصيل الخطأ (للمطورين)', style: context.textTheme.bodySmall),
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
