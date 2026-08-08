
import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/core/widgets/buttons/app_button.dart';
import 'package:ai_chat/core/widgets/dialogs/app_dialog.dart';
import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String description;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.description,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: Text(
        title,
        style: context.textTheme.titleLarge,
      ),
      content: Text(
        description,
        style: context.textTheme.bodyMedium,
      ),
      actions: [
        AppButton(
          text: cancelText,
          onPressed: () {
            if (onCancel != null) {
              onCancel!();
            }
            context.popRoute();
          },
          type: AppButtonType.text,
        ),
        AppButton(
          text: confirmText,
          onPressed: () {
            onConfirm();
            context.popRoute();
          },
          type: isDestructive ? AppButtonType.destructive : AppButtonType.primary,
        ),
      ],
    );
  }

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String description,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    return await AppDialog.show<bool?>(
      context,
      (context) => ConfirmationDialog(
        title: title,
        description: description,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }
}
