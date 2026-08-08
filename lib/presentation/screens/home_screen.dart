import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/routes/route_names.dart';
import 'package:ai_chat/presentation/blocs/models_cubit.dart';
import 'package:ai_chat/presentation/screens/chat_screen.dart';
import 'package:ai_chat/presentation/widgets/chat_input_field.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:ai_chat/presentation/widgets/model_selector.dart';
import 'package:ai_chat/presentation/widgets/suggestion_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Welcome / new-chat hub shown when the conversation list is empty.
///
/// Purely presentational: it observes [ModelsCubit] for the active
/// model and forwards intents — suggestion selection, message
/// submission and model selection — to the cubits or the router.
/// Starting a chat navigates to the conversation route via go_router,
/// carrying the launch payload.
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

    return Column(
      children: <Widget>[
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
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    localizedText(
                      context,
                      'Choose a model, pick a suggestion or type your question to begin.',
                      'اختر نموذجاً، اختر اقتراحاً، أو اكتب سؤالك للبدء.',
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SuggestionChips(
                  onSuggestionSelected: (suggestion) {
                    _startChat(context, suggestion);
                  },
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
        ChatInputField(
          hintText: localizedText(context, 'Ask anything…', 'اسأل أي شيء…'),
          onSendMessage: (message) => _startChat(context, message),
        ),
      ],
    );
  }
}
