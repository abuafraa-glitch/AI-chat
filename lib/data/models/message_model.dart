import 'package:equatable/equatable.dart';

/// Represents the role of the sender in a message.
enum MessageRole { user, assistant, system, tool }

/// Represents the status of a message during processing or display.
enum MessageStatus {
  pending,
  sent,
  delivered,
  read,
  failed,
  streaming,
  regenerating,
  editing,
}

/// Represents different types of content that can be attached to a message.
enum AttachmentType { image, audio, video, document, file, toolOutput }

/// A production-ready, immutable model representing a message in a conversation.
///
/// This model is designed to be highly extensible to support various content types,
/// streaming, tool calls, and future message capabilities.
class MessageModel extends Equatable {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MessageStatus status;
  final List<MessageAttachment> attachments;
  final List<MessageToolCall> toolCalls;
  final List<MessageCitation> citations;
  final MessageTokenUsage? tokenUsage;
  final Map<String, dynamic> modelMetadata;
  final bool isStreaming;
  final bool isEdited;
  final bool isRegenerated;
  final List<String> reactions;
  final String? parentMessageId;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.status = MessageStatus.sent,
    this.attachments = const [],
    this.toolCalls = const [],
    this.citations = const [],
    this.tokenUsage,
    this.modelMetadata = const {},
    this.isStreaming = false,
    this.isEdited = false,
    this.isRegenerated = false,
    this.reactions = const [],
    this.parentMessageId,
  });

  /// Creates a copy of this [MessageModel] with the given fields replaced by the new values.
  MessageModel copyWith({
    String? id,
    String? conversationId,
    MessageRole? role,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    MessageStatus? status,
    List<MessageAttachment>? attachments,
    List<MessageToolCall>? toolCalls,
    List<MessageCitation>? citations,
    MessageTokenUsage? tokenUsage,
    Map<String, dynamic>? modelMetadata,
    bool? isStreaming,
    bool? isEdited,
    bool? isRegenerated,
    List<String>? reactions,
    String? parentMessageId,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      toolCalls: toolCalls ?? this.toolCalls,
      citations: citations ?? this.citations,
      tokenUsage: tokenUsage ?? this.tokenUsage,
      modelMetadata: modelMetadata ?? this.modelMetadata,
      isStreaming: isStreaming ?? this.isStreaming,
      isEdited: isEdited ?? this.isEdited,
      isRegenerated: isRegenerated ?? this.isRegenerated,
      reactions: reactions ?? this.reactions,
      parentMessageId: parentMessageId ?? this.parentMessageId,
    );
  }

  /// Creates a [MessageModel] instance from a JSON map.
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json["id"] as String,
      conversationId: json["conversationId"] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.name == json["role"],
        orElse: () => MessageRole.user,
      ),
      content: json["content"] as String,
      createdAt: DateTime.parse(json["createdAt"] as String),
      updatedAt: DateTime.parse(json["updatedAt"] as String),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json["status"],
        orElse: () => MessageStatus.sent,
      ),
      attachments:
          (json["attachments"] as List<dynamic>?)
              ?.map(
                (e) => MessageAttachment.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      toolCalls:
          (json["toolCalls"] as List<dynamic>?)
              ?.map((e) => MessageToolCall.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      citations:
          (json["citations"] as List<dynamic>?)
              ?.map((e) => MessageCitation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      tokenUsage: json["tokenUsage"] != null
          ? MessageTokenUsage.fromJson(
              json["tokenUsage"] as Map<String, dynamic>,
            )
          : null,
      modelMetadata: json["modelMetadata"] as Map<String, dynamic>? ?? const {},
      isStreaming: json["isStreaming"] as bool? ?? false,
      isEdited: json["isEdited"] as bool? ?? false,
      isRegenerated: json["isRegenerated"] as bool? ?? false,
      reactions: List<String>.from(json["reactions"] as List? ?? const []),
      parentMessageId: json["parentMessageId"] as String?,
    );
  }

  /// Converts this [MessageModel] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "conversationId": conversationId,
      "role": role.name,
      "content": content,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
      "status": status.name,
      "attachments": attachments.map((e) => e.toJson()).toList(),
      "toolCalls": toolCalls.map((e) => e.toJson()).toList(),
      "citations": citations.map((e) => e.toJson()).toList(),
      "tokenUsage": tokenUsage?.toJson(),
      "modelMetadata": modelMetadata,
      "isStreaming": isStreaming,
      "isEdited": isEdited,
      "isRegenerated": isRegenerated,
      "reactions": reactions,
      "parentMessageId": parentMessageId,
    };
  }

  @override
  List<Object?> get props => [
    id,
    conversationId,
    role,
    content,
    createdAt,
    updatedAt,
    status,
    attachments,
    toolCalls,
    citations,
    tokenUsage,
    modelMetadata,
    isStreaming,
    isEdited,
    isRegenerated,
    reactions,
    parentMessageId,
  ];
}

