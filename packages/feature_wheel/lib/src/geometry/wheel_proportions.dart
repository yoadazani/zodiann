import 'package:flutter/foundation.dart';

/// MASTER.md §7.2's "The wheel drawing" table, as fractions of the outer
/// radius `R`, so the wheel scales (ZOD-WHL-001).
///
/// The values are the kit's (`design-reference/zodiann/_source/kit.js`,
/// `wheelSVG`, drawn with `R = 300` units) divided by [referenceRadius]. MASTER
/// prints them rounded (`296 / 300 = 0.98667`, printed 0.987). The fixed
/// pixel sizes in the table (ticks, glyphs, discs, dots, label sizes) live in
/// the same viewBox as `R`, so they scale with the drawing; they are stored
/// as fractions of `R` too, and a `WheelGeometry` turns them into pixels.
@immutable
final class WheelProportions {
  /// A table with explicit values. Use [desktop] or [compact].
  const WheelProportions({
    required this.haloRadius,
    required this.signBandOuter,
    required this.signBandInner,
    required this.signSeparatorInner,
    required this.tickInnerEdge,
    required this.tickLengthDegree,
    required this.tickLengthFive,
    required this.tickLengthTen,
    required this.degreeNumberRadius,
    required this.degreeNumberFontSize,
    required this.signGlyphSize,
    required this.bodyDiscRadiusAt,
    required this.bodyDiscRadius,
    required this.bodyGlyphSize,
    required this.bodyLabelRadiusAt,
    required this.bodyLabelFontSize,
    required this.innerDiscRadius,
    required this.trueDotRadius,
    required this.extentX,
    required this.extentTop,
    required this.extentBottom,
  });

  /// The kit's outer radius in its own units; every fraction is a value in
  /// these units divided by this.
  static const double referenceRadius = 300;

  /// The desktop column of MASTER §7.2.
  static const WheelProportions desktop = WheelProportions(
    haloRadius: 306 / referenceRadius,
    signBandOuter: 296 / referenceRadius,
    signBandInner: 250 / referenceRadius,
    signSeparatorInner: (250 - 18) / referenceRadius,
    tickInnerEdge: 250 / referenceRadius,
    tickLengthDegree: 5 / referenceRadius,
    tickLengthFive: 9 / referenceRadius,
    tickLengthTen: 14 / referenceRadius,
    degreeNumberRadius: (250 - 26) / referenceRadius,
    degreeNumberFontSize: 9.5 / referenceRadius,
    signGlyphSize: 21 / referenceRadius,
    bodyDiscRadiusAt: 192 / referenceRadius,
    bodyDiscRadius: 14 / referenceRadius,
    bodyGlyphSize: 17 / referenceRadius,
    bodyLabelRadiusAt: 164 / referenceRadius,
    bodyLabelFontSize: 11.5 / referenceRadius,
    innerDiscRadius: 136 / referenceRadius,
    trueDotRadius: 3.2 / referenceRadius,
    extentX: 322 / referenceRadius,
    extentTop: 334 / referenceRadius,
    extentBottom: 322 / referenceRadius,
  );

  /// The compact column (phone and tablet) of MASTER §7.2.
  static const WheelProportions compact = WheelProportions(
    haloRadius: 306 / referenceRadius,
    signBandOuter: 296 / referenceRadius,
    signBandInner: 240 / referenceRadius,
    signSeparatorInner: (240 - 18) / referenceRadius,
    tickInnerEdge: 240 / referenceRadius,
    tickLengthDegree: 5 / referenceRadius,
    tickLengthFive: 9 / referenceRadius,
    tickLengthTen: 14 / referenceRadius,
    degreeNumberRadius: (240 - 26) / referenceRadius,
    degreeNumberFontSize: 14 / referenceRadius,
    signGlyphSize: 30 / referenceRadius,
    bodyDiscRadiusAt: 180 / referenceRadius,
    bodyDiscRadius: 21 / referenceRadius,
    bodyGlyphSize: 27 / referenceRadius,
    bodyLabelRadiusAt: 140 / referenceRadius,
    bodyLabelFontSize: 19 / referenceRadius,
    innerDiscRadius: 112 / referenceRadius,
    trueDotRadius: 4.5 / referenceRadius,
    extentX: 322 / referenceRadius,
    extentTop: 334 / referenceRadius,
    extentBottom: 322 / referenceRadius,
  );

  /// Outer halo, `line` at 50 % (MASTER 1.02 R).
  final double haloRadius;

  /// Outer edge of the sign band, the `accent-line` rim (MASTER 0.987 R).
  final double signBandOuter;

