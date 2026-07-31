import 'package:flutter/material.dart';

/// Spacing design tokens for the Hajeen AI platform.
///
/// All values are multiples of a 4 dp base unit, producing a consistent
/// visual rhythm across every layout. Use the [EdgeInsets] and [SizedBox]
/// constants defined here; avoid inlining arbitrary spacing values
/// elsewhere in the codebase.
///
/// ### Scale
/// | Token | Value  | Typical use                                      |
/// |-------|--------|--------------------------------------------------|
/// | p0    |  0 dp  | No space / flush                                 |
/// | p1    |  4 dp  | Tight intra-component spacing                    |
/// | p2    |  8 dp  | Component internal padding (compact)             |
/// | p3    | 12 dp  | Component internal padding (standard)            |
/// | p4    | 16 dp  | Section padding, card insets                     |
/// | p5    | 20 dp  | Screen horizontal padding                        |
/// | p6    | 24 dp  | Large section insets, dialog padding             |
/// | p8    | 32 dp  | Hero section spacing                             |
/// | p10   | 40 dp  | Major vertical rhythm                            |
/// | p12   | 48 dp  | Extra-large visual breaks                        |
abstract final class AppSpacing {
  // ── Raw values ────────────────────────────────────────────────────────────

  /// `0 dp`
  static const double v0 = 0;

  /// `4 dp`
  static const double v1 = 4;

  /// `8 dp`
  static const double v2 = 8;

  /// `12 dp`
  static const double v3 = 12;

  /// `16 dp`
  static const double v4 = 16;

  /// `20 dp`
  static const double v5 = 20;

  /// `24 dp`
  static const double v6 = 24;

  /// `28 dp`
  static const double v7 = 28;

  /// `32 dp`
  static const double v8 = 32;

  /// `36 dp`
  static const double v9 = 36;

  /// `40 dp`
  static const double v10 = 40;

  /// `44 dp`
  static const double v11 = 44;

  /// `48 dp`
  static const double v12 = 48;

  /// `64 dp`
  static const double v16 = 64;

  /// `80 dp`
  static const double v20 = 80;

  /// `96 dp`
  static const double v24 = 96;

  // ── Symmetric EdgeInsets ──────────────────────────────────────────────────

  /// All sides = 4 dp.
  static const EdgeInsets all1 = EdgeInsets.all(v1);

  /// All sides = 8 dp.
  static const EdgeInsets all2 = EdgeInsets.all(v2);

  /// All sides = 12 dp.
  static const EdgeInsets all3 = EdgeInsets.all(v3);

  /// All sides = 16 dp.
  static const EdgeInsets all4 = EdgeInsets.all(v4);

  /// All sides = 20 dp.
  static const EdgeInsets all5 = EdgeInsets.all(v5);

  /// All sides = 24 dp.
  static const EdgeInsets all6 = EdgeInsets.all(v6);

  // ── Horizontal EdgeInsets ─────────────────────────────────────────────────

  /// Horizontal 8 dp.
  static const EdgeInsets h2 = EdgeInsets.symmetric(horizontal: v2);

  /// Horizontal 12 dp.
  static const EdgeInsets h3 = EdgeInsets.symmetric(horizontal: v3);

  /// Horizontal 16 dp.
  static const EdgeInsets h4 = EdgeInsets.symmetric(horizontal: v4);

  /// Horizontal 20 dp. Default screen horizontal inset.
  static const EdgeInsets h5 = EdgeInsets.symmetric(horizontal: v5);

  /// Horizontal 24 dp.
  static const EdgeInsets h6 = EdgeInsets.symmetric(horizontal: v6);

  // ── Vertical EdgeInsets ───────────────────────────────────────────────────

  /// Vertical 4 dp.
  static const EdgeInsets v1Insets = EdgeInsets.symmetric(vertical: v1);

  /// Vertical 8 dp.
  static const EdgeInsets v2Insets = EdgeInsets.symmetric(vertical: v2);

  /// Vertical 12 dp.
  static const EdgeInsets v3Insets = EdgeInsets.symmetric(vertical: v3);

  /// Vertical 16 dp.
  static const EdgeInsets v4Insets = EdgeInsets.symmetric(vertical: v4);

  /// Vertical 24 dp.
  static const EdgeInsets v6Insets = EdgeInsets.symmetric(vertical: v6);

  // ── Composite EdgeInsets ──────────────────────────────────────────────────

  /// Horizontal 20 dp, Vertical 12 dp — standard button padding.
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: v5,
    vertical: v3,
  );

  /// Horizontal 16 dp, Vertical 8 dp — compact button padding.
  static const EdgeInsets buttonSm = EdgeInsets.symmetric(
    horizontal: v4,
    vertical: v2,
  );

  /// Horizontal 20 dp, Vertical 16 dp — card content inset.
  static const EdgeInsets card = EdgeInsets.symmetric(
    horizontal: v5,
    vertical: v4,
  );

  /// Horizontal 20 dp, Vertical 24 dp — dialog content inset.
  static const EdgeInsets dialog = EdgeInsets.symmetric(
    horizontal: v5,
    vertical: v6,
  );

  /// Horizontal 16 dp, Vertical 12 dp — input field (text field) inset.
  static const EdgeInsets inputField = EdgeInsets.symmetric(
    horizontal: v4,
    vertical: v3,
  );

  /// Horizontal 20 dp, Vertical 16 dp — standard screen content padding.
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: v5,
    vertical: v4,
  );

  /// Horizontal 20 dp only — screen horizontal rails.
  static const EdgeInsets screenHorizontal =
      EdgeInsets.symmetric(horizontal: v5);

  /// Bottom-safe inset for FABs and floating bars; accounts for the
  /// home indicator on notched devices.
  static const EdgeInsets fabSafeBottom = EdgeInsets.only(bottom: v6);

  /// Inset for list items: 20 dp horizontal, 12 dp vertical.
  static const EdgeInsets listItem = EdgeInsets.symmetric(
    horizontal: v5,
    vertical: v3,
  );

  // ── SizedBox gap helpers ──────────────────────────────────────────────────

  /// 4 dp transparent gap for use in [Column] / [Row].
  static const SizedBox gap1 = SizedBox(width: v1, height: v1);

  /// 8 dp transparent gap.
  static const SizedBox gap2 = SizedBox(width: v2, height: v2);

  /// 12 dp transparent gap.
  static const SizedBox gap3 = SizedBox(width: v3, height: v3);

  /// 16 dp transparent gap.
  static const SizedBox gap4 = SizedBox(width: v4, height: v4);

  /// 20 dp transparent gap.
  static const SizedBox gap5 = SizedBox(width: v5, height: v5);

  /// 24 dp transparent gap.
  static const SizedBox gap6 = SizedBox(width: v6, height: v6);

  /// 32 dp transparent gap.
  static const SizedBox gap8 = SizedBox(width: v8, height: v8);

  /// 48 dp transparent gap.
  static const SizedBox gap12 = SizedBox(width: v12, height: v12);

  /// Vertical gap of [value] dp.
  static SizedBox verticalGap(double value) => SizedBox(height: value);

  /// Horizontal gap of [value] dp.
  static SizedBox horizontalGap(double value) => SizedBox(width: value);
}
