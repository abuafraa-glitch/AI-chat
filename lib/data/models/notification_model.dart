import 'package:equatable/equatable.dart';

/// Represents the category of a notification for routing/icon selection.
enum NotificationType { general, message, system, billing, agent }

/// An immutable, typed representation of an in-app notification.
///
/// Replaces the raw `Map<String, dynamic>` previously consumed by the
/// presentation layer via `_stringOf(item, 'title')`.
class NotificationModel extends Equatable {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.isRead = false,
    this.type = NotificationType.general,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['createdAt'];
    return NotificationModel(
      id: _asString(json['id']),
      title: _asString(json['title']),
      body: _asString(json['body']),
      isRead: json['read'] == true || json['isRead'] == true,
      type: _parseType(json['type']),
      createdAt: rawDate is String ? DateTime.tryParse(rawDate) : null,
    );
  }

  final String id;
  final String title;
  final String body;
  final bool isRead;
  final NotificationType type;
  final DateTime? createdAt;

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    bool? isRead,
    NotificationType? type,
    DateTime? createdAt,
  }) => NotificationModel(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    isRead: isRead ?? this.isRead,
    type: type ?? this.type,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  List<Object?> get props => [id, title, body, isRead, type, createdAt];
}

String _asString(Object? value) => value is String ? value : '';

NotificationType _parseType(Object? value) {
  if (value is String) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.general,
    );
  }
  return NotificationType.general;
}
