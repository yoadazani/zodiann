// ZOD-UI-004: the button state constants (MASTER §10 / §12, kit.css .btn)
// and each variant's fill, border and label colours, from ZodiannSurfaces.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

const _transparent = Color(0x00000000);

void main() {
  final themes = {
    'Graphite': graphiteTokens.surfaces,
    'Porcelain': porcelainTokens.surfaces,
  };

  test("state constants are MASTER §10 / §12's", () {
    expect(ZodiannStates.hoverBrightness, 1.12);
    expect(ZodiannStates.pressedBrightness, 0.94);
    expect(ZodiannStates.pressedOffset, 1);
    expect(ZodiannStates.disabledOpacity, 0.42);
    expect(ZodiannStates.focusRingWidth, 2);
    expect(ZodiannStates.focusRingGap, 2);
    expect(ZodiannStates.dangerBorderOpacity, 0.45);
    expect(ZodiannStates.hoverDuration, const Duration(milliseconds: 150));
    expect(ZodiannStates.transparent, _transparent);
    expect(ZodiannStates.onDangerSolid, const Color(0xFFFFFFFF));
  });

  themes.forEach((name, s) {
    test('$name: each variant resolves to its kit.css colours', () {
      final expected = <ZodiannButtonVariant, (Color, Color, Color)>{
        ZodiannButtonVariant.primary: (s.accent, s.accent, s.onAccent),
        ZodiannButtonVariant.secondary: (s.surface2, s.line, s.text),
        ZodiannButtonVariant.accentOutline: (
          _transparent,
          s.accentLine,
          s.accentStrong,
        ),
        ZodiannButtonVariant.quiet: (_transparent, _transparent, s.text2),
        ZodiannButtonVariant.danger: (
          _transparent,
          s.danger.withValues(alpha: 0.45),
          s.danger,
        ),
        ZodiannButtonVariant.dangerSolid: (
          s.danger,
          s.danger,
          const Color(0xFFFFFFFF),
        ),
      };
      expect(expected.keys, ZodiannButtonVariant.values);
      expected.forEach((variant, c) {
        expect(
          ZodiannButtonColors.resolve(s, variant),
          ZodiannButtonColors(fill: c.$1, border: c.$2, label: c.$3),
          reason: '$variant',
        );
      });
    });
  });

  test('colours compare by value', () {
    const a = ZodiannButtonColors(
      fill: Color(0xFF010203),
      border: Color(0xFF040506),
      label: Color(0xFF070809),
    );
    const b = ZodiannButtonColors(
      fill: Color(0xFF010203),
      border: Color(0xFF040506),
      label: Color(0xFF070809),
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(
      a,
      isNot(
        const ZodiannButtonColors(
          fill: Color(0xFF010203),
          border: Color(0xFF040506),
          label: Color(0xFF07080A),
        ),
      ),
    );
  });

  test('every enabled label meets WCAG AA (4.5:1) on its fill, except dark '
      'dangerSolid (3.37:1, the D2 hand-off to ZOD-NFR-009)', () {
    themes.forEach((name, s) {
      for (final variant in ZodiannButtonVariant.values) {
        final c = ZodiannButtonColors.resolve(s, variant);
        final ground = c.fill.a == 0 ? s.surface : c.fill;
        final ratio = _contrast(c.label, ground);
        if (name == 'Graphite' && variant == ZodiannButtonVariant.dangerSolid) {
          expect(ratio, inExclusiveRange(3.0, 4.5), reason: '$name $variant');
        } else {
          expect(ratio, greaterThanOrEqualTo(4.5), reason: '$name $variant');
        }
      }
    });
  });
}
