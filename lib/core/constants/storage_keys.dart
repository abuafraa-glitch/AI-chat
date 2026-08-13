/// Keys used with the on-device `SharedPreferences`-style local
/// storage service. Values are **non-sensitive**: tokens, refresh
/// tokens and similar secrets belong in [SecureStorageKeys].
abstract final class StorageKeys {
  const StorageKeys._();

  // ---- App-level bootstrap --------------------------------------------------

  /// Marks that the first-launch onboarding flow has been completed.
  static const String onboardingCompleted = 'app.onboarding.completed';

  /// Last selected UI locale code (e.g. `en`, `ar`).
  static const String locale = 'app.locale';

  /// Last selected UI theme mode (`system`, `light`, `dark`).
  static const String themeMode = 'app.theme_mode';

  /// Identifier of the last opened conversation.
  static const String lastOpenedConversationId =
      'app.last_opened_conversation_id';

  // ---- Authenticated user profile (non-sensitive) ---------------------------

  /// User id of the currently signed-in account.
  static const String currentUserId = 'auth.current_user_id';

  /// Display name cached for offline UI rendering.
  static const String currentUserDisplayName = 'auth.current_user_display_name';

  /// Email address cached for offline UI rendering.
  static const String currentUserEmail = 'auth.current_user_email';

  /// Avatar URL cached for offline UI rendering.
  static const String currentUserAvatarUrl = 'auth.current_user_avatar_url';

  /// Aggregated JSON blob of the currently signed-in user profile
  /// (non-sensitive), cached for offline rendering by the local data
  /// source. Distinct from the individual `auth.current_user_*` fields
  /// above, which mirror the same data as typed primitives for the auth
  /// controller and profile screen.
  static const String currentUser = 'auth.current_user';

  /// Expiration timestamp of the access token (milliseconds since epoch).
  static const String accessTokenExpiresAt = 'auth.access_token_expires_at';

  // ---- User preferences -----------------------------------------------------

  /// Preferred text size for the chat surface (`small`, `normal`, `large`).
  static const String preferredTextScale = 'pref.text_scale';

  /// Whether markdown rendering is enabled in chat messages.
  static const String markdownEnabled = 'pref.markdown_enabled';

  /// Whether the user opted in to analytics collection.
  static const String analyticsOptIn = 'pref.analytics_opt_in';

  /// Whether the user opted in to crash reporting.
  static const String crashReportingOptIn = 'pref.crash_reporting_opt_in';

  /// Whether the user opted in to marketing notifications.
  static const String marketingNotificationsOptIn =
      'pref.marketing_notifications_opt_in';

  /// Identifier of the most recently used AI model.
  static const String lastSelectedModelId = 'pref.last_selected_model_id';

  // ---- Cached domain data (deletable, refreshable) --------------------------

  /// JSON blob caching the user subscription summary.
  static const String subscriptionCache = 'cache.subscription.summary';

  /// JSON blob caching the AI model catalogue.
  static const String modelCatalogCache = 'cache.models.catalogue';

  /// JSON blob caching the recent conversation list.
  static const String conversationsCache = 'cache.conversations.recent';

  /// ISO-8601 timestamp of the last successful catalogue sync.
  static const String modelCatalogSyncedAt = 'cache.models.synced_at';
}

/// Keys used with the platform secure storage service. Values are
/// **sensitive** and must never be logged or persisted to plain
/// `SharedPreferences`.
abstract final class SecureStorageKeys {
  const SecureStorageKeys._();

  /// Short-lived access token used for REST authentication.
  static const String accessToken = 'secure.access_token';

  /// Long-lived refresh token used to mint new access tokens.
  static const String refreshToken = 'secure.refresh_token';

  /// Persistent device-registration id for push notifications.
  static const String pushDeviceToken = 'secure.push_device_token';

  /// Encrypted-at-rest copy of the biometric-protected API key (if any).
  static const String biometricApiKey = 'secure.biometric_api_key';

  /// PIN code hash guarding local-only features.
  static const String pinCodeHash = 'secure.pin_code_hash';
}

/// Keys used with the in-memory cache layer (`CacheService`).
/// These keys are scoped to the running process and never persisted.
abstract final class CacheKeys {
  const CacheKeys._();

  /// Cached representation of the current user profile.
  static const String currentUser = 'memory.current_user';

  /// Cached list of available AI models.
  static const String availableModels = 'memory.available_models';

  /// Cached subscription status for the current user.
  static const String currentSubscription = 'memory.current_subscription';

  /// Cached list of the user's conversations.
  static const String conversations = 'memory.conversations';

  /// Cached message thread for a single conversation id.
  static String conversationMessages(String conversationId) =>
      'memory.conversation.$conversationId.messages';

  /// Cached connectivity status snapshot.
  static const String connectivityStatus = 'memory.connectivity_status';

  /// Cached unread notifications count.
  static const String unreadNotificationsCount =
      'memory.unread_notifications_count';
}
