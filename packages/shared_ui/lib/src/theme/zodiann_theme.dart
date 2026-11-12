import 'package:material_ui/material_ui.dart';

import 'tokens/graphite_tokens.dart';
import 'tokens/porcelain_tokens.dart';
import 'zodiann_tokens.dart';

/// Builds a `ThemeData` from [t]: the `ColorScheme` and the scaffold colour
/// derive from `t.surfaces`, and the five groups become the theme's
/// extensions, so each colour has one source (MASTER.md §2, ARCH-7).
///
/// MASTER defines no secondary or tertiary colours, so the monochrome accent
/// fills those roles. Roles left unset fall back to `ColorScheme`'s defaults:
/// `primaryContainer` → `primary`, `tertiary` → `secondary`, and
/// `surfaceTint` → `primary` (an accent tint on M3 elevated surfaces, which
/// ZOD-UI-003/UI-004 should revisit).
ThemeData buildZodiannTheme(ZodiannTokens t) {
  final s = t.surfaces;
  return ThemeData(
    brightness: t.brightness,
    colorScheme: ColorScheme(
      brightness: t.brightness,
      primary: s.accent,
      onPrimary: s.onAccent,
      secondary: s.accent,
      onSecondary: s.onAccent,
      error: s.danger,
      onError: s.onAccent,
      surface: s.surface,
      onSurface: s.text,
      onSurfaceVariant: s.text2,
      surfaceContainerLowest: s.bg,
      surfaceContainerLow: s.bgRaised,
      surfaceContainer: s.surface,
      surfaceContainerHigh: s.surface2,
      surfaceContainerHighest: s.surface3,
      outline: s.line,
      outlineVariant: s.lineSoft,
      scrim: s.scrim,
    ),
    scaffoldBackgroundColor: s.bg,
    extensions: t.extensions,
  );
}

/// Zodiann's two themes: Graphite (dark) and Porcelain (light).
abstract final class ZodiannTheme {
  static final ThemeData graphite = buildZodiannTheme(graphiteTokens);
  static final ThemeData porcelain = buildZodiannTheme(porcelainTokens);
}
