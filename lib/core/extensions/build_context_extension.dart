import 'package:ai_chat/core/constants/app_constants.dart';
import 'package:ai_chat/core/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Extensions on [BuildContext] for concise access to theme, media,
/// locale, and navigation primitives used across the Hajeen AI UI.
///
/// All getters delegate to Flutter's established APIs ([Theme.of],
/// [MediaQuery.*Of], [EasyLocalization]) and carry no hidden state —
/// they are pure forwarding helpers.

// ── Theme ─────────────────────────────────────────────────────────────────

extension ThemeBuildContextExtension on BuildContext {
  /// The active [ThemeData] for this context.
  ThemeData get theme => Theme.of(this);

  /// The [ColorScheme] of the active theme.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// The [TextTheme] of the active theme.
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// `true` when the active theme brightness is [Brightness.dark].
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// `true` when the active theme brightness is [Brightness.light].
  bool get isLightMode => !isDarkMode;

  /// The primary colour of the active theme.
  Color get primaryColor => Theme.of(this).colorScheme.primary;

  /// The surface colour of the active theme.
  Color get surfaceColor => Theme.of(this).colorScheme.surface;

  /// The default scaffold background colour.
  Color get scaffoldBackgroundColor => Theme.of(this).scaffoldBackgroundColor;
}

// ── Media query ────────────────────────────────────────────────────────────

extension MediaQueryBuildContextExtension on BuildContext {
  /// Total screen size in logical pixels.
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Screen width in logical pixels.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Screen height in logical pixels.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// System-driven padding (notches, status bar, home indicator).
  EdgeInsets get systemPadding => MediaQuery.paddingOf(this);

  /// Insets caused by the on-screen keyboard.
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  /// The height of the on-screen keyboard, or `0` when not visible.
  double get keyboardHeight => MediaQuery.viewInsetsOf(this).bottom;

  /// `true` when the on-screen keyboard is currently visible.
  bool get isKeyboardVisible => MediaQuery.viewInsetsOf(this).bottom > 0;

  /// Current device text-scale factor.
  double get textScaleFactor => MediaQuery.textScalerOf(this).scale(1);

  /// `true` when the device is in landscape orientation.
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  /// `true` when the device is in portrait orientation.
  bool get isPortrait => MediaQuery.orientationOf(this) == Orientation.portrait;
}

// ── Responsive breakpoints ─────────────────────────────────────────────────

extension ResponsiveBuildContextExtension on BuildContext {
  /// `true` when the screen width is at least [AppBreakpoints.tablet].
  bool get isTablet => MediaQuery.sizeOf(this).width >= AppBreakpoints.tablet;

  /// `true` when the screen width is at least [AppBreakpoints.desktop].
  bool get isDesktop => MediaQuery.sizeOf(this).width >= AppBreakpoints.desktop;

  /// `true` when the screen width is below [AppBreakpoints.tablet]
  /// (phone form factor).
  bool get isPhone => MediaQuery.sizeOf(this).width < AppBreakpoints.tablet;

  /// Returns [phone], [tablet], or [desktop] depending on the current
  /// screen width, eagerly evaluating only the matching branch.
  T responsive<T>({
    required T Function() phone,
    T Function()? tablet,
    T Function()? desktop,
  }) {
    final width = MediaQuery.sizeOf(this).width;
    if (width >= AppBreakpoints.desktop && desktop != null) return desktop();
    if (width >= AppBreakpoints.tablet && tablet != null) return tablet();
    return phone();
  }
}

// ── Locale & localisation ──────────────────────────────────────────────────

/// Extensions exposing the active [Locale] and text direction from the
/// widget tree.
///
/// The locale is read from Flutter's [Localizations] layer, which is
/// driven by the root [MaterialApp.router] `locale` parameter; screens
/// switch languages through `LocalizationCubit`, never through this
/// extension.
extension LocaleBuildContextExtension on BuildContext {
  /// The currently active locale.
  Locale get locale => Localizations.localeOf(this);

