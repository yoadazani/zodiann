// ZOD-UI-002: every MASTER.md §3 type role has its exact values, the
// script's family, tabular figures and even leading; the TextTheme maps all
// 15 slots from the roles; withZodiannScript swaps only the typography.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

/// MASTER §3 (blanks from kit.css): role → (size, line height, weight, em).
const _master = <String, (double, double, FontWeight, double)>{
  'heroWordmark': (56, 1.0, FontWeight.w300, -0.035),
  'heroWordmarkPhone': (40, 1.0, FontWeight.w300, -0.035),
  'displayReadout': (44, 1.0, FontWeight.w300, -0.03),
  'displayReadoutPhone': (34, 1.0, FontWeight.w300, -0.03),
  'sectionTitle': (26, 1.2, FontWeight.w600, -0.02),
  'drawerWordmark': (20, 1.45, FontWeight.w600, -0.01),
  'screenTitle': (18, 1.2, FontWeight.w600, -0.01),
  'panelTitle': (16, 1.3, FontWeight.w600, 0),
  'body': (14, 1.45, FontWeight.w400, 0),
  'small': (13, 1.45, FontWeight.w400, 0),
  'label': (12, 1.45, FontWeight.w500, 0),
  'micro': (11, 1.45, FontWeight.w400, 0),
  'cell': (11.5, 1.12, FontWeight.w400, 0),
};

const _p = 'packages/shared_ui';
const _glyphFallback = [
  '$_p/Noto Sans Symbols',
  '$_p/Noto Sans Symbols 2',
  '$_p/Noto Sans',
];
const _family = {
  ZodiannScript.latin: '$_p/IBM Plex Sans',
  ZodiannScript.hebrew: '$_p/IBM Plex Sans Hebrew',
};
const _fallback = {
  ZodiannScript.latin: ['$_p/IBM Plex Sans Hebrew', ..._glyphFallback],
  ZodiannScript.hebrew: ['$_p/IBM Plex Sans', ..._glyphFallback],
};

final _tokens = {'graphite': graphiteTokens, 'porcelain': porcelainTokens};

TextStyle _w500(TextStyle s) => s.copyWith(fontWeight: FontWeight.w500);

