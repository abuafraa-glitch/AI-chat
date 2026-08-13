/// Sealed response wrapper and structured exception hierarchy for the
/// Hajeen AI network layer.
///
/// Every method on [ApiConsumer] returns a [NetworkResponse<T>] so
/// feature-layer code can pattern-match on success or failure without
/// catching raw exceptions. No [DioException] or platform exception
/// escapes this boundary.
library;

// ---------------------------------------------------------------------------
// Response hierarchy
// ---------------------------------------------------------------------------

/// Sealed base for all API call outcomes.
///
/// Use [fold] or a `switch` expression on the concrete subtype
/// ([NetworkSuccess] / [NetworkError]) to handle both cases.
sealed class NetworkResponse<T> {
  const NetworkResponse();

  /// `true` when this response is a [NetworkSuccess].
  bool get isSuccess => this is NetworkSuccess<T>;

  /// `true` when this response is a [NetworkError].
  bool get isError => this is NetworkError<T>;

  /// Transforms the [NetworkSuccess] payload with [transform], leaving
  /// [NetworkError] responses unchanged.
  NetworkResponse<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      NetworkSuccess<T>(:final T data, :final int statusCode) =>
        NetworkSuccess<R>(data: transform(data), statusCode: statusCode),
      NetworkError<T>(:final NetworkException exception) => NetworkError<R>(
        exception: exception,
      ),
    };
  }

  /// Collapses both variants into a single value of type [R].
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(NetworkException exception) onError,
  }) {
    return switch (this) {
      NetworkSuccess<T>(:final T data) => onSuccess(data),
      NetworkError<T>(:final NetworkException exception) => onError(exception),
    };
  }
}

/// Represents a successful API response carrying a decoded payload.
final class NetworkSuccess<T> extends NetworkResponse<T> {
  const NetworkSuccess({required this.data, required this.statusCode});

  /// Decoded response body.
  final T data;

  /// HTTP status code returned by the server (e.g. 200, 201, 204).
  final int statusCode;
}

/// Represents a failed API call described by a structured [NetworkException].
final class NetworkError<T> extends NetworkResponse<T> {
  const NetworkError({required this.exception});

  /// Structured description of what went wrong.
  final NetworkException exception;
}

// ---------------------------------------------------------------------------
// Exception hierarchy
// ---------------------------------------------------------------------------

/// Base class for all network-layer exceptions produced by [ApiClient].
///
/// Concrete subtypes cover the most common failure modes; catch
/// [NetworkException] when you want to handle any network failure, or
/// a specific subtype when you need to branch on a particular failure.
sealed class NetworkException implements Exception {
  const NetworkException({required this.message, this.statusCode});

  /// Human-readable description (English; for logging only).
  final String message;

  /// HTTP status code, when available.
  final int? statusCode;

  @override
  String toString() => '$runtimeType(statusCode: $statusCode, msg: $message)';
}

/// The device has no internet connectivity at call time.
final class NoConnectionException extends NetworkException {
  const NoConnectionException()
    : super(message: 'No internet connection available.');
}

/// The connection or receive timeout was exceeded.
final class RequestTimeoutException extends NetworkException {
  const RequestTimeoutException({super.statusCode})
    : super(message: 'The request timed out.');
}

/// The server returned HTTP 401 and the token refresh flow also failed.
///
/// The caller should redirect the user to the authentication screen.
final class UnauthorizedException extends NetworkException {
  const UnauthorizedException({required String message})
    : super(message: message, statusCode: 401);
}

/// The server returned HTTP 403 — authenticated but not permitted.
final class ForbiddenException extends NetworkException {
  const ForbiddenException({required String message})
    : super(message: message, statusCode: 403);
}

/// The requested resource does not exist (HTTP 404).
final class NotFoundException extends NetworkException {
  const NotFoundException({required String message})
    : super(message: message, statusCode: 404);
}

/// The request conflicts with the current server state (HTTP 409).
final class ConflictException extends NetworkException {
  const ConflictException({required String message})
    : super(message: message, statusCode: 409);
}

/// The server returned HTTP 422 — semantically invalid payload.
final class UnprocessableEntityException extends NetworkException {
  const UnprocessableEntityException({required String message})
    : super(message: message, statusCode: 422);
}

/// The client has exceeded the server rate limit (HTTP 429).
final class RateLimitException extends NetworkException {
  const RateLimitException({this.retryAfterSeconds})
    : super(message: 'Rate limit exceeded.', statusCode: 429);

  /// Seconds to wait before the next attempt, as instructed by the server.
  final int? retryAfterSeconds;
}

/// A 4xx error not covered by the specific types above.
final class BadRequestException extends NetworkException {
  const BadRequestException({required String message, super.statusCode})
    : super(message: message);
}

/// The server returned a 5xx error.
final class ServerException extends NetworkException {
  const ServerException({required String message, super.statusCode})
    : super(message: message);
}

/// The request was cancelled by the caller via a cancel token.
final class RequestCancelledException extends NetworkException {
  const RequestCancelledException()
    : super(message: 'The request was cancelled.');
}

/// An SSL / TLS certificate problem was detected.
final class CertificateException extends NetworkException {
  const CertificateException()
    : super(message: 'SSL certificate verification failed.');
}

/// An error that does not fit any of the typed categories above.
final class UnknownNetworkException extends NetworkException {
  const UnknownNetworkException({required String message, super.statusCode})
    : super(message: message);
}
