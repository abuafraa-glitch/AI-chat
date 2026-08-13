import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/theme/app_radius.dart';
import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.elevation,
    this.borderRadius,
    this.padding,
    this.backgroundColor,
    this.border,
    this.boxShadow,
  });
  final Widget child;
  final double? elevation;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor ?? context.colorScheme.surface,
        borderRadius: borderRadius ?? AppRadius.lg,
        border: border,
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: context.colorScheme.shadow.withValues(
                  alpha: elevation != null ? (elevation! * 0.05) : 0.1,
                ),
                blurRadius: elevation != null ? (elevation! * 2) : 8,
                offset: Offset(0, elevation != null ? (elevation! * 0.5) : 4),
              ),
            ],
      ),
      child: child,
    );
  }
}
