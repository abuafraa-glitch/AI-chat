import 'package:flutter/material.dart';

/// Themed application dialog used across Hajeen AI.
///
/// A thin wrapper around [AlertDialog] that inherits the Material 3
/// dialog theming configured in [ThemeData.dialogTheme]. Use the
/// static [AppDialog.show] helper to present it, or embed
/// [AppDialog] directly as a dialog widget.
class AppDialog extends StatelessWidget {
  /// Creates an [AppDialog].
  const AppDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.barrierDismissible = true,
  });

  /// Optional dialog header widget (usually a [Text]).
  final Widget? title;

  /// Optional dialog body widget.
  final Widget? content;

  /// Optional action row rendered below [content].
  final List<Widget>? actions;

  /// Whether tapping outside the dialog dismisses it.
  ///
  /// Honoured by [AppDialog.show]; stored here so widget-level usage
  /// stays source-compatible with the dialog API.
  final bool barrierDismissible;

  /// Presents a dialog built by [builder] over [context].
  ///
  /// Returns the value passed to `Navigator.pop`, or `null` when the
  /// dialog is dismissed without a result.
  static Future<T?> show<T>(
    BuildContext context,
    WidgetBuilder builder, {
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(title: title, content: content, actions: actions);
  }
}
