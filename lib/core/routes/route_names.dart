/// Canonical route path constants for the Hajeen AI application.
///
/// All navigation calls, deep-link handlers, and redirect guards must
/// reference these constants rather than inline string literals. This
/// ensures that renaming a route only requires a change in one place.
///
/// ### Path conventions
/// - Paths are absolute (start with `/`).
/// - Path parameters use `:paramName` notation, as required by go_router.
/// - Helper methods (e.g. [conversationPath]) build complete paths from
///   parameters so call sites never perform string interpolation directly.
///
/// ### Route tree (mirrors [AppRouter])
/// ```
/// /splash
/// /onboarding
/// /auth
///   /auth/login
///   /auth/register
///   /auth/forgot-password
///   /auth/reset-password
///   /auth/verify-email
/// / (shell — main navigation)
///   /chat
///   /chat/:conversationId
///   /models
///   /profile
///   /settings
/// /search
/// /notifications
/// /files
/// /subscriptions
/// /payments
/// /agents
/// ```
abstract final class RouteNames {
  const RouteNames._();

  // ── Bootstrap ──────────────────────────────────────────────────────────

  /// `/splash` — animated splash / bootstrap screen shown on cold start.
  static const String splash = '/splash';

  /// `/onboarding` — first-launch onboarding flow.
  static const String onboarding = '/onboarding';

  // ── Authentication ─────────────────────────────────────────────────────

  /// `/auth` — parent shell for all unauthenticated screens.
  static const String auth = '/auth';

  /// `/auth/login` — email + password / social sign-in.
  static const String login = '/auth/login';

  /// `/auth/register` — new account creation.
  static const String register = '/auth/register';

  /// `/auth/forgot-password` — password-reset request screen.
  static const String forgotPassword = '/auth/forgot-password';

  /// `/auth/reset-password` — complete password reset with a token.
  static const String resetPassword = '/auth/reset-password';

  /// `/auth/verify-email` — e-mail address verification.
  static const String verifyEmail = '/auth/verify-email';

  // ── Main shell ─────────────────────────────────────────────────────────

  /// `/chat` — conversation list (home tab).
  static const String chat = '/chat';

  /// `/chat/:conversationId` — single conversation / chat detail.
  static const String conversation = '/chat/:conversationId';

  /// Path parameter name for a conversation identifier.
  static const String paramConversationId = 'conversationId';

  /// `/models` — AI model catalogue and selection.
  static const String models = '/models';

  /// `/profile` — user profile and account details.
  static const String profile = '/profile';

  /// `/settings` — application and account settings.
  static const String settings = '/settings';

  // ── Feature screens ────────────────────────────────────────────────────

  /// `/search` — global in-app search.
  static const String search = '/search';

  /// `/notifications` — in-app notification feed.
  static const String notifications = '/notifications';

  /// `/files` — file upload, listing, and management.
  static const String files = '/files';

  /// `/subscriptions` — subscription plan listing and status.
  static const String subscriptions = '/subscriptions';

  /// `/payments` — payment flow and billing history.
  static const String payments = '/payments';

  /// `/agents` — autonomous agent definitions and run history.
  static const String agents = '/agents';

  // ── Path builders ──────────────────────────────────────────────────────

  /// Builds the path for a specific conversation: `/chat/<conversationId>`.
  static String conversationPath(String conversationId) =>
      '/chat/$conversationId';
}
