import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Dio interceptor that emits structured request / response / error
/// logs through [dart:developer.log].
///
/// Logging is scoped to the `HajeenAI.Network` zone so it can be
/// filtered in the DevTools logging view. In [debugMode] the full
/// request and response bodies are logged (truncated to
/// [_maxBodyLength] characters). Outside debug mode only the method,
/// path, status code, and duration are emitted — never payloads —
/// so this interceptor can safely be enabled in staging builds.
final class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({required bool debugMode}) : _debugMode = debugMode;

  final bool _debugMode;

  /// Maximum number of body characters written to the log.
  static const int _maxBodyLength = 2000;

  /// [developer.log] zone name for all network entries.
  static const String _logName = 'HajeenAI.Network';

  /// Stopwatch map keyed by request hash code, used to compute latency.
  final Map<int, Stopwatch> _timers = {};

  // ── Interceptor overrides ──────────────────────────────────────────────

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _timers[options.hashCode] = Stopwatch()..start();

    final buffer = StringBuffer()
      ..writeln('┌── REQUEST ─────────────────────────────────')
      ..writeln('│ ${options.method}  ${options.uri}');

    if (_debugMode) {
      _writeHeaders(buffer, options.headers);
      _writeBody(buffer, options.data);
    }

    buffer.write('└─────────────────────────────────────────────');
    _log(buffer.toString());

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final elapsed = _stopAndRemove(response.requestOptions.hashCode);

    final buffer = StringBuffer()
      ..writeln('┌── RESPONSE ────────────────────────────────')
      ..writeln(
        '│ ${response.statusCode}  '
        '${response.requestOptions.method}  '
        '${response.requestOptions.uri}  '
        '(${elapsed}ms)',
      );

    if (_debugMode) {
      _writeBody(buffer, response.data);
    }

    buffer.write('└─────────────────────────────────────────────');
    _log(buffer.toString());

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final elapsed = _stopAndRemove(err.requestOptions.hashCode);

    final buffer = StringBuffer()
      ..writeln('┌── ERROR ───────────────────────────────────')
      ..writeln(
        '│ ${err.response?.statusCode ?? err.type.name}  '
        '${err.requestOptions.method}  '
        '${err.requestOptions.uri}  '
        '(${elapsed}ms)',
      )
      ..writeln('│ ${err.message}');

    if (_debugMode && err.response?.data != null) {
      _writeBody(buffer, err.response?.data);
    }

    buffer.write('└─────────────────────────────────────────────');
    _logError(buffer.toString(), err);

    handler.next(err);
  }

  // ── Private helpers ────────────────────────────────────────────────────

  int _stopAndRemove(int key) {
    final watch = _timers.remove(key);
    watch?.stop();
    return watch?.elapsedMilliseconds ?? -1;
  }

  void _writeHeaders(StringBuffer buf, Map<String, dynamic> headers) {
    if (headers.isEmpty) return;
    buf.writeln('│ Headers:');
    for (final entry in headers.entries) {
      final value = entry.key == 'Authorization'
          ? '[REDACTED]'
          : entry.value.toString();
      buf.writeln('│   ${entry.key}: $value');
    }
  }

  void _writeBody(StringBuffer buf, Object? body) {
    if (body == null) return;
    final raw = body.toString();
    final truncated = raw.length > _maxBodyLength
        ? '${raw.substring(0, _maxBodyLength)}…[TRUNCATED]'
        : raw;
    buf.writeln('│ Body: $truncated');
  }

  void _log(String message) {
    developer.log(message, name: _logName, level: 800);
  }

  void _logError(String message, Object error) {
    developer.log(message, name: _logName, level: 900, error: error);
  }
}
