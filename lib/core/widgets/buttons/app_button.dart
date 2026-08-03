
import 'package:flutter/material.dart';
import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/core/theme/app_radius.dart';

enum AppButtonType {
  primary,
  secondary,
  outlined,
  text,
  destructive,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final bool fullWidth;
  final bool isLoading;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.fullWidth = false,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    Color? effectiveBackgroundColor;
    Color? effectiveForegroundColor;
    Color? effectiveBorderColor;
    ButtonStyleButton Function({VoidCallback? onPressed, Widget? child}) buttonBuilder;

    switch (type) {
      case AppButtonType.primary:
        effectiveBackgroundColor = backgroundColor ?? colorScheme.primary;
        effectiveForegroundColor = foregroundColor ?? colorScheme.onPrimary;
        buttonBuilder = ({onPressed, child}) => ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: effectiveBackgroundColor,
                foregroundColor: effectiveForegroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.mdRadius.x),
                ),
                padding: _getPadding(size),
                textStyle: _getTextStyle(textTheme, size),
              ),
              child: child,
            );
        break;
      case AppButtonType.secondary:
        effectiveBackgroundColor = backgroundColor ?? colorScheme.secondary;
        effectiveForegroundColor = foregroundColor ?? colorScheme.onSecondary;
        buttonBuilder = ({onPressed, child}) => ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: effectiveBackgroundColor,
                foregroundColor: effectiveForegroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.mdRadius.x),
                ),
                padding: _getPadding(size),
                textStyle: _getTextStyle(textTheme, size),
              ),
              child: child,
            );
        break;
      case AppButtonType.outlined:
        effectiveBorderColor = borderColor ?? colorScheme.primary;
        effectiveForegroundColor = foregroundColor ?? colorScheme.primary;
        buttonBuilder = ({onPressed, child}) => OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: effectiveForegroundColor,
                side: BorderSide(color: effectiveBorderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.mdRadius.x),
                ),
                padding: _getPadding(size),
                textStyle: _getTextStyle(textTheme, size),
              ),
              child: child,
            );
        break;
      case AppButtonType.text:
        effectiveForegroundColor = foregroundColor ?? colorScheme.primary;
        buttonBuilder = ({onPressed, child}) => TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                foregroundColor: effectiveForegroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.mdRadius.x),
                ),
                padding: _getPadding(size),
                textStyle: _getTextStyle(textTheme, size),
              ),
              child: child,
            );
        break;
      case AppButtonType.destructive:
        effectiveBackgroundColor = backgroundColor ?? colorScheme.error;
        effectiveForegroundColor = foregroundColor ?? colorScheme.onError;
        buttonBuilder = ({onPressed, child}) => ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: effectiveBackgroundColor,
                foregroundColor: effectiveForegroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.mdRadius.x),
                ),
                padding: _getPadding(size),
                textStyle: _getTextStyle(textTheme, size),
              ),
              child: child,
            );
        break;
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: buttonBuilder(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: _getLoadingIndicatorSize(size),
                height: _getLoadingIndicatorSize(size),
                child: CircularProgressIndicator(
                  color: effectiveForegroundColor,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }

  EdgeInsetsGeometry _getPadding(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.small:
        return padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm);
      case AppButtonSize.medium:
        return padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md);
      case AppButtonSize.large:
        return padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg);
    }
  }

  TextStyle _getTextStyle(TextTheme textTheme, AppButtonSize size) {
    switch (size) {
      case AppButtonSize.small:
        return textTheme.labelSmall!;
      case AppButtonSize.medium:
        return textTheme.labelMedium!;
      case AppButtonSize.large:
        return textTheme.labelLarge!;
    }
  }

  double _getLoadingIndicatorSize(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.small:
        return 16.0;
      case AppButtonSize.medium:
        return 20.0;
      case AppButtonSize.large:
        return 24.0;
    }
  }
}
