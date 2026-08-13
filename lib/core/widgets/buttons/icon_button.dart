import 'package:ai_chat/core/theme/app_radius.dart';
import 'package:flutter/material.dart';

enum AppIconButtonType { filled, outlined, tonal, standard }

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.type = AppIconButtonType.standard,
    this.size,
    this.tooltip,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.isCircular = false,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final AppIconButtonType type;
  final double? size;
  final String? tooltip;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final bool isCircular;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Widget iconWidget = Icon(icon, size: size ?? 24.0, color: iconColor);

    OutlinedBorder? buttonShape;
    if (isCircular) {
      buttonShape = const CircleBorder();
    } else {
      buttonShape = RoundedRectangleBorder(
        borderRadius: borderRadius ?? AppRadius.md,
      );
    }

    ButtonStyle? buttonStyle;
    switch (type) {
      case AppIconButtonType.filled:
        buttonStyle = IconButton.styleFrom(
          backgroundColor: backgroundColor ?? colorScheme.primary,
          foregroundColor: iconColor ?? colorScheme.onPrimary,
          shape: buttonShape,
        );
        break;
      case AppIconButtonType.outlined:
        buttonStyle = IconButton.styleFrom(
          foregroundColor: iconColor ?? colorScheme.primary,
          side: BorderSide(color: borderColor ?? colorScheme.outline),
          shape: buttonShape,
        );
        break;
      case AppIconButtonType.tonal:
        buttonStyle = IconButton.styleFrom(
          backgroundColor: backgroundColor ?? colorScheme.secondaryContainer,
          foregroundColor: iconColor ?? colorScheme.onSecondaryContainer,
          shape: buttonShape,
        );
        break;
      case AppIconButtonType.standard:
        buttonStyle = IconButton.styleFrom(
          foregroundColor: iconColor ?? colorScheme.onSurfaceVariant,
          shape: buttonShape,
        );
        break;
    }

    return IconButton(
      icon: iconWidget,
      onPressed: onPressed,
      tooltip: tooltip,
      style: buttonStyle,
    );
  }
}
