import 'package:ai_chat/core/config/app_config.dart';
import 'package:ai_chat/core/config/flavor.dart';

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
      appName: String.fromEnvironment(
        'APP_NAME',
        defaultValue: 'Hajeen AI Staging',
      ),
      appVersion: String.fromEnvironment(
        'APP_VERSION',
        defaultValue: '1.0.0+1',
      ),
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api-staging.hajeen.ai',
      ),
      webSocketUrl: String.fromEnvironment(
        'WS_BASE_URL',
        defaultValue: 'wss://ws-staging.hajeen.ai',
      ),
      apiVersion: String.fromEnvironment('API_VERSION', defaultValue: 'v1'),
      flavor: Flavor.staging,
      connectionTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 60),
      debugMode: true,
      enableLogging: true,
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
