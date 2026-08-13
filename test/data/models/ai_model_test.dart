import 'package:ai_chat/data/models/ai_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final capabilities = const AIModelCapabilities(
    supportsVision: true,
    supportsStreaming: true,
    supportsToolUse: false,
    supportsSystemPrompt: true,
  );

  final model = AIModel(
    id: 'gpt-4o',
    name: 'GPT-4o',
    description: 'Multimodal flagship model',
    version: '1.0.0',
    provider: AIProvider.openai,
    type: AIModelType.cloud,
    contextWindow: 128000,
    maxOutputTokens: 4096,
    capabilities: capabilities,
    isAvailable: true,
    metadata: const {'tier': 'premium'},
  );

  group('AIModel JSON round-trip', () {
    test('toJson serialises all fields', () {
      final json = model.toJson();
      expect(json['id'], 'gpt-4o');
      expect(json['provider'], 'openai');
      expect(json['type'], 'cloud');
      expect(json['contextWindow'], 128000);
      expect(json['isAvailable'], isTrue);
      expect((json['metadata'] as Map)['tier'], 'premium');
    });

    test('fromJson reconstructs an equal model', () {
      final restored = AIModel.fromJson(model.toJson());
      expect(restored, equals(model));
    });

    test('unknown provider/type fall back to defaults', () {
      final json = model.toJson();
      json['provider'] = 'unknown-provider';
      json['type'] = 'unknown-type';
      final restored = AIModel.fromJson(json);
      expect(restored.provider, AIProvider.custom);
      expect(restored.type, AIModelType.cloud);
    });

    test('null description/maxOutputTokens/metadata use defaults', () {
      final json = <String, dynamic>{
        'id': 'm',
        'name': 'M',
        'version': '1',
        'provider': 'gemini',
        'type': 'cloud',
        'contextWindow': 8000,
        'capabilities': const <String, dynamic>{},
      };
      final restored = AIModel.fromJson(json);
      expect(restored.description, isNull);
      expect(restored.maxOutputTokens, isNull);
      expect(restored.metadata, isEmpty);
      expect(restored.isAvailable, isTrue); // default
    });
  });

  group('AIModel.copyWith / equality', () {
    test('copyWith changes only the given field', () {
      final renamed = model.copyWith(name: 'GPT-4o-mini');
      expect(renamed.name, 'GPT-4o-mini');
      expect(renamed.id, model.id);
      expect(renamed.provider, model.provider);
    });

    test('equal models are equal; differing id are not', () {
      expect(AIModel.fromJson(model.toJson()), equals(model));
      expect(model.copyWith(id: 'other') == model, isFalse);
    });
  });

  group('AIModelCapabilities JSON', () {
    test('toJson/fromJson round-trip', () {
      final json = capabilities.toJson();
      expect(AIModelCapabilities.fromJson(json), equals(capabilities));
    });

    test('defaults when fields missing', () {
      final c = AIModelCapabilities.fromJson(const <String, dynamic>{});
      expect(c.supportsVision, isFalse);
      expect(c.supportsStreaming, isTrue); // default true
      expect(c.supportsSystemPrompt, isTrue); // default true
    });
  });
}
