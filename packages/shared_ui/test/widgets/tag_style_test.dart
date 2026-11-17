// ZOD-UI-009: the tag variants' fill, ink, outline and weight (MASTER §10
// "Tags", kit.css `.tag*`), the NFR-X4 marks, and the mark opacity.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

const _transparent = Color(0x00000000);

void main() {
  final themes = {
    'Graphite': (graphiteTokens.square, graphiteTokens.surfaces),
    'Porcelain': (porcelainTokens.square, porcelainTokens.surfaces),
  };

  themes.forEach((name, t) {
    final (sq, s) = t;

    test('$name: every variant maps to its kit.css colours', () {
      // fill, ink, outline, weight
      final expected = <ZodiannTagVariant, (Color, Color, Color?, FontWeight)>{
        ZodiannTagVariant.axis: (
          sq.axisFill,
          sq.axisInk,
          null,
          FontWeight.w600,
        ),
        ZodiannTagVariant.diagonal: (
          sq.diagFill,
          sq.diagInk,
          null,
          FontWeight.w600,
        ),
        ZodiannTagVariant.eighth: (
          sq.eighthFill,
          sq.eighthInk,
          null,
          FontWeight.w600,
        ),
        ZodiannTagVariant.noHighlight: (
          s.surface2,
          s.text2,
          null,
          FontWeight.w600,
        ),
        ZodiannTagVariant.center: (
          _transparent,
          sq.center,
          sq.center,
          FontWeight.w600,
        ),
        ZodiannTagVariant.today: (
          _transparent,
          sq.today,
          sq.today,
          FontWeight.w600,
        ),
        ZodiannTagVariant.neutral: (s.surface2, s.text2, null, FontWeight.w500),
        ZodiannTagVariant.accent: (
          s.accentSoft,
          s.accentStrong,
          null,
          FontWeight.w600,
        ),
      };
      expect(expected.keys, ZodiannTagVariant.values);
      expected.forEach((variant, e) {
        final style = ZodiannTagStyle.of(variant, sq, s);
        expect(style.fill, e.$1, reason: '$variant fill');
        expect(style.ink, e.$2, reason: '$variant ink');
        expect(style.outline, e.$3, reason: '$variant outline');
        expect(style.weight, e.$4, reason: '$variant weight');
      });
    });

    test('$name: accent is accent-soft on accent-strong (tokens)', () {
      final style = ZodiannTagStyle.of(ZodiannTagVariant.accent, sq, s);
      expect(style.fill, s.accentSoft);
      expect(style.ink, s.accentStrong);
    });

    test('$name: only the neutral tag is weight 500', () {
      for (final v in ZodiannTagVariant.values) {
        final w = ZodiannTagStyle.of(v, sq, s).weight;
        expect(
          w,
          v == ZodiannTagVariant.neutral ? FontWeight.w500 : FontWeight.w600,
          reason: '$v',
        );
      }
    });

    test(
      '$name: only center and today have an outline, equal to their ink',
      () {
        for (final v in ZodiannTagVariant.values) {
          final style = ZodiannTagStyle.of(v, sq, s);
          final outlined =
              v == ZodiannTagVariant.center || v == ZodiannTagVariant.today;
          expect(style.outline != null, outlined, reason: '$v');
          if (outlined) expect(style.outline, style.ink, reason: '$v');
        }
      },
    );
  });

  test('mark is + for axis, × for diagonal and null for the other six', () {
    expect(ZodiannTagVariant.axis.mark, '+');
    expect(ZodiannTagVariant.diagonal.mark, '\u{00D7}');
    for (final v in ZodiannTagVariant.values) {
      if (v == ZodiannTagVariant.axis || v == ZodiannTagVariant.diagonal) {
        continue;
      }
      expect(v.mark, isNull, reason: '$v');
    }
  });

  test('ZodiannStates.tagMarkOpacity is 0.9', () {
    expect(ZodiannStates.tagMarkOpacity, 0.9);
  });

  test('== and hashCode', () {
    const a = ZodiannTagStyle(
      fill: Color(0xFF000001),
      ink: Color(0xFF000002),
      outline: Color(0xFF000003),
      weight: FontWeight.w600,
    );
    const same = ZodiannTagStyle(
      fill: Color(0xFF000001),
      ink: Color(0xFF000002),
      outline: Color(0xFF000003),
      weight: FontWeight.w600,
    );
    expect(a, same);
    expect(a.hashCode, same.hashCode);
    for (final other in const [
      ZodiannTagStyle(
        fill: Color(0xFF000009),
        ink: Color(0xFF000002),
        outline: Color(0xFF000003),
        weight: FontWeight.w600,
      ),
      ZodiannTagStyle(
        fill: Color(0xFF000001),
        ink: Color(0xFF000009),
        outline: Color(0xFF000003),
        weight: FontWeight.w600,
      ),
      ZodiannTagStyle(
        fill: Color(0xFF000001),
        ink: Color(0xFF000002),
        weight: FontWeight.w600,
      ),
      ZodiannTagStyle(
        fill: Color(0xFF000001),
        ink: Color(0xFF000002),
        outline: Color(0xFF000003),
        weight: FontWeight.w500,
      ),
    ]) {
      expect(a, isNot(other));
    }
  });
}
