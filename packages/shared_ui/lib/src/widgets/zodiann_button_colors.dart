import 'package:material_ui/material_ui.dart';

import '../theme/tokens/zodiann_states.dart';
import '../theme/zodiann_surfaces.dart';

/// The button variants (MASTER.md §10 "Buttons").
enum ZodiannButtonVariant {
  /// Solid `accent` fill. **At most one primary per screen region**, a usage
  /// convention reviewed in PRs, not a runtime check.
  primary,

  /// `surface-2` with a `line` border: the default button.
  secondary,

  /// Transparent with an `accent-line` border: time and anchor shortcuts
  /// (Now, Show up to today, Anchor to …).
  accentOutline,

  /// Text only: Cancel.
  quiet,

  /// Outline in `danger`: destructive actions.
  danger,

  /// Solid `danger`: only inside a confirmation dialog.
  dangerSolid,
}

/// A button variant's fill, 1 px border and label colour, all from
/// [ZodiannSurfaces] (kit.css `.btn*`).
@immutable
final class ZodiannButtonColors {
  /// Explicit colours.
  const ZodiannButtonColors({
    required this.fill,
    required this.border,
    required this.label,
  });

  /// The background.
  final Color fill;

  /// The 1 px border, drawn inside the box.
  final Color border;

  /// The label and icon colour.
  final Color label;

  /// The colours of [variant] in the theme whose surfaces are [s].
  static ZodiannButtonColors resolve(
    ZodiannSurfaces s,
    ZodiannButtonVariant variant,
  ) => switch (variant) {
    ZodiannButtonVariant.primary => ZodiannButtonColors(
      fill: s.accent,
      border: s.accent,
      label: s.onAccent,
    ),
    ZodiannButtonVariant.secondary => ZodiannButtonColors(
      fill: s.surface2,
      border: s.line,
      label: s.text,
    ),
    ZodiannButtonVariant.accentOutline => ZodiannButtonColors(
      fill: ZodiannStates.transparent,
      border: s.accentLine,
      label: s.accentStrong,
    ),
    ZodiannButtonVariant.quiet => ZodiannButtonColors(
      fill: ZodiannStates.transparent,
      border: ZodiannStates.transparent,
      label: s.text2,
    ),
    ZodiannButtonVariant.danger => ZodiannButtonColors(
      fill: ZodiannStates.transparent,
      border: s.danger.withValues(alpha: ZodiannStates.dangerBorderOpacity),
      label: s.danger,
    ),
    ZodiannButtonVariant.dangerSolid => ZodiannButtonColors(
      fill: s.danger,
      border: s.danger,
      label: ZodiannStates.onDangerSolid,
    ),
  };

  @override
  bool operator ==(Object other) =>
      other is ZodiannButtonColors &&
      other.fill == fill &&
      other.border == border &&
      other.label == label;

  @override
  int get hashCode => Object.hash(fill, border, label);

  @override
  String toString() =>
      'ZodiannButtonColors(fill: $fill, border: $border, label: $label)';
}
