import 'package:ai_chat/core/constants/storage_keys.dart';
import 'package:ai_chat/core/network/api_consumer.dart';
import 'package:ai_chat/core/routes/route_guards.dart';
import 'package:ai_chat/core/services/local_storage_service.dart';
import 'package:ai_chat/core/services/secure_storage_service.dart';
import 'package:ai_chat/core/utils/jwt_decoder.dart';
import 'package:ai_chat/data/datasources/local/local_data_source.dart';
import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:flutter/foundation.dart';

/// Drives the authentication lifecycle of the application.
///
/// [AuthController] implements [AuthStatusProvider] so it can be handed
/// to [GoRouter] via `refreshListenable`: every status transition
/// re-evaluates the route guards and redirects the user accordingly.
/// It also implements [AuthSessionSink] so the network layer can
/// reconcile the auth state when an unrecoverable token-refresh failure
/// occurs — preventing a "fake authenticated" state where tokens are
/// gone but the UI still reports the user as signed in.
/// Screens never perform auth work themselves — they call the methods
/// on this controller (resolved from the DI container).
///
/// ### Bootstrap
/// Call [bootstrap] from the splash screen; the controller starts in
/// [AuthStatus.loading] and resolves to authenticated / unauthenticated
/// based on the persisted session.
final class AuthController extends ChangeNotifier
    implements AuthStatusProvider, AuthSessionSink {
  /// Creates an [AuthController] wired to the data layer.
  AuthController({
    required RemoteDataSource remoteDataSource,
    required LocalDataSource localDataSource,
    required SecureStorageService secureStorage,
    required LocalStorageService localStorage,
  }) : _remote = remoteDataSource,
       _localDataSource = localDataSource,
       _secureStorage = secureStorage,
       _localStorage = localStorage;

  final RemoteDataSource _remote;
  final LocalDataSource _localDataSource;
  final SecureStorageService _secureStorage;
  final LocalStorageService _localStorage;

  AuthStatus _status = AuthStatus.loading;
  bool _hasCompletedOnboarding = false;

  @override
  AuthStatus get status => _status;

  @override
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  // ── Bootstrap ─────────────────────────────────────────────────────────────

  /// Resolves the current session state from the persisted tokens.
  ///
  /// A stored access token is **not** treated as proof of authentication on
  /// its own: when the token is a JWT exposing an `exp` claim (the only
  /// contract-free source of expiration available locally — the backend
  /// does not surface a separate `expires_in`/`expires_at` field), an
  /// already-expired token is rejected here so the router lands on the
  /// login surface instead of a fake-authenticated state. Tokens that are
  /// not JWTs or omit `exp` fall back to a presence check; in that case
  /// runtime expiry is reconciled by the `AuthInterceptor` →
  /// `AuthSessionSink` flow on the first 401.
  ///
  /// Lifecycle:
  ///   valid JWT   → authenticated
  ///   expired JWT → unauthenticated (tokens cleared)
  ///   no / opaque token → unauthenticated (presence-based fallback)
  Future<void> bootstrap() async {
    final token = await _secureStorage.readAccessToken();
    _hasCompletedOnboarding =
        _localStorage.getBool(StorageKeys.onboardingCompleted) ?? false;

    if (token == null || token.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    if (JwtDecoder.isExpired(token)) {
      // Locally-verifiable expiry: drop the session rather than reporting a
      // fake-authenticated state. A live refresh token is not proactively
      // refreshed at bootstrap (that requires a bare-Dio refresh capability
      // owned by the interceptor); the user re-authenticates, and any
      // runtime 401 on a still-valid refresh is reconciled by the sink.
      await _secureStorage.clearTokens();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  // ── Session lifecycle ─────────────────────────────────────────────────────

  /// Signs the user in and persists the session.
  ///
  /// Throws an [AppException] subtype on failure — screens catch it
  /// and surface the message.
  Future<void> signIn({required String email, required String password}) async {
    final result = await _remote.login(email: email, password: password);
    await _persistSession(result);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Registers a new account and, when the server auto-signs-in,
  /// persists the session.
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await _remote.register(
      name: name,
      email: email,
      password: password,
    );
    await _persistSession(result);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Signs the user out, clearing the persisted session.
  Future<void> signOut() async {
    // Best effort server-side revocation. Local cleanup must still happen if
    // the backend is unreachable, otherwise another account could observe
    // stale persisted data on this device.
    try {
      await _remote.logout();
    } finally {
      await _localDataSource.clearCache();
      await _localDataSource.deleteUser();
      await _secureStorage.clearTokens();
      await _localStorage.remove(StorageKeys.currentUserId);
      await _localStorage.remove(StorageKeys.currentUserDisplayName);
      await _localStorage.remove(StorageKeys.currentUserEmail);
      await _localStorage.remove(StorageKeys.currentUserAvatarUrl);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Reconciles the auth state to `unauthenticated` after the network
  /// layer failed to refresh an expired token.
  ///
  /// The interceptor has already erased the persisted tokens via
  /// [TokenProvider.clearTokens]; this method only flips the observable
  /// status so the router (wired through `refreshListenable`) redirects
  /// to the login surface. It is a no-op when the session is already
  /// unauthenticated, which keeps [notifyListeners] from firing
  /// redundantly on repeated 401s.
  @override
  void markUnauthenticated() {
    if (_status == AuthStatus.unauthenticated) return;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Marks the first-launch onboarding flow as completed.
  Future<void> markOnboardingCompleted() async {
    await _localStorage.setBool(StorageKeys.onboardingCompleted, value: true);
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  // ── Password / verification flows ─────────────────────────────────────────

  /// Initiates the password-recovery flow for [email].
  Future<void> forgotPassword(String email) => _remote.forgotPassword(email);

  /// Completes the password-reset flow.
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
  }) {
    return _remote.resetPassword(
      email: email,
      token: token,
      password: password,
    );
  }

  /// Confirms the email address with the emailed [code].
  Future<void> verifyEmail({required String email, required String code}) {
    return _remote.verifyEmail(email: email, code: code);
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  /// Persists the tokens and user profile returned by the server.
  Future<void> _persistSession(Map<String, dynamic> result) async {
    final access = result['access_token'];
    final refresh = result['refresh_token'];
    if (access is String && access.isNotEmpty) {
      await _secureStorage.writeAccessToken(access);
    }
    if (refresh is String && refresh.isNotEmpty) {
      await _secureStorage.writeRefreshToken(refresh);
    }
    final user = result['user'];
    if (user is Map<String, dynamic>) {
      await _cacheUser(user);
    }
  }

  /// Caches the non-sensitive user profile for offline UI rendering.
  Future<void> _cacheUser(Map<String, dynamic> user) async {
    final id = user['id'];
    if (id is String && id.isNotEmpty) {
      await _localStorage.setString(StorageKeys.currentUserId, id);
    }
    final name = user['name'];
    if (name is String && name.isNotEmpty) {
      await _localStorage.setString(StorageKeys.currentUserDisplayName, name);
    }
    final email = user['email'];
    if (email is String && email.isNotEmpty) {
      await _localStorage.setString(StorageKeys.currentUserEmail, email);
    }
    final avatar = user['avatar_url'] ?? user['avatar'];
    if (avatar is String && avatar.isNotEmpty) {
      await _localStorage.setString(StorageKeys.currentUserAvatarUrl, avatar);
    }
  }
}
