import 'package:equatable/equatable.dart';

/// Represents the provider of the AI model.
enum AIProvider {
  openai,
  anthropic,
  gemini,
  qwen,
  hajeenLocal,
  ollama,
  vllm,
  openRouter,
  groq,
  custom,
}

/// Represents the type of the AI model (where it is hosted/executed).
enum AIModelType { cloud, local }

/// A production-ready, immutable model representing an AI Model and its capabilities.
///
/// This model is designed to be highly extensible to support various providers
/// and future capabilities without breaking existing architecture.
class AIModel extends Equatable {
  const AIModel({
    required this.id,
    required this.name,
    this.description,
    required this.version,
    required this.provider,
    required this.type,
    required this.contextWindow,
    this.maxOutputTokens,
    required this.capabilities,
    this.isAvailable = true,
    this.metadata = const {},
  });

  /// Creates an [AIModel] instance from a JSON map.
  factory AIModel.fromJson(Map<String, dynamic> json) {
    return AIModel(
      id: (json['id'] ?? json['model_id'] ?? 'unknown').toString(),
      name: (json['name'] ?? json['model_name'] ?? json['model_id'] ?? 'Hajeen AI').toString(),
      description: json['description']?.toString(),
      version: (json['version'] ?? '1.0').toString(),
      provider: AIProvider.values.firstWhere(
        (e) => e.name == (json['provider'] ?? json['provider_name']),
        orElse: () => AIProvider.custom,
      ),
      type: AIModelType.values.firstWhere(
        (e) => e.name == (json['type'] ?? (json['is_local'] == true ? 'local' : 'cloud')),
        orElse: () => AIModelType.cloud,
      ),
      contextWindow: (json['contextWindow'] ?? json['context_window'] ?? 32768) as int,
      maxOutputTokens: (json['maxOutputTokens'] ?? json['max_tokens']) as int?,
      capabilities: AIModelCapabilities.fromJson(
        (json['capabilities'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
      isAvailable: (json['isAvailable'] ?? json['available'] ?? true) as bool,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
    );
  }
  final String id;
  final String name;
  final String? description;
  final String version;
  final AIProvider provider;
  final AIModelType type;
  final int contextWindow;
  final int? maxOutputTokens;
  final AIModelCapabilities capabilities;
  final bool isAvailable;
  final Map<String, dynamic> metadata;

  /// Creates a copy of this [AIModel] with the given fields replaced by the new values.
  AIModel copyWith({
    String? id,
    String? name,
    String? description,
    String? version,
    AIProvider? provider,
    AIModelType? type,
    int? contextWindow,
    int? maxOutputTokens,
    AIModelCapabilities? capabilities,
    bool? isAvailable,
    Map<String, dynamic>? metadata,
  }) {
    return AIModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      provider: provider ?? this.provider,
      type: type ?? this.type,
      contextWindow: contextWindow ?? this.contextWindow,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      capabilities: capabilities ?? this.capabilities,
      isAvailable: isAvailable ?? this.isAvailable,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Converts this [AIModel] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'version': version,
      'provider': provider.name,
      'type': type.name,
      'contextWindow': contextWindow,
      'maxOutputTokens': maxOutputTokens,
      'capabilities': capabilities.toJson(),
      'isAvailable': isAvailable,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    version,
    provider,
    type,
    contextWindow,
    maxOutputTokens,
    capabilities,
    isAvailable,
    metadata,
  ];
}

/// Represents the technical capabilities of an [AIModel].
class AIModelCapabilities extends Equatable {
  const AIModelCapabilities({
    this.supportsVision = false,
    this.supportsAudio = false,
    this.supportsVideo = false,
    this.supportsStreaming = true,
    this.supportsToolUse = false,
    this.supportsJsonMode = false,
    this.supportsSystemPrompt = true,
  });

  factory AIModelCapabilities.fromJson(Map<String, dynamic> json) {
    return AIModelCapabilities(
      supportsVision: json['supportsVision'] as bool? ?? false,
      supportsAudio: json['supportsAudio'] as bool? ?? false,
      supportsVideo: json['supportsVideo'] as bool? ?? false,
      supportsStreaming: json['supportsStreaming'] as bool? ?? true,
      supportsToolUse: json['supportsToolUse'] as bool? ?? false,
      supportsJsonMode: json['supportsJsonMode'] as bool? ?? false,
      supportsSystemPrompt: json['supportsSystemPrompt'] as bool? ?? true,
    );
  }
  final bool supportsVision;
  final bool supportsAudio;
  final bool supportsVideo;
  final bool supportsStreaming;
  final bool supportsToolUse;
  final bool supportsJsonMode;
  final bool supportsSystemPrompt;

  AIModelCapabilities copyWith({
    bool? supportsVision,
    bool? supportsAudio,
    bool? supportsVideo,
    bool? supportsStreaming,
    bool? supportsToolUse,
    bool? supportsJsonMode,
    bool? supportsSystemPrompt,
  }) {
    return AIModelCapabilities(
      supportsVision: supportsVision ?? this.supportsVision,
      supportsAudio: supportsAudio ?? this.supportsAudio,
      supportsVideo: supportsVideo ?? this.supportsVideo,
      supportsStreaming: supportsStreaming ?? this.supportsStreaming,
      supportsToolUse: supportsToolUse ?? this.supportsToolUse,
      supportsJsonMode: supportsJsonMode ?? this.supportsJsonMode,
      supportsSystemPrompt: supportsSystemPrompt ?? this.supportsSystemPrompt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supportsVision': supportsVision,
      'supportsAudio': supportsAudio,
      'supportsVideo': supportsVideo,
      'supportsStreaming': supportsStreaming,
      'supportsToolUse': supportsToolUse,
      'supportsJsonMode': supportsJsonMode,
      'supportsSystemPrompt': supportsSystemPrompt,
    };
  }

  @override
  List<Object?> get props => [
    supportsVision,
    supportsAudio,
    supportsVideo,
    supportsStreaming,
    supportsToolUse,
    supportsJsonMode,
    supportsSystemPrompt,
  ];
}
