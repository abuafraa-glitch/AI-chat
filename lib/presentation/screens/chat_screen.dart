import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/widgets/app_scaffold.dart';
import 'package:ai_chat/core/widgets/empty_state.dart';
import 'package:ai_chat/core/widgets/error_view.dart';
import 'package:ai_chat/core/widgets/loaders/loading_indicator.dart';
import 'package:ai_chat/data/models/message_model.dart';
import 'package:ai_chat/presentation/animations/fade_in_slide.dart';
import 'package:ai_chat/presentation/blocs/chat_cubit.dart';
import 'package:ai_chat/core/di/injection.dart';
import 'package:ai_chat/presentation/blocs/data_sources.dart';
import 'package:ai_chat/presentation/blocs/models_cubit.dart';
import 'package:ai_chat/presentation/widgets/chat_input_field.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:ai_chat/presentation/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nested/nested.dart';
import 'package:go_router/go_router.dart';

/// Launch payload carried through the conversation route.
///
/// When [message] is non-empty the chat sends it on arrival; otherwise
/// the screen simply loads the (empty) thread. [modelId] defaults to
/// the user's current selection when omitted.
class ChatLaunchData {
  /// Creates [ChatLaunchData] for a new conversation.
  const ChatLaunchData({this.message = '', this.modelId});

  /// Initial user message to send on arrival.
  final String message;

  /// Model that should answer the initial message, or `null` to use
  /// the current selection.
  final String? modelId;
}

/// Renders a single conversation.
///
/// This screen is a self-contained route: it provides its own [ChatCubit]
/// (per-conversation state) but shares the application-wide [ModelsCubit]
/// singleton from the DI container via [BlocProvider.value], so the
/// model selection stays consistent with the main shell. It observes
/// [ChatState] and renders the four UI phases — loading, error, empty
/// and streaming — without containing any business logic.
class ChatScreen extends StatelessWidget {
  /// Identifier of the conversation to display.
  final String conversationId;

  /// Creates a [ChatScreen] for [conversationId].
  const ChatScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<ChatCubit>(
          create: (context) => ChatCubit(repository: buildMessageRepository()),
        ),
        BlocProvider<ModelsCubit>.value(value: sl<ModelsCubit>()),
      ],
      child: _ChatView(conversationId: conversationId),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView({required this.conversationId});

  final String conversationId;

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  late final ScrollController _scrollController;
  ChatLaunchData? _launchData;
  bool _didLaunch = false;
  int _previousLength = 0;
  final List<MessageAttachment> _pendingAttachments = <MessageAttachment>[];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLaunch) {
      return;
    }
    _didLaunch = true;
    final extra = GoRouterState.of(context).extra;
    if (extra is ChatLaunchData) {
      _launchData = extra;
      final modelId = _modelId(context);
      if (extra.message.isNotEmpty && modelId != null) {
        _send(extra.message, modelId);
        return;
      }
    }
    context.read<ChatCubit>().loadMessages(widget.conversationId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String? _modelId(BuildContext context) {
    final launchModel = _launchData?.modelId;
    if (launchModel != null && launchModel.isNotEmpty) {
      return launchModel;
    }
    return context.read<ModelsCubit>().ensureDefaultSelection();
  }

  void _send(String content, String modelId) {
    context.read<ChatCubit>().sendMessage(
      conversationId: widget.conversationId,
      content: content,
      modelId: modelId,
      attachments: List<MessageAttachment>.from(_pendingAttachments),
    );
    _pendingAttachments.clear();
  }

  void _onSendPressed(String content) {
    final state = context.read<ChatCubit>().state;
    if (state.isLoading) {
      context.showSnackBar(
        localizedTextRead(
          context,
          'Waiting for the response…',
          'بانتظار الرد…',
        ),
      );
      return;
    }
    final modelId = _modelId(context);
    if (modelId == null) {
      context.showSnackBar(
        localizedTextRead(
          context,
          'Please select a model first',
          'الرجاء اختيار نموذج أولاً',
        ),
      );
      return;
    }
    _send(content, modelId);
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
      type: FileType.any,
    );
    final selected = result?.files.single;
    if (selected == null || selected.path == null || !mounted) {
      return;
    }
    try {
      final uploaded = await buildFileRepository().uploadFile(
        filePath: selected.path!,
        fileFieldName: 'file',
      );
      final mime = uploaded.mimeType ?? 'application/octet-stream';
      final type = mime.startsWith('image/')
          ? AttachmentType.image
          : mime.startsWith('video/')
          ? AttachmentType.video
          : mime.startsWith('audio/')
          ? AttachmentType.audio
          : AttachmentType.file;
      setState(() {
        _pendingAttachments.add(
          MessageAttachment(
            id: uploaded.id,
            name: uploaded.name,
            type: type,
            url: uploaded.url ?? '',
            size: uploaded.size,
            mimeType: uploaded.mimeType,
          ),
        );
      });
      context.showSnackBar(
        localizedTextRead(
          context,
          'Attachment ready',
          'تم تجهيز المرفق للإرسال',
        ),
      );
    } on Exception catch (error) {
      if (mounted) {
        context.showErrorSnackBar(
          '${localizedTextRead(context, 'Upload failed', 'فشل رفع المرفق')}: $error',
        );
      }
    }
  }

  Future<void> _copyMessage(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) {
      return;
    }
    context.showSnackBar(
      localizedTextRead(context, 'Copied to clipboard', 'تم النسخ إلى الحافظة'),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCubit, ChatState>(
      listener: (context, state) {
        final error = state.error;
        if (error != null && error.isNotEmpty) {
          context.showErrorSnackBar(
            localizedTextRead(context, 'Something went wrong', 'حدث خطأ ما'),
          );
        }
        if (state.messages.length != _previousLength) {
          _previousLength = state.messages.length;
          _scrollToBottom();
        }
      },
      builder: (context, state) {
        return AppScaffold(
          appBar: AppBar(
            title: Text(
              localizedText(context, 'Hajeen AI Chat', 'محادثة هاجين'),
            ),
          ),
          body: _buildBody(context, state),
          bottomSheet: ChatInputField(
            hintText: localizedText(context, 'Ask anything…', 'اسأل أي شيء…'),
            onSendMessage: _onSendPressed,
            onAttachFile: _pickAttachment,
            onUploadImage: _pickAttachment,
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ChatState state) {
    if (state.isLoading && state.messages.isEmpty) {
      return const Center(child: LoadingIndicator());
    }

    if (state.error != null && state.messages.isEmpty) {
      return ErrorView(
        description: state.error,
        onRetry: () =>
            context.read<ChatCubit>().loadMessages(widget.conversationId),
      );
    }

    if (state.messages.isEmpty) {
      return const EmptyState(variant: EmptyStateVariant.noData);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        return FadeInSlide(
          child: MessageBubble(
            message: message,
            onCopy: () => _copyMessage(message.content),
            onRegenerate: message.role == MessageRole.assistant
                ? () {
                    final modelId = _modelId(context);
                    if (modelId != null) {
                      context.read<ChatCubit>().regenerate(
                        conversationId: widget.conversationId,
                        modelId: modelId,
                      );
                    }
                  }
                : null,
          ),
        );
      },
    );
  }
}
