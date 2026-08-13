import 'package:ai_chat/core/routes/route_names.dart';
import 'package:ai_chat/core/widgets/app_scaffold.dart';
import 'package:ai_chat/core/widgets/empty_state.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Route error page rendered by the router when no route matches.
class NotFoundScreen extends StatelessWidget {
  /// Creates a [NotFoundScreen].
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Text(
          localizedText(context, 'Page not found', 'الصفحة غير موجودة'),
        ),
      ),
      body: EmptyState(
        variant: EmptyStateVariant.custom,
        icon: Icons.error_outline,
        title: localizedText(context, 'Page not found', 'الصفحة غير موجودة'),
        description: localizedText(
          context,
          'The page you are looking for does not exist.',
          'الصفحة التي تبحث عنها غير موجودة.',
        ),
        buttonText: localizedText(context, 'Go home', 'العودة للرئيسية'),
        onButtonPressed: () => context.go(RouteNames.chat),
      ),
    );
  }
}
