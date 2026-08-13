import 'package:flutter/material.dart';

// ── Raw palette ─────────────────────────────────────────────────────────────
//
// These private classes define the immutable raw colour values used to
// assemble the semantic [ColorScheme] tokens below. They are intentionally
// private so that call sites always consume the semantic names defined on
// [AppColors], never raw hex values.

abstract final class _Brand {
  /// Deep violet — primary brand hue.
  static const Color violet50 = Color(0xFFEEE9FF);
  static const Color violet100 = Color(0xFFD8CEFF);
  static const Color violet300 = Color(0xFF9A7DFF);
  static const Color violet400 = Color(0xFF7C5CFC);
  static const Color violet500 = Color(0xFF6248E8);
  static const Color violet700 = Color(0xFF3D2E8A);
  static const Color violet800 = Color(0xFF2B2057);
  static const Color violet900 = Color(0xFF1A1432);

  /// Teal accent — secondary brand hue.
  static const Color teal300 = Color(0xFF5ADBD5);
  static const Color teal400 = Color(0xFF2ECBC3);
  static const Color teal500 = Color(0xFF00A99D);
  static const Color teal700 = Color(0xFF005752);

  /// Coral error hue.
  static const Color red300 = Color(0xFFFF8A8A);
  static const Color red500 = Color(0xFFE53935);
  static const Color red600 = Color(0xFFC62828);

  /// Amber warning hue.
  static const Color amber400 = Color(0xFFFFD740);
  static const Color amber500 = Color(0xFFFFB300);

  /// Success green hue.
  static const Color green500 = Color(0xFF43A047);
}

abstract final class _DarkNeutral {
  static const Color n900 = Color(0xFF0C0E1A); // scaffold background
  static const Color n800 = Color(0xFF151829); // surface
  static const Color n750 = Color(0xFF1C2038); // card / elevated surface
  static const Color n700 = Color(0xFF252946); // input fill
  static const Color n600 = Color(0xFF343862); // border / divider
  static const Color n200 = Color(0xFFBEC2E0); // secondary text
  static const Color n100 = Color(0xFFE8EAF6); // primary text
}

abstract final class _LightNeutral {
  static const Color n900 = Color(0xFF1A1A2E); // primary text
  static const Color n800 = Color(0xFF2D2D44); // secondary text
  static const Color n300 = Color(0xFFC5C6DB); // border / divider
  static const Color n200 = Color(0xFFE4E5F1); // input fill
  static const Color n100 = Color(0xFFF0F1FA); // card surface
  static const Color n50 = Color(0xFFF5F6FF); // scaffold background
}

// ── Semantic surface ─────────────────────────────────────────────────────────

/// Application-wide colour tokens for the Hajeen AI platform.
///
/// Consume [AppColors.lightScheme] and [AppColors.darkScheme] to build
/// [ThemeData]; use the individual semantic constants only in edge cases
/// where a [ColorScheme] property is insufficient.
///
/// Do **not** use raw hex literals anywhere else in the codebase.
abstract final class AppColors {
  // ── Light colour scheme ───────────────────────────────────────────────────

  /// Material 3 [ColorScheme] for the light theme.
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,

    // Primary
    primary: _Brand.violet500,
    onPrimary: Colors.white,
    primaryContainer: _Brand.violet50,
    onPrimaryContainer: _Brand.violet800,

    // Secondary
    secondary: _Brand.teal500,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD4F5F2),
    onSecondaryContainer: _Brand.teal700,

    // Tertiary
    tertiary: _Brand.amber500,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFFF3CC),
    onTertiaryContainer: Color(0xFF5C4000),

    // Error
    error: _Brand.red500,
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: _Brand.red600,

    // Surface
    surface: Colors.white,
    onSurface: _LightNeutral.n900,
    surfaceContainerHighest: _LightNeutral.n100,
    onSurfaceVariant: _LightNeutral.n800,

    // Outline
    outline: _LightNeutral.n300,
    outlineVariant: _LightNeutral.n200,

    // Inverse
    inverseSurface: _DarkNeutral.n800,
    onInverseSurface: _DarkNeutral.n100,
    inversePrimary: _Brand.violet300,

    // Shadow / scrim
    shadow: Colors.black,
    scrim: Colors.black,
  );

  // ── Dark colour scheme ────────────────────────────────────────────────────

  /// Material 3 [ColorScheme] for the dark theme.
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,

    // Primary
    primary: _Brand.violet400,
    onPrimary: Colors.white,
    primaryContainer: _Brand.violet700,
    onPrimaryContainer: _Brand.violet100,

    // Secondary
    secondary: _Brand.teal400,
    onSecondary: Color(0xFF003330),
    secondaryContainer: _Brand.teal700,
    onSecondaryContainer: _Brand.teal300,

    // Tertiary
    tertiary: _Brand.amber400,
    onTertiary: Color(0xFF3C2900),
    tertiaryContainer: Color(0xFF573D00),
    onTertiaryContainer: _Brand.amber400,

    // Error
    error: _Brand.red300,
    onError: Color(0xFF690005),
    errorContainer: _Brand.red600,
    onErrorContainer: Color(0xFFFFDAD6),

    // Surface
    surface: _DarkNeutral.n800,
    onSurface: _DarkNeutral.n100,
    surfaceContainerHighest: _DarkNeutral.n750,
    onSurfaceVariant: _DarkNeutral.n200,

    // Outline
    outline: _DarkNeutral.n600,
    outlineVariant: _DarkNeutral.n700,

    // Inverse
    inverseSurface: _LightNeutral.n100,
    onInverseSurface: _LightNeutral.n900,
    inversePrimary: _Brand.violet500,

    // Shadow / scrim
    shadow: Colors.black,
    scrim: Colors.black,
  );

  // ── Scaffold backgrounds ──────────────────────────────────────────────────

  /// Scaffold background for the light theme.
  static const Color scaffoldLight = _LightNeutral.n50;

  /// Scaffold background for the dark theme.
  static const Color scaffoldDark = _DarkNeutral.n900;

  // ── Elevated surfaces ─────────────────────────────────────────────────────

  /// Card/sheet surface in the dark theme (one level above [darkScheme.surface]).
  static const Color cardDark = _DarkNeutral.n750;

  /// Input field fill in the dark theme.
  static const Color inputFillDark = _DarkNeutral.n700;

  /// Input field fill in the light theme.
  static const Color inputFillLight = _LightNeutral.n200;

  // ── Status ────────────────────────────────────────────────────────────────

  /// Semantic success colour (use sparingly; prefer [ColorScheme.secondary]).
  static const Color success = _Brand.green500;

  /// Semantic warning colour (use sparingly; prefer [ColorScheme.tertiary]).
  static const Color warning = _Brand.amber500;

  // ── AI brand gradient ─────────────────────────────────────────────────────

  /// Gradient used on AI-generated content indicators and primary CTAs.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[_Brand.violet400, _Brand.teal400],
  );

  /// Subtle gradient for dark-theme hero sections and splash screens.
  static const LinearGradient heroGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[_DarkNeutral.n900, _Brand.violet900],
  );

  /// Subtle gradient for light-theme hero sections.
  static const LinearGradient heroGradientLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[_LightNeutral.n50, _Brand.violet50],
  );

  // ── Overlay ───────────────────────────────────────────────────────────────

  /// Semi-transparent overlay applied over modals and bottom sheets.
  static const Color modalBarrier = Color(0xB3000000); // 70 % black

  /// Transparent colour helper.
  static const Color transparent = Color(0x00000000);
}
