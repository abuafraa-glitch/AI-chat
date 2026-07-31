import 'package:ai_chat/core/constants/api_constants.dart';

/// Typed endpoint factory for the Hajeen AI REST API.
///
/// Simple, path-only routes are exposed as `const String` constants
/// sourced from [ApiPaths]. Routes that require path parameters are
/// provided as static builder methods that interpolate the parameter
/// into the final path string.
///
/// All strings are **path-only** (no base URL, no version prefix).
/// The base URL and API version are prepended by [DioFactory] through
/// [AppConfig.resolvedApiUrl].
///
/// Usage:
/// ```dart
/// final url = Endpoints.conversation('abc-123');
/// // → '/conversations/abc-123'
/// ```
abstract final class Endpoints {
  const Endpoints._();

  // ── Authentication ────────────────────────────────────────────────────────

  /// `POST /auth/login` — exchange credentials for a token pair.
  static const String login = ApiPaths.authLogin;

  /// `POST /auth/register` — create a new user account.
  static const String register = ApiPaths.authRegister;

  /// `POST /auth/refresh` — rotate the access token using a refresh token.
  static const String refresh = ApiPaths.authRefresh;

  /// `POST /auth/logout` — invalidate the current session server-side.
  static const String logout = ApiPaths.authLogout;

  /// `POST /auth/forgot-password` — initiate a password-reset flow.
  static const String forgotPassword = ApiPaths.authForgotPassword;

  /// `POST /auth/reset-password` — complete a password reset with a token.
  static const String resetPassword = '/auth/reset-password';

  /// `POST /auth/verify-email` — confirm an email address with a code.
  static const String verifyEmail = '/auth/verify-email';

  /// `POST /auth/resend-verification` — resend the email verification code.
  static const String resendVerification = '/auth/resend-verification';

  // ── Users / Profile ───────────────────────────────────────────────────────

  /// `GET | PATCH /users/me` — fetch or update the authenticated user.
  static const String me = ApiPaths.usersMe;

  /// `PUT /users/me/password` — change the authenticated user's password.
  static const String changePassword = '/users/me/password';

  /// `DELETE /users/me` — permanently delete the authenticated account.
  static const String deleteAccount = '/users/me';

  /// `POST /users/me/avatar` — upload a new profile picture.
  static const String uploadAvatar = ApiPaths.usersMeAvatar;

  // ── Conversations ─────────────────────────────────────────────────────────

  /// `GET | POST /conversations` — list or create conversations.
  static const String conversations = ApiPaths.conversations;

  /// `GET | PATCH | DELETE /conversations/{id}`.
  static String conversation(String id) => '/conversations/$id';

  /// `PATCH /conversations/{id}/title` — rename a conversation.
  static String conversationTitle(String id) => '/conversations/$id/title';

  /// `GET | POST /conversations/{id}/messages`.
  static String conversationMessages(String id) =>
      '/conversations/$id/messages';

  /// `GET | DELETE /conversations/{id}/messages/{messageId}`.
  static String conversationMessage(String id, String messageId) =>
      '/conversations/$id/messages/$messageId';

  /// `POST /conversations/{id}/messages/{messageId}/regenerate`
  /// — trigger a new model generation for an existing message.
  static String regenerateMessage(String id, String messageId) =>
      '/conversations/$id/messages/$messageId/regenerate';

  /// `POST /conversations/{id}/messages/stream`
  /// — SSE / streaming endpoint for real-time token delivery.
  static String streamMessage(String id) =>
      '/conversations/$id/messages/stream';

  // ── AI Models ─────────────────────────────────────────────────────────────

  /// `GET /models` — list all available AI models.
  static const String models = ApiPaths.models;

  /// `GET /models/{id}` — fetch a single model's details.
  static String model(String id) => '/models/$id';

  // ── Subscriptions ─────────────────────────────────────────────────────────

  /// `GET /subscriptions` — list available subscription plans.
  static const String subscriptions = ApiPaths.subscriptions;

  /// `GET /subscriptions/current` — fetch the user's active subscription.
  static const String currentSubscription = '/subscriptions/current';

  /// `GET /subscriptions/plans` — list all purchasable plans.
  static const String subscriptionPlans = '/subscriptions/plans';

  /// `POST /subscriptions/{id}/cancel` — cancel a subscription.
  static String cancelSubscription(String id) => '/subscriptions/$id/cancel';

  // ── Payments ──────────────────────────────────────────────────────────────

  /// `POST /payments/intent` — create a payment intent.
  static const String paymentIntent = '/payments/intent';

  /// `GET /payments/history` — list the user's payment history.
  static const String paymentHistory = '/payments/history';

  /// `GET /payments/{id}` — fetch a single payment record.
  static String payment(String id) => '/payments/$id';

  // ── File Management ───────────────────────────────────────────────────────

  /// `GET | POST /files` — list or upload files.
  static const String files = ApiPaths.files;

  /// `GET | DELETE /files/{id}` — fetch or delete a single file.
  static String file(String id) => '/files/$id';

  /// `GET /files/{id}/download` — get a signed download URL.
  static String fileDownload(String id) => '/files/$id/download';

  // ── Search ────────────────────────────────────────────────────────────────

  /// `GET /search` — global full-text search across all content.
  static const String search = ApiPaths.search;

  /// `GET /search/conversations` — search within conversations.
  static const String searchConversations = '/search/conversations';

  /// `GET /search/files` — search within uploaded files.
  static const String searchFiles = '/search/files';

  // ── RAG ───────────────────────────────────────────────────────────────────

  /// `GET | POST /rag/documents` — list or add RAG documents.
  static const String ragDocuments = '/rag/documents';

  /// `GET | DELETE /rag/documents/{id}`.
  static String ragDocument(String id) => '/rag/documents/$id';

  /// `POST /rag/query` — run a RAG-augmented query.
  static const String ragQuery = '/rag/query';

  // ── Agents ────────────────────────────────────────────────────────────────

  /// `GET | POST /agents` — list or create agent definitions.
  static const String agents = ApiPaths.agents;

  /// `GET | PATCH | DELETE /agents/{id}`.
  static String agent(String id) => '/agents/$id';

  /// `GET | POST /agents/runs` — list or start agent runs.
  static const String agentRuns = '/agents/runs';

  /// `GET /agents/runs/{id}` — get the status of a single run.
  static String agentRun(String id) => '/agents/runs/$id';

  /// `POST /agents/runs/{id}/cancel` — abort an in-flight run.
  static String cancelAgentRun(String id) => '/agents/runs/$id/cancel';

  // ── Notifications ─────────────────────────────────────────────────────────

  /// `GET /notifications` — list in-app notifications.
  static const String notifications = ApiPaths.notifications;

  /// `PATCH /notifications/{id}` — mark a single notification read.
  static String notification(String id) => '/notifications/$id';

  /// `POST /notifications/read-all` — mark all notifications read.
  static const String markAllNotificationsRead = '/notifications/read-all';

  // ── System ────────────────────────────────────────────────────────────────

  /// `GET /health` — API liveness probe.
  static const String health = ApiPaths.health;
}
