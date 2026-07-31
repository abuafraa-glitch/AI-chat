import 'package:ai_chat/core/network/network_response.dart';

// ---------------------------------------------------------------------------
// Token storage contract
// ---------------------------------------------------------------------------

/// Contract for reading and persisting authentication tokens.
///
/// Implementations live in `lib/core/services/` (e.g. backed by
/// [FlutterSecureStorage]) and are injected into [AuthInterceptor] via
/// the DI container. Keeping this interface inside the network package
/// prevents the interceptor from taking a direct dependency on any
/// storage library.
abstract interface class TokenProvider {
  /// Returns the stored access token, or `null` when none is present.
  Future<String?> readAccessToken();

  /// Returns the stored refresh token, or `null` when none is present.
  Future<String?> readRefreshToken();

  /// Persists [token] as the current access token.
  Future<void> writeAccessToken(String token);

  /// Persists [token] as the current refresh token.
  Future<void> writeRefreshToken(String token);

  /// Erases both the access token and the refresh token.
  ///
  /// Should be called when the user logs out or when a token refresh
  /// attempt fails unrecoverably.
  Future<void> clearTokens();
}

// ---------------------------------------------------------------------------
// Upload progress callback
// ---------------------------------------------------------------------------

/// Callback reporting the progress of a file upload.
///
/// [sent] is the number of bytes transmitted so far; [total] is the
/// expected total. [total] may be `-1` when the content length is unknown.
typedef UploadProgressCallback = void Function(int sent, int total);

// ---------------------------------------------------------------------------
// HTTP consumer contract
// ---------------------------------------------------------------------------

/// Abstract HTTP client used by every data source in the application.
///
/// All methods return [NetworkResponse<T>] — a sealed type that the
/// caller pattern-matches rather than catching raw exceptions. No Dio
/// or platform exception escapes this interface.
///
/// Path strings are bare paths without the base URL (e.g. `/auth/login`);
/// use the [Endpoints] factory to compose them. The [cancelToken] parameter
/// is a caller-supplied string key; pass the same key to [cancelRequest]
/// to abort the in-flight request.
abstract interface class ApiConsumer {
  // ── Core HTTP verbs ────────────────────────────────────────────────────

  /// Sends an HTTP **GET** request and decodes the response with [fromJson].
  Future<NetworkResponse<T>> get<T>({
    required String path,
    required T Function(dynamic json) fromJson,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? cancelToken,
  });

  /// Sends an HTTP **POST** request with an optional [data] body and
  /// decodes the response with [fromJson].
  Future<NetworkResponse<T>> post<T>({
    required String path,
    required T Function(dynamic json) fromJson,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? cancelToken,
  });

  /// Sends an HTTP **PUT** request (full replacement semantics).
  Future<NetworkResponse<T>> put<T>({
    required String path,
    required T Function(dynamic json) fromJson,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? cancelToken,
  });

  /// Sends an HTTP **PATCH** request (partial update semantics).
  Future<NetworkResponse<T>> patch<T>({
    required String path,
    required T Function(dynamic json) fromJson,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? cancelToken,
  });

  /// Sends an HTTP **DELETE** request.
  ///
  /// Returns [NetworkResponse<void>] because DELETE responses typically
  /// carry no meaningful body.
  Future<NetworkResponse<void>> delete({
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? cancelToken,
  });

  // ── Multipart upload ───────────────────────────────────────────────────

  /// Uploads a single file via a **multipart/form-data POST** and decodes
  /// the server response with [fromJson].
  ///
  /// [filePath]       — absolute path to the file on the device.
  /// [fileFieldName]  — the form-field name the server expects.
  /// [additionalFields] — optional plain-text form fields to include.
  /// [onSendProgress] — optional callback for upload progress reporting.
  Future<NetworkResponse<T>> uploadFile<T>({
    required String path,
    required String filePath,
    required String fileFieldName,
    required T Function(dynamic json) fromJson,
    Map<String, String>? additionalFields,
    UploadProgressCallback? onSendProgress,
    String? cancelToken,
  });

  // ── Server-Sent Events streaming ───────────────────────────────────────

  /// Opens an SSE / streaming connection to [path] and yields decoded
  /// UTF-8 chunks as they arrive.
  ///
  /// The stream closes naturally when the server signals completion or
  /// when [cancelRequest] is called with the matching [cancelToken].
  /// The caller is responsible for catching [NetworkException] thrown
  /// from the stream on connection failure.
  Stream<String> streamRequest({
    required String path,
    Object? data,
    Map<String, String>? headers,
    String? cancelToken,
  });

  // ── Cancellation ───────────────────────────────────────────────────────

  /// Cancels any in-flight request identified by [cancelToken].
  ///
  /// If no request with that token is currently in flight, the call is
  /// a no-op. Cancellation causes the corresponding method to complete
  /// with [RequestCancelledException].
  void cancelRequest(String cancelToken);
}
