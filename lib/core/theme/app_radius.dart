import 'package:flutter/material.dart';

/// Border-radius design tokens for the Hajeen AI platform.
///
/// All values follow a consistent scale derived from a 4-point base
/// unit so that corner radii feel intentional and cohesive across every
/// surface. Use the [BorderRadius] and [Radius] constants directly;
/// avoid inlining arbitrary radius values elsewhere in the codebase.
///
/// ### Token scale
/// | Token   | Value | Typical use                               |
/// |---------|-------|-------------------------------------------|
/// | xs      |  4 dp | Badges, chips, small tags                 |
/// | sm      |  8 dp | Buttons (compact), input fields, tooltips |
/// | md      | 12 dp | Buttons (standard), cards (compact)       |
/// | lg      | 16 dp | Cards, sheets, dialogs (standard)         |
/// | xl      | 20 dp | Bottom sheets, large cards                |
/// | xxl     | 24 dp | Modals, large panels                      |
/// | full    | 99 dp | Pills, fully-rounded avatars              |
///
/// Use [AppRadius.xsRadius], [AppRadius.smRadius], … for quick [Radius]
/// values and [AppRadius.xs], [AppRadius.sm], … for quick [BorderRadius]
/// values.
abstract final class AppRadius {
  // ── Radius atoms ──────────────────────────────────────────────────────────

  /// `4 dp` — smallest radius; used for badges and compact chips.
  static const Radius xsRadius = Radius.circular(4);

  /// `8 dp` — used for compact buttons, input fields, and tooltips.
  static const Radius smRadius = Radius.circular(8);

  /// `12 dp` — used for standard buttons and compact card surfaces.
  static const Radius mdRadius = Radius.circular(12);

  /// `16 dp` — used for standard cards, dialogs, and sheet headers.
  static const Radius lgRadius = Radius.circular(16);

  /// `20 dp` — used for large cards and elevated bottom sheets.
  static const Radius xlRadius = Radius.circular(20);

  /// `24 dp` — used for modals and prominent panel surfaces.
  static const Radius xxlRadius = Radius.circular(24);

  /// `99 dp` — pill shape; used for fully-rounded avatars and FABs.
  static const Radius fullRadius = Radius.circular(99);

  // ── BorderRadius convenience ──────────────────────────────────────────────

  /// `BorderRadius.all(xsRadius)` — all corners at 4 dp.
  static const BorderRadius xs = BorderRadius.all(xsRadius);

  /// `BorderRadius.all(smRadius)` — all corners at 8 dp.
  static const BorderRadius sm = BorderRadius.all(smRadius);

  /// `BorderRadius.all(mdRadius)` — all corners at 12 dp.
  static const BorderRadius md = BorderRadius.all(mdRadius);

  /// `BorderRadius.all(lgRadius)` — all corners at 16 dp.
  static const BorderRadius lg = BorderRadius.all(lgRadius);

  /// `BorderRadius.all(xlRadius)` — all corners at 20 dp.
  static const BorderRadius xl = BorderRadius.all(xlRadius);

  /// `BorderRadius.all(xxlRadius)` — all corners at 24 dp.
  static const BorderRadius xxl = BorderRadius.all(xxlRadius);

  /// `BorderRadius.all(fullRadius)` — pill shape.
  static const BorderRadius full = BorderRadius.all(fullRadius);

  // ── Directional variants ──────────────────────────────────────────────────

  /// Rounds only the top two corners at 16 dp.
  ///
  /// Used for bottom sheets and cards that sit flush with the bottom
  /// of the screen.
  static const BorderRadius topLg = BorderRadius.vertical(top: lgRadius);

  /// Rounds only the top two corners at 24 dp.
  static const BorderRadius topXxl = BorderRadius.vertical(top: xxlRadius);

  /// Rounds only the bottom two corners at 16 dp.
  static const BorderRadius bottomLg = BorderRadius.vertical(bottom: lgRadius);

  /// Rounds only the right two corners at 12 dp.
  ///
  /// Used for message bubbles originating from the current user.
  static const BorderRadius messageBubbleUser = BorderRadius.only(
    topLeft: lgRadius,
    topRight: smRadius,
    bottomLeft: lgRadius,
    bottomRight: lgRadius,
  );

  /// Rounds only the left two corners at 12 dp.
  ///
  /// Used for message bubbles originating from the AI.
  static const BorderRadius messageBubbleAi = BorderRadius.only(
    topLeft: smRadius,
    topRight: lgRadius,
    bottomLeft: lgRadius,
    bottomRight: lgRadius,
  );

  // ── RoundedRectangleBorder helpers ────────────────────────────────────────

  /// Returns a [RoundedRectangleBorder] with [BorderRadius.all] at
  /// the given [radius].
  static RoundedRectangleBorder rounded(Radius radius) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.all(radius));

  /// [RoundedRectangleBorder] at the standard 8 dp button radius.
  static final RoundedRectangleBorder buttonSm = rounded(smRadius);

  /// [RoundedRectangleBorder] at the standard 12 dp button radius.
  static final RoundedRectangleBorder buttonMd = rounded(mdRadius);

  /// [RoundedRectangleBorder] at the standard pill radius.
  static final RoundedRectangleBorder pill = rounded(fullRadius);
}
