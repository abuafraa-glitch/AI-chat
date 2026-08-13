import 'package:ai_chat/core/theme/app_radius.dart';
import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/data/models/message_model.dart';
import 'package:ai_chat/presentation/widgets/formatters.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';

/// Renders a single chat message as a bubble.
///
/// A pure presentation widget: it receives a [MessageModel] and action
/// callbacks, and reads the active locale only for tooltips. It never
/// talks to the network, storage, or state layer directly.
class MessageBubble extends StatelessWidget {
  /// Creates a [MessageBubble].
  const MessageBubble({
    super.key,
    required this.message,
    required this.onCopy,
    this.onRegenerate,
  });

  /// The message to display.
  final MessageModel message;

  /// Invoked when the user copies the message content.
  final VoidCallback onCopy;

  /// Invoked when the user regenerates the assistant response; only
  /// rendered for assistant messages when non-null.
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.role == MessageRole.user;
    final isAssistant = message.role == MessageRole.assistant;

    return Padding(
      padding: AppSpacing.v2Insets,
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.75,
            ),
            padding: AppSpacing.inputField,
            decoration: BoxDecoration(
              color: isUser
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              borderRadius: AppRadius.lg,
              border: isUser ? null : Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (message.isStreaming && isAssistant)
                  Padding(
                    padding: AppSpacing.bottom2,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        AppSpacing.gap2,
                        Text(
                          localizedText(context, 'Thinking', 'جارٍ التفكير'),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                SelectableText(
                  message.content,
                  style: TextStyle(
                    color: isUser
                        ? colorScheme.onPrimary
                        : theme.textTheme.bodyLarge?.color,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                if (message.content.isNotEmpty)
                  Padding(
                    padding: AppSpacing.top2,
                    child: Text(
                      formatAppTime(message.createdAt),
                      style: TextStyle(
                        color: isUser
                            ? colorScheme.onPrimary.withValues(alpha: 0.7)
                            : theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isAssistant)
            Padding(
              padding: AppSpacing.top1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: localizedText(context, 'Copy', 'نسخ'),
                    onPressed: onCopy,
                  ),
                  if (onRegenerate != null)
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      tooltip: localizedText(
                        context,
                        'Regenerate',
                        'إعادة التوليد',
                      ),
                      onPressed: onRegenerate,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
