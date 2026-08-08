
import 'package:ai_chat/core/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';

class LoadingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonType type;
  final AppButtonSize size;
  final bool fullWidth;
  final Widget? icon;
  final String? loadingText;
  final Widget? loadingIcon;

  const LoadingButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.fullWidth = false,
    this.icon,
    this.loadingText,
    this.loadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: isLoading ? loadingText ?? 'Loading...' : text,
      onPressed: isLoading ? null : onPressed,
      isLoading: isLoading,
      type: type,
      size: size,
      fullWidth: fullWidth,
      icon: isLoading ? loadingIcon : icon,
    );
  }
}
