import 'package:equatable/equatable.dart';

/// An immutable, typed representation of a user-uploaded file.
///
/// Replaces the previous raw `Map<String, dynamic>` flowing from the
/// remote data source all the way to the presentation layer, removing
/// the `_stringOf(file, 'name')` access pattern.
class FileModel extends Equatable {
  const FileModel({
    required this.id,
    required this.name,
    this.url,
    this.size = 0,
    this.mimeType,
    this.createdAt,
  });

  /// Creates a [FileModel] from a backend JSON payload, tolerating
  /// missing or mistyped fields by falling back to safe defaults.
  factory FileModel.fromJson(Map<String, dynamic> json) {
    final size = json['size'];
    final rawDate = json['createdAt'];
    return FileModel(
      id: _asString(json['id']),
      name: _asString(json['name']),
      url: _asStringOrNull(json['url']),
      size: size is int ? size : (size is num ? size.toInt() : 0),
      mimeType: _asStringOrNull(json['mimeType']),
      createdAt: rawDate is String ? DateTime.tryParse(rawDate) : null,
    );
  }

  final String id;
  final String name;
  final String? url;
  final int size;
  final String? mimeType;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'size': size,
    'mimeType': mimeType,
    'createdAt': createdAt?.toIso8601String(),
  };

  FileModel copyWith({
    String? id,
    String? name,
    String? url,
    int? size,
    String? mimeType,
    DateTime? createdAt,
  }) => FileModel(
    id: id ?? this.id,
    name: name ?? this.name,
    url: url ?? this.url,
    size: size ?? this.size,
    mimeType: mimeType ?? this.mimeType,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  List<Object?> get props => [id, name, url, size, mimeType, createdAt];
}

String _asString(Object? value) => value is String ? value : '';
String? _asStringOrNull(Object? value) => value is String ? value : null;
