import 'package:equatable/equatable.dart';

/// Represents the operational status of an autonomous agent.
enum AgentStatus { active, idle, paused, error, unknown }

/// An immutable, typed representation of an autonomous AI agent.
///
/// Replaces the raw `Map<String, dynamic>` previously consumed by the
/// presentation layer via `_stringOf(agent, 'name')`.
class AgentModel extends Equatable {
  const AgentModel({
    required this.id,
    required this.name,
    required this.description,
    this.status = AgentStatus.unknown,
    this.createdAt,
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['createdAt'];
    return AgentModel(
      id: _asString(json['id']),
      name: _asString(json['name']),
      description: _asString(json['description']),
      status: _parseStatus(json['status']),
      createdAt: rawDate is String ? DateTime.tryParse(rawDate) : null,
    );
  }

  final String id;
  final String name;
  final String description;
  final AgentStatus status;
  final DateTime? createdAt;

  AgentModel copyWith({
    String? id,
    String? name,
    String? description,
    AgentStatus? status,
    DateTime? createdAt,
  }) => AgentModel(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  List<Object?> get props => [id, name, description, status, createdAt];
}

String _asString(Object? value) => value is String ? value : '';

AgentStatus _parseStatus(Object? value) {
  if (value is String) {
    return AgentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AgentStatus.unknown,
    );
  }
  return AgentStatus.unknown;
}
