
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ai_chat/core/extensions/build_context_extension.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final Color? backgroundColor;
  final double? elevation;
  final double? height;
  final bool centerTitle;
  final bool showBackButton;
  final bool searchMode;
  final Widget? searchField;

  const AppAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.backgroundColor,
    this.elevation,
    this.height,
    this.centerTitle = false,
    this.showBackButton = true,
    this.searchMode = false,
    this.searchField,
  });

  @override
  Size get preferredSize => Size.fromHeight(height ?? kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? context.colorScheme.background,
      elevation: elevation ?? 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: showBackButton && context.canPop() && leading == null
          ? IconButton(
              icon: Icon(
                context.isRtl ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                color: context.colorScheme.onBackground,
              ),
              onPressed: () => context.popRoute(),
            )
          : leading,
      title: searchMode
          ? searchField
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: context.textTheme.titleLarge?.copyWith(
                      color: context.colorScheme.onBackground,
                    ),
                  ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
      actions: actions,
    );
  }
}
