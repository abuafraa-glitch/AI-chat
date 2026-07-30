import 'package:intl/intl.dart';

class Message {
  final String id;
  final String conversationId;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final String? modelId;
  final List<MessageAttachment>? attachments;
  final int? likeCount;
  final int? dislikeCount;
  final bool isLiked;
  final bool isDisliked;
  final bool isPinned;
  final bool isStreaming;
  final double? streamingProgress;

  Message({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.role,
    required this.timestamp,
    this.modelId,
    this.attachments,
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.isLiked = false,
    this.isDisliked = false,
    this.isPinned = false,
    this.isStreaming = false,
    this.streamingProgress = 0,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      content: json['content'] as String,
      role: MessageRole.values.byName(json['role'] as String? ?? 'user'),
      timestamp: DateTime.parse(json['timestamp'] as String),
      modelId: json['modelId'] as String?,
      attachments: (json['attachments'] as List?)
          ?.map((e) => MessageAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      likeCount: json['likeCount'] as int? ?? 0,
      dislikeCount: json['dislikeCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      isDisliked: json['isDisliked'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'content': content,
    'role': role.name,
    'timestamp': timestamp.toIso8601String(),
    'modelId': modelId,
    'attachments': attachments?.map((e) => e.toJson()).toList(),
    'likeCount': likeCount,
    'dislikeCount': dislikeCount,
    'isLiked': isLiked,
    'isDisliked': isDisliked,
    'isPinned': isPinned,
  };

  String get formattedTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (msgDate == today) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (msgDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd').format(timestamp);
    }
  }
}

enum MessageRole {
  user,
  assistant,
  system,
}

class MessageAttachment {
  final String id;
  final String name;
  final String type;
  final String url;
  final int size;
  final DateTime uploadedAt;

  MessageAttachment({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    required this.size,
    required this.uploadedAt,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      url: json['url'] as String,
      size: json['size'] as int,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'url': url,
    'size': size,
    'uploadedAt': uploadedAt.toIso8601String(),
  };

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
