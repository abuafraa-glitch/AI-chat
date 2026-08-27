import 'package:ai_chat/core/routes/app_router.dart';
import 'package:ai_chat/presentation/screens/agents_screen.dart';
import 'package:ai_chat/presentation/screens/chat_screen.dart';
import 'package:ai_chat/presentation/screens/conversations_screen.dart';
import 'package:ai_chat/presentation/screens/files_screen.dart';
import 'package:ai_chat/presentation/screens/forgot_password_screen.dart';
import 'package:ai_chat/presentation/screens/login_screen.dart';
import 'package:ai_chat/presentation/screens/main_layout.dart';
import 'package:ai_chat/presentation/screens/models_screen.dart';
import 'package:ai_chat/presentation/screens/not_found_screen.dart';
import 'package:ai_chat/presentation/screens/notifications_screen.dart';
import 'package:ai_chat/presentation/screens/onboarding_screen.dart';
import 'package:ai_chat/presentation/screens/payments_screen.dart';
import 'package:ai_chat/presentation/screens/profile_screen.dart';
import 'package:ai_chat/presentation/screens/register_screen.dart';
import 'package:ai_chat/presentation/screens/reset_password_screen.dart';
import 'package:ai_chat/presentation/screens/search_screen.dart';
import 'package:ai_chat/presentation/screens/settings_screen.dart';
import 'package:ai_chat/presentation/screens/splash_screen.dart';
import 'package:ai_chat/presentation/screens/subscription_screen.dart';
import 'package:ai_chat/presentation/screens/verify_email_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Maps every route declared by [AppRouter] to its concrete screen.
///
/// Screens are plain const constructions — the router hands each one
/// the [GoRouterState] it needs (path parameters, extras) and the DI
/// container provides any service dependencies.
final class RouterPageFactory implements AppRouterPageFactory {
  /// Creates a [RouterPageFactory].
  const RouterPageFactory();

  // ── Bootstrap ─────────────────────────────────────────────────────────────

  @override
  Widget buildSplashPage(GoRouterState state) => const SplashScreen();

  @override
  Widget buildOnboardingPage(GoRouterState state) => const OnboardingScreen();

  // ── Authentication ────────────────────────────────────────────────────────

  @override
  Widget buildLoginPage(GoRouterState state) => const LoginScreen();

  @override
  Widget buildRegisterPage(GoRouterState state) => const RegisterScreen();

  @override
  Widget buildForgotPasswordPage(GoRouterState state) =>
      const ForgotPasswordScreen();

  @override
  Widget buildResetPasswordPage(GoRouterState state) =>
      const ResetPasswordScreen();

  @override
  Widget buildVerifyEmailPage(GoRouterState state) => VerifyEmailScreen(
        initialEmail: state.uri.queryParameters['email'],
      );

  // ── Main shell ────────────────────────────────────────────────────────────

  @override
  Widget buildMainShell(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return MainLayout(navigationShell: navigationShell);
  }

  @override
  Widget buildChatListPage(GoRouterState state) => const ConversationsScreen();

  @override
  Widget buildChatPage(GoRouterState state, String conversationId) {
    return ChatScreen(conversationId: conversationId);
  }

  @override
  Widget buildModelsPage(GoRouterState state) => const ModelsScreen();

  @override
  Widget buildProfilePage(GoRouterState state) => const ProfileScreen();

  @override
  Widget buildSettingsPage(GoRouterState state) => const SettingsScreen();

  // ── Feature screens ───────────────────────────────────────────────────────

  @override
  Widget buildSearchPage(GoRouterState state) => const SearchScreen();

  @override
  Widget buildNotificationsPage(GoRouterState state) =>
      const NotificationsScreen();

  @override
  Widget buildFilesPage(GoRouterState state) => const FilesScreen();

  @override
  Widget buildSubscriptionsPage(GoRouterState state) =>
      const SubscriptionScreen();

  @override
  Widget buildPaymentsPage(GoRouterState state) => const PaymentsScreen();

  @override
  Widget buildAgentsPage(GoRouterState state) => const AgentsScreen();

  @override
  Widget buildNotFoundPage(BuildContext context, GoRouterState state) =>
      const NotFoundScreen();
}
