import 'package:material_ui/material_ui.dart';

import '../aspect_colors.dart';
import '../body_colors.dart';
import '../square_colors.dart';
import '../zodiac_colors.dart';
import '../zodiann_elevation.dart';
import '../zodiann_surfaces.dart';
import '../zodiann_tokens.dart';

/// Dark theme tokens (Graphite): MASTER.md §2's exact values (ZOD-UI-001).
///
/// This directory is the only place colour literals are allowed (ARCH-7).
final ZodiannTokens graphiteTokens = ZodiannTokens(
  brightness: Brightness.dark,
  surfaces: _surfaces,
  square: const SquareColors(
    axisFill: Color(0xFF16305A),
    axisInk: Color(0xFFD6E4FF),
    axis: Color(0xFF4F8CFF),
    diagFill: Color(0xFF3D3412),
    diagInk: Color(0xFFF3E3A3),
    diag: Color(0xFFE2BF3E),
    eighthFill: Color(0xFF222226),
    eighthInk: Color(0xFFC4C6CC),
    cellFill: Color(0xFF0E0E11),
    cellInk: Color(0xFF8A8E97),
    cellLine: Color(0xFF1C1C21),
    center: Color(0xFFF5A524),
    today: Color(0xFF2DD4BF),
    selOuter: Color(0xFFFFFFFF),
    selInner: Color(0xFF08080A),
  ),
  zodiac: const ZodiacColors(
    fire: Color(0xFFF2735A),
    earth: Color(0xFF7CC47F),
    air: Color(0xFFE8D06E),
    water: Color(0xFF5AA9FF),
    signTintOpacity: 0.10,
  ),
  aspects: const AspectColors(
    conj: Color(0xFFF5A524),
    soft: Color(0xFF2DD4BF),
    hard: Color(0xFFF2555A),
  ),
  bodies: const BodyColors(
    sun: Color(0xFFF5C042),
    moon: Color(0xFFD4D8E0),
    mercury: Color(0xFF8EC5E8),
    venus: Color(0xFFF0A3C0),
    mars: Color(0xFFF2555A),
    jupiter: Color(0xFFF29E5C),
    saturn: Color(0xFFC9B37E),
    uranus: Color(0xFF4FD1C5),
    neptune: Color(0xFF7B93FF),
    pluto: Color(0xFFB48CF2),
    node: Color(0xFF9CA1AB),
  ),
  elevation: _elevation,
);

const ZodiannSurfaces _surfaces = ZodiannSurfaces(
  bg: Color(0xFF08080A),
  bgRaised: Color(0xFF0E0E11),
  surface: Color(0xFF111114),
  surface2: Color(0xFF18181C),
  surface3: Color(0xFF212126),
  line: Color(0xFF2A2A30),
  lineSoft: Color(0xFF1B1B20),
  text: Color(0xFFF4F5F7),
  text2: Color(0xFFA0A4AD),
  text3: Color(0xFF7C808A),
  accent: Color(0xFFF4F5F7),
  accentStrong: Color(0xFFFFFFFF),
  accentSoft: Color.fromRGBO(255, 255, 255, 0.07),
  accentLine: Color.fromRGBO(255, 255, 255, 0.24),
  onAccent: Color(0xFF0A0A0B),
  focus: Color(0xFFFFFFFF),
  scrim: Color.fromRGBO(0, 0, 0, 0.72),
  danger: Color(0xFFF2555A),
  ok: Color(0xFF34D399),
);

/// MASTER §4: floating layers cast `0 24 64 rgba(0,0,0,.55)` and carry a
/// 1 px `line` outline. (kit.css's .6 differs; MASTER wins.)
final ZodiannElevation _elevation = ZodiannElevation(
  floating: [
    BoxShadow(
      color: const Color.fromRGBO(0, 0, 0, 0.55),
      offset: const Offset(0, 24),
      blurRadius: ZodiannElevation.blurFromCss(64),
    ),
  ],
  floatingOutline: BorderSide(color: _surfaces.line),
);
