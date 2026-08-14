import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ai_chat/core/config/app_config.dart';
import 'package:ai_chat/core/config/flavor.dart';
import 'package:ai_chat/core/constants/api_constants.dart';
import 'package:ai_chat/core/network/api_consumer.dart';
import 'package:ai_chat/core/network/endpoints.dart';
import 'package:ai_chat/core/network/interceptors/auth_interceptor.dart';
import 'package:ai_chat/core/services/logger_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [TokenProvider] so the interceptor can read/write tokens
/// without touching platform secure storage.
class _FakeTokenProvider implements TokenProvider {
  _FakeTokenProvider({this.accessToken, this.refreshToken});

  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> writeAccessToken(String token) async => accessToken = token;

  @override
  Future<void> writeRefreshToken(String token) async => refreshToken = token;

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
  }
}

/// Records whether the network layer asked the auth controller to flip to
/// the unauthenticated state (ISSUE U reconciliation).
class _RecordingSink implements AuthSessionSink {
  int unauthenticatedCalls = 0;

  @override
  void markUnauthenticated() => unauthenticatedCalls++;
}

/// A tiny HTTP server that responds based on the request path, letting us
/// exercise the interceptor's real (platform-adapter) refresh path with no
/// mocking of Dio internals. This is a genuine integration test: the
/// interceptor builds its own bare [Dio] for the refresh call, and that
/// client connects to this same loopback server.
class _TestServer {
  _TestServer(this._handle);

  final Future<void> Function(HttpRequest request) _handle;
  late HttpServer _server;
  late String base; // e.g. http://127.0.0.1:54321

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = 'http://${_server.address.host}:${_server.port}';
    unawaited(_serve());
  }

  Future<void> _serve() async {
    await for (final request in _server) {
      try {
        await _handle(request);
      } finally {
        await request.response.close();
      }
    }
  }

  Future<void> stop() => _server.close(force: true);

  /// Writes a JSON response with [status].
  static Future<void> json(
    HttpResponse response,
    Map<String, dynamic> body, [
    int status = 200,
  ]) async {
    response.statusCode = status;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
  }
}

AppConfig _config(String base) => AppConfig.internal(
  appName: 'test',
  appVersion: '0.0.0',
  apiBaseUrl: base,
  webSocketUrl: '',
  apiVersion: 'v1',
  flavor: Flavor.development,
  connectionTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 5),
  sendTimeout: const Duration(seconds: 5),
  debugMode: true,
  enableLogging: false,
  featureFlags: const FeatureFlags(),
);

/// Builds a Dio whose requests go through the interceptor and on to the
/// loopback server. [config] carries the server's base URL so the
/// interceptor's bare refresh Dio targets the same server.
Dio _client(AppConfig config, _FakeTokenProvider tokens, _RecordingSink sink) {
  final dio = Dio(BaseOptions(baseUrl: config.resolvedApiUrl));
  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      tokenProvider: tokens,
      config: config,
      logger: LoggerService(flavor: Flavor.development),
      authSessionSink: sink,
    ),
  );
  return dio;
}

void main() {
  group('AuthInterceptor', () {
    test('injects the Bearer token when one is available', () async {
      final tokens = _FakeTokenProvider(accessToken: 'abc');
      String? receivedAuth;
      final server = _TestServer((request) async {
        receivedAuth = request.headers.value(ApiHeaders.authorization);
        await _TestServer.json(request.response, <String, dynamic>{'ok': true});
      });
      await server.start();
      addTearDown(server.stop);

      final dio = _client(_config(server.base), tokens, _RecordingSink());
      await dio.get(Endpoints.me);

      expect(receivedAuth, '${ApiHeaders.bearerPrefix}abc');
    });

    test('omits the Authorization header when no token is stored', () async {
      final tokens = _FakeTokenProvider();
      String? receivedAuth;
      final server = _TestServer((request) async {
        receivedAuth = request.headers.value(ApiHeaders.authorization);
        await _TestServer.json(request.response, <String, dynamic>{'ok': true});
      });
      await server.start();
      addTearDown(server.stop);

      final dio = _client(_config(server.base), tokens, _RecordingSink());
      await dio.get(Endpoints.me);

      expect(receivedAuth, isNull);
    });

    test(
      'on a 401 it refreshes, stores the new token, and retries the call',
      () async {
        final tokens = _FakeTokenProvider(
          accessToken: 'old',
          refreshToken: 'rt',
        );
        final sink = _RecordingSink();
        var meHits = 0;
        late String retryAuth;

        final server = _TestServer((request) async {
          final path = request.uri.path;
          if (path.contains(Endpoints.me)) {
            meHits++;
            if (meHits == 1) {
              request.response.statusCode = 401;
              return;
            }
            retryAuth = request.headers.value(ApiHeaders.authorization) ?? '';
            await _TestServer.json(request.response, <String, dynamic>{
              'ok': true,
            });
            return;
          }
          if (path.contains(Endpoints.refresh)) {
            await _TestServer.json(request.response, <String, dynamic>{
              'access_token': 'new-access',
              'refresh_token': 'new-refresh',
            });
            return;
          }
          request.response.statusCode = 404;
        });
        await server.start();
        addTearDown(server.stop);

        final dio = _client(_config(server.base), tokens, sink);
        final response = await dio.get(Endpoints.me);

        expect(response.statusCode, 200);
        expect(meHits, 2); // original 401 + retry
        expect(tokens.accessToken, 'new-access');
        expect(tokens.refreshToken, 'new-refresh');
        expect(retryAuth, '${ApiHeaders.bearerPrefix}new-access');
        // A successful refresh must NOT flip the auth state.
        expect(sink.unauthenticatedCalls, 0);
      },
    );

    test('on refresh failure it clears tokens and marks the session '
        'unauthenticated (no fake-auth state)', () async {
      final tokens = _FakeTokenProvider(accessToken: 'old', refreshToken: 'rt');
      final sink = _RecordingSink();
      var meHits = 0;

      final server = _TestServer((request) async {
        final path = request.uri.path;
        if (path.contains(Endpoints.me)) {
          meHits++;
          request.response.statusCode = 401;
          return;
        }
        if (path.contains(Endpoints.refresh)) {
          request.response.statusCode = 401; // refresh also rejected
          return;
        }
        request.response.statusCode = 404;
      });
      await server.start();
      addTearDown(server.stop);

      final dio = _client(_config(server.base), tokens, sink);

      // The original 401 error must propagate (no silent swallow).
      await expectLater(dio.get(Endpoints.me), throwsA(isA<DioException>()));

      expect(meHits, 1); // not retried (refresh failed)
      expect(tokens.accessToken, isNull); // tokens cleared
      expect(tokens.refreshToken, isNull);
      expect(sink.unauthenticatedCalls, 1); // session reconciled
    });
  });
}
