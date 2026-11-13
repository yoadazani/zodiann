// ZOD-UI-003: MASTER.md §4's floating-layer elevation (drawer, dialog,
// toast), per theme: MASTER's shadow (not kit.css's), with the CSS blur
// converted to the same Gaussian σ, plus the 1 px `line` outline in both
// themes (product-owner decision, 2026-11-13).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  final themes = {'Graphite': graphiteTokens, 'Porcelain': porcelainTokens};

  test("the floating shadow is MASTER's, per theme", () {
    final expected = {
      // CSS `0 24 64 rgba(0,0,0,.55)` / `0 24 56 rgba(21,25,31,.18)`;
      // CSS blur radius = 2σ.
      'Graphite': (const Color.fromRGBO(0, 0, 0, 0.55), 32.0),
      'Porcelain': (const Color.fromRGBO(21, 25, 31, 0.18), 28.0),
    };
    themes.forEach((name, tokens) {
      final floating = tokens.elevation.floating;
      expect(floating, hasLength(1), reason: name);
      final shadow = floating.single;
      expect(shadow.color, expected[name]!.$1, reason: name);
      expect(shadow.offset, const Offset(0, 24), reason: name);
      expect(shadow.spreadRadius, 0, reason: name);
      expect(shadow.blurSigma, closeTo(expected[name]!.$2, 1e-9), reason: name);
    });
  });

  test("the outline is 1 px of the theme's line colour", () {
    themes.forEach((name, tokens) {
      expect(
        tokens.elevation.floatingOutline,
        BorderSide(color: tokens.surfaces.line, width: 1),
        reason: name,
      );
    });
  });

  test('the themes carry ZodiannElevation', () {
    expect(
      ZodiannTheme.graphite.extension<ZodiannElevation>(),
      same(graphiteTokens.elevation),
    );
    expect(
      ZodiannTheme.porcelain.extension<ZodiannElevation>(),
      same(porcelainTokens.elevation),
    );
    for (final script in ZodiannScript.values) {
      expect(
        withZodiannScript(
          ZodiannTheme.graphite,
          script,
        ).extension<ZodiannElevation>(),
        same(graphiteTokens.elevation),
        reason: '$script',
      );
    }
  });

  group('lerp, copyWith, ==', () {
    final a = graphiteTokens.elevation;
    final b = porcelainTokens.elevation;

    test('lerp at 0 and 1 gives the endpoints', () {
      expect(a.lerp(b, 0), a);
      expect(a.lerp(b, 1), b);
    });

    test('lerp at 0.5 blends the shadow and the outline', () {
      final mid = a.lerp(b, 0.5);
      expect(
        mid.floating.single.color,
        Color.lerp(a.floating.single.color, b.floating.single.color, 0.5),
      );
      expect(
        mid.floatingOutline,
        BorderSide.lerp(a.floatingOutline, b.floatingOutline, 0.5),
      );
      expect(mid, isNot(a));
      expect(mid, isNot(b));
    });

    test('lerp with null returns this', () {
      expect(a.lerp(null, 0.5), same(a));
    });

    test('copyWith replaces only the given fields', () {
      expect(a.copyWith(), a);
      final c = a.copyWith(floatingOutline: b.floatingOutline);
      expect(c.floating, a.floating);
      expect(c.floatingOutline, b.floatingOutline);
      final d = a.copyWith(floating: b.floating);
      expect(d.floating, b.floating);
      expect(d.floatingOutline, a.floatingOutline);
    });

    test('equal values are == with equal hashCodes', () {
      ZodiannElevation build() => ZodiannElevation(
        floating: [
          BoxShadow(
            color: const Color(0x11223344),
            offset: const Offset(0, 3),
            blurRadius: 5,
          ),
        ],
        floatingOutline: const BorderSide(color: Color(0xFF556677)),
      );
      final x = build();
      final y = build();
      expect(identical(x.floating, y.floating), isFalse);
      expect(x, y);
      expect(x.hashCode, y.hashCode);
      expect(x, isNot(a));
    });
  });

  test('blurFromCss gives the same sigma as the CSS blur', () {
    for (final css in [8.0, 56.0, 64.0]) {
      final shadow = BoxShadow(blurRadius: ZodiannElevation.blurFromCss(css));
      expect(shadow.blurSigma, closeTo(css / 2, 1e-9), reason: '$css');
    }
  });
}
