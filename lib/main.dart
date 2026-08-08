import 'package:ai_chat/app.dart';
import 'package:ai_chat/core/config/app_config.dart';
import 'package:ai_chat/core/config/flavor.dart';
import 'package:ai_chat/core/di/injection.dart';
import 'package:flutter/material.dart';

/// Application entry point.
///
/// Bootstraps the immutable [AppConfig] from the build-time flavor,
/// initialises the DI container (services, data sources, repositories,
/// cubits and the router) and then hands control to [HajeenAIApp].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.initialize(AppConfig.forFlavor(Flavor.fromEnvironment()));
  await initDependencies();
  runApp(const HajeenAIApp());
}
