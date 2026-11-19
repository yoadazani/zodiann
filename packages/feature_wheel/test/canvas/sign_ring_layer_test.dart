import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:astro_core/astro_core.dart';
import 'package:feature_wheel/feature_wheel.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show ThemeData;
import 'package:shared_ui/shared_ui.dart';

import '../support/load_wheel_fonts.dart';

const _desktop = WheelProportions.desktop;
const _compact = WheelProportions.compact;

// MASTER §2.3 element colours (RGB), typed here, never read from the tokens.
const _dark = {
  ZodiacElement.fire: 0xF2735A,
  ZodiacElement.earth: 0x7CC47F,
  ZodiacElement.air: 0xE8D06E,
  ZodiacElement.water: 0x5AA9FF,
};
const _light = {
  ZodiacElement.fire: 0xD9472B,
  ZodiacElement.earth: 0x2F8F3E,
  ZodiacElement.air: 0xA88600,
  ZodiacElement.water: 0x1F6FD6,
};

const _draws = {#drawPath, #drawParagraph, #drawLine, #drawCircle};

typedef _Call = ({Symbol name, List<dynamic> args});

typedef _Glyph = ({double height, double longestLine, Offset at});

/// A recording canvas that reads each paragraph's metrics when it is drawn:
/// the layer disposes its paragraphs right after painting.
final class _MetricsCanvas extends TestRecordingCanvas {
  final paragraphs = <_Glyph>[];

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {
    paragraphs.add((
      height: paragraph.height,
      longestLine: paragraph.longestLine,
      at: offset,
    ));
    super.drawParagraph(paragraph, offset);
  }
}

/// One recorded paint pass of the layer.
final class _Pass {
  _Pass(this.calls, this.geometry, this.canvas);
  final List<_Call> calls;
  final WheelGeometry geometry;
  final _MetricsCanvas canvas;

  Iterable<List<dynamic>> of(Symbol name) =>
      calls.where((c) => c.name == name).map((c) => c.args);
}

WheelPaintContext _context(
  ui.Canvas canvas,
  WheelGeometry geometry,
  ThemeData theme,
  double pointer,
) => WheelPaintContext(
  canvas: canvas,
  geometry: geometry,
  state: WheelState(pointerLongitude: pointer),
  surfaces: theme.extension<ZodiannSurfaces>()!,
  zodiac: theme.extension<ZodiacColors>()!,
  glyphStyle: theme.extension<ZodiannTextStyles>()!.glyph,
  textDirection: TextDirection.ltr,
);

_Pass _paint({
  Size box = const Size(644, 656),
  WheelProportions proportions = _desktop,
  double pointer = 0,
  ThemeData? theme,
}) {
  final canvas = _MetricsCanvas();
  final geometry = WheelGeometry.fit(box, proportions);
  const SignRingLayer().paint(
    _context(canvas, geometry, theme ?? ZodiannTheme.graphite, pointer),
  );
  return _Pass(
    [
      for (final r in canvas.invocations)
        if (_draws.contains(r.invocation.memberName))
          (
            name: r.invocation.memberName,
            args: r.invocation.positionalArguments,
          ),
    ],
    geometry,
    canvas,
  );
}

Offset _centreOf(_Glyph glyph) =>
    glyph.at + Offset(glyph.longestLine / 2, glyph.height / 2);

void _expectNear(Offset actual, Offset expected, [double tol = 0.01]) {
  expect(actual.dx, closeTo(expected.dx, tol), reason: '$actual vs $expected');
  expect(actual.dy, closeTo(expected.dy, tol), reason: '$actual vs $expected');
}

void main() {
  group('order and count', () {
    for (final (name, table) in [
      ('desktop', _desktop),
      ('compact', _compact),
    ]) {
      test('$name: 12 x (sector, glyph, separator), then three circles', () {
        final names = _paint(proportions: table).calls
            .map((c) => c.name)
            .toList();
        expect(names, hasLength(12 * 3 + 3));
        for (var i = 0; i < 12; i++) {
          expect(names.sublist(i * 3, i * 3 + 3), [
            #drawPath,
            #drawParagraph,
            #drawLine,
          ], reason: 'sign $i');
        }
        expect(names.sublist(36), [#drawCircle, #drawCircle, #drawCircle]);
      });
    }

    test('no glyph is rotated or transformed', () {
      final all = _paint().canvas.invocations
          .map((r) => r.invocation.memberName)
          .toSet();
      expect(all.contains(#rotate), isFalse);
      expect(all.contains(#transform), isFalse);
    });
  });

  group('positions (literals: R 300, centre (322, 334), pointer 0)', () {
    test('desktop separators and glyph centres', () {
      final pass = _paint();
      final lines = pass.of(#drawLine).toList();
      _expectNear(lines[0][0] as Offset, const Offset(322, 38));
      _expectNear(lines[0][1] as Offset, const Offset(322, 102));
      _expectNear(lines[1][0] as Offset, const Offset(174, 77.656));
      _expectNear(lines[1][1] as Offset, const Offset(206, 133.082));
      final glyphs = pass.canvas.paragraphs;
      _expectNear(_centreOf(glyphs[0]), const Offset(251.342, 70.302));
      _expectNear(_centreOf(glyphs[11]), const Offset(392.658, 70.302));
    });

    test('compact separators and glyph centres', () {
      final pass = _paint(proportions: _compact);
      final lines = pass.of(#drawLine).toList();
      _expectNear(lines[0][0] as Offset, const Offset(322, 38));
      _expectNear(lines[0][1] as Offset, const Offset(322, 112));
      _expectNear(lines[1][1] as Offset, const Offset(211, 141.742));
      _expectNear(
        _centreOf(pass.canvas.paragraphs.first),
        const Offset(252.636, 75.132),
      );
    });

    test('the same layout at R 150 scales about the centre', () {
      final pass = _paint(box: const Size(322, 328));
      expect(pass.geometry.radius, closeTo(150, 1e-9));
      final lines = pass.of(#drawLine).toList();
      _expectNear(lines[0][0] as Offset, const Offset(161, 19));
      _expectNear(lines[0][1] as Offset, const Offset(161, 51));
      _expectNear(
        _centreOf(pass.canvas.paragraphs.first),
        const Offset(161 + (251.342 - 322) / 2, 167 + (70.302 - 334) / 2),
      );
    });

    test('rotation: the pointer longitude moves the whole ring', () {
      _expectNear(
        _paint(pointer: 123.4).of(#drawLine).first[0] as Offset,
        const Offset(569.115, 496.942),
      );
      _expectNear(
        _paint(pointer: 359.9).of(#drawLine).first[0] as Offset,
        const Offset(321.483, 38.000),
      );
    });

    test('centring offset is a fraction of the glyph size, so it scales', () {
      // Expected glyph point: the ring point plus
      // glyphCentringFactor * signGlyphSize * R (half as large at R 150).
      for (final (box, r) in [
        (const Size(644, 656), 300.0),
        (const Size(322, 328), 150.0),
      ]) {
        final pass = _paint(box: box);
        final mid = (_desktop.signBandOuter + _desktop.signBandInner) / 2;
        final expected =
            pass.geometry.offsetOf(15, mid) +
            Offset(
              0,
              SignRingLayer.glyphCentringFactor * _desktop.signGlyphSize * r,
            );
        _expectNear(_centreOf(pass.canvas.paragraphs.first), expected);
      }
    });
  });

  group('sector geometry', () {
    for (final pointer in [0.0, 123.4, 359.9]) {
      test('every sector spans exactly its 30 degrees at pointer $pointer', () {
        final pass = _paint(pointer: pointer);
        final g = pass.geometry;
        final mid = (_desktop.signBandOuter + _desktop.signBandInner) / 2;
        final paths = pass.of(#drawPath).toList();
        expect(paths, hasLength(12));
        for (var i = 0; i < 12; i++) {
          final path = paths[i][0] as ui.Path;
          Offset at(double offset, double ring) =>
              g.offsetOf(i * 30 + offset, ring, pointerLongitude: pointer);
          expect(path.contains(at(0.5, mid)), isTrue, reason: 'sign $i start');
          expect(path.contains(at(29.5, mid)), isTrue, reason: 'sign $i end');
          expect(path.contains(at(15, mid)), isTrue, reason: 'sign $i middle');
          expect(
            path.contains(at(-0.5, mid)),
            isFalse,
            reason: 'sign $i before',
          );
          expect(
            path.contains(at(30.5, mid)),
            isFalse,
            reason: 'sign $i after',
          );
          expect(
            path.contains(at(15, _desktop.signBandOuter + 1 / 300)),
            isFalse,
            reason: 'sign $i outside the rim',
          );
          expect(
            path.contains(at(15, _desktop.signBandInner - 1 / 300)),
            isFalse,
            reason: 'sign $i inside the inner edge',
          );
        }
      });
    }
  });

  group('colour and stroke', () {
    for (final (name, theme, rgb, tint) in [
      ('graphite', ZodiannTheme.graphite, _dark, 0.10),
      ('porcelain', ZodiannTheme.porcelain, _light, 0.09),
    ]) {
      test('$name: tints, separators, rims and halo', () {
        final pass = _paint(theme: theme);
        final surfaces = theme.extension<ZodiannSurfaces>()!;
        final paths = pass.of(#drawPath).toList();
        for (var i = 0; i < 12; i++) {
          final paint = paths[i][1] as Paint;
          final element = elementOf(ZodiacSign.values[i]);
          expect(paint.style, PaintingStyle.fill);
          expect(paint.color.toARGB32() & 0xFFFFFF, rgb[element], reason: '$i');
          expect(paint.color.a, closeTo(tint, 1e-6), reason: '$i');
        }
        final radius = pass.geometry.radius;
        final unit = radius / 300;
        for (final line in pass.of(#drawLine)) {
          final paint = line[2] as Paint;
          expect(paint.color.toARGB32(), surfaces.line.toARGB32());
          expect(paint.strokeWidth, closeTo(unit, 1e-9));
          expect(paint.style, PaintingStyle.stroke);
        }
        final circles = pass.of(#drawCircle).toList();
        expect(circles[0][1] as double, closeTo(radius * 296 / 300, 1e-9));
        expect(
          (circles[0][2] as Paint).color.toARGB32(),
          surfaces.accentLine.toARGB32(),
        );
        expect(circles[1][1] as double, closeTo(radius * 250 / 300, 1e-9));
        expect(
          (circles[1][2] as Paint).color.toARGB32(),
          surfaces.line.toARGB32(),
        );
        expect(circles[2][1] as double, closeTo(radius * 306 / 300, 1e-9));
        final halo = (circles[2][2] as Paint).color;
        expect(halo.a, closeTo(surfaces.line.a * 0.5, 1e-6));
        expect(halo.toARGB32() & 0xFFFFFF, surfaces.line.toARGB32() & 0xFFFFFF);
        for (final c in circles) {
          expect((c[2] as Paint).style, PaintingStyle.stroke);
          expect((c[2] as Paint).strokeWidth, closeTo(unit, 1e-9));
        }
      });
    }
  });

  group('glyph size', () {
    for (final (name, table, units) in [
      ('desktop', _desktop, 21.0),
      ('compact', _compact, 30.0),
    ]) {
      for (final (box, r) in [
        (const Size(644, 656), 300.0),
        (const Size(322, 328), 150.0),
      ]) {
        test('$name at R ${r.toInt()}: signGlyphSize x R', () {
          final pass = _paint(box: box, proportions: table);
          for (final glyph in pass.canvas.paragraphs) {
            // Flutter rounds paragraph heights to whole pixels.
            expect(glyph.height, closeTo(units / 300 * r, 0.5));
          }
        });
      }
    }
  });

  group('degenerate sizes', () {
    test('R of 1 paints with no exception and no NaN', () {
      final pass = _paint(box: const Size(644 / 300, 656 / 300));
      expect(pass.geometry.radius, closeTo(1, 1e-9));
      for (final c in pass.calls) {
        for (final a in c.args) {
          if (a is Offset) {
            expect(a.dx.isFinite && a.dy.isFinite, isTrue, reason: '${c.name}');
          }
        }
      }
    });
  });

  group('glyph identity and colour (bundled fonts)', () {
    setUpAll(loadWheelGlyphFonts);

    const box = Size(644, 656);

    Future<List<int>> render(
      void Function(Canvas canvas, WheelGeometry g) draw,
    ) async {
      final g = WheelGeometry.fit(box, _desktop);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Offset.zero & box,
        Paint()..color = const Color(0xFF000000),
      );
      draw(canvas, g);
      final image = await recorder.endRecording().toImage(
        box.width.toInt(),
        box.height.toInt(),
      );
      final data = await image.toByteData();
      image.dispose();
      return data!.buffer.asUint8List();
    }

    testWidgets('each sector holds its own sign in its element colour', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final theme = ZodiannTheme.graphite;
        final style = theme.extension<ZodiannTextStyles>()!.glyph;
        final actual = await render((canvas, g) {
          const SignRingLayer().paint(_context(canvas, g, theme, 0));
        });
        final mid = (_desktop.signBandOuter + _desktop.signBandInner) / 2;
        for (var i = 0; i < 12; i++) {
          final colour = Color(
            0xFF000000 | _dark[elementOf(ZodiacSign.values[i])]!,
          );
          // An independent reference: the sector's tint over the crop, then
          // sign i's glyph from the same style at the ring point.
          final expected = await render((canvas, g) {
            final centre = g.offsetOf(i * 30 + 15, mid);
            canvas.drawRect(
              Rect.fromCircle(center: centre, radius: 12),
              Paint()..color = colour.withValues(alpha: 0.10),
            );
            final tp = TextPainter(
              text: TextSpan(
                text: ZodiannGlyphs.signs[i],
                style: style.copyWith(
                  fontSize: _desktop.signGlyphSize * g.radius,
                  color: colour,
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout();
            tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
          });
          final c = WheelGeometry.fit(box, _desktop).offsetOf(i * 30 + 15, mid);
          var maxDiff = 0;
          var inked = false;
          for (var y = c.dy.round() - 9; y <= c.dy.round() + 9; y++) {
            for (var x = c.dx.round() - 9; x <= c.dx.round() + 9; x++) {
              final at = (y * 644 + x) * 4;
              for (var k = 0; k < 3; k++) {
                maxDiff = math.max(
                  maxDiff,
                  (actual[at + k] - expected[at + k]).abs(),
                );
              }
              if (actual[at] == (colour.toARGB32() >> 16 & 255) &&
                  actual[at + 1] == (colour.toARGB32() >> 8 & 255) &&
                  actual[at + 2] == (colour.toARGB32() & 255)) {
                inked = true;
              }
            }
          }
          expect(maxDiff, lessThanOrEqualTo(2), reason: 'sign $i differs');
          expect(inked, isTrue, reason: 'sign $i has no full-colour ink');
        }
      });
    });
  });
}
