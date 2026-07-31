import 'package:flutter/material.dart';

/// The font family declared in `pubspec.yaml` for the Cairo typeface.
const String _kCairoFamily = 'Cairo';

/// Typography design tokens for the Hajeen AI platform.
///
/// All text styles use the locally bundled **Cairo** typeface, which
/// supports both Arabic (primary) and Latin scripts seamlessly. The
/// scale follows Material 3 type roles so that every [TextStyle] maps
/// directly to a [TextTheme] slot in [AppTheme].
///
/// ### Role → usage guide
/// | Role          | Material 3 name    | Typical use                        |
/// |---------------|--------------------|------------------------------------|
/// | displayLarge  | Display Large      | Hero numbers, splash taglines      |
/// | displayMedium | Display Medium     | Marketing headlines                |
/// | displaySmall  | Display Small      | Section intro text                 |
/// | headlineLarge | Headline Large     | Screen titles (large)              |
/// | headlineMedium| Headline Medium    | Screen titles (standard)           |
/// | headlineSmall | Headline Small     | Card titles, dialog titles         |
/// | titleLarge    | Title Large        | AppBar titles                      |
/// | titleMedium   | Title Medium       | List item headers, tab labels      |
/// | titleSmall    | Title Small        | Chip labels, column headers        |
/// | bodyLarge     | Body Large         | Primary chat message text          |
/// | bodyMedium    | Body Medium        | Secondary body text, descriptions  |
/// | bodySmall     | Body Small         | Captions, metadata                 |
/// | labelLarge    | Label Large        | Button labels                      |
/// | labelMedium   | Label Medium       | Badge labels, tags                 |
/// | labelSmall    | Label Small        | Timestamps, footnotes              |
abstract final class AppTextStyles {
  // ── Display ───────────────────────────────────────────────────────────────

  /// 57 sp / Regular — hero taglines and splash displays.
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _kCairoFamily,
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );

  /// 45 sp / Regular — marketing section headlines.
  static const TextStyle displayMedium = TextStyle(
    fontFamily: _kCairoFamily,
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );

  /// 36 sp / Regular — large section intro text.
  static const TextStyle displaySmall = TextStyle(
    fontFamily: _kCairoFamily,
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );

  // ── Headline ──────────────────────────────────────────────────────────────

  /// 32 sp / SemiBold — large screen titles.
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _kCairoFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
  );

  /// 28 sp / SemiBold — standard screen titles (AppBar).
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _kCairoFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
  );

  /// 24 sp / SemiBold — card titles, dialog headings.
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _kCairoFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
  );

  // ── Title ─────────────────────────────────────────────────────────────────

  /// 22 sp / SemiBold — AppBar titles.
  static const TextStyle titleLarge = TextStyle(
    fontFamily: _kCairoFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.27,
  );

  /// 16 sp / Medium — list item headers, tab labels.
  static const TextStyle titleMedium = TextStyle(
    fontFamily: _kCairoFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.50,
  );

  /// 14 sp / Medium — chip labels, compact column headers.
  static const TextStyle titleSmall = TextStyle(
    fontFamily: _kCairoFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // ── Body ──────────────────────────────────────────────────────────────────

  /// 16 sp / Regular — primary chat message body text.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _kCairoFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.75,
  );

  /// 14 sp / Regular — secondary body text, list descriptions.
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _kCairoFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  /// 12 sp / Regular — captions, metadata, helper text.
  static const TextStyle bodySmall = TextStyle(
    fontFamily: _kCairoFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // ── Label ─────────────────────────────────────────────────────────────────

  /// 14 sp / SemiBold — button labels.
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _kCairoFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  /// 12 sp / Medium — badge labels, small tags.
  static const TextStyle labelMedium = TextStyle(
    fontFamily: _kCairoFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );

  /// 11 sp / Medium — timestamps, footnotes.
  static const TextStyle labelSmall = TextStyle(
    fontFamily: _kCairoFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // ── Semantic aliases ──────────────────────────────────────────────────────

  /// Primary chat message text — mirrors [bodyLarge] with enhanced line
  /// height for readability in long AI responses.
  static const TextStyle chatMessage = TextStyle(
    fontFamily: _kCairoFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    height: 1.80,
  );

  /// Timestamp label below messages — mirrors [labelSmall].
  static const TextStyle messageTimestamp = TextStyle(
    fontFamily: _kCairoFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    height: 1.45,
  );

  /// Conversation list item title.
  static const TextStyle conversationTitle = TextStyle(
    fontFamily: _kCairoFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.40,
  );

  /// Conversation list item preview snippet — truncated to one line.
  static const TextStyle conversationPreview = TextStyle(
    fontFamily: _kCairoFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.38,
  );

  /// AI model name shown in selectors and headers.
  static const TextStyle modelName = TextStyle(
    fontFamily: _kCairoFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // ── TextTheme builder ─────────────────────────────────────────────────────

  /// Returns a [TextTheme] where every role is wired to the correct
  /// [AppTextStyles] constant.
  ///
  /// Colour is not applied here; [ThemeData] merges the text theme
  /// with the active [ColorScheme] automatically.
  static const TextTheme textTheme = TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
