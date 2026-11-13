import 'package:material_ui/material_ui.dart';

/// Interactive-state values (MASTER.md §10 "Buttons", §12 "Motion";
/// `_source/kit.css` `.btn*`), shared by every control (ZOD-UI-004).
///
/// The design reference draws hover and press as CSS `brightness()` filters
/// on the whole control layer, not as colour swaps.
abstract final class ZodiannStates {
  /// Hover lightens the control by 12 % (`filter: brightness(1.12)`).
  static const double hoverBrightness = 1.12;

  /// Pressed darkens the control by 6 % (`filter: brightness(.94)`).
  static const double pressedBrightness = 0.94;

  /// Pressed moves the control down by 1 px (`translateY(1px)`).
  static const double pressedOffset = 1.0;

  /// Disabled controls render at 42 % opacity.
  static const double disabledOpacity = 0.42;

  /// The keyboard focus ring's stroke width (2 px `focus`).
  static const double focusRingWidth = 2.0;

  /// The gap between the control and its focus ring (`outline-offset: 2px`).
  static const double focusRingGap = 2.0;

  /// The outline danger button's border: `danger` at 45 %
  /// (`color-mix(in srgb, var(--danger) 45%, transparent)`).
  static const double dangerBorderOpacity = 0.45;

  /// The hover transition (MASTER §12); instant under reduced motion.
  static const Duration hoverDuration = Duration(milliseconds: 150);

  /// No fill or no border.
  static const Color transparent = Color(0x00000000);

  /// The solid danger button's label (kit.css `.btn.danger.solid`: `#fff`),
  /// in both themes.
  ///
  /// Product-owner decision D2 (2026-11-13): kept as designed. On the dark
  /// theme's `danger` it is 3.37:1, below WCAG AA for 14 px text (NFR-X5);
  /// handed to ZOD-NFR-009.
  static const Color onDangerSolid = Color(0xFFFFFFFF);
}
