import 'package:ai_chat/data/models/message_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes attachment metadata for image, video, and file payloads', () {
    final attachments = <MessageAttachment>[
      const MessageAttachment(
        id: 'img-1',
        name: 'photo.png',
        type: AttachmentType.image,
        url: 'data:image/png;base64,AA==',
        size: 1,
        mimeType: 'image/png',
      ),
      const MessageAttachment(
        id: 'vid-1',
        name: 'clip.mp4',
        type: AttachmentType.video,
        url: 'https://example.invalid/clip.mp4',
        size: 2,
        mimeType: 'video/mp4',
      ),
      const MessageAttachment(
        id: 'file-1',
        name: 'notes.pdf',
        type: AttachmentType.file,
        url: 'https://example.invalid/notes.pdf',
        size: 3,
        mimeType: 'application/pdf',
      ),
    ];

    final payload = attachments.map((item) => item.toJson()).toList();
    expect(payload.map((item) => item['type']), ['image', 'video', 'file']);
    expect(payload[0]['mimeType'], 'image/png');
    expect(payload[1]['url'], contains('clip.mp4'));
    expect(payload[2]['name'], 'notes.pdf');
  });

  test('keeps meaningful attachment-only title data available to backend', () {
    const attachment = MessageAttachment(
      id: 'file-1',
      name: 'invoice.pdf',
      type: AttachmentType.file,
      url: 'https://example.invalid/invoice.pdf',
      size: 12,
      mimeType: 'application/pdf',
    );
    expect(attachment.toJson()['name'], 'invoice.pdf');
  });
}
