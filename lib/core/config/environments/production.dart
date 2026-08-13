import '../app_config.dart';
import '../flavor.dart';

/// Configuration for the customer-facing production environment.
///
/// All debug surfaces and verbose logging are disabled, network
/// timeouts are tight, and feature flags expose only what has been
/// fully released. The defaults baked into [FeatureFlags] are
/// production-safe; anything added here is an explicit opt-in.
base class ProductionConfig extends EnvironmentConfig {
  const ProductionConfig();

  @override
  AppConfig build() {
    return const AppConfig.internal(
      appName: const String.fromEnvironment(
        'APP_NAME',
        defaultValue: 'Hajeen AI',
      ),
      appVersion: const String.fromEnvironment(
        'APP_VERSION',
        defaultValue: '1.0.0+1',
      ),
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.hajeen.ai',
      ),
      webSocketUrl: const String.fromEnvironment(
        'WS_BASE_URL',
        defaultValue: 'wss://ws.hajeen.ai',
      ),
      apiVersion: const String.fromEnvironment(
        'API_VERSION',
        defaultValue: 'v1',
      ),
      flavor: Flavor.production,
      connectionTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      debugMode: false,
      enableLogging: false,
      featureFlags: const FeatureFlags(
        // Core, verified surfaces that do not depend on unverified
        // backend contracts.
        enableChat: true,
        enableAiModelSelection: true,
        enableWebSocketStreaming: true,
        enableMultiModelSwitching: true,
        // Backend-dependent or unverified surfaces are disabled in
        // production until their contracts are confirmed. The route
        // feature-flag guard redirects these to the chat surface.
        enableSubscriptions: false,
        enablePayments: false,
        enableFileManagement: false,
        enableSearch: false,
        enableRag: false,
        enableAgents: false,
        enableNotifications: false,
      ),
    );
  }
}
