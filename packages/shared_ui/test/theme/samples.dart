// Distinct, index-coded sample values: field i of a sample with seed s is
// Color.fromARGB(255, s, i, 0), passed in MASTER order.
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

Color sampleColor(int seed, int i) => Color.fromARGB(255, seed, i, 0);

ZodiannSurfaces sampleSurfaces(int seed) => ZodiannSurfaces(
  bg: sampleColor(seed, 0),
  bgRaised: sampleColor(seed, 1),
  surface: sampleColor(seed, 2),
  surface2: sampleColor(seed, 3),
  surface3: sampleColor(seed, 4),
  line: sampleColor(seed, 5),
  lineSoft: sampleColor(seed, 6),
  text: sampleColor(seed, 7),
  text2: sampleColor(seed, 8),
  text3: sampleColor(seed, 9),
  accent: sampleColor(seed, 10),
  accentStrong: sampleColor(seed, 11),
  accentSoft: sampleColor(seed, 12),
  accentLine: sampleColor(seed, 13),
  onAccent: sampleColor(seed, 14),
  focus: sampleColor(seed, 15),
  scrim: sampleColor(seed, 16),
  danger: sampleColor(seed, 17),
  ok: sampleColor(seed, 18),
);

SquareColors sampleSquare(int seed) => SquareColors(
  axisFill: sampleColor(seed, 0),
  axisInk: sampleColor(seed, 1),
  axis: sampleColor(seed, 2),
  diagFill: sampleColor(seed, 3),
  diagInk: sampleColor(seed, 4),
  diag: sampleColor(seed, 5),
  eighthFill: sampleColor(seed, 6),
  eighthInk: sampleColor(seed, 7),
  cellFill: sampleColor(seed, 8),
  cellInk: sampleColor(seed, 9),
  cellLine: sampleColor(seed, 10),
  center: sampleColor(seed, 11),
  today: sampleColor(seed, 12),
  selOuter: sampleColor(seed, 13),
  selInner: sampleColor(seed, 14),
);

ZodiacColors sampleZodiac(int seed) => ZodiacColors(
  fire: sampleColor(seed, 0),
  earth: sampleColor(seed, 1),
  air: sampleColor(seed, 2),
  water: sampleColor(seed, 3),
  signTintOpacity: seed / 100,
);

AspectColors sampleAspects(int seed) => AspectColors(
  conj: sampleColor(seed, 0),
  soft: sampleColor(seed, 1),
  hard: sampleColor(seed, 2),
);

BodyColors sampleBodies(int seed) => BodyColors(
  sun: sampleColor(seed, 0),
  moon: sampleColor(seed, 1),
  mercury: sampleColor(seed, 2),
  venus: sampleColor(seed, 3),
  mars: sampleColor(seed, 4),
  jupiter: sampleColor(seed, 5),
  saturn: sampleColor(seed, 6),
  uranus: sampleColor(seed, 7),
  neptune: sampleColor(seed, 8),
  pluto: sampleColor(seed, 9),
  node: sampleColor(seed, 10),
);

/// `a.copyWith` of every field taken from [b].
ZodiannSurfaces copyAllZodiannSurfaces(ZodiannSurfaces a, ZodiannSurfaces b) =>
    a.copyWith(
      bg: b.bg,
      bgRaised: b.bgRaised,
      surface: b.surface,
      surface2: b.surface2,
      surface3: b.surface3,
      line: b.line,
      lineSoft: b.lineSoft,
      text: b.text,
      text2: b.text2,
      text3: b.text3,
      accent: b.accent,
      accentStrong: b.accentStrong,
      accentSoft: b.accentSoft,
      accentLine: b.accentLine,
      onAccent: b.onAccent,
      focus: b.focus,
      scrim: b.scrim,
      danger: b.danger,
      ok: b.ok,
    );

/// `a.copyWith` of every field taken from [b].
SquareColors copyAllSquareColors(SquareColors a, SquareColors b) => a.copyWith(
  axisFill: b.axisFill,
  axisInk: b.axisInk,
  axis: b.axis,
  diagFill: b.diagFill,
  diagInk: b.diagInk,
  diag: b.diag,
  eighthFill: b.eighthFill,
  eighthInk: b.eighthInk,
  cellFill: b.cellFill,
  cellInk: b.cellInk,
  cellLine: b.cellLine,
  center: b.center,
  today: b.today,
  selOuter: b.selOuter,
  selInner: b.selInner,
);

/// `a.copyWith` of every field taken from [b].
ZodiacColors copyAllZodiacColors(ZodiacColors a, ZodiacColors b) => a.copyWith(
  fire: b.fire,
  earth: b.earth,
  air: b.air,
  water: b.water,
  signTintOpacity: b.signTintOpacity,
);

/// `a.copyWith` of every field taken from [b].
AspectColors copyAllAspectColors(AspectColors a, AspectColors b) =>
    a.copyWith(conj: b.conj, soft: b.soft, hard: b.hard);

/// `a.copyWith` of every field taken from [b].
BodyColors copyAllBodyColors(BodyColors a, BodyColors b) => a.copyWith(
  sun: b.sun,
  moon: b.moon,
  mercury: b.mercury,
  venus: b.venus,
  mars: b.mars,
  jupiter: b.jupiter,
  saturn: b.saturn,
  uranus: b.uranus,
  neptune: b.neptune,
  pluto: b.pluto,
  node: b.node,
);

ZodiannElevation sampleElevation(int seed) => ZodiannElevation(
  floating: [
    BoxShadow(
      color: sampleColor(seed, 0),
      offset: Offset(0, seed.toDouble()),
      blurRadius: seed.toDouble(),
    ),
  ],
  floatingOutline: BorderSide(color: sampleColor(seed, 1)),
);

ZodiannTokens sampleTokens(int seed, Brightness brightness) => ZodiannTokens(
  brightness: brightness,
  surfaces: sampleSurfaces(seed),
  square: sampleSquare(seed),
  zodiac: sampleZodiac(seed),
  aspects: sampleAspects(seed),
  bodies: sampleBodies(seed),
  elevation: sampleElevation(seed),
);
