import 'dart:async';
import 'dart:io';

import 'package:ai_chat/core/network/interceptors/retry_interceptor.dart';
import 'package:ai_chat/core/network/network_info.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Always-online [NetworkInfo] for retry-positive scenarios.
class _OnlineNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get connectivityStream => const Stream<bool>.empty();
}

/// Always-offline [NetworkInfo]: retry must be aborted immediately, with no
/// HTTP attempt after the first failure.
class _OfflineNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => false;

  @override
  Stream<bool> get connectivityStream => const Stream<bool>.empty();
}

/// Loopback HTTP server that counts hits per path and lets each handler
/// decide the response status, so we can assert retry behaviour end-to-end.
class _CountingServer {
  _CountingServer(this._statusFor);

  /// Returns the status code to emit for [hit] of the given path (1-based),
  /// or `null` to respond 200 (success).
  final int? Function(String path, int hit) _statusFor;

  late HttpServer _server;
  late String base;
  final Map<String, int> _hits = <String, int>{};

  int hits(String path) => _hits[path] ?? 0;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = 'http://${_server.address.host}:${_server.port}';
    unawaited(_serve());
  }

  Future<void> _serve() async {
    await for (final request in _server) {
      final path = request.uri.path;
      final hit = (_hits[path] ?? 0) + 1;
      _hits[path] = hit;
      final status = _statusFor(path, hit);
      request.response.statusCode = status ?? 200;
      request.response.write('ok');
      await request.response.close();
    }
  }

  Future<void> stop() => _server.close(force: true);
}

void main() {
  group('RetryInterceptor', () {
    test('4xx client errors are NOT retried', () async {
      final server = _CountingServer((path, hit) => 400);
      await server.start();
      addTearDown(server.stop);

      final dio = Dio(BaseOptions(baseUrl: server.base));
      dio.interceptors.add(
        RetryInterceptor(dio: dio, networkInfo: _OnlineNetworkInfo()),
      );

      await expectLater(dio.get('/billing'), throwsA(isA<DioException>()));

      // Exactly one attempt — never retried.
      expect(server.hits('/billing'), 1);
    });

    test('offline aborts retries with no extra HTTP attempt', () async {
      final server = _CountingServer((path, hit) => 503);
      await server.start();
      addTearDown(server.stop);

      final dio = Dio(BaseOptions(baseUrl: server.base));
      dio.interceptors.add(
        RetryInterceptor(dio: dio, networkInfo: _OfflineNetworkInfo()),
      );

      await expectLater(dio.get('/billing'), throwsA(isA<DioException>()));

      // First attempt happens, then connectivity check fails → no retry.
      expect(server.hits('/billing'), 1);
    });

    test(
      '5xx transient errors are retried until success (idempotent GET)',
      () async {
        // Fail the first two attempts, succeed on the third. With maxRetries=3
        // (up to 4 total attempts) this stays within budget. Production wires
        // RetryInterceptor with the same intercepted Dio so the retry path
        // re-enters the interceptor (incrementing the attempt counter) — this
        // test mirrors that wiring.
        final server = _CountingServer((path, hit) => hit <= 2 ? 503 : null);
        await server.start();
        addTearDown(server.stop);

        final dio = Dio(BaseOptions(baseUrl: server.base));
        dio.interceptors.add(
          RetryInterceptor(dio: dio, networkInfo: _OnlineNetworkInfo()),
        );

        final response = await dio.get('/billing');

        expect(response.statusCode, 200);
        expect(server.hits('/billing'), 3); // 2 failures + 1 success
      },
    );

    test('POST is never retried (non-idempotent)', () async {
      final server = _CountingServer((path, hit) => 503);
      await server.start();
      addTearDown(server.stop);

      final dio = Dio(BaseOptions(baseUrl: server.base));
      dio.interceptors.add(
        RetryInterceptor(dio: dio, networkInfo: _OnlineNetworkInfo()),
      );

      await expectLater(dio.post('/billing'), throwsA(isA<DioException>()));

      expect(server.hits('/billing'), 1); // POST never retried
    });
  });
}