  /// Inner edge of the sign band (MASTER 0.833 R desktop, 0.80 R compact).
  final double signBandInner;

  /// Where the 30° sign separators end: 18 kit units inside the band's inner
  /// edge (`kit.js` `rTick - 18`), so each runs across the tick zone and is the
  /// 30° mark (the kit draws no tick at multiples of 30°).
  final double signSeparatorInner;

  /// Where the degree ticks start and run inward from: the band's inner edge.
  final double tickInnerEdge;

  /// Tick length for a 1° mark (5 units).
  final double tickLengthDegree;

  /// Tick length for a 5° mark (9 units).
  final double tickLengthFive;

  /// Tick length for a 10° mark (14 units).
  final double tickLengthTen;

  /// Radius of the degree numbers' centres (10, 20 within the sign).
  ///
  /// Decision D7 (ZOD-WHL-001 plan): the kit places them at
  /// `signBandInner − 26` units. MASTER §7.2's prose says "22 px inside the
  /// band"; the design PNGs are rendered from `kit.js`, so the kit value
  /// stands. Confirmed by eye on the desktop PNG (2026-11-17): the "10" and
  /// "20" labels sit about 224–225 kit units from the centre, MASTER's 22
  /// would be 228; not a pixel-script measurement.
  final double degreeNumberRadius;

  /// Degree number font size (9.5 units desktop, 14 compact).
  final double degreeNumberFontSize;

  /// Sign glyph size, centred in the band (21 desktop, 30 compact).
  final double signGlyphSize;

  /// Radius at which body glyph discs sit (MASTER 0.64 R, compact 0.60 R).
  final double bodyDiscRadiusAt;

  /// Body glyph disc radius (14 desktop, 21 compact).
  final double bodyDiscRadius;

  /// Body glyph size (17 desktop, 27 compact).
  final double bodyGlyphSize;

  /// Radius at which body degree labels sit (MASTER 0.547 R, compact 0.467 R).
  final double bodyLabelRadiusAt;

  /// Body degree label font size (11.5 desktop, 19 compact).
  final double bodyLabelFontSize;

  /// Inner disc (`bg-raised`), where aspect chords and true-position dots
  /// live (MASTER 0.453 R, compact 0.373 R).
  final double innerDiscRadius;

  /// True-position dot radius (3.2 desktop, 4.5 compact).
  final double trueDotRadius;

  /// Half the drawing's width, in R: the kit viewBox is `-322 -334 644 656`.
  final double extentX;

  /// The drawing's extent above the centre, in R (the pointer's apex).
  final double extentTop;

  /// The drawing's extent below the centre, in R.
  final double extentBottom;

  /// Width over height of the drawing's extents, 644 / 656.
  double get aspectRatio => (2 * extentX) / (extentTop + extentBottom);

  @override
  bool operator ==(Object other) =>
      other is WheelProportions &&
      other.haloRadius == haloRadius &&
      other.signBandOuter == signBandOuter &&
      other.signBandInner == signBandInner &&
      other.signSeparatorInner == signSeparatorInner &&
      other.tickInnerEdge == tickInnerEdge &&
      other.tickLengthDegree == tickLengthDegree &&
      other.tickLengthFive == tickLengthFive &&
      other.tickLengthTen == tickLengthTen &&
      other.degreeNumberRadius == degreeNumberRadius &&
      other.degreeNumberFontSize == degreeNumberFontSize &&
      other.signGlyphSize == signGlyphSize &&
      other.bodyDiscRadiusAt == bodyDiscRadiusAt &&
      other.bodyDiscRadius == bodyDiscRadius &&
      other.bodyGlyphSize == bodyGlyphSize &&
      other.bodyLabelRadiusAt == bodyLabelRadiusAt &&
      other.bodyLabelFontSize == bodyLabelFontSize &&
      other.innerDiscRadius == innerDiscRadius &&
      other.trueDotRadius == trueDotRadius &&
      other.extentX == extentX &&
      other.extentTop == extentTop &&
      other.extentBottom == extentBottom;

  @override
  int get hashCode => Object.hashAll([
    haloRadius,
    signBandOuter,
    signBandInner,
    signSeparatorInner,
    tickInnerEdge,
    tickLengthDegree,
    tickLengthFive,
    tickLengthTen,
    degreeNumberRadius,
    degreeNumberFontSize,
    signGlyphSize,
    bodyDiscRadiusAt,
    bodyDiscRadius,
    bodyGlyphSize,
    bodyLabelRadiusAt,
    bodyLabelFontSize,
    innerDiscRadius,
    trueDotRadius,
    extentX,
    extentTop,
    extentBottom,
  ]);
}
