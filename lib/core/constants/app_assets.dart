/// Asset paths declared in `pubspec.yaml`.
///
/// All paths are **relative to the `assets/` root** declared in the
/// Flutter manifest. They must be kept in sync with the manifest —
/// renaming an asset here without updating `pubspec.yaml` will break
/// the build. Centralising them in one place keeps that contract
/// easy to audit.
abstract final class AppAssets {
  const AppAssets._();

  // ---- Images ---------------------------------------------------------------

  /// `assets/images/logo.png` — primary brand logo.
  static const String logo = 'assets/images/logo.png';

  /// `assets/images/logo_dark.png` — logo for dark surfaces.
  static const String logoDark = 'assets/images/logo_dark.png';

  /// `assets/images/avatar_placeholder.png` — neutral avatar.
  static const String avatarPlaceholder = 'assets/images/avatar_placeholder.png';

  /// `assets/images/empty_state.png` — illustration for empty lists.
  static const String emptyState = 'assets/images/empty_state.png';

  /// `assets/images/error_state.png` — illustration for error states.
  static const String errorState = 'assets/images/error_state.png';

  /// `assets/images/onboarding_1.png` — first onboarding slide art.
  static const String onboarding1 = 'assets/images/onboarding_1.png';

  /// `assets/images/onboarding_2.png` — second onboarding slide art.
  static const String onboarding2 = 'assets/images/onboarding_2.png';

  /// `assets/images/onboarding_3.png` — third onboarding slide art.
  static const String onboarding3 = 'assets/images/onboarding_3.png';

  /// `assets/images/splash.png` — splash screen hero art.
  static const String splash = 'assets/images/splash.png';

  // ---- Icons (SVG) ----------------------------------------------------------

  /// `assets/icons/ic_chat.svg` — chat tab icon.
  static const String iconChat = 'assets/icons/ic_chat.svg';

  /// `assets/icons/ic_conversations.svg` — conversations tab icon.
  static const String iconConversations = 'assets/icons/ic_conversations.svg';

  /// `assets/icons/ic_settings.svg` — settings tab icon.
  static const String iconSettings = 'assets/icons/ic_settings.svg';

  /// `assets/icons/ic_subscription.svg` — subscription tab icon.
  static const String iconSubscription = 'assets/icons/ic_subscription.svg';

  /// `assets/icons/ic_send.svg` — message-send action icon.
  static const String iconSend = 'assets/icons/ic_send.svg';

  /// `assets/icons/ic_attach.svg` — file-attach action icon.
  static const String iconAttach = 'assets/icons/ic_attach.svg';

  /// `assets/icons/ic_model.svg` — AI model picker icon.
  static const String iconModel = 'assets/icons/ic_model.svg';

  // ---- Animations / Lottie --------------------------------------------------

  /// `assets/animations/loading.json` — generic loading animation.
  static const String loadingAnimation = 'assets/animations/loading.json';

  /// `assets/animations/success.json` — success-state animation.
  static const String successAnimation = 'assets/animations/success.json';

  /// `assets/animations/error.json` — error-state animation.
  static const String errorAnimation = 'assets/animations/error.json';

  // ---- Fonts ----------------------------------------------------------------

  /// `assets/fonts/Roboto-Regular.ttf` — primary regular weight.
  static const String fontRegular = 'assets/fonts/Roboto-Regular.ttf';

  /// `assets/fonts/Roboto-Medium.ttf` — primary medium weight.
  static const String fontMedium = 'assets/fonts/Roboto-Medium.ttf';

  /// `assets/fonts/Roboto-Bold.ttf` — primary bold weight.
  static const String fontBold = 'assets/fonts/Roboto-Bold.ttf';

  /// Font family name referenced in `TextStyle.fontFamily`.
  static const String fontFamily = 'Roboto';
}
