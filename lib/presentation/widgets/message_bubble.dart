import 'package:ai_chat/data/models/message_model.dart';
import 'package:ai_chat/presentation/widgets/formatters.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

/// Renders a single chat message as a bubble.
///
/// A pure presentation widget: it receives a [MessageModel] and action
/// callbacks, and reads the active locale only for tooltips. It never
/// talks to the network, storage, or state layer directly.
class MessageBubble extends StatelessWidget {
  /// The message to display.
  final MessageModel message;

  /// Invoked when the user copies the message content.
  final VoidCallback onCopy;

  /// Invoked when the user regenerates the assistant response; only
  /// rendered for assistant messages when non-null.
  final VoidCallback? onRegenerate;

  /// Creates a [MessageBubble].
  const MessageBubble({
    super.key,
    required this.message,
    required this.onCopy,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.role == MessageRole.user;
    final isAssistant = message.role == MessageRole.assistant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: isUser ? null : Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (message.isStreaming && isAssistant)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          localizedText(context, 'Thinking', 'جارٍ التفكير'),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                if (message.attachments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: message.attachments.map((attachment) {
                        final isImage = attachment.type == AttachmentType.image;
                        final isDataImage = attachment.url.startsWith(
                          'data:image/',
                        );
                        if (isImage && isDataImage) {
                          final encoded = attachment.url
                              .split(',')
                              .skip(1)
                              .join(',');
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              base64Decode(encoded),
                              width: 180,
                              height: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _attachmentChip(theme, attachment),
                            ),
                          );
                        }
                        return _attachmentChip(theme, attachment);
                      }).toList(),
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
                    padding: const EdgeInsets.only(top: 8),
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
              padding: const EdgeInsets.only(top: 4),
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

  static Widget _attachmentChip(ThemeData theme, MessageAttachment attachment) {
    return Chip(
      avatar: Icon(
        attachment.type == AttachmentType.video
            ? Icons.video_file
            : Icons.attach_file,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: Text(attachment.name, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
