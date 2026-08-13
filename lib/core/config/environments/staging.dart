import '../app_config.dart';
import '../flavor.dart';

/// Configuration for the staging environment.
///
/// Staging mirrors production's shape and constraints, but exposes
/// limited logging/debug affordances so QA and release engineering
/// can validate behavior without compromising production safety.
base class StagingConfig extends EnvironmentConfig {
  const StagingConfig();

  @override
  AppConfig build() {
    return const AppConfig.internal(
      appName: const String.fromEnvironment(
        'APP_NAME',
        defaultValue: 'Hajeen AI Staging',
      ),
      appVersion: const String.fromEnvironment(
        'APP_VERSION',
        defaultValue: '1.0.0+1',
      ),
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api-staging.hajeen.ai',
      ),
      webSocketUrl: const String.fromEnvironment(
        'WS_BASE_URL',
        defaultValue: 'wss://ws-staging.hajeen.ai',
      ),
      apiVersion: const String.fromEnvironment(
        'API_VERSION',
        defaultValue: 'v1',
      ),
      flavor: Flavor.staging,
      connectionTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 45),
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
