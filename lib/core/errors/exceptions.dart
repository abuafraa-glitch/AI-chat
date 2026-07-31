import 'package:ai_chat/core/constants/app_strings.dart';

/// Base exception class for the Hajeen AI platform.
///
/// All specialized exceptions must extend this class to ensure consistent
/// error handling, logging, and failure mapping across the application.
abstract class AppException implements Exception {
  const AppException({
    required this.message,
    this.code = AppStrings.errorCodeUnknown,
    this.cause,
    this.metadata,
    this.stackTrace,
  });

  /// A human-readable message describing the error.
  final String message;

  /// A machine-readable error code for classification and logic.
  final String code;

  /// The underlying cause of this exception, if any.
  final Object? cause;

  /// Additional contextual data related to the error.
  final Map<String, dynamic>? metadata;

  /// The stack trace associated with the error, if captured.
  final StackTrace? stackTrace;

  @override
  String toString() {
    final buffer = StringBuffer()
      ..write(runtimeType)
      ..write('(code: ')
      ..write(code)
      ..write(', message: ')
      ..write(message)
      ..write(')');
    if (cause != null) {
      buffer.write('\nCause: $cause');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a server-side error occurs (HTTP 5xx).
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.code = AppStrings.errorCodeServer,
    super.cause,
    super.metadata,
    super.stackTrace,
  });
}

/// Exception thrown when a network-level error occurs (e.g., DNS, Socket).
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code = AppStrings.errorCodeNoConnection,
    super.cause,
    super.metadata,
    super.stackTrace,
  });
}

/// Exception thrown when a local or remote caching operation fails.
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code = 'ERR_CACHE',
    super.cause,
    super.metadata,
    super.stackTrace,
  });
}

/// Exception thrown when an operation exceeds its time limit.
class TimeoutException extends AppException {
  const TimeoutException({
    required super.message,
    super.code = AppStrings.errorCodeTimeout,
    super.cause,
    super.metadata,
    super.stackTrace,
  });
}

/// Exception thrown when the user is not authenticated (HTTP 401).
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    required super.message,
    super.code = AppStrings.errorCodeUnauthenticated,
    super.cause,
    super.metadata,
    super.stackTrace,
  });
}

/// Exception thrown when the user lacks permission for an action (HTTP 403).
class ForbiddenException extends AppException {
  const ForbiddenException({
    required super.message,
    super.code = AppStrings.errorCodeForbidden,
    super.cause,
    super.metadata,
    super.stackTrace,
  });
}

/// Exception thrown when request data fails validation (HTTP 400/422).
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code = AppStrings.errorCodeValidation,
    super.cause,
    super.metadata,
    super.stackTrace,
  });
}

/// Exception thrown when a requested resource is not found (HTTP 404).
class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.code = AppStrings.errorCodeNotFound,
    super.cause,
    super.metadata,
    super.stackTrace,
  });
}

/// Exception thrown when data parsing or serialization fails.
class ParsingException extends AppException {
  const ParsingException({
    required super.message,
    super.code = 'ERR_PARSING',
    super.cause,
    super.metadata,
    super.stackTrace,
  });
}

/// Exception thrown when local storage operations fail (e.g., disk full).
class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code = 'ERR_STORAGE',
    super.cause,
    super.metadata,
    super.stackTrace,
  });
}

/// Exception thrown when WebSocket communication fails.
class WebSocketException extends AppException {
  const WebSocketException({
    required super.message,
    super.code = 'ERR_WEBSOCKET',
    super.cause,
    super.metadata,
    super.stackTrace,
  });
}

/// Exception thrown during real-time data streaming operations.
class StreamingException extends AppException {
  const StreamingException({
    required super.message,
    super.code = 'ERR_STREAMING',
    super.cause,
    super.metadata,
    super.stackTrace,
  });
}

/// Exception thrown when file system operations fail.
class FileException extends AppException {
  const FileException({
    required super.message,
    super.code = 'ERR_FILE',
    super.cause,
    super.metadata,
    super.stackTrace,
  });
}

/// Exception thrown during authentication or registration flows.
class AuthenticationException extends AppException {
  const AuthenticationException({
    required super.message,
    super.code = 'ERR_AUTH',
    super.cause,
    super.metadata,
    super.stackTrace,
  });
}

/// Exception thrown during subscription management operations.
class SubscriptionException extends AppException {
  const SubscriptionException({
    required super.message,
    super.code = 'ERR_SUBSCRIPTION',
    super.cause,
    super.metadata,
    super.stackTrace,
  });
}

/// Exception thrown during payment processing operations.
class PaymentException extends AppException {
  const PaymentException({
    required super.message,
    super.code = 'ERR_PAYMENT',
    super.cause,
    super.metadata,
    super.stackTrace,
  });
}

/// Exception thrown by AI engine or model inference operations.
class AIException extends AppException {
  const AIException({
    required super.message,
    super.code = 'ERR_AI',
    super.cause,
    super.metadata,
    super.stackTrace,
  });
}

/// Exception thrown during Retrieval-Augmented Generation (RAG) operations.
class RAGException extends AppException {
  const RAGException({
    required super.message,
    super.code = 'ERR_RAG',
    super.cause,
    super.metadata,
    super.stackTrace,
  });
}

/// Exception thrown by autonomous AI agent workflows.
class AgentException extends AppException {
  const AgentException({
    required super.message,
    super.code = 'ERR_AGENT',
    super.cause,
    super.metadata,
    super.stackTrace,
  });
}

/// Exception thrown for unclassified or unexpected errors.
class UnknownException extends AppException {
  const UnknownException({
    required super.message,
    super.code = AppStrings.errorCodeUnknown,
    super.cause,
    super.metadata,
    super.stackTrace,
  });
}

/// Exception thrown when the user has exceeded the rate limit (HTTP 429).
class RateLimitException extends AppException {
  const RateLimitException({
    required super.message,
    super.code = AppStrings.errorCodeRateLimited,
    super.cause,
    super.metadata,
    super.stackTrace,
  });
}
