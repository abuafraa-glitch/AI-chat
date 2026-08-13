import 'package:ai_chat/core/routes/route_guards.dart';
import 'package:ai_chat/core/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Page factory contract
// ---------------------------------------------------------------------------

/// Contract for supplying screen [Widget]s to [AppRouter].
///
/// Implement this in the presentation layer and register the implementation
/// with the DI container. This indirection decouples the routing layer from
/// any concrete page widget, allowing the router to be configured in
/// `core/routes` before the presentation layer is built.
///
/// Each method receives the current [GoRouterState] so the implementation
/// can extract path parameters, query parameters, and the `extra` payload
/// without depending on [AppRouter]'s internal wiring.
abstract interface class AppRouterPageFactory {
  /// Builds the splash / bootstrap screen.
  Widget buildSplashPage(GoRouterState state);

  /// Builds the first-launch onboarding flow.
  Widget buildOnboardingPage(GoRouterState state);

  /// Builds the login screen.
  Widget buildLoginPage(GoRouterState state);

  /// Builds the registration screen.
  Widget buildRegisterPage(GoRouterState state);

  /// Builds the forgot-password screen.
  Widget buildForgotPasswordPage(GoRouterState state);

  /// Builds the reset-password screen.
  Widget buildResetPasswordPage(GoRouterState state);

  /// Builds the e-mail verification screen.
  Widget buildVerifyEmailPage(GoRouterState state);

  /// Builds the main shell widget (e.g. bottom-navigation scaffold).
  ///
  /// [navigationShell] is the [StatefulNavigationShell] provided by
  /// go_router; it must be placed in the widget tree so nested branches
  /// are rendered correctly.
  Widget buildMainShell(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  );

  /// Builds the conversation list (home tab).
  Widget buildChatListPage(GoRouterState state);

  /// Builds the chat detail screen for [conversationId].
  Widget buildChatPage(GoRouterState state, String conversationId);

  /// Builds the AI model catalogue screen.
  Widget buildModelsPage(GoRouterState state);

  /// Builds the user profile screen.
  Widget buildProfilePage(GoRouterState state);

  /// Builds the settings screen.
  Widget buildSettingsPage(GoRouterState state);

  /// Builds the global search screen.
  Widget buildSearchPage(GoRouterState state);

  /// Builds the in-app notification feed.
  Widget buildNotificationsPage(GoRouterState state);

  /// Builds the file management screen.
  Widget buildFilesPage(GoRouterState state);

  /// Builds the subscription management screen.
  Widget buildSubscriptionsPage(GoRouterState state);

  /// Builds the payment / billing screen.
  Widget buildPaymentsPage(GoRouterState state);

  /// Builds the agents management screen.
  Widget buildAgentsPage(GoRouterState state);

  /// Builds the error screen shown when a route is not found.
  Widget buildNotFoundPage(BuildContext context, GoRouterState state);
}

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

/// Central [GoRouter] configuration for the Hajeen AI application.
///
/// Create a single instance via the DI container and expose [router] to
/// the root [MaterialApp.router]. The instance listens to
/// [AuthStatusProvider] for reactive re-evaluation of redirect guards
/// whenever the authentication state changes.
///
/// ### Route tree
/// ```
/// /splash
/// /onboarding
/// /auth
///   login
///   register
///   forgot-password
///   reset-password
///   verify-email
/// / (StatefulShellRoute — bottom nav tabs)
///   /chat               [tab 0]
///   /chat/:id
///   /models             [tab 1]
///   /profile            [tab 2]
///   /settings           [tab 3]
/// /search
/// /notifications
/// /files
/// /subscriptions
/// /payments
/// /agents
/// ```
final class AppRouter {
  AppRouter({
    required AuthStatusProvider authStatusProvider,
    required AppRouterPageFactory pageFactory,
  }) : _authStatusProvider = authStatusProvider,
       _pageFactory = pageFactory;

  final AuthStatusProvider _authStatusProvider;
  final AppRouterPageFactory _pageFactory;

