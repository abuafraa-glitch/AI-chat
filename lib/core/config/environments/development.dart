import '../app_config.dart';
import '../flavor.dart';

/// Configuration for the local development environment.
///
/// Verbose logging and debug surfaces are enabled, all feature flags
/// are turned on so engineers can exercise every code path, and
/// timeouts are generous to absorb local backend latency.
base class DevelopmentConfig extends EnvironmentConfig {
  const DevelopmentConfig();

  @override
  AppConfig build() {
    return const AppConfig.internal(
      appName: const String.fromEnvironment(
        'APP_NAME',
        defaultValue: 'Hajeen AI Dev',
      ),
      appVersion: const String.fromEnvironment(
        'APP_VERSION',
        defaultValue: '1.0.0+1',
      ),
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api-dev.hajeen.ai',
      ),
      webSocketUrl: const String.fromEnvironment(
        'WS_BASE_URL',
        defaultValue: 'wss://ws-dev.hajeen.ai',
      ),
      apiVersion: const String.fromEnvironment(
        'API_VERSION',
        defaultValue: 'v1',
      ),
      flavor: Flavor.development,
      connectionTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 60),
      debugMode: true,
      enableLogging: true,
      featureFlags: const FeatureFlags(
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
