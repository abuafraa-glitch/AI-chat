import 'package:equatable/equatable.dart';

/// Base class for all domain-layer failures in Hajeen AI.
///
/// Failures are used to represent error states in the domain and UI layers,
/// providing a way to handle errors without throwing exceptions.
/// All failures are immutable and support equality checks via [Equatable].
abstract class Failure extends Equatable {
  const Failure({required this.message, required this.code, this.metadata});

  /// A human-readable message intended for the user or logging.
  final String message;

  /// A machine-readable code for classification.
  final String code;

  /// Additional metadata associated with the failure.
  final Map<String, dynamic>? metadata;

  /// Whether the operation that produced this failure can be retried.
  bool get isTransient => false;

  @override
  List<Object?> get props => [message, code, metadata];

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

/// Failure representing a server-side error.
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    required super.code,
    super.metadata,
  });

  @override
  bool get isTransient => true;
}

/// Failure representing a network connectivity issue.
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    required super.code,
    super.metadata,
  });

  @override
  bool get isTransient => true;
}

/// Failure representing a caching operation error.
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    required super.code,
    super.metadata,
  });
}

/// Failure representing an operation timeout.
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    required super.message,
    required super.code,
    super.metadata,
  });

  @override
  bool get isTransient => true;
}

/// Failure representing an unauthenticated state.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    required super.message,
    required super.code,
    super.metadata,
  });
}

/// Failure representing a lack of permissions.
class ForbiddenFailure extends Failure {
  const ForbiddenFailure({
    required super.message,
    required super.code,
    super.metadata,
  });
}

/// Failure representing a data validation error.
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    required super.code,
    super.metadata,
  });
}

/// Failure representing a missing resource.
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    required super.code,
    super.metadata,
  });
}

/// Failure representing a data parsing or serialization error.
class ParsingFailure extends Failure {
  const ParsingFailure({
    required super.message,
    required super.code,
    super.metadata,
  });
}

/// Failure representing a local storage error.
class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    required super.code,
    super.metadata,
  });
}

/// Failure representing a WebSocket communication error.
class WebSocketFailure extends Failure {
  const WebSocketFailure({
    required super.message,
    required super.code,
    super.metadata,
  });
}

/// Failure representing a streaming operation error.
class StreamingFailure extends Failure {
  const StreamingFailure({
    required super.message,
    required super.code,
    super.metadata,
  });
}

/// Failure representing a file system operation error.
class FileFailure extends Failure {
  const FileFailure({
    required super.message,
    required super.code,
    super.metadata,
  });
}

/// Failure representing an authentication flow error.
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required super.message,
    required super.code,
    super.metadata,
  });
}

/// Failure representing a subscription management error.
class SubscriptionFailure extends Failure {
  const SubscriptionFailure({
    required super.message,
    required super.code,
    super.metadata,
  });
}

/// Failure representing a payment processing error.
class PaymentFailure extends Failure {
  const PaymentFailure({
    required super.message,
    required super.code,
    super.metadata,
  });
}

/// Failure representing an AI engine or model error.
class AIFailure extends Failure {
  const AIFailure({
    required super.message,
    required super.code,
    super.metadata,
  });
}

/// Failure representing a RAG pipeline error.
class RAGFailure extends Failure {
  const RAGFailure({
    required super.message,
    required super.code,
    super.metadata,
  });
}

/// Failure representing an AI agent workflow error.
class AgentFailure extends Failure {
  const AgentFailure({
    required super.message,
    required super.code,
    super.metadata,
  });
}

/// Failure representing an unknown or unclassified error.
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    required super.code,
    super.metadata,
  });
}

/// Failure representing a rate limit threshold being exceeded.
class RateLimitFailure extends Failure {
  const RateLimitFailure({
    required super.message,
    required super.code,
    super.metadata,
  });
}
