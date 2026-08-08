/// HTTP header names used across the Hajeen AI platform.
///
/// The constants in this class are **string identifiers only** — they
/// never carry values. The values are populated dynamically by the
/// `Dio` interceptor chain (auth token, request id, locale, …).
abstract final class ApiHeaders {
  const ApiHeaders._();

  /// `Authorization` — bearer token issued by the auth service.
  static const String authorization = 'Authorization';

  /// `Content-Type` — request body MIME type.
  static const String contentType = 'Content-Type';

  /// `Accept` — response MIME type the client understands.
  static const String accept = 'Accept';

  /// `Accept-Language` — preferred response language.
  static const String acceptLanguage = 'Accept-Language';

  /// `User-Agent` — client identification string.
  static const String userAgent = 'User-Agent';

  /// `X-Request-Id` — correlation id for distributed tracing.
  static const String requestId = 'X-Request-Id';

  /// `X-Platform` — origin platform (`ios`, `android`, `web`, …).
  static const String platform = 'X-Platform';

  /// `X-App-Version` — semantic version of the running client.
  static const String appVersion = 'X-App-Version';

  /// `X-Device-Id` — anonymous device identifier.
  static const String deviceId = 'X-Device-Id';

  /// `X-Client-Name` — marketing name of the client app.
  static const String clientName = 'X-Client-Name';

  /// `X-Retry-Count` — number of times a request has been retried.
  static const String retryCount = 'X-Retry-Count';

  /// `X-Rate-Limit-Remaining` — server hint for remaining quota.
  static const String rateLimitRemaining = 'X-Rate-Limit-Remaining';

  /// `Retry-After` — server-requested delay before the next attempt.
  static const String retryAfter = 'Retry-After';

  /// Bearer scheme prefix used with [authorization]. The full header
  /// value is `'$bearerPrefix <token>'`. A leading space is included
  /// so the value can be concatenated directly.
  static const String bearerPrefix = 'Bearer ';
}

/// Canonical MIME type identifiers used by the REST and WebSocket
/// gateways. Avoid inlining these strings elsewhere in the codebase.
abstract final class ApiContentType {
  const ApiContentType._();

  /// `application/json` — default for REST request/response bodies.
  static const String json = 'application/json';

  /// `application/json; charset=utf-8` — explicit UTF-8 JSON.
  static const String jsonUtf8 = 'application/json; charset=utf-8';

  /// `multipart/form-data` — file uploads.
  static const String multipartFormData = 'multipart/form-data';

  /// `application/octet-stream` — raw binary uploads.
  static const String octetStream = 'application/octet-stream';

  /// `text/plain` — plain text payloads.
  static const String textPlain = 'text/plain';

  /// `text/event-stream` — Server-Sent Events streams.
  static const String eventStream = 'text/event-stream';
}

/// Subset of HTTP status codes the application explicitly branches on.
///
/// Codes outside this list are treated as generic errors by the
/// failure mapping layer.
abstract final class HttpStatusCode {
  const HttpStatusCode._();

  /// `200` — success.
  static const int ok = 200;

  /// `201` — resource created.
  static const int created = 201;

  /// `202` — request accepted, processing asynchronously.
  static const int accepted = 202;

  /// `204` — success, no content to return.
  static const int noContent = 204;

  /// `400` — request was malformed.
  static const int badRequest = 400;

  /// `401` — authentication required or invalid.
  static const int unauthorized = 401;

  /// `403` — authenticated but not permitted.
  static const int forbidden = 403;

  /// `404` — resource not found.
  static const int notFound = 404;

  /// `409` — conflict with the current resource state.
  static const int conflict = 409;

  /// `422` — request was understood but semantically invalid.
  static const int unprocessableEntity = 422;

  /// `429` — too many requests; client should back off.
  static const int tooManyRequests = 429;

  /// `500` — generic server error.
  static const int internalServerError = 500;

  /// `502` — bad gateway from an upstream dependency.
  static const int badGateway = 502;

  /// `503` — service temporarily unavailable.
  static const int serviceUnavailable = 503;

  /// `504` — gateway timed out waiting for an upstream.
  static const int gatewayTimeout = 504;
}

