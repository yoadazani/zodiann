import 'package:material_ui/material_ui.dart';

import '../aspect_colors.dart';
import '../body_colors.dart';
import '../square_colors.dart';
import '../zodiac_colors.dart';
import '../zodiann_surfaces.dart';
import '../zodiann_tokens.dart';

/// Light theme tokens (Porcelain): MASTER.md §2's exact values (ZOD-UI-001).
///
/// This directory is the only place colour literals are allowed (ARCH-7).
final ZodiannTokens porcelainTokens = ZodiannTokens(
  brightness: Brightness.light,
  surfaces: const ZodiannSurfaces(
    bg: Color(0xFFF5F6F8),
    bgRaised: Color(0xFFEEF0F3),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF4F5F7),
    surface3: Color(0xFFE9EBEF),
    line: Color(0xFFD9DCE1),
    lineSoft: Color(0xFFE7E9ED),
    text: Color(0xFF0B0C0E),
    text2: Color(0xFF4B5059),
    text3: Color(0xFF646A74),
    accent: Color(0xFF0B0C0E),
    accentStrong: Color(0xFF000000),
    accentSoft: Color.fromRGBO(11, 12, 14, 0.06),
    accentLine: Color.fromRGBO(11, 12, 14, 0.26),
    onAccent: Color(0xFFFFFFFF),
    focus: Color(0xFF0B0C0E),
    scrim: Color.fromRGBO(11, 12, 14, 0.40),
    danger: Color(0xFFDC3545),
    ok: Color(0xFF15803D),
  ),
  square: const SquareColors(
    axisFill: Color(0xFFDCE8FF),
    axisInk: Color(0xFF12357A),
    axis: Color(0xFF2E6BE6),
    diagFill: Color(0xFFFBEFC2),
    diagInk: Color(0xFF5C4500),
    diag: Color(0xFFA87F00),
    eighthFill: Color(0xFFECEDF0),
    eighthInk: Color(0xFF3B4049),
    cellFill: Color(0xFFFFFFFF),
    cellInk: Color(0xFF646A74),
    cellLine: Color(0xFFE7E9ED),
    center: Color(0xFFD97706),
    today: Color(0xFF0E9F8E),
    selOuter: Color(0xFF0B0C0E),
    selInner: Color(0xFFFFFFFF),
  ),
  zodiac: const ZodiacColors(
    fire: Color(0xFFD9472B),
    earth: Color(0xFF2F8F3E),
    air: Color(0xFFA88600),
    water: Color(0xFF1F6FD6),
    signTintOpacity: 0.09,
  ),
  aspects: const AspectColors(
    conj: Color(0xFFD97706),
    soft: Color(0xFF0E9F8E),
    hard: Color(0xFFDC3545),
  ),
  bodies: const BodyColors(
    sun: Color(0xFFB98500),
    moon: Color(0xFF646A74),
    mercury: Color(0xFF2B7DB0),
    venus: Color(0xFFC2457A),
    mars: Color(0xFFDC3545),
    jupiter: Color(0xFFC4621A),
    saturn: Color(0xFF7D6A33),
    uranus: Color(0xFF0E8C82),
    neptune: Color(0xFF3D5AE0),
    pluto: Color(0xFF7A45C9),
    node: Color(0xFF646A74),
  ),
);
