import 'package:ai_chat/core/config/app_config.dart';
import 'package:ai_chat/core/constants/api_constants.dart';
import 'package:ai_chat/core/network/api_consumer.dart';
import 'package:ai_chat/core/network/interceptors/auth_interceptor.dart';
import 'package:ai_chat/core/network/interceptors/logging_interceptor.dart';
import 'package:ai_chat/core/network/interceptors/retry_interceptor.dart';
import 'package:ai_chat/core/network/network_info.dart';
import 'package:ai_chat/core/services/logger_service.dart';
import 'package:dio/dio.dart';

/// Factory that constructs a fully-configured [Dio] instance for
/// the Hajeen AI REST API.
///
/// The created instance is intended to be a **long-lived singleton**
/// managed by the DI container. Do not call [create] more than once
/// per application lifecycle; pass the returned [Dio] instance to
/// [ApiClient] through the DI graph.
///
/// ### Interceptor stack (request order)
/// 1. [AuthInterceptor] — injects Bearer token and per-request headers,
///    handles 401 → token refresh → retry.
/// 2. [RetryInterceptor] — retries idempotent requests on transient
///    network or server errors with exponential backoff.
/// 3. [LoggingInterceptor] — emits structured log entries via
///    `dart:developer`; added only when [AppConfig.enableLogging] is
///    `true`.
///
/// Errors from lower interceptors bubble up through higher ones in
/// reverse order (Dio's standard behaviour).
abstract final class DioFactory {
  const DioFactory._();

  /// Builds and returns a configured [Dio] instance.
  ///
  /// [config]        — immutable environment configuration; call
  ///                   [AppConfig.initialize] before this factory.
  /// [tokenProvider] — supplies / persists authentication tokens;
  ///                   implementation lives in the services layer.
  /// [networkInfo]   — checked by [RetryInterceptor] before each retry
  ///                   to avoid pointless attempts while offline.
  static Dio create({
    required AppConfig config,
    required TokenProvider tokenProvider,
    required NetworkInfo networkInfo,
    required LoggerService logger,
    AuthSessionSink? authSessionSink,
    AuthSessionSink? Function()? authSessionSinkProvider,
  }) {
    final dio = Dio()
      ..options = BaseOptions(
        baseUrl: config.resolvedApiUrl,
        connectTimeout: config.connectionTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.sendTimeout,
        headers: <String, String>{
          ApiHeaders.contentType: ApiContentType.jsonUtf8,
          ApiHeaders.accept: ApiContentType.json,
        },
      );

    dio.interceptors.addAll(<Interceptor>[
      AuthInterceptor(
        dio: dio,
        tokenProvider: tokenProvider,
        config: config,
        logger: logger,
        authSessionSink: authSessionSink,
        authSessionSinkProvider: authSessionSinkProvider,
      ),
      RetryInterceptor(dio: dio, networkInfo: networkInfo),
      if (config.enableLogging) LoggingInterceptor(debugMode: config.debugMode),
    ]);

    return dio;
  }
}
