import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import 'samples.dart';

/// The ColorScheme mapping table from the FND-013 plan, as (role, token).
List<(String, Color, Color)> _mapping(ThemeData theme) {
  final s = theme.extension<ZodiannSurfaces>()!;
  final c = theme.colorScheme;
  return [
    ('primary', c.primary, s.accent),
    ('onPrimary', c.onPrimary, s.onAccent),
    ('secondary', c.secondary, s.accent),
    ('onSecondary', c.onSecondary, s.onAccent),
    ('error', c.error, s.danger),
    ('onError', c.onError, s.onAccent),
    ('surface', c.surface, s.surface),
    ('onSurface', c.onSurface, s.text),
    ('onSurfaceVariant', c.onSurfaceVariant, s.text2),
    ('surfaceContainerLowest', c.surfaceContainerLowest, s.bg),
    ('surfaceContainerLow', c.surfaceContainerLow, s.bgRaised),
    ('surfaceContainer', c.surfaceContainer, s.surface),
    ('surfaceContainerHigh', c.surfaceContainerHigh, s.surface2),
    ('surfaceContainerHighest', c.surfaceContainerHighest, s.surface3),
    ('outline', c.outline, s.line),
    ('outlineVariant', c.outlineVariant, s.lineSoft),
    ('scrim', c.scrim, s.scrim),
    ('scaffoldBackgroundColor', theme.scaffoldBackgroundColor, s.bg),
  ];
}

void main() {
  final themes = {
    'graphite': (ZodiannTheme.graphite, graphiteTokens),
    'porcelain': (ZodiannTheme.porcelain, porcelainTokens),
  };

  test('graphite is dark and porcelain is light', () {
    expect(ZodiannTheme.graphite.brightness, Brightness.dark);
    expect(ZodiannTheme.graphite.colorScheme.brightness, Brightness.dark);
    expect(ZodiannTheme.porcelain.brightness, Brightness.light);
    expect(ZodiannTheme.porcelain.colorScheme.brightness, Brightness.light);
  });

  test('both themes carry all five extensions', () {
    themes.forEach((name, entry) {
      final (theme, tokens) = entry;
      expect(
        theme.extension<ZodiannSurfaces>(),
        same(tokens.surfaces),
        reason: name,
      );
      expect(
        theme.extension<SquareColors>(),
        same(tokens.square),
        reason: name,
      );
      expect(
        theme.extension<ZodiacColors>(),
        same(tokens.zodiac),
        reason: name,
      );
      expect(
        theme.extension<AspectColors>(),
        same(tokens.aspects),
        reason: name,
      );
      expect(theme.extension<BodyColors>(), same(tokens.bodies), reason: name);
    });
  });

  test('ColorScheme and scaffold derive from ZodiannSurfaces', () {
    themes.forEach((name, entry) {
      for (final (role, actual, token) in _mapping(entry.$1)) {
        expect(actual, token, reason: '$name $role');
      }
    });
  });

  test('buildZodiannTheme uses only the given tokens', () {
    final tokens = sampleTokens(7, Brightness.dark);
    final theme = buildZodiannTheme(tokens);
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, tokens.surfaces.accent);
    for (final (role, actual, token) in _mapping(theme)) {
      expect(actual, token, reason: role);
    }
    expect(theme.extension<ZodiannSurfaces>(), same(tokens.surfaces));
    expect(theme.extension<SquareColors>(), same(tokens.square));
    expect(theme.extension<ZodiacColors>(), same(tokens.zodiac));
    expect(theme.extension<AspectColors>(), same(tokens.aspects));
    expect(theme.extension<BodyColors>(), same(tokens.bodies));
  });

  test("placeholder signTintOpacity is MASTER's 10 % / 9 %", () {
    expect(graphiteTokens.zodiac.signTintOpacity, 0.10);
    expect(porcelainTokens.zodiac.signTintOpacity, 0.09);
  });
}
