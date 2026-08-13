import 'package:ai_chat/core/config/app_config.dart';
import 'package:ai_chat/core/config/flavor.dart';

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
      appName: String.fromEnvironment('APP_NAME', defaultValue: 'Hajeen AI'),
      appVersion: String.fromEnvironment(
        'APP_VERSION',
        defaultValue: '1.0.0+1',
      ),
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.hajeen.ai',
      ),
      webSocketUrl: String.fromEnvironment(
        'WS_BASE_URL',
        defaultValue: 'wss://ws.hajeen.ai',
      ),
      apiVersion: String.fromEnvironment('API_VERSION', defaultValue: 'v1'),
      flavor: Flavor.production,
      connectionTimeout: Duration(seconds: 20),
      receiveTimeout: Duration(seconds: 30),
      debugMode: false,
      enableLogging: false,
      featureFlags: FeatureFlags(
        enableChat: true,
        enableAiModelSelection: true,
        enableSubscriptions: true,
        enablePayments: true,
        enableFileManagement: true,
        enableSearch: true,
        enableRag: true,
        enableAgents: true,
        enableWebSocketStreaming: true,
        enableNotifications: true,
        enableMultiModelSwitching: true,
      ),
    );
  }
}
