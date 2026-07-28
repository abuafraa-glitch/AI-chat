import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/localization/app_localization.dart';
import '../../providers/localization_provider.dart';

class ChatInputField extends ConsumerStatefulWidget {
  final Function(String) onSendMessage;
  final VoidCallback? onAttachFile;
  final VoidCallback? onUploadImage;
  final VoidCallback? onRecordAudio;

  const ChatInputField({
    Key? key,
    required this.onSendMessage,
    this.onAttachFile,
    this.onUploadImage,
    this.onRecordAudio,
  }) : super(key: key);

  @override
  ConsumerState<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends ConsumerState<ChatInputField> {
  late final TextEditingController _controller;
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isComposing = _controller.text.trim().isNotEmpty;
    });
  }

  void _sendMessage() {
    if (!_isComposing) return;

    final message = _controller.text.trim();
    if (message.isEmpty) return;

    widget.onSendMessage(message);
    _controller.clear();
    _onTextChanged();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localizationProvider) == 'ar';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action Buttons (for attachments)
          if (widget.onAttachFile != null ||
              widget.onUploadImage != null ||
              widget.onRecordAudio != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  if (widget.onAttachFile != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: widget.onAttachFile,
                        tooltip: Strings.attachFile,
                      ),
                    ),
                  if (widget.onUploadImage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: IconButton(
                        icon: const Icon(Icons.image),
                        onPressed: widget.onUploadImage,
                        tooltip: Strings.uploadImage,
                      ),
                    ),
                  if (widget.onRecordAudio != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: IconButton(
                        icon: const Icon(Icons.mic),
                        onPressed: widget.onRecordAudio,
                        tooltip: Strings.recordAudio,
                      ),
                    ),
                  const Spacer(),
                ],
              ),
            ),

          // Input Row
          Row(
            children: [
              // Text Field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    minLines: 1,
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    decoration: InputDecoration(
                      hintText: Strings.askAnything,
                      hintTextDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send Button
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isComposing
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isComposing ? _sendMessage : null,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Icon(
                        Icons.send_rounded,
                        color: _isComposing
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
