import 'package:flutter/material.dart';

/// Reusable entrance animation: fades the child in while sliding it
/// from below.
///
/// Pure Flutter implementation (no external animation package) built on
/// [TweenAnimationBuilder], so it is self-contained, testable and
/// dependency-free. Use it anywhere an item should reveal itself
/// gradually, e.g. list entries or screen sections.
class FadeInSlide extends StatelessWidget {
  /// The widget to reveal.
  final Widget child;

  /// Optional extra delay added to the base duration.
  final Duration delay;

  /// Distance the child travels vertically while fading in.
  final double slideDistance;

  /// Creates a [FadeInSlide].
  const FadeInSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.slideDistance = 12,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 250) + delay,
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, slideDistance * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
