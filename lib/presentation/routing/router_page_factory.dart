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
  Widget buildSplashPage(BuildContext context, GoRouterState state) =>
      const SplashScreen();

  @override
  Widget buildOnboardingPage(BuildContext context, GoRouterState state) =>
      const OnboardingScreen();

  // ── Authentication ────────────────────────────────────────────────────────

  @override
  Widget buildLoginPage(BuildContext context, GoRouterState state) =>
      const LoginScreen();

  @override
  Widget buildRegisterPage(BuildContext context, GoRouterState state) =>
      const RegisterScreen();

  @override
  Widget buildForgotPasswordPage(BuildContext context, GoRouterState state) =>
      const ForgotPasswordScreen();

  @override
  Widget buildResetPasswordPage(BuildContext context, GoRouterState state) =>
      const ResetPasswordScreen();

  @override
  Widget buildVerifyEmailPage(BuildContext context, GoRouterState state) =>
      const VerifyEmailScreen();

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
  Widget buildChatListPage(BuildContext context, GoRouterState state) =>
      const ConversationsScreen();

  @override
  Widget buildChatPage(
    BuildContext context,
    GoRouterState state,
    String conversationId,
  ) {
    return ChatScreen(conversationId: conversationId);
  }

  @override
  Widget buildModelsPage(BuildContext context, GoRouterState state) =>
      const ModelsScreen();

  @override
  Widget buildProfilePage(BuildContext context, GoRouterState state) =>
      const ProfileScreen();

  @override
  Widget buildSettingsPage(BuildContext context, GoRouterState state) =>
      const SettingsScreen();

  // ── Feature screens ───────────────────────────────────────────────────────

  @override
  Widget buildSearchPage(BuildContext context, GoRouterState state) =>
      const SearchScreen();

  @override
  Widget buildNotificationsPage(BuildContext context, GoRouterState state) =>
      const NotificationsScreen();

  @override
  Widget buildFilesPage(BuildContext context, GoRouterState state) =>
      const FilesScreen();

  @override
  Widget buildSubscriptionsPage(BuildContext context, GoRouterState state) =>
      const SubscriptionScreen();

  @override
  Widget buildPaymentsPage(BuildContext context, GoRouterState state) =>
      const PaymentsScreen();

  @override
  Widget buildAgentsPage(BuildContext context, GoRouterState state) =>
      const AgentsScreen();

  @override
  Widget buildNotFoundPage(BuildContext context, GoRouterState state) =>
      const NotFoundScreen();
}
