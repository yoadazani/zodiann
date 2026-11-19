import 'package:astro_core/astro_core.dart';
import 'package:feature_wheel/feature_wheel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/load_wheel_fonts.dart';
import '../support/wheel_capture.dart';
import '../support/wheel_harness.dart';

Future<List<int>> _bytes(WidgetTester tester) => captureBytes(tester);

Widget Function(Widget) _onSurface({double textScale = 1}) =>
    onSurface(textScale: textScale);

void main() {
  l6Tests();
  setUpAll(loadWheelGlyphFonts);

  testWidgets('text scale 2.0 draws the same pixels as 1.0', (tester) async {
    await pumpWheelCanvas(tester, wrap: _onSurface());
    final normal = await _bytes(tester);
    await pumpWheelCanvas(tester, wrap: _onSurface(textScale: 2));
    expect(await _bytes(tester), normal);
  });

  testWidgets('a theme switch repaints the tint and the element colours', (
    tester,
  ) async {
    // Aries' sector near its start, clear of the glyph and the separator:
    // longitude 4°, mid radius, pointer 0, R 300, centre (322, 334).
    final g = WheelGeometry.fit(const Size(644, 656), WheelProportions.desktop);
    final mid =
        (WheelProportions.desktop.signBandOuter +
            WheelProportions.desktop.signBandInner) /
        2;
    final at = g.offsetOf(4, mid);

    Future<List<int>> sectorPixel(Brightness brightness) async {
      await pumpWheelCanvas(tester, wrap: _onSurface(), brightness: brightness);
      await tester.pump(const Duration(seconds: 1)); // AnimatedTheme
      final bytes = await _bytes(tester);
      final i = (at.dy.round() * 644 + at.dx.round()) * 4;
      return bytes.sublist(i, i + 3);
    }

    // MASTER §2.3 fire over the theme's surface at the sign tint.
    List<int> blend(int rgb, int surface, double tint) => [
      for (final shift in [16, 8, 0])
        (((rgb >> shift) & 255) * tint +
                ((surface >> shift) & 255) * (1 - tint))
            .round(),
    ];
    final dark = ZodiannTheme.graphite.extension<ZodiannSurfaces>()!.surface;
    final light = ZodiannTheme.porcelain.extension<ZodiannSurfaces>()!.surface;
    final expectedDark = blend(0xF2735A, dark.toARGB32() & 0xFFFFFF, 0.10);
    final expectedLight = blend(0xD9472B, light.toARGB32() & 0xFFFFFF, 0.09);

    final darkPixel = await sectorPixel(Brightness.dark);
    final lightPixel = await sectorPixel(Brightness.light);
    for (var k = 0; k < 3; k++) {
      expect(darkPixel[k], closeTo(expectedDark[k], 1), reason: 'dark ch $k');
      expect(lightPixel[k], closeTo(expectedLight[k], 1), reason: 'light $k');
    }
  });

  testWidgets('the ring turns with the pointer and the glyphs stay upright', (
    tester,
  ) async {
    await pumpWheelCanvas(tester, wrap: _onSurface());
    final atZero = await _bytes(tester);
    await pumpWheelCanvas(
      tester,
      wrap: _onSurface(),
      state: const WheelState(pointerLongitude: 30),
    );
    final atThirty = await _bytes(tester);
    // One sign (30°) further: the sector pattern is 12-fold, so the tints land
    // on the same sectors shifted by one sign, not the same pixels.
    expect(atThirty, isNot(atZero));
    expect(ZodiacSign.values, hasLength(12));
  });
}

void l6Tests() {
  // L-6: the ring never mirrors and never changes with the language. The app
  // is really RTL in Hebrew (real delegates) and really swaps the script
  // (the harness builder, as app.dart does), so equal bytes mean the ring
  // ignored both.
  for (final (table, proportions) in [
    ('desktop', WheelProportions.desktop),
    ('compact', WheelProportions.compact),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '$table ${brightness.name}: English and Hebrew are identical',
        (tester) async {
          Future<List<int>> render(String language, double textScale) async {
            await pumpWheelCanvas(
              tester,
              proportions: proportions,
              state: const WheelState(pointerLongitude: 227.05),
              layers: const [SignRingLayer()],
              locale: Locale(language),
              brightness: brightness,
              wrap: _onSurface(textScale: textScale),
            );
            await tester.pump(const Duration(seconds: 1));
            return _bytes(tester);
          }

          final english = await render('en', 1);
          expect(await render('he', 1), english, reason: 'he vs en');
          expect(await render('he', 2), english, reason: 'he at text scale 2');
        },
      );
    }
  }
}