  /// The configured [GoRouter] instance.
  ///
  /// Assign to [MaterialApp.router] via [MaterialApp.router]'s
  /// `routerConfig` parameter.
  late final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: _authStatusProvider,
    redirect: _globalRedirect,
    errorBuilder: _pageFactory.buildNotFoundPage,
    routes: _buildRoutes(),
  );

  // ── Global redirect ──────────────────────────────────────────────────────

  String? _globalRedirect(BuildContext context, GoRouterState state) {
    final authRedirect = RouteGuard.authGuard(state, _authStatusProvider);
    if (authRedirect != null) return authRedirect;

    final featureRedirect = RouteGuard.featureFlagGuard(state);
    if (featureRedirect != null) return featureRedirect;

    return null;
  }

  // ── Route tree ───────────────────────────────────────────────────────────

  List<RouteBase> _buildRoutes() => <RouteBase>[
    // ── Bootstrap ──────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.splash,
      builder: (context, state) => _pageFactory.buildSplashPage(state),
    ),

    // ── Onboarding ─────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.onboarding,
      builder: (context, state) => _pageFactory.buildOnboardingPage(state),
    ),

    // ── Authentication shell ────────────────────────────────────────────
    GoRoute(
      path: RouteNames.auth,
      redirect: (_, state) =>
          state.uri.path == RouteNames.auth ? RouteNames.login : null,
      routes: <RouteBase>[
        GoRoute(
          path: 'login',
          builder: (context, state) => _pageFactory.buildLoginPage(state),
        ),
        GoRoute(
          path: 'register',
          builder: (context, state) => _pageFactory.buildRegisterPage(state),
        ),
        GoRoute(
          path: 'forgot-password',
          builder: (context, state) =>
              _pageFactory.buildForgotPasswordPage(state),
        ),
        GoRoute(
          path: 'reset-password',
          builder: (context, state) =>
              _pageFactory.buildResetPasswordPage(state),
        ),
        GoRoute(
          path: 'verify-email',
          builder: (context, state) => _pageFactory.buildVerifyEmailPage(state),
        ),
      ],
    ),

    // ── Main shell (bottom navigation) ─────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: _pageFactory.buildMainShell,
      branches: <StatefulShellBranch>[
        // Tab 0 — Chat
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: RouteNames.chat,
              builder: (context, state) =>
                  _pageFactory.buildChatListPage(state),
              routes: <RouteBase>[
                GoRoute(
                  path: ':${RouteNames.paramConversationId}',
                  builder: (context, state) => _pageFactory.buildChatPage(
                    state,
                    state.pathParameters[RouteNames.paramConversationId] ?? '',
                  ),
                ),
              ],
            ),
          ],
        ),

        // Tab 1 — Models
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: RouteNames.models,
              builder: (context, state) => _pageFactory.buildModelsPage(state),
            ),
          ],
        ),

        // Tab 2 — Profile
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: RouteNames.profile,
              builder: (context, state) => _pageFactory.buildProfilePage(state),
            ),
          ],
        ),

        // Tab 3 — Settings
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: RouteNames.settings,
              builder: (context, state) =>
                  _pageFactory.buildSettingsPage(state),
            ),
          ],
        ),
      ],
    ),

    // ── Feature screens (pushed over the shell) ─────────────────────────
    GoRoute(
      path: RouteNames.search,
      builder: (context, state) => _pageFactory.buildSearchPage(state),
    ),
    GoRoute(
      path: RouteNames.notifications,
      builder: (context, state) => _pageFactory.buildNotificationsPage(state),
    ),
    GoRoute(
      path: RouteNames.files,
      builder: (context, state) => _pageFactory.buildFilesPage(state),
    ),
    GoRoute(
      path: RouteNames.subscriptions,
      builder: (context, state) => _pageFactory.buildSubscriptionsPage(state),
    ),
    GoRoute(
      path: RouteNames.payments,
      builder: (context, state) => _pageFactory.buildPaymentsPage(state),
    ),
    GoRoute(
      path: RouteNames.agents,
      builder: (context, state) => _pageFactory.buildAgentsPage(state),
    ),
  ];
}
