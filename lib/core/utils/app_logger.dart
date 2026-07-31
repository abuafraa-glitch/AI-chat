import 'dart:developer' as developer;
import 'package:ai_chat/core/config/app_config.dart';
import 'package:ai_chat/core/config/flavor.dart';
import 'package:ai_chat/core/constants/app_strings.dart';

/// Severity levels supported by the [AppLogger].
enum LoggerLevel {
  /// Granular tracing information for debugging.
  debug,

  /// General operational events.
  info,

  /// Non-fatal anomalies that should be investigated.
  warning,

  /// Errors that interrupted an individual operation.
  error,

  /// Critical failures that may cause the application to terminate.
  critical,
}

/// Centralized logging utility for the Hajeen AI application.
///
/// This utility provides a unified way to log messages, exceptions, and
/// stack traces across the application. It respects the current environment
/// (Development, Staging, Production) to gate log verbosity.
abstract final class AppLogger {
  const AppLogger._();

  /// Logs a [LoggerLevel.debug] message.
  static void debug(String message, {String tag = AppStrings.appTag, Object? error, StackTrace? stackTrace}) {
    _log(LoggerLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Logs an [LoggerLevel.info] message.
  static void info(String message, {String tag = AppStrings.appTag, Object? error, StackTrace? stackTrace}) {
    _log(LoggerLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Logs a [LoggerLevel.warning] message.
  static void warning(String message, {String tag = AppStrings.appTag, Object? error, StackTrace? stackTrace}) {
    _log(LoggerLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Logs an [LoggerLevel.error] message.
  static void error(String message, {String tag = AppStrings.appTag, Object? error, StackTrace? stackTrace}) {
    _log(LoggerLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Logs a [LoggerLevel.critical] message.
  static void critical(String message, {String tag = AppStrings.appTag, Object? error, StackTrace? stackTrace}) {
    _log(LoggerLevel.critical, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Internal logging logic that filters by level and environment.
  static void _log(
    LoggerLevel level,
    String message, {
    required String tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_shouldLog(level)) return;

    final time = DateTime.now().toIso8601String();
    final levelName = level.name.toUpperCase();
    final formattedMessage = '[$time] [$levelName] [$tag] $message';

    developer.log(
      formattedMessage,
      name: tag,
      level: _toDeveloperLevel(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Determines if a log entry should be emitted based on the current flavor.
  static bool _shouldLog(LoggerLevel level) {
    if (!AppConfig.instance.enableLogging) return false;

    final flavor = AppConfig.instance.flavor;
    return switch (flavor) {
      Flavor.development => true, // Log everything in development.
      Flavor.staging => level.index >= LoggerLevel.info.index,
      Flavor.production => level.index >= LoggerLevel.warning.index,
    };
  }

  /// Maps [LoggerLevel] to [developer.log] integer levels.
  static int _toDeveloperLevel(LoggerLevel level) {
    return switch (level) {
      LoggerLevel.debug => 500,
      LoggerLevel.info => 800,
      LoggerLevel.warning => 900,
      LoggerLevel.error => 1000,
      LoggerLevel.critical => 1200,
    };
  }
}
