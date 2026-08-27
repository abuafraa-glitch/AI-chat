import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';

/// Composer input used at the bottom of the chat surfaces.
///
/// A pure presentation widget: it holds the text-editing state, watches
/// the active locale for direction and tooltips, and forwards the
/// trimmed message through [onSendMessage]. Attachment actions are
/// optional and only rendered when a callback is supplied.
class ChatInputField extends StatefulWidget {
  /// Creates a [ChatInputField].
  const ChatInputField({
    super.key,
    required this.hintText,
    required this.onSendMessage,
    this.onAttachFile,
    this.onUploadImage,
    this.onRecordAudio,
    this.onOpenAttachments,
  });

  /// Localized hint shown while the field is empty.
  final String hintText;

  /// Invoked with the trimmed message when the user sends.
  final ValueChanged<String> onSendMessage;

  /// Optional file-attachment action; hides the button when `null`.
  final VoidCallback? onAttachFile;

  /// Optional image-attachment action; hides the button when `null`.
  final VoidCallback? onUploadImage;

  /// Optional audio-recording action; hides the button when `null`.
  final VoidCallback? onRecordAudio;

  /// Opens the attachment actions menu from the compact plus button.
  final VoidCallback? onOpenAttachments;

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final composing = _controller.text.trim().isNotEmpty;
    if (composing != _isComposing) {
      setState(() {
        _isComposing = composing;
      });
    }
  }

  void _sendMessage() {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      return;
    }
    widget.onSendMessage(message);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = isArabicLocale(context);
    final theme = Theme.of(context);

    return Container(
      padding: AppSpacing.inputField,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: Row(
              children: <Widget>[
                if (widget.onOpenAttachments != null)
                  IconButton(
                    icon: const Icon(Icons.add_rounded),
                    tooltip: localizedText(
                      context,
                      'Add attachment',
                      'إضافة مرفق',
                    ),
                    onPressed: widget.onOpenAttachments,
                  ),
                Expanded(
                  child: Directionality(
                    textDirection: isArabic
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                AppSpacing.gap2,
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: _isComposing ? _sendMessage : null,
                  tooltip: localizedText(context, 'Send', 'إرسال'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
