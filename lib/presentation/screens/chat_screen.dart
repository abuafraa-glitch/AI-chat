import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../../data/models/message.dart';
import '../../providers/api_provider.dart';
import '../../config/localization/app_localization.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_field.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String initialMessage;
  final String modelId;
  final String? conversationId;

  const ChatScreen({
    Key? key,
    required this.initialMessage,
    required this.modelId,
    this.conversationId,
  }) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late final ScrollController _scrollController;
  late final List<Message> _messages;
  bool _isLoading = false;
  String? _currentStreamingResponse;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _messages = [];
    _sendInitialMessage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _sendInitialMessage() {
    _addUserMessage(widget.initialMessage);
    _sendMessage(widget.initialMessage);
  }

  void _addUserMessage(String content) {
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: widget.conversationId ?? 'new',
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
      modelId: widget.modelId,
    );
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage(String content) async {
    setState(() {
      _isLoading = true;
      _currentStreamingResponse = '';
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      
      // Add a placeholder for the assistant message
      final assistantMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: widget.conversationId ?? 'new',
        content: '',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        modelId: widget.modelId,
        isStreaming: true,
      );
      
      setState(() {
        _messages.add(assistantMessage);
      });
      _scrollToBottom();

      // Get the streaming response
      final stream = await apiService.sendMessage(
        conversationId: widget.conversationId ?? 'new',
        content: content,
        modelId: widget.modelId,
      );

      await for (final chunk in stream) {
        if (mounted) {
          setState(() {
            _currentStreamingResponse = (_currentStreamingResponse ?? '') + chunk;
            // Update the last message with the streamed content
            if (_messages.isNotEmpty && _messages.last.role == MessageRole.assistant) {
              _messages[_messages.length - 1] = _messages.last.copyWith(
                content: _currentStreamingResponse ?? '',
              );
            }
          });
          _scrollToBottom();
        }
      }

      // Mark streaming as complete
      if (_messages.isNotEmpty && _messages.last.role == MessageRole.assistant) {
        setState(() {
          _messages[_messages.length - 1] = _messages.last.copyWith(
            isStreaming: false,
          );
          _currentStreamingResponse = null;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Failed to send message: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hajeen AI Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show options menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      Strings.noData,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return FadeInUp(
                        child: MessageBubble(
                          message: message,
                          onCopy: () {
                            _copyToClipboard(message.content);
                          },
                          onRegenerate: message.role == MessageRole.assistant
                              ? () {
                                  if (index > 0) {
                                    final userMsg = _messages[index - 1];
                                    _messages.removeAt(index);
                                    setState(() {});
                                    _sendMessage(userMsg.content);
                                  }
                                }
                              : null,
                          onLike: message.role == MessageRole.assistant
                              ? () {
                                  _rateMessage(message.id, true);
                                }
                              : null,
                          onDislike: message.role == MessageRole.assistant
                              ? () {
                                  _rateMessage(message.id, false);
                                }
                              : null,
                          onShare: () {
                            _shareMessage(message.content);
                          },
                          onPin: () {
                            _togglePin(index);
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Thinking indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FadeIn(
                child: Row(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${Strings.thinking}...',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),

          // Chat Input
          ChatInputField(
            onSendMessage: _isLoading
                ? (_) {} // Disable input while loading
                : (message) {
                    _addUserMessage(message);
                    _sendMessage(message);
                  },
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    // TODO: Implement copy to clipboard
  }

  void _rateMessage(String messageId, bool isPositive) {
    // TODO: Implement message rating
  }

  void _shareMessage(String content) {
    // TODO: Implement share functionality
  }

  void _togglePin(int index) {
    // TODO: Implement pin functionality
  }
}

extension on Message {
  Message copyWith({
    String? id,
    String? conversationId,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    String? modelId,
    List<MessageAttachment>? attachments,
    int? likeCount,
    int? dislikeCount,
    bool? isLiked,
    bool? isDisliked,
    bool? isPinned,
    bool? isStreaming,
    double? streamingProgress,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      modelId: modelId ?? this.modelId,
      attachments: attachments ?? this.attachments,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      isLiked: isLiked ?? this.isLiked,
      isDisliked: isDisliked ?? this.isDisliked,
      isPinned: isPinned ?? this.isPinned,
      isStreaming: isStreaming ?? this.isStreaming,
      streamingProgress: streamingProgress ?? this.streamingProgress,
    );
  }
}
