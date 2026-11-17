import 'package:material_ui/material_ui.dart';

import '../theme/square_colors.dart';
import '../theme/tokens/zodiann_states.dart';
import '../theme/zodiann_glyphs.dart';
import '../theme/zodiann_surfaces.dart';

/// The tag variants (MASTER.md §10 "Tags"; kit.css `.tag*`).
enum ZodiannTagVariant {
  /// A cell on the axes: `axis-fill` / `axis-ink`, marked `+`.
  axis,

  /// A cell on the diagonals: `diag-fill` / `diag-ink`, marked `×`.
  diagonal,

  /// An eighth-line cell: `eighth-fill` / `eighth-ink`.
  eighth,

  /// A cell with no highlight: `surface-2` / `text-2`.
  noHighlight,

  /// The centre cell: an inside outline in `center`, no fill.
  center,

  /// Today's cell: an inside outline in `today`, no fill.
  today,

  /// A neutral label (a mode, a licence): `surface-2` / `text-2`, weight 500.
  neutral,

  /// An accent label: `accent-soft` / `accent-strong`.
  accent;

  /// The mark that stands in front of the label, so the highlight is not
  /// conveyed by colour alone (NFR-X4), or null. Bound to the variant, so a
  /// caller cannot leave it out. The other variants are told apart by their
  /// label or their outline.
  String? get mark => switch (this) {
    axis => ZodiannGlyphs.markAxis,
    diagonal => ZodiannGlyphs.markDiagonal,
    _ => null,
  };
}

/// A tag variant's fill, ink, optional inside outline and label weight, from
/// [SquareColors] and [ZodiannSurfaces] (kit.css `.tag*`).
@immutable
final class ZodiannTagStyle {
  /// Explicit values.
  const ZodiannTagStyle({
    required this.fill,
    required this.ink,
    this.outline,
    required this.weight,
  });

  /// The style of [variant] in the theme whose colours are [square] and
  /// [surfaces].
  factory ZodiannTagStyle.of(
    ZodiannTagVariant variant,
    SquareColors square,
    ZodiannSurfaces surfaces,
  ) => switch (variant) {
    ZodiannTagVariant.axis => ZodiannTagStyle(
      fill: square.axisFill,
      ink: square.axisInk,
      weight: FontWeight.w600,
    ),
    ZodiannTagVariant.diagonal => ZodiannTagStyle(
      fill: square.diagFill,
      ink: square.diagInk,
      weight: FontWeight.w600,
    ),
    ZodiannTagVariant.eighth => ZodiannTagStyle(
      fill: square.eighthFill,
      ink: square.eighthInk,
      weight: FontWeight.w600,
    ),
    ZodiannTagVariant.noHighlight => ZodiannTagStyle(
      fill: surfaces.surface2,
      ink: surfaces.text2,
      weight: FontWeight.w600,
    ),
    ZodiannTagVariant.center => ZodiannTagStyle(
      fill: ZodiannStates.transparent,
      ink: square.center,
      outline: square.center,
      weight: FontWeight.w600,
    ),
    ZodiannTagVariant.today => ZodiannTagStyle(
      fill: ZodiannStates.transparent,
      ink: square.today,
      outline: square.today,
      weight: FontWeight.w600,
    ),
    // kit.css `.tag.neutral`: 500, unlike every other tag.
    ZodiannTagVariant.neutral => ZodiannTagStyle(
      fill: surfaces.surface2,
      ink: surfaces.text2,
      weight: FontWeight.w500,
    ),
    ZodiannTagVariant.accent => ZodiannTagStyle(
      fill: surfaces.accentSoft,
      ink: surfaces.accentStrong,
      weight: FontWeight.w600,
    ),
  };

  /// The background (transparent for the outline variants).
  final Color fill;

  /// The label and mark colour.
  final Color ink;

  /// The 1.5 px outline drawn inside the box, or null.
  final Color? outline;

  /// The label weight.
  final FontWeight weight;

  @override
  bool operator ==(Object other) =>
      other is ZodiannTagStyle &&
      other.fill == fill &&
      other.ink == ink &&
      other.outline == outline &&
      other.weight == weight;

  @override
  int get hashCode => Object.hash(fill, ink, outline, weight);
}
