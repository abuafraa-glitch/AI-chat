import 'package:ai_chat/core/constants/app_strings.dart';
import 'package:ai_chat/core/errors/exceptions.dart';
import 'package:ai_chat/core/errors/failures.dart';
import 'package:ai_chat/core/services/logger_service.dart';
import 'package:dio/dio.dart';

/// Centralized error handler for the Hajeen AI application.
///
/// This class is responsible for intercepting all exceptions, logging them
/// appropriately, and mapping them to domain-layer [Failure] objects.
/// It provides a unified way to handle errors across different layers
/// (Network, Storage, AI, etc.).
final class ErrorHandler {
  ErrorHandler({required LoggerService logger}) : _logger = logger;

  final LoggerService _logger;

  /// Handles an error by logging it and converting it to a [Failure].
  ///
  /// This is the primary entry point for error handling in the application.
  /// It classifies the [error] and returns the most appropriate [Failure]
  /// subtype.
  Failure handle(Object error, [StackTrace? stackTrace]) {
    _logError(error, stackTrace);

    if (error is AppException) {
      return _mapAppExceptionToFailure(error);
    }

    if (error is DioException) {
      return _mapDioExceptionToFailure(error);
    }

    return _handleUnknownError(error);
  }

  /// Maps [AppException] subtypes to their corresponding [Failure] subtypes.
  Failure _mapAppExceptionToFailure(AppException exception) {
    final message = exception.message;
    final code = exception.code;
    final metadata = exception.metadata;

    return switch (exception) {
      ServerException() => ServerFailure(message: message, code: code, metadata: metadata),
      NetworkException() => NetworkFailure(message: message, code: code, metadata: metadata),
      CacheException() => CacheFailure(message: message, code: code, metadata: metadata),
      TimeoutException() => TimeoutFailure(message: message, code: code, metadata: metadata),
      UnauthorizedException() => UnauthorizedFailure(message: message, code: code, metadata: metadata),
      ForbiddenException() => ForbiddenFailure(message: message, code: code, metadata: metadata),
      ValidationException() => ValidationFailure(message: message, code: code, metadata: metadata),
      NotFoundException() => NotFoundFailure(message: message, code: code, metadata: metadata),
      ParsingException() => ParsingFailure(message: message, code: code, metadata: metadata),
      StorageException() => StorageFailure(message: message, code: code, metadata: metadata),
      WebSocketException() => WebSocketFailure(message: message, code: code, metadata: metadata),
      StreamingException() => StreamingFailure(message: message, code: code, metadata: metadata),
      FileException() => FileFailure(message: message, code: code, metadata: metadata),
      AuthenticationException() => AuthenticationFailure(message: message, code: code, metadata: metadata),
      SubscriptionException() => SubscriptionFailure(message: message, code: code, metadata: metadata),
      PaymentException() => PaymentFailure(message: message, code: code, metadata: metadata),
      AIException() => AIFailure(message: message, code: code, metadata: metadata),
      RAGException() => RAGFailure(message: message, code: code, metadata: metadata),
      AgentException() => AgentFailure(message: message, code: code, metadata: metadata),
      RateLimitException() => RateLimitFailure(message: message, code: code, metadata: metadata),
      UnknownException() => UnknownFailure(message: message, code: code, metadata: metadata),
      _ => UnknownFailure(message: message, code: code, metadata: metadata),
    };
  }

  /// Maps [DioException] to the appropriate [Failure].
  ///
  /// This ensures that even if a Dio error escapes the network layer,
  /// it is handled consistently.
  Failure _mapDioExceptionToFailure(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const TimeoutFailure(
          message: 'The request timed out. Please try again.',
          code: AppStrings.errorCodeTimeout,
        ),
      DioExceptionType.connectionError => const NetworkFailure(
          message: 'No internet connection. Please check your network.',
          code: AppStrings.errorCodeNoConnection,
        ),
      DioExceptionType.badResponse => _mapDioBadResponse(error.response),
      DioExceptionType.cancel => const NetworkFailure(
          message: 'Request was cancelled.',
          code: 'ERR_CANCELLED',
        ),
      _ => const UnknownFailure(
          message: 'A network error occurred.',
          code: AppStrings.errorCodeUnknown,
        ),
    };
  }

  /// Maps Dio bad responses (4xx, 5xx) to failures.
  Failure _mapDioBadResponse(Response<dynamic>? response) {
    final statusCode = response?.statusCode ?? 0;
    final message = _extractMessageFromResponse(response);

    if (statusCode >= 500) {
      return ServerFailure(
        message: message,
        code: AppStrings.errorCodeServer,
      );
    }

    return switch (statusCode) {
      401 => UnauthorizedFailure(message: message, code: AppStrings.errorCodeUnauthenticated),
      403 => ForbiddenFailure(message: message, code: AppStrings.errorCodeForbidden),
      404 => NotFoundFailure(message: message, code: AppStrings.errorCodeNotFound),
      422 || 400 => ValidationFailure(message: message, code: AppStrings.errorCodeValidation),
      429 => RateLimitFailure(message: message, code: AppStrings.errorCodeRateLimited),
      _ => UnknownFailure(message: message, code: AppStrings.errorCodeUnknown),
    };
  }

  /// Extracts a human-readable message from a response object.
  String _extractMessageFromResponse(Response<dynamic>? response) {
    if (response == null) return 'An unexpected error occurred.';
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ?? data['error']?.toString() ?? 'Server error occurred.';
    }
    return 'Server returned an error (${response.statusCode}).';
  }

  /// Handles completely unknown errors by returning an [UnknownFailure].
  Failure _handleUnknownError(Object error) {
    return const UnknownFailure(
      message: 'An unexpected error occurred. Please try again later.',
      code: AppStrings.errorCodeUnknown,
    );
  }

  /// Logs the error using [LoggerService].
  void _logError(Object error, [StackTrace? stackTrace]) {
    final tag = _getLogTagForError(error);
    final message = error is AppException ? exceptionToTechnicalMessage(error) : error.toString();

    _logger.e(
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Returns a suitable log tag based on the error type.
  String _getLogTagForError(Object error) {
    return switch (error) {
      NetworkException() || DioException() => AppStrings.logTagNetwork,
      StorageException() || CacheException() => AppStrings.logTagStorage,
      AuthenticationException() || UnauthorizedException() => AppStrings.logTagAuth,
      WebSocketException() || StreamingException() => AppStrings.logTagWebSocket,
      _ => 'ErrorHandler',
    };
  }

  /// Converts an [AppException] to a detailed technical message for developers.
  String exceptionToTechnicalMessage(AppException exception) {
    return 'AppException[${exception.code}]: ${exception.message}';
  }
}
