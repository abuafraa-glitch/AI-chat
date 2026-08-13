import 'package:ai_chat/data/models/message_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageModel', () {
    final now = DateTime.utc(2026, 1, 1);
    final later = now.add(const Duration(minutes: 1));

    test('toJson/fromJson round-trip preserves scalar fields', () {
      final original = MessageModel(
        id: 'm1',
        conversationId: 'c1',
        role: MessageRole.assistant,
        content: 'hello',
        createdAt: now,
        updatedAt: later,
      );

      final decoded = MessageModel.fromJson(original.toJson());

      expect(decoded.id, original.id);
      expect(decoded.conversationId, original.conversationId);
      expect(decoded.role, original.role);
      expect(decoded.content, original.content);
      expect(decoded.createdAt, original.createdAt);
      expect(decoded.updatedAt, original.updatedAt);
    });

    test('fromJson falls back to defaults for optional fields', () {
      final json = <String, dynamic>{
        'id': 'm2',
        'conversationId': 'c2',
        'role': 'unknown_role',
        'content': '',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final decoded = MessageModel.fromJson(json);

      expect(decoded.role, MessageRole.user);
      expect(decoded.status, MessageStatus.sent);
      expect(decoded.attachments, isEmpty);
      expect(decoded.isStreaming, isFalse);
    });

    test('copyWith overrides only the supplied fields', () {
      final original = MessageModel(
        id: 'm3',
        conversationId: 'c3',
        role: MessageRole.user,
        content: 'old',
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(content: 'new', isStreaming: true);

      expect(updated.id, 'm3');
      expect(updated.content, 'new');
      expect(updated.isStreaming, isTrue);
      expect(updated.role, MessageRole.user);
    });

    test('equality respects content and streaming state', () {
      final a = MessageModel(
        id: 'm4',
        conversationId: 'c4',
        role: MessageRole.assistant,
        content: 'x',
        createdAt: now,
        updatedAt: now,
        isStreaming: true,
      );
      final b = a.copyWith(isStreaming: false);

      expect(a == a.copyWith(), isTrue);
      expect(a == b, isFalse);
    });
  });

  group('MessageAttachment', () {
    test('round-trips through JSON', () {
      final original = MessageAttachment(
        id: 'a1',
        name: 'photo.png',
        type: AttachmentType.image,
        url: 'https://example.com/p.png',
        size: 1024,
        mimeType: 'image/png',
      );

      final decoded = MessageAttachment.fromJson(original.toJson());

      expect(decoded, original);
    });
  });

  group('MessageTokenUsage', () {
    test('round-trips through JSON', () {
      const original = MessageTokenUsage(
        promptTokens: 10,
        completionTokens: 20,
        totalTokens: 30,
      );

      final decoded = MessageTokenUsage.fromJson(original.toJson());

      expect(decoded, original);
    });
  });
}
