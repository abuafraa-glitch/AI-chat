import 'package:ai_chat/core/config/app_config.dart';
import 'package:ai_chat/core/routes/route_names.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Auth status contract
// ---------------------------------------------------------------------------

/// Possible authentication states used by the route guards.
enum AuthStatus {
  /// Bootstrap is in progress; the auth state has not yet been resolved.
  loading,

  /// The user has completed authentication and holds a valid session.
  authenticated,

  /// The user is not authenticated (logged out or session expired).
  unauthenticated,
}

/// Contract for providing the current authentication state to the router.
///
/// Implement this in the auth layer (e.g. an `AuthCubit`-backed adapter)
/// and pass the implementation to [AppRouter] through the DI container.
///
/// By extending [Listenable] the provider can be passed directly to
/// [GoRouter.refreshListenable], so navigation is re-evaluated every time
/// the auth state changes.
abstract interface class AuthStatusProvider implements Listenable {
  /// Current authentication status.
  AuthStatus get status;

  /// `true` when the user has completed the first-launch onboarding flow.
  bool get hasCompletedOnboarding;
}

// ---------------------------------------------------------------------------
// Route guard functions
// ---------------------------------------------------------------------------

/// Collection of pure redirect functions consumed by [AppRouter].
///
/// Each guard returns a redirect path when navigation should be interrupted,
/// or `null` to allow the navigation to proceed. They are intentionally
/// stateless functions so they can be composed and tested in isolation.
abstract final class RouteGuard {
  const RouteGuard._();

  // ── Auth guard ───────────────────────────────────────────────────────────

  /// Redirects to [RouteNames.splash] while auth is loading, to
  /// [RouteNames.login] when unauthenticated, and to [RouteNames.chat]
  /// when an authenticated user tries to access an auth screen.
  ///
  /// Returns `null` when no redirect is needed.
  static String? authGuard(
    GoRouterState state,
    AuthStatusProvider authProvider,
  ) {
    final location = state.uri.toString();
    final status = authProvider.status;

    // Still resolving the session — hold at the splash screen.
    if (status == AuthStatus.loading) {
      return location == RouteNames.splash ? null : RouteNames.splash;
    }

    final isOnAuthScreen = _isAuthScreen(location);

    if (status == AuthStatus.unauthenticated) {
      // Send to onboarding or login when protected routes are accessed.
      if (isOnAuthScreen || location == RouteNames.splash) return null;
      return authProvider.hasCompletedOnboarding
          ? RouteNames.login
          : RouteNames.onboarding;
    }

    // Authenticated: prevent re-visiting auth / splash / onboarding screens.
    if (status == AuthStatus.authenticated) {
      if (isOnAuthScreen ||
          location == RouteNames.splash ||
          location == RouteNames.onboarding) {
        return RouteNames.chat;
      }
    }

    return null;
  }

  // ── Feature flag guard ────────────────────────────────────────────────────

  /// Redirects to [RouteNames.chat] when a route that requires a feature
  /// flag is accessed but the flag is disabled in [AppConfig.instance].
  ///
  /// Returns `null` when the feature is enabled or the location does not
  /// require a flag check.
  static String? featureFlagGuard(GoRouterState state) {
    final location = state.uri.toString();
    final flags = AppConfig.instance.featureFlags;

    if (location.startsWith(RouteNames.subscriptions) &&
        !flags.enableSubscriptions) {
      return RouteNames.chat;
    }
    if (location.startsWith(RouteNames.payments) && !flags.enablePayments) {
      return RouteNames.chat;
    }
    if (location.startsWith(RouteNames.files) && !flags.enableFileManagement) {
      return RouteNames.chat;
    }
    if (location.startsWith(RouteNames.search) && !flags.enableSearch) {
      return RouteNames.chat;
    }
    if (location.startsWith(RouteNames.agents) && !flags.enableAgents) {
      return RouteNames.chat;
    }
    if (location.startsWith(RouteNames.notifications) &&
        !flags.enableNotifications) {
      return RouteNames.chat;
    }

    return null;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns `true` when [location] is one of the authentication-flow routes.
  static bool _isAuthScreen(String location) {
    return location.startsWith(RouteNames.auth);
  }
}