void main() {
  for (final MapEntry(key: name, value: tokens) in _tokens.entries) {
    for (final script in ZodiannScript.values) {
      group('$name ${script.name}', () {
        final r = buildZodiannTextStyles(tokens.surfaces, script);

        test('every role has MASTER\'s size, line height, weight and '
            'tracking', () {
          expect(r.roles.keys.toList(), [..._master.keys, 'glyph']);
          _master.forEach((role, v) {
            final (size, height, weight, em) = v;
            final s = r.roles[role]!;
            expect(s.fontSize, size, reason: role);
            expect(s.height, height, reason: role);
            expect(s.fontWeight, weight, reason: role);
            expect(s.letterSpacing, closeTo(em * size, 1e-9), reason: role);
          });
        });

        test('UI roles use the script\'s family with the planned fallback', () {
          for (final role in _master.keys) {
            final s = r.roles[role]!;
            expect(s.fontFamily, _family[script], reason: role);
            expect(s.fontFamilyFallback, _fallback[script], reason: role);
          }
        });

        test('the glyph style uses the glyph fonts at 400 with no fixed '
            'size', () {
          final g = r.glyph;
          expect(g.fontFamily, '$_p/Noto Sans Symbols');
          expect(g.fontFamilyFallback, _glyphFallback.sublist(1));
          expect(g.fontWeight, FontWeight.w400);
          expect(g.height, 1.0);
          expect(g.fontSize, isNull);
          expect(g.letterSpacing, 0);
          expect(g.leadingDistribution, TextLeadingDistribution.even);
        });

        test('UI roles use tabular figures and even leading', () {
          for (final role in _master.keys) {
            final s = r.roles[role]!;
            expect(
              s.fontFeatures,
              contains(const FontFeature.tabularFigures()),
              reason: role,
            );
            expect(
              s.leadingDistribution,
              TextLeadingDistribution.even,
              reason: role,
            );
          }
        });

        test('every style is coloured with the theme\'s text colour', () {
          r.roles.forEach((role, s) {
            expect(s.color, tokens.surfaces.text, reason: role);
          });
        });

        test('no role is letter-spaced (sentence case, no eyebrows)', () {
          r.roles.forEach((role, s) {
            expect(s.letterSpacing, lessThanOrEqualTo(0), reason: role);
          });
        });

        test('the TextTheme fills all 15 slots from the roles', () {
          final t = buildZodiannTextTheme(r);
          final expected = {
            'displayLarge': (t.displayLarge, r.heroWordmark),
            'displayMedium': (t.displayMedium, r.displayReadout),
            'displaySmall': (t.displaySmall, r.displayReadoutPhone),
            'headlineLarge': (t.headlineLarge, r.heroWordmarkPhone),
            'headlineMedium': (t.headlineMedium, r.sectionTitle),
            'headlineSmall': (t.headlineSmall, r.drawerWordmark),
            'titleLarge': (t.titleLarge, r.screenTitle),
            'titleMedium': (t.titleMedium, r.panelTitle),
            'titleSmall': (t.titleSmall, _w500(r.small)),
            'bodyLarge': (t.bodyLarge, r.body),
            'bodyMedium': (t.bodyMedium, r.body),
            'bodySmall': (t.bodySmall, r.small),
            'labelLarge': (t.labelLarge, _w500(r.body)),
            'labelMedium': (t.labelMedium, r.label),
            'labelSmall': (t.labelSmall, r.micro),
          };
          expected.forEach((slot, pair) {
            expect(pair.$1, isNotNull, reason: slot);
            expect(pair.$1, pair.$2, reason: slot);
          });
        });

        test('==/hashCode', () {
          final again = buildZodiannTextStyles(tokens.surfaces, script);
          expect(again, r);
          expect(again.hashCode, r.hashCode);
          for (final role in r.roles.keys) {
            final changed = _withRole(
              r,
              role,
              r.roles[role]!.copyWith(fontSize: 99),
            );
            expect(changed, isNot(r), reason: role);
          }
        });
      });
    }
  }

  test('the themes carry Latin typography', () {
    for (final (theme, tokens) in [
      (ZodiannTheme.graphite, graphiteTokens),
      (ZodiannTheme.porcelain, porcelainTokens),
    ]) {
      expect(
        theme.extension<ZodiannTextStyles>(),
        buildZodiannTextStyles(tokens.surfaces, ZodiannScript.latin),
      );
      expect(theme.textTheme.bodyMedium!.fontFamily, '$_p/IBM Plex Sans');
    }
  });

  test('withZodiannScript swaps only the typography', () {
    for (final theme in [ZodiannTheme.graphite, ZodiannTheme.porcelain]) {
      final he = withZodiannScript(theme, ZodiannScript.hebrew);
      expect(he.textTheme.bodyMedium!.fontFamily, '$_p/IBM Plex Sans Hebrew');
      expect(
        he.extension<ZodiannTextStyles>()!.body.fontFamily,
        '$_p/IBM Plex Sans Hebrew',
      );
      expect(he.colorScheme, theme.colorScheme);
      expect(he.scaffoldBackgroundColor, theme.scaffoldBackgroundColor);
      expect(
        he.extension<ZodiannSurfaces>(),
        same(theme.extension<ZodiannSurfaces>()),
      );
      expect(
        he.extension<SquareColors>(),
        same(theme.extension<SquareColors>()),
      );
      expect(
        he.extension<ZodiacColors>(),
        same(theme.extension<ZodiacColors>()),
      );
      expect(
        he.extension<AspectColors>(),
        same(theme.extension<AspectColors>()),
      );
      expect(he.extension<BodyColors>(), same(theme.extension<BodyColors>()));
      expect(
        withZodiannScript(theme, ZodiannScript.latin).textTheme,
        theme.textTheme,
      );
      expect(
        withZodiannScript(he, ZodiannScript.latin).textTheme,
        theme.textTheme,
      );
      expect(
        withZodiannScript(
          he,
          ZodiannScript.latin,
        ).extension<ZodiannTextStyles>(),
        theme.extension<ZodiannTextStyles>(),
      );
    }
  });

  test('ZodiannScript.forLocale', () {
    for (final l in const [Locale('he'), Locale('he', 'IL'), Locale('iw')]) {
      expect(ZodiannScript.forLocale(l), ZodiannScript.hebrew, reason: '$l');
    }
    for (final l in const [Locale('en'), Locale('fr'), Locale('ar')]) {
      expect(ZodiannScript.forLocale(l), ZodiannScript.latin, reason: '$l');
    }
  });

  test('lerp and copyWith', () {
    final a = buildZodiannTextStyles(
      graphiteTokens.surfaces,
      ZodiannScript.latin,
    );
    final b = buildZodiannTextStyles(
      porcelainTokens.surfaces,
      ZodiannScript.latin,
    );
    expect(a.lerp(b, 0), a);
    expect(a.lerp(b, 1), b);
    expect(
      a.lerp(b, 0.5).body.color,
      Color.lerp(
        graphiteTokens.surfaces.text,
        porcelainTokens.surfaces.text,
        0.5,
      ),
    );
    expect(a.lerp(null, 0.5), same(a));
    const x = TextStyle(fontSize: 1);
    final c = a.copyWith(body: x);
    expect(c.body, x);
    for (final role in a.roles.keys.where((k) => k != 'body')) {
      expect(c.roles[role], a.roles[role], reason: role);
    }
  });

  testWidgets("Material's localized text theme keeps every role's geometry", (
    tester,
  ) async {
    late TextTheme localized;
    await tester.pumpWidget(
      MaterialApp(
        theme: ZodiannTheme.graphite,
        home: Builder(
          builder: (context) {
            localized = Theme.of(context).textTheme;
            return const SizedBox();
          },
        ),
      ),
    );
    final mine = buildZodiannTextTheme(
      ZodiannTheme.graphite.extension<ZodiannTextStyles>()!,
    );
    final pairs = [
      (localized.displayLarge, mine.displayLarge),
      (localized.displayMedium, mine.displayMedium),
      (localized.displaySmall, mine.displaySmall),
      (localized.headlineLarge, mine.headlineLarge),
      (localized.headlineMedium, mine.headlineMedium),
      (localized.headlineSmall, mine.headlineSmall),
      (localized.titleLarge, mine.titleLarge),
      (localized.titleMedium, mine.titleMedium),
      (localized.titleSmall, mine.titleSmall),
      (localized.bodyLarge, mine.bodyLarge),
      (localized.bodyMedium, mine.bodyMedium),
      (localized.bodySmall, mine.bodySmall),
      (localized.labelLarge, mine.labelLarge),
      (localized.labelMedium, mine.labelMedium),
      (localized.labelSmall, mine.labelSmall),
    ];
    for (final (i, (got, want)) in pairs.indexed) {
      expect(got!.fontSize, want!.fontSize, reason: 'slot $i');
      expect(got.height, want.height, reason: 'slot $i');
      expect(got.letterSpacing, want.letterSpacing, reason: 'slot $i');
      expect(got.fontWeight, want.fontWeight, reason: 'slot $i');
    }
  });
}

ZodiannTextStyles _withRole(ZodiannTextStyles r, String role, TextStyle s) =>
    switch (role) {
      'heroWordmark' => r.copyWith(heroWordmark: s),
      'heroWordmarkPhone' => r.copyWith(heroWordmarkPhone: s),
      'displayReadout' => r.copyWith(displayReadout: s),
      'displayReadoutPhone' => r.copyWith(displayReadoutPhone: s),
      'sectionTitle' => r.copyWith(sectionTitle: s),
      'drawerWordmark' => r.copyWith(drawerWordmark: s),
      'screenTitle' => r.copyWith(screenTitle: s),
      'panelTitle' => r.copyWith(panelTitle: s),
      'body' => r.copyWith(body: s),
      'small' => r.copyWith(small: s),
      'label' => r.copyWith(label: s),
      'micro' => r.copyWith(micro: s),
      'cell' => r.copyWith(cell: s),
      'glyph' => r.copyWith(glyph: s),
      _ => throw ArgumentError(role),
    };
