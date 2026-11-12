import 'package:material_ui/material_ui.dart';

import '../aspect_colors.dart';
import '../body_colors.dart';
import '../square_colors.dart';
import '../zodiac_colors.dart';
import '../zodiann_surfaces.dart';
import '../zodiann_tokens.dart';

/// Placeholder token values (ZOD-FND-013, product-owner decision 1).
///
/// Each token maps to a role of Material's default `ColorScheme` for
/// [brightness], with no colour literals. `bg` is the default `surface`, so
/// the shell's scaffold colour is unchanged. Data tokens (square, zodiac,
/// aspects, bodies) are all `outline`: nothing paints them yet.
///
/// ZOD-UI-001 deletes this file and writes MASTER.md §2's exact values into
/// `graphite_tokens.dart` and `porcelain_tokens.dart`.
ZodiannTokens placeholderTokens(Brightness brightness) {
  final c = ThemeData(brightness: brightness).colorScheme;
  final data = c.outline;
  return ZodiannTokens(
    brightness: brightness,
    surfaces: ZodiannSurfaces(
      bg: c.surface,
      bgRaised: c.surfaceContainerLow,
      surface: c.surface,
      surface2: c.surfaceContainerHigh,
      surface3: c.surfaceContainerHighest,
      line: c.outline,
      lineSoft: c.outlineVariant,
      text: c.onSurface,
      text2: c.onSurfaceVariant,
      text3: c.onSurfaceVariant,
      accent: c.primary,
      accentStrong: c.primary,
      accentSoft: c.primaryContainer,
      accentLine: c.outline,
      onAccent: c.onPrimary,
      focus: c.primary,
      scrim: c.scrim,
      danger: c.error,
      ok: c.tertiary,
    ),
    square: SquareColors(
      axisFill: data,
      axisInk: data,
      axis: data,
      diagFill: data,
      diagInk: data,
      diag: data,
      eighthFill: data,
      eighthInk: data,
      cellFill: data,
      cellInk: data,
      cellLine: data,
      center: data,
      today: data,
      selOuter: data,
      selInner: data,
    ),
    zodiac: ZodiacColors(
      fire: data,
      earth: data,
      air: data,
      water: data,
      // MASTER §2.3's sign tint: 10 % dark, 9 % light (numbers, not colours).
      signTintOpacity: brightness == Brightness.dark ? 0.10 : 0.09,
    ),
    aspects: AspectColors(conj: data, soft: data, hard: data),
    bodies: BodyColors(
      sun: data,
      moon: data,
      mercury: data,
      venus: data,
      mars: data,
      jupiter: data,
      saturn: data,
      uranus: data,
      neptune: data,
      pluto: data,
      node: data,
    ),
  );
}