  /// `true` when the current locale uses right-to-left text direction.
  bool get isRtl =>
      Directionality.of(this) == TextDirection.rtl ||
      locale.languageCode == 'ar';

  /// `true` when the current locale uses left-to-right text direction.
  bool get isLtr => !isRtl;
}

// ── Navigation (typed helpers) ─────────────────────────────────────────────

extension NavigationBuildContextExtension on BuildContext {
  /// Navigates to [path] using go_router's `go` (replaces the stack).
  void navigateTo(String path, {Object? extra}) =>
      GoRouter.of(this).go(path, extra: extra);

  /// Pushes [path] onto the navigation stack.
  ///
  /// Use [pushToForResult] when the pushed route returns a value that the
  /// caller needs to await.
  Future<void> pushTo(String path, {Object? extra}) =>
      GoRouter.of(this).push<void>(path, extra: extra);

  /// Pushes [path] onto the navigation stack and awaits the result value.
  Future<T?> pushToForResult<T>(String path, {Object? extra}) =>
      GoRouter.of(this).push<T>(path, extra: extra);

  /// Replaces the current route with [path].
  void replaceTo(String path, {Object? extra}) =>
      GoRouter.of(this).replace<void>(path, extra: extra);

  /// Pops the current route if the stack allows it.
  void popRoute<T extends Object?>([T? result]) {
    if (canPop()) GoRouter.of(this).pop(result);
  }

  /// `true` when there is a route that can be popped.
  bool canPop() => GoRouter.of(this).canPop();

  // ── Typed route helpers ──────────────────────────────────────────────────

  /// Navigates to the login screen.
  void goToLogin() => GoRouter.of(this).go(RouteNames.login);

  /// Navigates to the registration screen.
  void goToRegister() => GoRouter.of(this).go(RouteNames.register);

  /// Navigates to the chat list (main home tab).
  void goToChat() => GoRouter.of(this).go(RouteNames.chat);

  /// Opens a specific conversation while preserving the previous route.
  ///
  /// This is intentionally a push: conversations can be opened from the
  /// list or global search, and Android back must return to that source.
  Future<void> goToConversation(String conversationId) =>
      GoRouter.of(this).push<void>(RouteNames.conversationPath(conversationId));

  /// Navigates to the model selection screen.
  void goToModels() => GoRouter.of(this).go(RouteNames.models);

  /// Navigates to the user profile screen.
  void goToProfile() => GoRouter.of(this).go(RouteNames.profile);

  /// Navigates to the settings screen.
  void goToSettings() => GoRouter.of(this).go(RouteNames.settings);

  /// Opens notifications above the current screen so Android back returns
  /// to the originating profile/settings screen.
  Future<void> goToNotifications() =>
      GoRouter.of(this).push<void>(RouteNames.notifications);

  /// Opens search above the current screen so Android back returns to the
  /// originating profile screen instead of exiting the application.
  Future<void> goToSearch() => GoRouter.of(this).push<void>(RouteNames.search);
}

// ── Snackbar & overlay ─────────────────────────────────────────────────────

extension OverlayBuildContextExtension on BuildContext {
  /// Shows a [SnackBar] with [message] at the bottom of the nearest
  /// [ScaffoldMessenger]. Any existing snackbar is removed first.
  void showSnackBar(
    String message, {
    Duration duration = const Duration(milliseconds: 2500),
    Color? backgroundColor,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          backgroundColor: backgroundColor,
          action: action,
        ),
      );
  }

  /// Shows an error [SnackBar] styled with the error colour.
  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: colorScheme.error);
  }

  /// Shows a success [SnackBar] styled with the secondary colour.
  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: colorScheme.secondary);
  }

  /// Hides any currently visible [SnackBar].
  void hideSnackBar() => ScaffoldMessenger.of(this).hideCurrentSnackBar();

  /// Unfocuses any active text field by removing focus from the FocusScope.
  void dismissKeyboard() => FocusScope.of(this).unfocus();
}
