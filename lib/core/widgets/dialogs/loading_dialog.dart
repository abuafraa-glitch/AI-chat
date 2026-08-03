
import 'package:flutter/material.dart';
import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/core/widgets/dialogs/app_dialog.dart';

class LoadingDialog extends StatelessWidget {
  final String? message;
  final Widget? customLoader;
  final bool dismissible;

  const LoadingDialog({
    super.key,
    this.message,
    this.customLoader,
    this.dismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      barrierDismissible: dismissible,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          customLoader ?? const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: context.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  static Future<void> show({
    required BuildContext context,
    String? message,
    Widget? customLoader,
    bool dismissible = false,
  }) async {
    return await AppDialog.show(
      context,
      (context) => LoadingDialog(
        message: message,
        customLoader: customLoader,
        dismissible: dismissible,
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}
