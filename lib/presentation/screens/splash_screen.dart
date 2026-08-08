import 'package:ai_chat/core/config/app_config.dart';
import 'package:ai_chat/core/constants/app_constants.dart';
import 'package:ai_chat/core/di/injection.dart';
import 'package:ai_chat/core/routes/route_guards.dart';
import 'package:ai_chat/core/routes/route_names.dart';
import 'package:ai_chat/core/theme/app_colors.dart';
import 'package:ai_chat/core/theme/app_text_styles.dart';
import 'package:ai_chat/presentation/blocs/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Splash / bootstrap screen.
///
/// Shown on cold start while the persisted session is resolved. Once
/// [AuthController.bootstrap] completes, the user is routed to the
/// chat (authenticated), login (onboarding completed) or onboarding
/// flow. The screen never touches the network itself — it only
/// triggers the bootstrap and navigates.
class SplashScreen extends StatefulWidget {
  /// Creates a [SplashScreen].
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = sl<AuthController>();
    final startedAt = DateTime.now();
    await auth.bootstrap();

    // Enforce a minimum splash display time for a polished start.
    final elapsed = DateTime.now().difference(startedAt);
    final remaining = AppDurations.splashMin - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

    if (!mounted) {
      return;
    }
    switch (auth.status) {
      case AuthStatus.authenticated:
        context.go(RouteNames.chat);
      case AuthStatus.unauthenticated:
        context.go(
          auth.hasCompletedOnboarding
              ? RouteNames.login
              : RouteNames.onboarding,
        );
      case AuthStatus.loading:
        // Bootstrap is guaranteed to have resolved above; nothing to do.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.heroGradientDark
              : AppColors.heroGradientLight,
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              const Spacer(flex: 3),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 52,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppConfig.instance.appName,
                style: AppTextStyles.headlineLarge.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(flex: 2),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
