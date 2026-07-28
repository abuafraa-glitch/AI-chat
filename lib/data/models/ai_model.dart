class AIModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isAvailable;
  final bool isPremium;
  final int? maxTokens;
  final double? temperature;
  final List<String>? capabilities;

  AIModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isAvailable = true,
    this.isPremium = false,
    this.maxTokens,
    this.temperature,
    this.capabilities,
  });

  factory AIModel.fromJson(Map<String, dynamic> json) {
    return AIModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '🧠',
      isAvailable: json['isAvailable'] as bool? ?? true,
      isPremium: json['isPremium'] as bool? ?? false,
      maxTokens: json['maxTokens'] as int?,
      temperature: json['temperature'] as double?,
      capabilities: List<String>.from(json['capabilities'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon': icon,
    'isAvailable': isAvailable,
    'isPremium': isPremium,
    'maxTokens': maxTokens,
    'temperature': temperature,
    'capabilities': capabilities,
  };
}
