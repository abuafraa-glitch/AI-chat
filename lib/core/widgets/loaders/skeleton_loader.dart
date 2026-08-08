
import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/theme/app_radius.dart';
import 'package:ai_chat/core/widgets/loaders/shimmer_loader.dart';
import 'package:flutter/material.dart';

class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBaseColor = baseColor ?? context.colorScheme.surfaceVariant.withOpacity(0.5);
    final effectiveHighlightColor = highlightColor ?? context.colorScheme.surfaceVariant.withOpacity(0.2);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: effectiveBaseColor,
        borderRadius: borderRadius ?? AppRadius.sm,
      ),
      child: ShimmerLoader(
        baseColor: effectiveBaseColor,
        highlightColor: effectiveHighlightColor,
        child: Container(), // Empty container to apply shimmer effect on
      ),
    );
  }
}


