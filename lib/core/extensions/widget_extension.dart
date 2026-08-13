import 'package:flutter/material.dart';

/// Extensions on [Widget] for concise layout, padding, visibility, and
/// interaction composition without adding wrapping boilerplate.
///
/// These helpers are pure syntactic sugar — they produce the same widget
/// tree as the verbose counterparts. Use them to keep build methods
/// readable without sacrificing flexibility.

// ── Padding ───────────────────────────────────────────────────────────────

extension PaddingWidgetExtension on Widget {
  /// Wraps the widget in a [Padding] with [value] applied on all sides.
  Widget paddingAll(double value) =>
      Padding(padding: EdgeInsets.all(value), child: this);

  /// Wraps the widget in a [Padding] with symmetric insets.
  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) =>
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        ),
        child: this,
      );

  /// Wraps the widget in a [Padding] with independent side insets.
  Widget paddingOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) => Padding(
    padding: EdgeInsets.only(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    ),
    child: this,
  );

  /// Wraps the widget in a [Padding] with horizontal-only insets.
  Widget paddingHorizontal(double value) => Padding(
    padding: EdgeInsets.symmetric(horizontal: value),
    child: this,
  );

  /// Wraps the widget in a [Padding] with vertical-only insets.
  Widget paddingVertical(double value) => Padding(
    padding: EdgeInsets.symmetric(vertical: value),
    child: this,
  );
}

// ── Layout ────────────────────────────────────────────────────────────────

extension LayoutWidgetExtension on Widget {
  /// Wraps the widget in a [Center].
  Widget get centered => Center(child: this);

  /// Wraps the widget in an [Expanded] with the given [flex] factor.
  Widget expanded({int flex = 1}) => Expanded(flex: flex, child: this);

  /// Wraps the widget in a [Flexible] with the given [flex] factor and
  /// [fit].
  Widget flexible({int flex = 1, FlexFit fit = FlexFit.loose}) =>
      Flexible(flex: flex, fit: fit, child: this);

  /// Constrains the widget to [width] × [height] using a [SizedBox].
  Widget sizedBox({double? width, double? height}) =>
      SizedBox(width: width, height: height, child: this);

  /// Constrains the widget to a square of [size] × [size].
  Widget square(double size) => SizedBox.square(dimension: size, child: this);

  /// Wraps the widget in an [Align] with the given [alignment].
  Widget aligned(AlignmentGeometry alignment) =>
      Align(alignment: alignment, child: this);

  /// Constrains the widget with [BoxConstraints] applied via a
  /// [ConstrainedBox].
  Widget constrained(BoxConstraints constraints) =>
      ConstrainedBox(constraints: constraints, child: this);

  /// Wraps the widget in a [SafeArea].
  Widget safeArea({
    bool left = true,
    bool top = true,
    bool right = true,
    bool bottom = true,
  }) =>
      SafeArea(left: left, top: top, right: right, bottom: bottom, child: this);

  /// Clips the widget to a rectangle with [borderRadius].
  Widget clipRounded(double radius) =>
      ClipRRect(borderRadius: BorderRadius.circular(radius), child: this);
}

// ── Visibility & opacity ───────────────────────────────────────────────────

extension VisibilityWidgetExtension on Widget {
  /// Shows this widget when [condition] is `true`, otherwise shows an
  /// empty [SizedBox].
  Widget visibleIf(bool condition) =>
      condition ? this : const SizedBox.shrink();

  /// Hides this widget when [condition] is `true`.
  Widget hiddenIf(bool condition) => visibleIf(!condition);

  /// Wraps the widget in an [Opacity] with [value].
  ///
  /// [value] must be between `0.0` (fully transparent) and `1.0` (fully
  /// opaque).
  Widget withOpacity(double value) => Opacity(opacity: value, child: this);

  /// Wraps the widget in [Visibility] with [visible] controlling its
  /// rendering. When [maintainSize] is `true`, the widget keeps its
  /// layout space even when invisible.
  Widget visibility({required bool visible, bool maintainSize = false}) =>
      Visibility(
        visible: visible,
        maintainSize: maintainSize,
        maintainAnimation: maintainSize,
        maintainState: maintainSize,
        child: this,
      );
}

// ── Interaction ───────────────────────────────────────────────────────────

extension InteractionWidgetExtension on Widget {
  /// Wraps the widget in a [GestureDetector] that calls [onTap] on a tap.
  Widget onTap(VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: this,
  );

  /// Wraps the widget in a [GestureDetector] that calls [onLongPress] on a
  /// long press.
  Widget onLongPress(VoidCallback onLongPress) => GestureDetector(
    onLongPress: onLongPress,
    behavior: HitTestBehavior.opaque,
    child: this,
  );

  /// Wraps the widget in a [Tooltip] that shows [message] on long press.
  Widget withTooltip(String message) => Tooltip(message: message, child: this);

  /// Wraps the widget in a [Hero] widget with the given [tag].
  Widget hero(Object tag) => Hero(tag: tag, child: this);

  /// Wraps the widget in an [IgnorePointer], optionally making it
  /// non-interactive based on [ignoring].
  Widget ignorePointer({bool ignoring = true}) =>
      IgnorePointer(ignoring: ignoring, child: this);

  /// Wraps the widget in an [AbsorbPointer], consuming all hit tests when
  /// [absorbing] is `true` without removing the widget from the tree.
  Widget absorbPointer({bool absorbing = true}) =>
      AbsorbPointer(absorbing: absorbing, child: this);
}

// ── Sliver wrappers ───────────────────────────────────────────────────────

extension SliverWidgetExtension on Widget {
  /// Wraps the widget in a [SliverToBoxAdapter] for use inside a
  /// [CustomScrollView].
  Widget get asSliver => SliverToBoxAdapter(child: this);

  /// Wraps the widget in a [SliverFillRemaining] that fills the remaining
  /// scroll space.
  Widget get asSliverFillRemaining => SliverFillRemaining(child: this);
}
