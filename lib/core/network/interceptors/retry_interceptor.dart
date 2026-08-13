import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:ai_chat/core/constants/api_constants.dart';
import 'package:ai_chat/core/network/network_info.dart';
import 'package:dio/dio.dart';

/// Dio interceptor that retries **idempotent** requests that fail due
/// to transient network conditions or server-side errors (5xx).
///
/// ### Retry policy
/// - Only GET, PUT, DELETE, and HEAD requests are eligible (safe
///   idempotent methods). POST and PATCH are never retried automatically
///   because re-sending them may cause duplicate state changes on the server.
/// - A request is retried on [DioExceptionType.connectionTimeout],
///   [DioExceptionType.receiveTimeout], [DioExceptionType.connectionError],
///   and on HTTP 5xx responses.
/// - 4xx errors (client errors) are never retried.
/// - The number of attempts is capped at [ApiDefaults.maxRetries].
/// - Delays follow a **full jitter exponential backoff** strategy:
///   `delay = random(0, min(cap, base * 2^attempt))`, clamped between
///   [ApiDefaults.retryBackoffBaseMs] and [ApiDefaults.retryBackoffCapMs].
/// - Before each retry the device connectivity is checked; if the device
///   is offline the retry is aborted immediately and the original error
///   is propagated.
final class RetryInterceptor extends Interceptor {
  RetryInterceptor({required Dio dio, required NetworkInfo networkInfo})
    : _dio = dio,
      _networkInfo = networkInfo;

  final Dio _dio;
  final NetworkInfo _networkInfo;

  static const String _logName = 'HajeenAI.Network.Retry';
  static const String _retryCountKey = '_retry_count';
  static final math.Random _random = math.Random();

  // ── Interceptor override ───────────────────────────────────────────────

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_retryCountKey] as int?) ?? 0;

    if (!_shouldRetry(err, attempt)) {
      handler.next(err);
      return;
    }

    final connected = await _networkInfo.isConnected;
    if (!connected) {
      developer.log(
        'Retry aborted: device is offline (attempt $attempt).',
        name: _logName,
      );
      handler.next(err);
      return;
    }

    final delay = _computeBackoff(attempt);
    developer.log(
      'Retrying ${options.method} ${options.path} '
      '(attempt ${attempt + 1}/${ApiDefaults.maxRetries}) '
      'after ${delay.inMilliseconds}ms.',
      name: _logName,
    );

    await Future<void>.delayed(delay);

    options.extra[_retryCountKey] = attempt + 1;

    try {
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────

  /// Returns `true` when [error] qualifies for an automatic retry.
  bool _shouldRetry(DioException error, int attempt) {
    if (attempt >= ApiDefaults.maxRetries) return false;
    if (!_isIdempotent(error.requestOptions)) return false;

    return switch (error.type) {
      DioExceptionType.connectionTimeout => true,
      DioExceptionType.sendTimeout => true,
      DioExceptionType.receiveTimeout => true,
      DioExceptionType.transformTimeout => true,
      DioExceptionType.connectionError => true,
      DioExceptionType.badResponse => _isRetryableStatus(
        error.response?.statusCode,
      ),
      DioExceptionType.cancel => false,
      DioExceptionType.badCertificate => false,
      DioExceptionType.unknown => false,
    };
  }

  /// Returns `true` for HTTP methods that are safe to replay.
  bool _isIdempotent(RequestOptions options) {
    return switch (options.method.toUpperCase()) {
      'GET' => true,
      'HEAD' => true,
      'PUT' => true,
      'DELETE' => true,
      _ => false,
    };
  }

  /// Returns `true` for 5xx status codes (transient server errors).
  bool _isRetryableStatus(int? statusCode) {
    if (statusCode == null) return false;
    return statusCode >= HttpStatusCode.internalServerError;
  }

  /// Computes the backoff duration for [attempt] (0-based) using a
  /// full-jitter exponential strategy.
  ///
  /// Formula: `random(0, min(cap, base × 2^attempt))`
  Duration _computeBackoff(int attempt) {
    const base = ApiDefaults.retryBackoffBaseMs;
    const cap = ApiDefaults.retryBackoffCapMs;
    final ceiling = math.min(cap, base * math.pow(2, attempt).toInt());
    final ms = _random.nextInt(math.max(1, ceiling));
    return Duration(milliseconds: ms);
  }
}
