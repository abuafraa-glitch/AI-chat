import 'dart:async';
import 'dart:io';

import 'package:ai_chat/core/config/app_config.dart';
import 'package:ai_chat/core/constants/api_constants.dart';
import 'package:ai_chat/core/network/api_consumer.dart';
import 'package:ai_chat/core/network/endpoints.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Dio interceptor that handles authentication token lifecycle.
///
/// Responsibilities:
/// 1. Injects the `Authorization: Bearer <token>` header on every
///    outbound request (when a token is available).
/// 2. Attaches per-request metadata headers (request-id, platform,
///    app version).
/// 3. On HTTP 401, attempts a single token refresh via a clean Dio
///    instance (bypassing this interceptor to avoid infinite loops).
///    — If refresh succeeds, all queued requests are retried once with
///      the new access token.
///    — If refresh fails (bad token, network error, etc.), all tokens
///      are cleared and every waiting request receives the original 401.
final class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenProvider tokenProvider,
    required AppConfig config,
  })  : _dio = dio,
        _tokenProvider = tokenProvider,
        _config = config;

  final Dio _dio;
  final TokenProvider _tokenProvider;
  final AppConfig _config;

  /// Guards concurrent 401 handling: only one refresh is performed
  /// at a time; all other 401s wait for the same [Completer].
  Completer<bool>? _refreshCompleter;

  static const Uuid _uuid = Uuid();

  // ── Interceptor overrides ──────────────────────────────────────────────

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _tokenProvider.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers[ApiHeaders.authorization] =
            '${ApiHeaders.bearerPrefix}$token';
      }
      options.headers[ApiHeaders.requestId] = _uuid.v4();
      options.headers[ApiHeaders.appVersion] = _config.appVersion;
      options.headers[ApiHeaders.platform] = Platform.operatingSystem;
      options.headers[ApiHeaders.clientName] = _config.appName;
    } catch (_) {
      // Never block a request because of a header-injection failure.
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == HttpStatusCode.unauthorized &&
        !_isRefreshRequest(err.requestOptions)) {
      await _handleUnauthorized(err, handler);
      return;
    }
    handler.next(err);
  }

  // ── Private helpers ────────────────────────────────────────────────────

  /// Returns `true` when [options] targets the token-refresh endpoint,
  /// preventing infinite refresh loops.
  bool _isRefreshRequest(RequestOptions options) =>
      options.path.contains(Endpoints.refresh);

  /// Orchestrates the token-refresh flow.
  ///
  /// If a refresh is already in flight, the caller waits for its result
  /// instead of starting a second one.
  Future<void> _handleUnauthorized(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (_refreshCompleter != null) {
      final success = await _refreshCompleter!.future;
      if (success) {
        try {
          handler.resolve(await _retryRequest(error.requestOptions));
          return;
        } catch (_) {
          handler.next(error);
          return;
        }
      }
      handler.next(error);
      return;
    }

    _refreshCompleter = Completer<bool>();
    try {
      final refreshed = await _performTokenRefresh();
      _refreshCompleter!.complete(refreshed);

      if (refreshed) {
        try {
          handler.resolve(await _retryRequest(error.requestOptions));
        } catch (_) {
          handler.next(error);
        }
      } else {
        handler.next(error);
      }
    } catch (_) {
      _refreshCompleter!.complete(false);
      handler.next(error);
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Calls the refresh endpoint with a dedicated Dio instance (no
  /// interceptors) so that a 401 on the refresh call does not recurse.
  Future<bool> _performTokenRefresh() async {
    final refreshToken = await _tokenProvider.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _tokenProvider.clearTokens();
      return false;
    }

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: _config.resolvedApiUrl,
        connectTimeout: _config.connectionTimeout,
        receiveTimeout: _config.receiveTimeout,
        headers: {
          ApiHeaders.contentType: ApiContentType.jsonUtf8,
          ApiHeaders.accept: ApiContentType.json,
        },
      ),
    );

    try {
      final response = await refreshDio.post<Map<String, dynamic>>(
        Endpoints.refresh,
        data: <String, String>{'refresh_token': refreshToken},
      );

      final data = response.data;
      if (data == null) {
        await _tokenProvider.clearTokens();
        return false;
      }

      final newAccessToken = data['access_token'];
      final newRefreshToken = data['refresh_token'];

      if (newAccessToken is! String || newAccessToken.isEmpty) {
        await _tokenProvider.clearTokens();
        return false;
      }

      await _tokenProvider.writeAccessToken(newAccessToken);
      if (newRefreshToken is String && newRefreshToken.isNotEmpty) {
        await _tokenProvider.writeRefreshToken(newRefreshToken);
      }
      return true;
    } on DioException catch (_) {
      await _tokenProvider.clearTokens();
      return false;
    }
  }

  /// Retries [options] with the freshly stored access token.
  Future<Response<dynamic>> _retryRequest(RequestOptions options) async {
    final token = await _tokenProvider.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers[ApiHeaders.authorization] =
          '${ApiHeaders.bearerPrefix}$token';
    }
    return _dio.fetch<dynamic>(options);
  }
}