/// REST path segments. Each constant is appended to
/// `AppConfig.instance.resolvedApiUrl` to compose a full endpoint.
///
/// Paths intentionally omit the API version — the version is added
/// once, at the configuration layer, to keep it swappable.
abstract final class ApiPaths {
  const ApiPaths._();

  /// `/auth` — login, register, refresh, logout.
  static const String auth = '/auth';

  /// `/auth/login` — credential exchange.
  static const String authLogin = '/auth/login';

  /// `/auth/register` — account creation.
  static const String authRegister = '/auth/register';

  /// `/auth/refresh` — token refresh.
  static const String authRefresh = '/auth/refresh';

  /// `/auth/logout` — session termination.
  static const String authLogout = '/auth/logout';

  /// `/auth/forgot-password` — password recovery initiation.
  static const String authForgotPassword = '/auth/forgot-password';

  /// `/users` — account management endpoints.
  static const String users = '/users';

  /// `/users/me` — current authenticated user profile.
  static const String usersMe = '/users/me';

  /// `/users/me/avatar` — avatar upload/retrieval.
  static const String usersMeAvatar = '/users/me/avatar';

  /// `/conversations` — chat conversation list and creation.
  static const String conversations = '/conversations';

  /// `/messages` — message history and posting.
  static const String messages = '/messages';

  /// `/models` — available AI model catalogue.
  static const String models = '/models';

  /// `/models/{id}` — single model lookup.
  static const String modelById = '/models/{id}';

  /// `/subscriptions` — subscription plans and status.
  static const String subscriptions = '/subscriptions';

  /// `/payments` — payment intents and history.
  static const String payments = '/payments';

  /// `/files` — file upload, listing, deletion.
  static const String files = '/files';

  /// `/search` — global in-app search.
  static const String search = '/search';

  /// `/agents` — autonomous agent definitions and runs.
  static const String agents = '/agents';

  /// `/notifications` — push and in-app notification feeds.
  static const String notifications = '/notifications';

  /// `/health` — liveness/readiness probe.
  static const String health = '/health';
}

/// WebSocket frame event names exchanged with the streaming gateway.
abstract final class WebSocketEvent {
  const WebSocketEvent._();

  /// Client → server: subscribe to a conversation stream.
  static const String subscribe = 'subscribe';

  /// Client → server: cancel an active subscription.
  static const String unsubscribe = 'unsubscribe';

  /// Client → server: send a user message to the model.
  static const String sendMessage = 'send_message';

  /// Client → server: abort an in-flight model generation.
  static const String cancelGeneration = 'cancel_generation';

  /// Server → client: connection established.
  static const String connected = 'connected';

  /// Server → client: streaming token chunk from the model.
  static const String tokenChunk = 'token_chunk';

  /// Server → client: full assistant message finalized.
  static const String messageComplete = 'message_complete';

  /// Server → client: generation failed with a semantic error code.
  static const String error = 'error';

  /// Server → client: presence/typing indicator.
  static const String typing = 'typing';

  /// Server → client: a model finished reasoning and is streaming.
  static const String reasoning = 'reasoning';

  /// Server → client: heartbeat ping.
  static const String ping = 'ping';

  /// Client → server: heartbeat pong reply.
  static const String pong = 'pong';
}

/// Protocol-level defaults that are independent of the active
/// environment. Environment-tunable values live in
/// `lib/core/config/`; only true protocol constants belong here.
abstract final class ApiDefaults {
  const ApiDefaults._();

  /// Default number of items requested per page.
  static const int pageSize = 20;

  /// Maximum page size honoured by the server; client requests above
  /// this are clamped before transmission.
  static const int maxPageSize = 100;

  /// Default `1` — first page is always 1-indexed.
  static const int firstPage = 1;

  /// Maximum number of retry attempts for idempotent requests.
  static const int maxRetries = 3;

  /// Backoff base used for exponential retry strategy (milliseconds).
  static const int retryBackoffBaseMs = 500;

  /// Cap on the exponential backoff growth (milliseconds).
  static const int retryBackoffCapMs = 8000;

  /// WebSocket heartbeat interval (seconds).
  static const int webSocketHeartbeatSeconds = 30;

  /// Maximum payload size accepted by the upload endpoint (bytes).
  static const int maxUploadBytes = 50 * 1024 * 1024;
}
