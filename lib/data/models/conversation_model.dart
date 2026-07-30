import 'message.dart';

class Conversation {
  final String id;
  final String title;
  final String? description;
  final String userId;
  final String currentModelId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Message> messages;
  final bool isPinned;
  final bool isArchived;
  final int messageCount;
  final String? lastMessage;

  Conversation({
    required this.id,
    required this.title,
    this.description,
    required this.userId,
    required this.currentModelId,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
    this.isPinned = false,
    this.isArchived = false,
    this.messageCount = 0,
    this.lastMessage,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      userId: json['userId'] as String,
      currentModelId: json['currentModelId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      messages: (json['messages'] as List?)
          ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      isPinned: json['isPinned'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      messageCount: json['messageCount'] as int? ?? 0,
      lastMessage: json['lastMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'userId': userId,
    'currentModelId': currentModelId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'messages': messages.map((e) => e.toJson()).toList(),
    'isPinned': isPinned,
    'isArchived': isArchived,
    'messageCount': messageCount,
    'lastMessage': lastMessage,
  };

  Conversation copyWith({
    String? id,
    String? title,
    String? description,
    String? userId,
    String? currentModelId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Message>? messages,
    bool? isPinned,
    bool? isArchived,
    int? messageCount,
    String? lastMessage,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      currentModelId: currentModelId ?? this.currentModelId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      messageCount: messageCount ?? this.messageCount,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}
