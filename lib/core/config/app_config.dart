import 'package:ai_chat/core/config/environments/development.dart';
import 'package:ai_chat/core/config/environments/production.dart';
import 'package:ai_chat/core/config/environments/staging.dart';
import 'package:ai_chat/core/config/flavor.dart';

/// Immutable snapshot of feature flags for the active environment.
///
/// Flags are evaluated at boot and treated as immutable for the
/// remainder of the process. Each flag defaults to the strictest
/// (production-safe) value so that omitting a flag in a new
/// environment never accidentally enables an unfinished feature.
class FeatureFlags {
  const FeatureFlags({
    this.enableChat = true,
    this.enableAiModelSelection = true,
    this.enableSubscriptions = false,
    this.enablePayments = false,
    this.enableFileManagement = false,
    this.enableSearch = false,
    this.enableRag = false,
    this.enableAgents = false,
    this.enableWebSocketStreaming = true,
    this.enableNotifications = false,
    this.enableMultiModelSwitching = true,
  });

  /// Master switch for the AI chat surface.
  final bool enableChat;

  /// Whether users may pick which AI model powers a conversation.
  final bool enableAiModelSelection;

  /// Whether the subscription management UI is exposed.
  final bool enableSubscriptions;

  /// Whether paid subscription flows (billing, checkout) are active.
  final bool enablePayments;

  /// Whether file upload, preview, and management features are active.
  final bool enableFileManagement;

  /// Whether in-app search is active.
  final bool enableSearch;

  /// Whether Retrieval-Augmented Generation pipelines are active.
  final bool enableRag;

  /// Whether autonomous agent workflows are active.
  final bool enableAgents;

  /// Whether WebSocket-based streaming responses are active.
  final bool enableWebSocketStreaming;

  /// Whether push and in-app notifications are active.
  final bool enableNotifications;

  /// Whether multiple AI models may co-exist within one conversation.
  final bool enableMultiModelSwitching;

  /// Returns a copy of these flags with any provided overrides applied.
  FeatureFlags copyWith({
    bool? enableChat,
    bool? enableAiModelSelection,
    bool? enableSubscriptions,
    bool? enablePayments,
    bool? enableFileManagement,
    bool? enableSearch,
    bool? enableRag,
    bool? enableAgents,
    bool? enableWebSocketStreaming,
    bool? enableNotifications,
    bool? enableMultiModelSwitching,
  }) {
    return FeatureFlags(
      enableChat: enableChat ?? this.enableChat,
      enableAiModelSelection:
          enableAiModelSelection ?? this.enableAiModelSelection,
      enableSubscriptions: enableSubscriptions ?? this.enableSubscriptions,
      enablePayments: enablePayments ?? this.enablePayments,
      enableFileManagement: enableFileManagement ?? this.enableFileManagement,
      enableSearch: enableSearch ?? this.enableSearch,
      enableRag: enableRag ?? this.enableRag,
      enableAgents: enableAgents ?? this.enableAgents,
      enableWebSocketStreaming:
          enableWebSocketStreaming ?? this.enableWebSocketStreaming,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableMultiModelSwitching:
          enableMultiModelSwitching ?? this.enableMultiModelSwitching,
    );
  }
}

/// Contract that every environment-specific configuration must satisfy.
///
/// Each implementation under `lib/core/config/environments/` is a
/// `const`-constructible value object whose sole responsibility is to
/// materialise the [AppConfig] consumed at runtime. New environments
/// (e.g. `qa`, `canary`) only need to extend this class.
abstract base class EnvironmentConfig {
  const EnvironmentConfig();

  /// Materialises the [AppConfig] for this environment.
  AppConfig build();
}

/// Centralised, immutable application configuration for Hajeen AI.
///
/// A single instance is produced at boot from the active [Flavor] and
/// exposed through [AppConfig.instance]. The only sanctioned way to
/// construct an [AppConfig] is via [AppConfig.forFlavor] or the
/// internal constructor [AppConfig.internal] used by
/// [EnvironmentConfig] implementations.
class AppConfig {
  const AppConfig.internal({
    required this.appName,
    required this.appVersion,
    required this.apiBaseUrl,
    required this.webSocketUrl,
    required this.apiVersion,
    required this.flavor,
    required this.connectionTimeout,
    required this.receiveTimeout,
    required this.sendTimeout,
    required this.debugMode,
    required this.enableLogging,
    required this.featureFlags,
  });

  /// Materialises the [AppConfig] for [flavor] using the matching
  /// environment implementation. This is the only sanctioned way to
  /// construct an [AppConfig] from outside the configuration layer.
  factory AppConfig.forFlavor(Flavor flavor) {
    switch (flavor) {
      case Flavor.development:
        return const DevelopmentConfig().build();
      case Flavor.staging:
        return const StagingConfig().build();
      case Flavor.production:
        return const ProductionConfig().build();
    }
  }

  /// Application display name (e.g. shown in splash and store metadata).
  final String appName;

  /// Semantic version of the current build, typically `MAJOR.MINOR.PATCH+BUILD`.
  final String appVersion;

  /// Base URL of the REST API. Must not include a trailing slash.
  final String apiBaseUrl;

  /// Base URL of the WebSocket gateway. Must not include a trailing slash.
  final String webSocketUrl;

  /// API version segment used for routing (e.g. `v1`).
  final String apiVersion;

  /// Active runtime environment.
  final Flavor flavor;

  /// Maximum duration a connection establishment may take.
  final Duration connectionTimeout;

  /// Maximum duration a complete response may take to arrive.
  final Duration receiveTimeout;

  /// Maximum duration for sending the request body.
  ///
  /// Set generously so large uploads (e.g. file attachments) are not
  /// aborted prematurely; streaming responses are exempted separately
  /// via the streaming request options.
  final Duration sendTimeout;

  /// When `true`, debug-only UI and verbose diagnostics are exposed.
  final bool debugMode;

  /// When `true`, the logger is permitted to emit entries.
  final bool enableLogging;

  /// Snapshot of feature flags for the active environment.
  final FeatureFlags featureFlags;

  /// Fully-qualified API root, composed of the canonical `/api` prefix,
  /// [apiBaseUrl], and [apiVersion].
  ///
  /// This normalization prevents a mobile build from silently targeting
  /// `/v1/...` when the FastAPI gateway is mounted under `/api/v1/...`.
  String get resolvedApiUrl {
    final normalizedBase = apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final apiRoot = normalizedBase.endsWith('/api')
        ? normalizedBase
        : '$normalizedBase/api';
    return '$apiRoot/$apiVersion';
  }

  /// Singleton accessor. Must be initialised via [AppConfig.initialize]
  /// during bootstrap; otherwise a [StateError] is raised to surface
  /// misconfiguration as early as possible.
  static AppConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError(
        'AppConfig has not been initialized. '
        'Call AppConfig.initialize() during application bootstrap.',
      );
    }
    return config;
  }

  static AppConfig? _instance;

  /// Installs [config] as the global [AppConfig] singleton.
  ///
  /// Calling this more than once replaces the previous configuration;
  /// production bootstrap should invoke it exactly once. Tests may
  /// call it repeatedly inside `setUp`/`tearDown`.
  static void initialize(AppConfig config) {
    _instance = config;
  }

  /// Clears the singleton. Intended for test teardown and for
  /// application shutdown paths that need to release the reference.
  static void reset() {
    _instance = null;
  }
}
