
import 'package:flutter/material.dart';
import 'package:ai_chat/core/extensions/build_context_extension.dart';

enum LoadingIndicatorType {
  circular,
  linear,
}

class LoadingIndicator extends StatelessWidget {
  final LoadingIndicatorType type;
  final Color? color;
  final double? value;
  final double? strokeWidth;

  const LoadingIndicator({
    super.key,
    this.type = LoadingIndicatorType.circular,
    this.color,
    this.value,
    this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.colorScheme.primary;

    switch (type) {
      case LoadingIndicatorType.circular:
        return CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
          value: value,
          strokeWidth: strokeWidth ?? 4.0,
        );
      case LoadingIndicatorType.linear:
        return LinearProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
          value: value,
        );
    }
  }
}
