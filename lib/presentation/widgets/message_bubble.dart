import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/message.dart';
import '../../config/localization/app_localization.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final VoidCallback onCopy;
  final VoidCallback? onRegenerate;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback onShare;
  final VoidCallback onPin;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.onCopy,
    this.onRegenerate,
    this.onLike,
    this.onDislike,
    required this.onShare,
    required this.onPin,
  }) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showActions = false;

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == MessageRole.user;
    final isAssistant = widget.message.role == MessageRole.assistant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onLongPress: () {
          setState(() {
            _showActions = !_showActions;
          });
        },
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message bubble
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: !isUser
                    ? Border.all(
                        color: Theme.of(context).dividerColor,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thinking indicator
                  if (widget.message.isStreaming && isAssistant)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            Strings.thinking,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),

                  // Message content
                  SelectableText(
                    widget.message.content,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  // Time
                  if (widget.message.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        widget.message.formattedTime,
                        style: TextStyle(
                          color: isUser
                              ? Colors.white.withOpacity(0.7)
                              : Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Actions
            if (_showActions && isAssistant)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionButton(
                        icon: Icons.copy,
                        tooltip: Strings.copy,
                        onPressed: widget.onCopy,
                      ),
                      _ActionButton(
                        icon: Icons.refresh,
                        tooltip: Strings.regenerate,
                        onPressed: widget.onRegenerate ?? () {},
                      ),
                      _ActionButton(
                        icon: Icons.thumb_up_outlined,
                        tooltip: Strings.like,
                        onPressed: widget.onLike ?? () {},
                      ),
                      _ActionButton(
                        icon: Icons.thumb_down_outlined,
                        tooltip: Strings.unlike,
                        onPressed: widget.onDislike ?? () {},
                      ),
                      _ActionButton(
                        icon: Icons.share_outlined,
                        tooltip: Strings.share,
                        onPressed: widget.onShare,
                      ),
                      _ActionButton(
                        icon: Icons.pin_outlined,
                        tooltip: Strings.pin,
                        onPressed: widget.onPin,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