/// Represents an attachment associated with a message.
class MessageAttachment extends Equatable {
  final String id;
  final String name;
  final AttachmentType type;
  final String url;
  final int size;
  final String? mimeType;
  final Map<String, dynamic> metadata;

  const MessageAttachment({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    required this.size,
    this.mimeType,
    this.metadata = const {},
  });

  /// Creates a [MessageAttachment] instance from a JSON map.
  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json["id"] as String,
      name: json["name"] as String,
      type: AttachmentType.values.firstWhere(
        (e) => e.name == json["type"],
        orElse: () => AttachmentType.file,
      ),
      url: json["url"] as String,
      size: json["size"] as int,
      mimeType: json["mimeType"] as String?,
      metadata: json["metadata"] as Map<String, dynamic>? ?? const {},
    );
  }

  /// Converts this [MessageAttachment] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "type": type.name,
      "url": url,
      "size": size,
      "mimeType": mimeType,
      "metadata": metadata,
    };
  }

  @override
  List<Object?> get props => [id, name, type, url, size, mimeType, metadata];
}

/// Represents a tool call made within a message.
class MessageToolCall extends Equatable {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;
  final String? output;

  const MessageToolCall({
    required this.id,
    required this.name,
    required this.arguments,
    this.output,
  });

  /// Creates a [MessageToolCall] instance from a JSON map.
  factory MessageToolCall.fromJson(Map<String, dynamic> json) {
    return MessageToolCall(
      id: json["id"] as String,
      name: json["name"] as String,
      arguments: json["arguments"] as Map<String, dynamic>,
      output: json["output"] as String?,
    );
  }

  /// Converts this [MessageToolCall] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {"id": id, "name": name, "arguments": arguments, "output": output};
  }

  @override
  List<Object?> get props => [id, name, arguments, output];
}

/// Represents a citation or reference within a message.
class MessageCitation extends Equatable {
  final String id;
  final String text;
  final String? url;
  final String? title;

  const MessageCitation({
    required this.id,
    required this.text,
    this.url,
    this.title,
  });

  /// Creates a [MessageCitation] instance from a JSON map.
  factory MessageCitation.fromJson(Map<String, dynamic> json) {
    return MessageCitation(
      id: json["id"] as String,
      text: json["text"] as String,
      url: json["url"] as String?,
      title: json["title"] as String?,
    );
  }

  /// Converts this [MessageCitation] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {"id": id, "text": text, "url": url, "title": title};
  }

  @override
  List<Object?> get props => [id, text, url, title];
}

/// Represents token usage statistics for a message.
class MessageTokenUsage extends Equatable {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  const MessageTokenUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  /// Creates a [MessageTokenUsage] instance from a JSON map.
  factory MessageTokenUsage.fromJson(Map<String, dynamic> json) {
    return MessageTokenUsage(
      promptTokens: json["promptTokens"] as int,
      completionTokens: json["completionTokens"] as int,
      totalTokens: json["totalTokens"] as int,
    );
  }

  /// Converts this [MessageTokenUsage] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      "promptTokens": promptTokens,
      "completionTokens": completionTokens,
      "totalTokens": totalTokens,
    };
  }

  @override
  List<Object?> get props => [promptTokens, completionTokens, totalTokens];
}
