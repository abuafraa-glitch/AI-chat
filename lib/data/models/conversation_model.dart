import 'package:equatable/equatable.dart';

/// Represents the status of a conversation.
enum ConversationStatus { active, archived, deleted, pinned }

/// A production-ready, immutable model representing a conversation.
///
/// This model focuses solely on conversation metadata and does not store
/// individual messages, which are managed separately.
class ConversationModel extends Equatable {
  const ConversationModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.status = ConversationStatus.active,
    this.lastMessageSnippet,
    this.aiModelId,
    this.metadata = const {},
  });

  /// Creates a [ConversationModel] instance from a JSON map.
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      status: ConversationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ConversationStatus.active,
      ),
      lastMessageSnippet: json['lastMessageSnippet'] as String?,
      aiModelId: json['aiModelId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );
  }
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ConversationStatus status;
  final String? lastMessageSnippet;
  final String? aiModelId;
  final Map<String, dynamic> metadata;

  /// Creates a copy of this [ConversationModel] with the given fields replaced by the new values.
  ConversationModel copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    ConversationStatus? status,
    String? lastMessageSnippet,
    String? aiModelId,
    Map<String, dynamic>? metadata,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      lastMessageSnippet: lastMessageSnippet ?? this.lastMessageSnippet,
      aiModelId: aiModelId ?? this.aiModelId,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Converts this [ConversationModel] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.name,
      'lastMessageSnippet': lastMessageSnippet,
      'aiModelId': aiModelId,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
    id,
    title,
    createdAt,
    updatedAt,
    status,
    lastMessageSnippet,
    aiModelId,
    metadata,
  ];
}
