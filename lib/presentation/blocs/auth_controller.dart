import 'package:ai_chat/core/constants/storage_keys.dart';
import 'package:ai_chat/core/routes/route_guards.dart';
import 'package:ai_chat/core/services/local_storage_service.dart';
import 'package:ai_chat/core/services/secure_storage_service.dart';
import 'package:ai_chat/data/datasources/remote/remote_data_source.dart';
import 'package:flutter/foundation.dart';

/// Drives the authentication lifecycle of the application.
///
/// [AuthController] implements [AuthStatusProvider] so it can be handed
/// to [GoRouter] via `refreshListenable`: every status transition
/// re-evaluates the route guards and redirects the user accordingly.
/// Screens never perform auth work themselves — they call the methods
/// on this controller (resolved from the DI container).
///
/// ### Bootstrap
/// Call [bootstrap] from the splash screen; the controller starts in
/// [AuthStatus.loading] and resolves to authenticated / unauthenticated
/// based on the persisted session.
final class AuthController extends ChangeNotifier
    implements AuthStatusProvider {
  /// Creates an [AuthController] wired to the data layer.
  AuthController({
    required RemoteDataSource remoteDataSource,
    required SecureStorageService secureStorage,
    required LocalStorageService localStorage,
  }) : _remote = remoteDataSource,
       _secureStorage = secureStorage,
       _localStorage = localStorage;

  final RemoteDataSource _remote;
  final SecureStorageService _secureStorage;
  final LocalStorageService _localStorage;

  AuthStatus _status = AuthStatus.loading;
  bool _hasCompletedOnboarding = false;

  @override
  AuthStatus get status => _status;

  @override
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  // ── Bootstrap ─────────────────────────────────────────────────────────────

  /// Resolves the current session state from persisted tokens.
  Future<void> bootstrap() async {
    final token = await _secureStorage.readAccessToken();
    _hasCompletedOnboarding =
        _localStorage.getBool(StorageKeys.onboardingCompleted) ?? false;
    _status = (token != null && token.isNotEmpty)
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
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
    await _secureStorage.clearTokens();
    await _localStorage.remove(StorageKeys.currentUserId);
    await _localStorage.remove(StorageKeys.currentUserDisplayName);
    await _localStorage.remove(StorageKeys.currentUserEmail);
    await _localStorage.remove(StorageKeys.currentUserAvatarUrl);
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
