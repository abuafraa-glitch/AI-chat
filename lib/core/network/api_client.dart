import 'dart:convert';

import 'package:ai_chat/core/constants/api_constants.dart';
import 'package:ai_chat/core/network/api_consumer.dart';
import 'package:ai_chat/core/network/network_response.dart';
import 'package:dio/dio.dart';

/// Concrete [ApiConsumer] implementation backed by [Dio].
///
/// Every public method catches [DioException] at the boundary and maps
/// it to a typed [NetworkException] subtype so that no Dio-specific
/// exception escapes into the domain or feature layers.
///
/// ### Cancel-token lifecycle
/// Tokens are stored in an internal map keyed by the caller-supplied
/// string. The entry is removed:
/// - automatically when the request completes (success or error), and
/// - explicitly via [cancelRequest].
///
/// ### Thread safety
/// [Dio] handles its own request queuing; this class does not add
/// additional synchronisation. Do not share a single [ApiClient]
/// instance across isolates.
final class ApiClient implements ApiConsumer {
  ApiClient({required Dio dio}) : _dio = dio;

  final Dio _dio;
  final Map<String, CancelToken> _cancelTokens = {};

  // ── ApiConsumer — core verbs ───────────────────────────────────────────

  @override
  Future<NetworkResponse<T>> get<T>({
    required String path,
    required T Function(dynamic json) fromJson,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? cancelToken,
  }) async {
    final token = _getOrCreateToken(cancelToken);
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: token,
      );
      return NetworkSuccess<T>(
        data: fromJson(response.data),
        statusCode: response.statusCode ?? HttpStatusCode.ok,
      );
    } on DioException catch (e) {
      return NetworkError<T>(exception: _mapDioException(e));
    } finally {
      _removeToken(cancelToken);
    }
  }

  @override
  Future<NetworkResponse<T>> post<T>({
    required String path,
    required T Function(dynamic json) fromJson,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? cancelToken,
  }) async {
    final token = _getOrCreateToken(cancelToken);
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: token,
      );
      return NetworkSuccess<T>(
        data: fromJson(response.data),
        statusCode: response.statusCode ?? HttpStatusCode.created,
      );
    } on DioException catch (e) {
      return NetworkError<T>(exception: _mapDioException(e));
    } finally {
      _removeToken(cancelToken);
    }
  }

  @override
  Future<NetworkResponse<T>> put<T>({
    required String path,
    required T Function(dynamic json) fromJson,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? cancelToken,
  }) async {
    final token = _getOrCreateToken(cancelToken);
    try {
      final response = await _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: token,
      );
      return NetworkSuccess<T>(
        data: fromJson(response.data),
        statusCode: response.statusCode ?? HttpStatusCode.ok,
      );
    } on DioException catch (e) {
      return NetworkError<T>(exception: _mapDioException(e));
    } finally {
      _removeToken(cancelToken);
    }
  }

  @override
  Future<NetworkResponse<T>> patch<T>({
    required String path,
    required T Function(dynamic json) fromJson,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? cancelToken,
  }) async {
    final token = _getOrCreateToken(cancelToken);
    try {
      final response = await _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: token,
      );
      return NetworkSuccess<T>(
        data: fromJson(response.data),
        statusCode: response.statusCode ?? HttpStatusCode.ok,
      );
    } on DioException catch (e) {
      return NetworkError<T>(exception: _mapDioException(e));
    } finally {
      _removeToken(cancelToken);
    }
  }

  @override
  Future<NetworkResponse<void>> delete({
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? cancelToken,
  }) async {
    final token = _getOrCreateToken(cancelToken);
    try {
      final response = await _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: token,
      );
      return NetworkSuccess<void>(
        data: null,
        statusCode: response.statusCode ?? HttpStatusCode.noContent,
      );
    } on DioException catch (e) {
      return NetworkError<void>(exception: _mapDioException(e));
    } finally {
      _removeToken(cancelToken);
    }
  }

  // ── ApiConsumer — file upload ──────────────────────────────────────────

  @override
  Future<NetworkResponse<T>> uploadFile<T>({
    required String path,
    required String filePath,
    required String fileFieldName,
    required T Function(dynamic json) fromJson,
    Map<String, String>? additionalFields,
    UploadProgressCallback? onSendProgress,
    String? cancelToken,
  }) async {
    final token = _getOrCreateToken(cancelToken);
    try {
      final formFields = <String, dynamic>{};

      if (additionalFields != null) {
        for (final entry in additionalFields.entries) {
          formFields[entry.key] = entry.value;
        }
      }

      formFields[fileFieldName] = await MultipartFile.fromFile(filePath);

      final formData = FormData.fromMap(formFields);

      final response = await _dio.post<dynamic>(
        path,
        data: formData,
        options: Options(contentType: ApiContentType.multipartFormData),
        onSendProgress: onSendProgress,
        cancelToken: token,
      );

      return NetworkSuccess<T>(
        data: fromJson(response.data),
        statusCode: response.statusCode ?? HttpStatusCode.created,
      );
    } on DioException catch (e) {
      return NetworkError<T>(exception: _mapDioException(e));
    } finally {
      _removeToken(cancelToken);
    }
  }

  // ── ApiConsumer — SSE streaming ────────────────────────────────────────

  @override
  Stream<String> streamRequest({
    required String path,
    Object? data,
    Map<String, String>? headers,
    String? cancelToken,
  }) async* {
    final token = cancelToken != null
        ? (_cancelTokens[cancelToken] ??= CancelToken())
        : CancelToken();

    try {
      final response = await _dio.post<ResponseBody>(
        path,
        data: data,
        // Streaming must not be killed by the default receive timeout:
        // token generation can take longer than a regular REST response.
        // A zero duration disables the receive timeout for this request
        // only, while connection/send timeouts still protect the caller.
        options: Options(
          responseType: ResponseType.stream,
          headers: headers,
          receiveTimeout: const Duration(milliseconds: 0),
        ),
        cancelToken: token,
      );

      final body = response.data;
      if (body == null) return;

      await for (final chunk in body.stream) {
        yield utf8.decode(chunk, allowMalformed: true);
      }
    } on DioException catch (e) {
      if (e.type != DioExceptionType.cancel) {
        throw _mapDioException(e);
      }
    } finally {
      _removeToken(cancelToken);
    }
  }

  // ── ApiConsumer — cancellation ─────────────────────────────────────────

  @override
  void cancelRequest(String cancelToken) {
    final token = _cancelTokens.remove(cancelToken);
    token?.cancel('Request cancelled by caller.');
  }

  // ── Private helpers ────────────────────────────────────────────────────

  /// Returns the existing [CancelToken] for [key], or creates and
  /// stores a new one. When [key] is `null`, an anonymous token is
  /// returned (not stored, cannot be cancelled via [cancelRequest]).
  CancelToken _getOrCreateToken(String? key) {
    if (key == null) return CancelToken();
    return _cancelTokens.putIfAbsent(key, CancelToken.new);
  }

  /// Removes the [CancelToken] entry for [key] (if any) after a
  /// request completes or fails, preventing unbounded map growth.
  void _removeToken(String? key) {
    if (key != null) _cancelTokens.remove(key);
  }

  // ── Exception mapping ──────────────────────────────────────────────────

  /// Converts a [DioException] into the appropriate [NetworkException]
  /// subtype. This method is the single translation point between Dio
  /// and the domain layer; all callers rely on it.
  NetworkException _mapDioException(DioException error) {
    return switch (error.type) {
      DioExceptionType.cancel => const RequestCancelledException(),
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => RequestTimeoutException(
        statusCode: error.response?.statusCode,
      ),
      DioExceptionType.connectionError => const NoConnectionException(),
      DioExceptionType.badCertificate => const CertificateException(),
      DioExceptionType.badResponse => _mapBadResponse(error),
      DioExceptionType.unknown => UnknownNetworkException(
        message: error.message ?? 'Unknown error.',
      ),
    };
  }

  /// Translates a [DioExceptionType.badResponse] into a typed exception
  /// using the HTTP status code.
  NetworkException _mapBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final message = _extractErrorMessage(error.response);

    return switch (statusCode) {
      HttpStatusCode.unauthorized => UnauthorizedException(message: message),
      HttpStatusCode.forbidden => ForbiddenException(message: message),
      HttpStatusCode.notFound => NotFoundException(message: message),
      HttpStatusCode.conflict => ConflictException(message: message),
      HttpStatusCode.unprocessableEntity => UnprocessableEntityException(
        message: message,
      ),
      HttpStatusCode.tooManyRequests => RateLimitException(
        retryAfterSeconds: _parseRetryAfterHeader(error.response?.headers),
      ),
      _ when (statusCode ?? 0) >= HttpStatusCode.internalServerError =>
        ServerException(message: message, statusCode: statusCode),
      _ when (statusCode ?? 0) >= HttpStatusCode.badRequest =>
        BadRequestException(message: message, statusCode: statusCode),
      _ => UnknownNetworkException(message: message, statusCode: statusCode),
    };
  }

  /// Extracts a human-readable message from the server error payload.
  ///
  /// The backend is expected to return `{"message": "..."}` or
  /// `{"error": "..."}` on failure. Falls back to a generic string
  /// when neither key is present.
  String _extractErrorMessage(Response<dynamic>? response) {
    if (response == null) return 'An unexpected error occurred.';

    final body = response.data;
    if (body is Map<String, dynamic>) {
      final message = body['message'];
      if (message is String && message.isNotEmpty) return message;
      final error = body['error'];
      if (error is String && error.isNotEmpty) return error;
    }

    return 'Server returned status ${response.statusCode}.';
  }

  /// Parses the `Retry-After` header into an integer seconds value.
  int? _parseRetryAfterHeader(Headers? headers) {
    final raw = headers?.value(ApiHeaders.retryAfter);
    if (raw == null) return null;
    return int.tryParse(raw);
  }
}
