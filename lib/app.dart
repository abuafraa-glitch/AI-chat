import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme/app_theme.dart';
import 'config/localization/app_localization.dart';
import 'presentation/screens/main_layout.dart';
import 'providers/theme_provider.dart';
import 'providers/localization_provider.dart';

class HajeenAIApp extends ConsumerWidget {
  const HajeenAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final locale = ref.watch(localizationProvider);

    return MaterialApp(
      title: 'Hajeen AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(locale),
      localizationsDelegates: AppLocalization.localizationsDelegates,
      supportedLocales: AppLocalization.supportedLocales,
      home: const MainLayout(),
    );
  }
}
