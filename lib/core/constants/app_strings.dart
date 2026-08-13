/// Non-localizable string constants used in code logic.
///
/// These identifiers are **never shown directly to end users**;
/// they appear in logs, analytics events, crash reports, JSON
/// payloads, storage keys and feature flags. Anything visible in
/// the UI must go through the localization layer in
/// `lib/localization/`.
abstract final class AppStrings {
  const AppStrings._();

  // ---- Application identity -------------------------------------------------

  /// Canonical product identifier used by analytics, crash
  /// reporting and store metadata.
  static const String appIdentifier = 'hajeen_ai';

  /// Short marketing name used as a logger tag.
  static const String appTag = 'HajeenAI';

  // ---- Logger tags ----------------------------------------------------------

  /// Tag used by the global logger for network-layer output.
  static const String logTagNetwork = 'network';

  /// Tag used by the global logger for storage-layer output.
  static const String logTagStorage = 'storage';

  /// Tag used by the global logger for auth-layer output.
  static const String logTagAuth = 'auth';

  /// Tag used by the global logger for WebSocket output.
  static const String logTagWebSocket = 'websocket';

  /// Tag used by the global logger for cache output.
  static const String logTagCache = 'cache';

  /// Tag used by the global logger for analytics output.
  static const String logTagAnalytics = 'analytics';

  /// Tag used by the global logger for navigation output.
  static const String logTagNavigation = 'navigation';

  // ---- Locale codes ---------------------------------------------------------

  /// `en` — English locale code.
  static const String localeEn = 'en';

  /// `ar` — Arabic locale code.
  static const String localeAr = 'ar';

  /// Locale codes the application explicitly supports.
  static const List<String> supportedLocaleCodes = <String>[localeEn, localeAr];

  // ---- Platform identifiers -------------------------------------------------

  /// Platform identifier sent in `X-Platform` for iOS clients.
  static const String platformIos = 'ios';

  /// Platform identifier sent in `X-Platform` for Android clients.
  static const String platformAndroid = 'android';

  /// Platform identifier sent in `X-Platform` for web clients.
  static const String platformWeb = 'web';

  /// Platform identifier sent in `X-Platform` for desktop clients.
  static const String platformMacos = 'macos';

  /// Platform identifier sent in `X-Platform` for Windows clients.
  static const String platformWindows = 'windows';

  /// Platform identifier sent in `X-Platform` for Linux clients.
  static const String platformLinux = 'linux';

  /// Platform identifier used when the platform cannot be determined.
  static const String platformUnknown = 'unknown';

  // ---- Theme mode identifiers ----------------------------------------------

  /// Persisted value of `ThemeMode.system`.
  static const String themeModeSystem = 'system';

  /// Persisted value of `ThemeMode.light`.
  static const String themeModeLight = 'light';

  /// Persisted value of `ThemeMode.dark`.
  static const String themeModeDark = 'dark';

  // ---- Text-scale identifiers ----------------------------------------------

  /// Persisted value of the `small` text scale.
  static const String textScaleSmall = 'small';

  /// Persisted value of the `normal` text scale.
  static const String textScaleNormal = 'normal';

  /// Persisted value of the `large` text scale.
  static const String textScaleLarge = 'large';

  // ---- Currency codes -------------------------------------------------------

  /// ISO-4217 code for US Dollar.
  static const String currencyUsd = 'USD';

  /// ISO-4217 code for Euro.
  static const String currencyEur = 'EUR';

  /// ISO-4217 code for Saudi Riyal.
  static const String currencySar = 'SAR';

  /// ISO-4217 code for UAE Dirham.
  static const String currencyAed = 'AED';

  /// ISO-4217 code for Egyptian Pound.
  static const String currencyEgp = 'EGP';

  // ---- Semantic error codes (for crash reporting) ---------------------------

  /// Network connectivity lost.
  static const String errorCodeNoConnection = 'ERR_NO_CONNECTION';

  /// Request exceeded the configured timeout.
  static const String errorCodeTimeout = 'ERR_TIMEOUT';

  /// Server returned a 5xx response.
  static const String errorCodeServer = 'ERR_SERVER';

  /// Request payload failed validation.
  static const String errorCodeValidation = 'ERR_VALIDATION';

  /// Authentication token is missing or expired.
  static const String errorCodeUnauthenticated = 'ERR_UNAUTHENTICATED';

  /// Authenticated user is not permitted to perform the action.
  static const String errorCodeForbidden = 'ERR_FORBIDDEN';

  /// Requested resource was not found.
  static const String errorCodeNotFound = 'ERR_NOT_FOUND';

  /// Rate-limit threshold exceeded.
  static const String errorCodeRateLimited = 'ERR_RATE_LIMITED';

  /// Catch-all code for unmapped failures.
  static const String errorCodeUnknown = 'ERR_UNKNOWN';

  // ---- Semantic empty-state codes (for analytics) ---------------------------

  /// Conversation list is empty.
  static const String emptyStateConversations = 'EMPTY_CONVERSATIONS';

  /// Model list is empty.
  static const String emptyStateModels = 'EMPTY_MODELS';

  /// Search returned no results.
  static const String emptyStateSearch = 'EMPTY_SEARCH';

  /// Notification feed is empty.
  static const String emptyStateNotifications = 'EMPTY_NOTIFICATIONS';

  /// File list is empty.
  static const String emptyStateFiles = 'EMPTY_FILES';

  // ---- Semantic event names (for analytics) --------------------------------

  /// User opened the application.
  static const String eventAppOpened = 'app_opened';

  /// User signed in successfully.
  static const String eventUserSignedIn = 'user_signed_in';

  /// User signed out.
  static const String eventUserSignedOut = 'user_signed_out';

  /// User sent a chat message.
  static const String eventMessageSent = 'message_sent';

  /// User started a new conversation.
  static const String eventConversationStarted = 'conversation_started';

  /// User selected a new AI model.
  static const String eventModelSelected = 'model_selected';

  /// User opened the paywall.
  static const String eventPaywallOpened = 'paywall_opened';

  /// User completed a subscription purchase.
  static const String eventSubscriptionPurchased = 'subscription_purchased';

  // ---- Header / payload literals -------------------------------------------

  /// Token type sent in OAuth flows.
  static const String tokenTypeBearer = 'bearer';

  /// Scope string requested during OAuth flows.
  static const String defaultOAuthScope = 'openid profile email offline_access';

  // ---- Semantic role identifiers (for analytics) ---------------------------

  /// Anonymous / unauthenticated role.
  static const String userRoleAnonymous = 'anonymous';

  /// Standard authenticated user role.
  static const String userRoleUser = 'user';

  /// Premium-tier user role.
  static const String userRolePro = 'pro';

  /// Internal staff role used by admin tooling.
  static const String userRoleStaff = 'staff';
}
