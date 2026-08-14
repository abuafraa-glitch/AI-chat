import 'dart:convert';

import 'package:ai_chat/core/utils/jwt_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

/// Encodes a compact JWT ([header].[payload].[signature]) whose payload is
/// [claims]. The header is a standard HS256 JWT header and the signature is
/// a fixed dummy segment — JwtDecoder never verifies the signature.
String _jwt(Map<String, dynamic> claims) {
  final header = <String, dynamic>{'alg': 'HS256', 'typ': 'JWT'};
  return '${_b64UrlJson(header)}.${_b64UrlJson(claims)}.sig';
}

/// JSON-encodes [map] then base64url-encodes the result without padding,
/// matching the JWT compact segment encoding.
String _b64UrlJson(Map<String, dynamic> map) {
  final jsonStr = jsonEncode(map);
  return base64Url.encode(utf8.encode(jsonStr)).replaceAll('=', '');
}

void main() {
  group('JwtDecoder.expirationOf', () {
    test('decodes the exp claim as a UTC DateTime', () {
      final exp = DateTime.utc(2025, 1, 1, 0, 0, 0);
      final seconds = exp.millisecondsSinceEpoch ~/ 1000;
      final token = _jwt(<String, dynamic>{'exp': seconds, 'sub': 'u1'});

      final result = JwtDecoder.expirationOf(token);

      expect(result, isNotNull);
      expect(result!.toUtc(), exp);
    });

    test('returns null for a JWT without an exp claim', () {
      expect(
        JwtDecoder.expirationOf(_jwt(<String, dynamic>{'sub': 'u1'})),
        isNull,
      );
    });

    test('returns null for a non-JWT opaque token', () {
      expect(JwtDecoder.expirationOf('opaque-session-token'), isNull);
    });

    test('returns null for null / empty input', () {
      expect(JwtDecoder.expirationOf(null), isNull);
      expect(JwtDecoder.expirationOf(''), isNull);
    });

    test('returns null for a malformed token (wrong segment count)', () {
      expect(JwtDecoder.expirationOf('a.b'), isNull);
      expect(JwtDecoder.expirationOf('a.b.c.d'), isNull);
    });

    test('returns null when the payload is not a JSON object', () {
      final payload = base64Url
          .encode(utf8.encode('[1,2,3]'))
          .replaceAll('=', '');
      expect(JwtDecoder.expirationOf('h.$payload.sig'), isNull);
    });
  });

  group('JwtDecoder.isExpired', () {
    test('true when exp is in the past', () {
      final past = DateTime.utc(2000, 1, 1);
      final seconds = past.millisecondsSinceEpoch ~/ 1000;
      expect(
        JwtDecoder.isExpired(_jwt(<String, dynamic>{'exp': seconds})),
        isTrue,
      );
    });

    test('false when exp is in the future', () {
      final future = DateTime.utc(2100, 1, 1);
      final seconds = future.millisecondsSinceEpoch ~/ 1000;
      expect(
        JwtDecoder.isExpired(_jwt(<String, dynamic>{'exp': seconds})),
        isFalse,
      );
    });

    test(
      'false when the token is not a JWT (validity not locally decidable)',
      () {
        expect(JwtDecoder.isExpired('opaque-token'), isFalse);
        expect(JwtDecoder.isExpired(null), isFalse);
      },
    );

    test('honours clock skew tolerance', () {
      // exp is 30s in the future; with a 60s skew it is considered expired.
      final exp = DateTime.now().toUtc().add(const Duration(seconds: 30));
      final seconds = exp.millisecondsSinceEpoch ~/ 1000;
      final token = _jwt(<String, dynamic>{'exp': seconds});

      expect(
        JwtDecoder.isExpired(token, clockSkew: const Duration(seconds: 60)),
        isTrue,
      );
      expect(JwtDecoder.isExpired(token, clockSkew: Duration.zero), isFalse);
    });
  });
}
