import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';

/// Composer input used at the bottom of the chat surfaces.
///
/// A pure presentation widget: it holds the text-editing state, watches
/// the active locale for direction and tooltips, and forwards the
/// trimmed message through [onSendMessage]. Attachment actions are
/// optional and only rendered when a callback is supplied.
class ChatInputField extends StatefulWidget {
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

  /// Creates a [ChatInputField].
  const ChatInputField({
    super.key,
    required this.hintText,
    required this.onSendMessage,
    this.onAttachFile,
    this.onUploadImage,
    this.onRecordAudio,
  });

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.onAttachFile != null ||
              widget.onUploadImage != null ||
              widget.onRecordAudio != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: <Widget>[
                  if (widget.onAttachFile != null)
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      tooltip: localizedText(context, 'Attach file', 'إرفاق ملف'),
                      onPressed: widget.onAttachFile,
                    ),
                  if (widget.onUploadImage != null)
                    IconButton(
                      icon: const Icon(Icons.image_outlined),
                      tooltip: localizedText(context, 'Upload image', 'رفع صورة'),
                      onPressed: widget.onUploadImage,
                    ),
                  if (widget.onRecordAudio != null)
                    IconButton(
                      icon: const Icon(Icons.mic_none),
                      tooltip: localizedText(context, 'Record audio', 'تسجيل صوتي'),
                      onPressed: widget.onRecordAudio,
                    ),
                  const Spacer(),
                ],
              ),
            ),
          Row(
            children: <Widget>[
              Expanded(
                child: Directionality(
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
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
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.send_rounded),
                onPressed: _isComposing ? _sendMessage : null,
                tooltip: localizedText(context, 'Send', 'إرسال'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
