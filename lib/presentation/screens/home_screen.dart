import 'package:ai_chat/core/constants/app_strings.dart';
import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/routes/route_names.dart';
import 'package:ai_chat/core/theme/theme_cubit.dart';
import 'package:ai_chat/core/widgets/app_scaffold.dart';
import 'package:ai_chat/presentation/blocs/localization_cubit.dart';
import 'package:ai_chat/presentation/blocs/models_cubit.dart';
import 'package:ai_chat/presentation/screens/chat_screen.dart';
import 'package:ai_chat/presentation/widgets/chat_input_field.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:ai_chat/presentation/widgets/model_selector.dart';
import 'package:ai_chat/presentation/widgets/suggestion_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Landing tab of the application.
///
/// Purely presentational: it observes [ThemeCubit], [LocalizationCubit]
/// and [ModelsCubit] for rendering, and forwards user intents — theme
/// toggle, locale toggle, model selection and message submission — to
/// the cubits or to the router. Starting a chat navigates to the
/// conversation route via go_router, carrying the launch payload.
class HomeScreen extends StatelessWidget {
  /// Creates a [HomeScreen].
  const HomeScreen({super.key});

  void _startChat(BuildContext context, String message) {
    final modelId = context.read<ModelsCubit>().state.selectedModelId;
    if (modelId == null) {
      context.showSnackBar(
        localizedTextRead(context, 'Please select a model first', 'الرجاء اختيار نموذج أولاً'),
      );
      return;
    }
    final conversationId = DateTime.now().microsecondsSinceEpoch.toString();
    context.pushTo(
      RouteNames.conversationPath(conversationId),
      extra: ChatLaunchData(message: message, modelId: modelId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.watch<ThemeCubit>().state.isDark;
    final isArabic = isArabicLocale(context);
    final textDirection = isArabic ? TextDirection.rtl : TextDirection.ltr;

    return AppScaffold(
      body: Directionality(
        textDirection: textDirection,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    tooltip: localizedText(context, 'Toggle theme', 'تبديل المظهر'),
                    onPressed: () {
                      context.read<ThemeCubit>().toggle(
                            MediaQuery.platformBrightnessOf(context),
                          );
                    },
                  ),
                  const Spacer(),
                  Text(
                    '🧠 Hajeen AI',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Text(isArabic ? '🇺🇸' : '🇸🇦'),
                    tooltip: localizedText(context, 'Toggle language', 'تبديل اللغة'),
                    onPressed: () {
                      context.read<LocalizationCubit>().setLocale(
                            isArabic ? AppStrings.localeEn : AppStrings.localeAr,
                          );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ModelSelector(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        localizedText(context, 'Welcome to Hajeen AI', 'مرحباً بك في هاجين'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SuggestionChips(
                      onSuggestionSelected: (suggestion) {
                        _startChat(context, suggestion);
                      },
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
            ChatInputField(
              hintText: localizedText(context, 'Ask anything…', 'اسأل أي شيء…'),
              onSendMessage: (message) => _startChat(context, message),
            ),
          ],
        ),
      ),
    );
  }
}
