import 'package:ai_chat/core/constants/storage_keys.dart';
import 'package:ai_chat/core/network/api_consumer.dart';
import 'package:ai_chat/core/routes/route_guards.dart';
import 'package:ai_chat/core/services/local_storage_service.dart';
import 'package:ai_chat/core/services/secure_storage_service.dart';
import 'package:ai_chat/core/utils/jwt_decoder.dart';
import 'package:ai_chat/data/datasources/local/local_data_source.dart';
import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  static const String _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static const String _facebookAppId = String.fromEnvironment(
    'FACEBOOK_APP_ID',
  );
  static const String _facebookClientToken = String.fromEnvironment(
    'FACEBOOK_CLIENT_TOKEN',
  );
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleInitialization;

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
    String? token;
    try {
      token = await _secureStorage.readAccessToken();
    } on Object {
      // A corrupt or unavailable Android Keystore entry must not crash the
      // process on cold start. Treat it as a signed-out session and allow the
      // user to authenticate again.
      token = null;
    }
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

  /// Completes server authentication with a provider token.
  Future<void> signInWithSocial({
    required String provider,
    required String token,
  }) async {
    final result = await _remote.socialLogin(provider: provider, token: token);
    await _persistSession(result);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Opens Google Sign-In, then exchanges the returned ID token with FastAPI.
  Future<void> signInWithGoogle() async {
    if (_googleServerClientId.isEmpty) {
      throw StateError(
        'Google authentication configuration is incomplete. '
        'Provide GOOGLE_SERVER_CLIENT_ID before using Google Login.',
      );
    }
    _googleInitialization ??= _googleSignIn.initialize(
      serverClientId: _googleServerClientId.isEmpty
          ? null
          : _googleServerClientId,
    );
    await _googleInitialization;

    final account = await _googleSignIn.authenticate();
    final token = account.authentication.idToken;
    if (token == null || token.isEmpty) {
      throw StateError('Google did not return an ID token.');
    }
    await signInWithSocial(provider: 'google', token: token);
  }

  /// Opens Facebook Login, then exchanges the access token with FastAPI.
  Future<void> signInWithFacebook() async {
    if (_facebookAppId.isEmpty || _facebookClientToken.isEmpty) {
      throw StateError(
        'Facebook authentication configuration is incomplete. '
        'Provide FACEBOOK_APP_ID and FACEBOOK_CLIENT_TOKEN at build time.',
      );
    }
    final result = await FacebookAuth.instance.login(
      permissions: const <String>['email', 'public_profile'],
    );
    if (result.status == LoginStatus.cancelled) {
      throw StateError('Facebook sign-in was cancelled.');
    }
    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw StateError(result.message ?? 'Facebook sign-in failed.');
    }
    await signInWithSocial(
      provider: 'facebook',
      token: result.accessToken!.tokenString,
    );
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

  /// Persists tokens and establishes a user-specific local cache namespace.
  ///
  /// Login responses from social providers can encode `id` as either a string
  /// or a number. Treating only strings as valid previously left the old
  /// namespace active, so a later account could read another account's cache.
  Future<void> _persistSession(Map<String, dynamic> result) async {
    final access = result['access_token'];
    final refresh = result['refresh_token'];
    if (access is String && access.isNotEmpty) {
      await _secureStorage.writeAccessToken(access);
    }
    if (refresh is String && refresh.isNotEmpty) {
      await _secureStorage.writeRefreshToken(refresh);
    }

    Map<String, dynamic>? user;
    final responseUser = result['user'];
    if (responseUser is Map<String, dynamic>) {
      user = responseUser;
    } else {
      // Some auth responses return tokens first and expose the profile through
      // /me. Resolve it before marking the session authenticated.
      try {
        user = await _remote.getCurrentUser();
      } on Object {
        user = null;
      }
    }

    final identity = user == null ? null : _identityFromUser(user!);
    if (identity == null) {
      await _localDataSource.clearCache();
      await _localStorage.remove(StorageKeys.currentUserId);
      throw StateError('Authentication response did not contain a user identity.');
    }

    final previousIdentity =
        _localStorage.getString(StorageKeys.currentUserId);
    if (previousIdentity != identity || previousIdentity == null) {
      // Clear both the old account namespace and any legacy anonymous cache
      // before activating the new namespace.
      await _localDataSource.clearCache();
    }
    await _cacheUser(user!);
  }

  /// Returns a stable namespace identity for a backend user.
  String? _identityFromUser(Map<String, dynamic> user) {
    final rawId = user['id'] ?? user['user_id'];
    if (rawId is String && rawId.trim().isNotEmpty) return rawId.trim();
    if (rawId is num) return rawId.toString();
    final email = user['email'];
    if (email is String && email.trim().isNotEmpty) {
      return 'email:${email.trim().toLowerCase()}';
    }
    return null;
  }

  /// Caches the non-sensitive user profile for offline UI rendering.
  Future<void> _cacheUser(Map<String, dynamic> user) async {
    final id = _identityFromUser(user);
    if (id != null) {
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
