import 'package:ai_chat/core/config/app_config.dart';
import 'package:ai_chat/core/di/injection.dart';
import 'package:ai_chat/core/routes/app_router.dart';
import 'package:ai_chat/core/services/local_storage_service.dart';
import 'package:ai_chat/core/theme/app_theme.dart';
import 'package:ai_chat/core/theme/theme_cubit.dart';
import 'package:ai_chat/presentation/blocs/localization_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nested/nested.dart';

/// Root widget of the Hajeen AI application.
///
/// Provides the two application-wide cubits — [ThemeCubit] and
/// [LocalizationCubit] — so every route (including pages pushed above
/// the main shell) can react to theme and locale changes, then mounts
/// [MaterialApp.router] with the [AppRouter] instance built by the DI
/// container.
class HajeenAIApp extends StatelessWidget {
  /// Creates the [HajeenAIApp].
  const HajeenAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<ThemeCubit>(
          create: (context) => sl<ThemeCubit>()..loadSavedTheme(),
        ),
        BlocProvider<LocalizationCubit>(
          create: (context) =>
              LocalizationCubit(storage: sl<LocalStorageService>()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LocalizationCubit, LocalizationState>(
            builder: (context, localeState) {
              return MaterialApp.router(
                title: AppConfig.instance.appName,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeState.mode,
                locale: Locale(localeState.locale),
                supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
                localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                routerConfig: sl<AppRouter>().router,
              );
            },
          );
        },
      ),
    );
  }
}
