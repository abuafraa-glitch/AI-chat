import 'dart:convert';

import 'package:ai_chat/core/network/sse_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SseParser', () {
    test('dispatches data on a blank line', () async {
      final result = await SseParser.parse(
        Stream<String>.fromIterable(<String>['data: hello\n\n']),
      ).toList();
      expect(result, <String>['hello']);
    });

    test('joins multiline data fields with a newline', () async {
      final result = await SseParser.parse(
        Stream<String>.fromIterable(<String>[
          'event: message\n',
          'data: hello\n',
          'data: world\n\n',
        ]),
      ).toList();
      expect(result, <String>['hello\nworld']);
    });

    test('handles fragmented framing, CRLF, comments, and DONE', () async {
      final result = await SseParser.parse(
        Stream<String>.fromIterable(<String>[
          ': keep alive\r\n\r',
          '\ndata: hel',
          'lo\r\n\r\ndata: [DONE]\n\n',
        ]),
      ).toList();
      expect(result, <String>['hello', '[DONE]']);
    });

    test('preserves UTF-8 characters split across byte chunks', () async {
      final bytes = utf8.encode('data: مرحبا\n\n');
      final result = await SseParser.parse(
        utf8.decoder.bind(
          Stream<List<int>>.fromIterable(<List<int>>[
            bytes.sublist(0, 8),
            bytes.sublist(8, 11),
            bytes.sublist(11),
          ]),
        ),
      ).toList();
      expect(result, <String>['مرحبا']);
    });

    test('keeps data from error events for the application layer', () async {
      final result = await SseParser.parse(
        Stream<String>.fromIterable(<String>[
          'event: error\n',
          'data: service unavailable\n\n',
        ]),
      ).toList();
      expect(result, <String>['service unavailable']);
    });

    test('supports cancellation after the first event', () async {
      final result = await SseParser.parse(
        Stream<String>.fromIterable(<String>[
          'data: first\n\n',
          'data: second\n\n',
        ]),
      ).take(1).toList();
      expect(result, <String>['first']);
    });

    test('does not emit an empty event', () async {
      final result = await SseParser.parse(
        Stream<String>.fromIterable(<String>['\n\ndata: value\n\n']),
      ).toList();
      expect(result, <String>['value']);
    });
  });
}
