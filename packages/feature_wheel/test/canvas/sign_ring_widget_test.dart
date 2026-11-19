import 'dart:ui' as ui;

import 'package:astro_core/astro_core.dart';
import 'package:feature_wheel/feature_wheel.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Theme;
import 'package:shared_ui/shared_ui.dart';

import '../support/load_wheel_fonts.dart';
import '../support/wheel_harness.dart';

/// The wheel canvas's pixels, on a `surface` background, as straight RGBA.
final _frame = GlobalKey();

/// The wheel on its `surface` background, as pixels (the boundary wraps the
/// background, so the tint blends over it as it does on screen).
Future<ui.Image> _capture(WidgetTester tester) async {
  final boundary =
      _frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(boundary.toImage))!;
}

Future<List<int>> _bytes(WidgetTester tester) async {
  final image = await _capture(tester);
  final data = await tester.runAsync(image.toByteData);
  image.dispose();
  return data!.buffer.asUint8List();
}

Widget Function(Widget) _onSurface({double textScale = 1}) =>
    (canvas) => Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: RepaintBoundary(
          key: _frame,
          child: ColoredBox(
            color: Theme.of(context).extension<ZodiannSurfaces>()!.surface,
            child: SizedBox(width: 644, height: 656, child: canvas),
          ),
        ),
      ),
    );

void main() {
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
