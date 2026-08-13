import 'dart:developer' as developer;

import 'package:ai_chat/core/config/flavor.dart';
import 'package:flutter/foundation.dart';

/// Severity levels supported by [LoggerService].
///
/// Values are ordered from least to most severe; the integer index is
/// used to compare levels without exhaustive switch branches.
enum LogLevel {
  /// Granular tracing information useful during active debugging.
  verbose,

  /// General operational events (service init, route change, etc.).
  info,

  /// Non-fatal anomalies that should be investigated.
  warning,

  /// Errors that interrupted an individual operation but did not crash
  /// the application.
  error,

  /// Critical failures that may cause the application to terminate.
  fatal,
}

/// Centralised, structured logging service for the Hajeen AI
/// application.
///
/// All log output must route through this service so that:
/// - [print] never appears in production code (satisfying the
///   `avoid_print` lint rule).
/// - Log verbosity is gated by [LogLevel] and [Flavor] from a single
///   location.
/// - A remote observability integration (Sentry, Firebase Crashlytics,
///   Datadog, …) can be wired in [_dispatchToRemote] without touching
///   any call site.
///
/// ### Usage
/// ```dart
/// final log = LoggerService(flavor: AppConfig.instance.flavor);
/// log.i('Chat session started', tag: 'ChatBloc');
/// log.e('Token refresh failed', error: e, stackTrace: st);
/// ```
final class LoggerService {
  /// Creates a [LoggerService] for the given [flavor].
  ///
  /// Production builds silence everything below [LogLevel.warning].
  /// Non-production builds emit from [LogLevel.verbose] upward.
  LoggerService({required Flavor flavor}) : _flavor = flavor;

  final Flavor _flavor;

  /// The minimum [LogLevel] that will be forwarded to the output.
  LogLevel get minimumLevel =>
      _flavor.isNonProduction ? LogLevel.verbose : LogLevel.warning;

  // ── Convenience methods ───────────────────────────────────────────────────

  /// Emits a [LogLevel.verbose] entry.
  void v(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => _log(
    LogLevel.verbose,
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );

  /// Emits a [LogLevel.info] entry.
  void i(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => _log(
    LogLevel.info,
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );

  /// Emits a [LogLevel.warning] entry.
  void w(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => _log(
    LogLevel.warning,
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );

  /// Emits a [LogLevel.error] entry.
  void e(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => _log(
    LogLevel.error,
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );

  /// Emits a [LogLevel.fatal] entry.
  void f(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => _log(
    LogLevel.fatal,
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );

  // ── Core dispatch ─────────────────────────────────────────────────────────

  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < minimumLevel.index) return;

    final prefix = _levelPrefix(level);
    final tagPart = tag != null ? ' [$tag]' : '';
    final fullMessage = '$prefix$tagPart $message';

    // Write to dart:developer (visible in DevTools / Xcode console).
    if (kDebugMode || _flavor.isNonProduction) {
      developer.log(
        fullMessage,
        name: 'HajeenAI',
        level: _dartLogLevel(level),
        error: error,
        stackTrace: stackTrace,
        time: DateTime.now(),
      );
    }

    // Forward errors and fatal entries to the remote sink.
    if (level.index >= LogLevel.error.index) {
      _dispatchToRemote(level, message, error: error, stackTrace: stackTrace);
    }
  }

  /// Remote observability integration hook.
  ///
  /// Wire in the appropriate SDK call — e.g.
  /// `Sentry.captureException(error, stackTrace: stackTrace)` or
  /// `FirebaseCrashlytics.instance.recordError(error, stackTrace)` —
  /// when the crash-reporting integration is configured. The method
  /// body is intentionally left without calls so that the service
  /// compiles cleanly before those SDKs are added.
  void _dispatchToRemote(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Integration point: attach remote observability SDK here.
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _levelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return '🔍 VERBOSE';
      case LogLevel.info:
        return 'ℹ️  INFO   ';
      case LogLevel.warning:
        return '⚠️  WARN   ';
      case LogLevel.error:
        return '🔴 ERROR  ';
      case LogLevel.fatal:
        return '💀 FATAL  ';
    }
  }

  /// Maps [LogLevel] to the integer severity expected by [developer.log].
  ///
  /// `dart:developer` uses the same scale as `java.util.logging`:
  /// FINEST = 300, INFO = 800, WARNING = 900, SEVERE = 1000.
  static int _dartLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return 300;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.fatal:
        return 1200;
    }
  }
}
