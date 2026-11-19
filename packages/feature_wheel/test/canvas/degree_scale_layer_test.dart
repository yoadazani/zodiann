import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:feature_wheel/feature_wheel.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show Locale, SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show ThemeData;
import 'package:shared_ui/shared_ui.dart';

import '../support/load_wheel_fonts.dart';
import '../support/wheel_capture.dart';
import '../support/wheel_harness.dart';

const _desktop = WheelProportions.desktop;
const _compact = WheelProportions.compact;

// MASTER §2.1 text colours (RGB), typed here, never read from the tokens.
const _text2 = {ui.Brightness.dark: 0xA0A4AD, ui.Brightness.light: 0x4B5059};
const _text3 = {ui.Brightness.dark: 0x7C808A, ui.Brightness.light: 0x646A74};

const _draws = {#drawLine, #drawParagraph, #drawCircle, #drawPath};

typedef _Call = ({Symbol name, List<dynamic> args});
typedef _Label = ({double height, double longestLine, Offset at});

/// Records each paragraph's metrics when it is drawn (the layer disposes its
/// paragraphs right after painting).
final class _MetricsCanvas extends TestRecordingCanvas {
  final paragraphs = <_Label>[];

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
  labelStyle: theme.extension<ZodiannTextStyles>()!.micro,
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
  const DegreeScaleLayer().paint(
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

/// The independent closed form: longitude [d] at radius [r] from the centre,
/// with [pointer] under the fixed pointer at 12 o'clock, counter-clockwise.
Offset _at(WheelGeometry g, double r, double d, double pointer) {
  final delta = (d - pointer) * math.pi / 180;
  return g.center + Offset(-r * math.sin(delta), -r * math.cos(delta));
}

// The test-local classification (kit.js:318-321), written independently of
// the layer.
bool _hasTick(int d) => d % 30 != 0;
double _length(int d) => d % 10 == 0 ? 14 : (d % 5 == 0 ? 9 : 5);
const _tenDegrees = [
  10, 20, 40, 50, 70, 80, 100, 110, 130, 140, 160, 170, //
  190, 200, 220, 230, 250, 260, 280, 290, 310, 320, 340, 350,
];

Offset _centreOf(_Label label) =>
    label.at + Offset(label.longestLine / 2, label.height / 2);

void _expectNear(Offset actual, Offset expected, [double tol = 0.01]) {
  expect(actual.dx, closeTo(expected.dx, tol), reason: '$actual vs $expected');
  expect(actual.dy, closeTo(expected.dy, tol), reason: '$actual vs $expected');
}

void main() {
  group('the tick table', () {
    test('348 ticks: 288 / 36 / 24, none at a multiple of 30', () {
      final ticks = degreeTicks();
      expect(ticks, hasLength(348));
      expect(
        ticks.where((t) => t.tickClass == TickClass.degree),
        hasLength(288),
      );
      expect(ticks.where((t) => t.tickClass == TickClass.five), hasLength(36));
      expect(ticks.where((t) => t.tickClass == TickClass.ten), hasLength(24));
      expect(ticks.where((t) => t.degree % 30 == 0), isEmpty);
    });

    test('classes follow the kit rule, ascending and unique', () {
      final ticks = degreeTicks();
      expect(ticks.map((t) => t.degree), [
        for (var d = 1; d < 360; d++)
          if (_hasTick(d)) d,
      ]);
      for (final t in ticks) {
        final expected = t.degree % 10 == 0
            ? TickClass.ten
            : (t.degree % 5 == 0 ? TickClass.five : TickClass.degree);
        expect(t.tickClass, expected, reason: '${t.degree}');
      }
      expect(
        ticks.where((t) => t.tickClass == TickClass.ten).map((t) => t.degree),
        _tenDegrees,
      );
    });
  });

  group('lines', () {
    for (final (name, table) in [
      ('desktop', _desktop),
      ('compact', _compact),
    ]) {
      for (final pointer in [0.0, 123.4, 359.9]) {
        test(
          '$name, pointer $pointer: 348 ticks at the closed-form points',
          () {
            final pass = _paint(proportions: table, pointer: pointer);
            final lines = pass.of(#drawLine).toList();
            final degrees = [
              for (var d = 1; d < 360; d++)
                if (_hasTick(d)) d,
            ];
            expect(lines, hasLength(348));
            final start = table.tickInnerEdge * pass.geometry.radius;
            for (var i = 0; i < degrees.length; i++) {
              final d = degrees[i];
              final length = _length(d) / 300 * pass.geometry.radius;
              _expectNear(
                lines[i][0] as Offset,
                _at(pass.geometry, start, d.toDouble(), pointer),
              );
              _expectNear(
                lines[i][1] as Offset,
                _at(pass.geometry, start - length, d.toDouble(), pointer),
              );
            }
          },
        );
      }
    }

    test('R = 150 halves every offset from the centre', () {
      final big = _paint();
      final small = _paint(box: const Size(322, 328));
      expect(small.geometry.radius, closeTo(150, 1e-9));
      final a = big.of(#drawLine).toList();
      final b = small.of(#drawLine).toList();
      for (var i = 0; i < a.length; i++) {
        _expectNear(
          (b[i][0] as Offset) - small.geometry.center,
          ((a[i][0] as Offset) - big.geometry.center) / 2,
        );
        _expectNear(
          (b[i][1] as Offset) - small.geometry.center,
          ((a[i][1] as Offset) - big.geometry.center) / 2,
        );
      }
    });

    test(
      'the number and order of draws: a tick, then its label when it has one',
      () {
        final names = _paint().calls.map((c) => c.name).toList();
        expect(names, hasLength(348 + 24));
        // The first tick that has a label is 10°: nine ticks, then the tick
        // itself and its paragraph.
        expect(names.sublist(0, 11), [
          for (var i = 0; i < 10; i++) #drawLine,
          #drawParagraph,
        ]);
      },
    );
  });

  group('strokes and colours', () {
    for (final theme in [ZodiannTheme.graphite, ZodiannTheme.porcelain]) {
      final brightness = theme.brightness;
      test('$brightness: width, cap and colour per class', () {
        final pass = _paint(theme: theme);
        final unit = pass.geometry.radius / 300;
        final lines = pass.of(#drawLine).toList();
        final degrees = [
          for (var d = 1; d < 360; d++)
            if (_hasTick(d)) d,
        ];
        for (var i = 0; i < degrees.length; i++) {
          final d = degrees[i];
          final paint = lines[i][2] as Paint;
          final width = d % 10 == 0 ? 1.2 : (d % 5 == 0 ? 1.0 : 0.8);
          final rgb = d % 10 == 0 ? _text2[brightness]! : _text3[brightness]!;
          expect(
            paint.strokeWidth,
            closeTo(width * unit, 1e-6),
            reason: '$d',
          ); // float32
          expect(paint.style, PaintingStyle.stroke, reason: '$d');
          expect(paint.strokeCap, StrokeCap.butt, reason: '$d');
          expect(paint.color.toARGB32(), 0xFF000000 | rgb, reason: '$d');
        }
      });
    }
  });

  group('labels', () {
    for (final (name, table) in [
      ('desktop', _desktop),
      ('compact', _compact),
    ]) {
      for (final pointer in [0.0, 123.4, 359.9]) {
        test('$name, pointer $pointer: 24 labels at the label radius', () {
          final pass = _paint(proportions: table, pointer: pointer);
          final g = pass.geometry;
          final size = table.degreeNumberFontSize * g.radius;
          final labels = pass.canvas.paragraphs;
          expect(labels, hasLength(24));
          for (var i = 0; i < 24; i++) {
            expect(labels[i].height, closeTo(1.45 * size, 0.5)); // whole pixels
            final expected = _at(
              g,
              table.degreeNumberRadius * g.radius,
              _tenDegrees[i].toDouble(),
              pointer,
            );
            _expectNear(
              _centreOf(labels[i]),
              expected + Offset(0, DegreeScaleLayer.labelCentringFactor * size),
            );
          }
        });
      }
    }

    test('no label or tick is rotated or transformed', () {
      final all = _paint().canvas.invocations
          .map((r) => r.invocation.memberName)
          .toSet();
      expect(all.contains(#rotate), isFalse);
      expect(all.contains(#transform), isFalse);
    });
  });

  group('labelStyleOf', () {
    test('keeps tabular figures, family, size and colour', () {
      for (final (table, size, theme) in [
        (_desktop, 9.5, ZodiannTheme.graphite),
        (_compact, 14.0, ZodiannTheme.porcelain),
      ]) {
        final g = WheelGeometry.fit(const Size(644, 656), table);
        final context = _context(_MetricsCanvas(), g, theme, 0);
        final style = DegreeScaleLayer.labelStyleOf(context);
        final micro = theme.extension<ZodiannTextStyles>()!.micro;
        expect(
          style.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
        expect(style.fontFamily, micro.fontFamily);
        expect(style.fontFamilyFallback, micro.fontFamilyFallback);
        expect(style.fontSize, closeTo(size, 1e-9));
        expect(style.color!.toARGB32(), 0xFF000000 | _text3[theme.brightness]!);
      }
    });
  });

  group('robustness', () {
    test('a tiny radius paints without throwing or producing NaN', () {
      final pass = _paint(box: const Size(644 / 300, 656 / 300));
      expect(pass.geometry.radius, closeTo(1, 1e-9));
      for (final line in pass.of(#drawLine)) {
        for (final p in [line[0] as Offset, line[1] as Offset]) {
          expect(p.dx.isFinite && p.dy.isFinite, isTrue);
        }
      }
      for (final label in pass.canvas.paragraphs) {
        expect(label.at.dx.isFinite && label.at.dy.isFinite, isTrue);
      }
    });
  });

  group('labels in the bundled fonts', () {
    setUpAll(() async {
      await loadWheelGlyphFonts();
      await loadWheelTextFonts();
    });

    const box = Size(644, 656);

    double widthOf(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    test('font self-check: "10" is two 0.6 em Plex digits (11.4 at 9.5)', () {
      final g = WheelGeometry.fit(box, _desktop);
      for (final script in ZodiannScript.values) {
        final theme = withZodiannScript(ZodiannTheme.graphite, script);
        final style = DegreeScaleLayer.labelStyleOf(
          _context(_MetricsCanvas(), g, theme, 0),
        );
        expect(widthOf('10', style), closeTo(11.4, 0.1), reason: '$script');
      }
    });

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

    List<int> crop(List<int> rgba, Offset centre) {
      final out = <int>[];
      for (var y = centre.dy.round() - 6; y <= centre.dy.round() + 6; y++) {
        for (var x = centre.dx.round() - 8; x <= centre.dx.round() + 8; x++) {
          final i = (y * box.width.toInt() + x) * 4;
          out.addAll(rgba.sublist(i, i + 4));
        }
      }
      return out;
    }

    testWidgets('each label draws its own text ("10" or "20", never 0 or 30)', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final theme = ZodiannTheme.graphite;
        final actual = await render((canvas, g) {
          const DegreeScaleLayer().paint(_context(canvas, g, theme, 0));
        });
        final g = WheelGeometry.fit(box, _desktop);

        Future<List<int>> reference(Offset centre, String text) =>
            render((canvas, g) {
              final style = DegreeScaleLayer.labelStyleOf(
                _context(canvas, g, theme, 0),
              );
              final painter = TextPainter(
                text: TextSpan(text: text, style: style),
                textDirection: TextDirection.ltr,
              )..layout();
              painter.paint(
                canvas,
                centre -
                    Offset(painter.width / 2, painter.height / 2) +
                    Offset(
                      0,
                      DegreeScaleLayer.labelCentringFactor * style.fontSize!,
                    ),
              );
              painter.dispose();
            });

        for (final d in _tenDegrees) {
          final centre = _at(
            g,
            _desktop.degreeNumberRadius * 300,
            d.toDouble(),
            0,
          );
          final text = '${d % 30}';
          final inked = crop(actual, centre);
          expect(inked.toSet().length, greaterThan(1), reason: '$d has ink');
          expect(
            inked,
            crop(await reference(centre, text), centre),
            reason: 'the label at $d is "$text"',
          );
          for (final wrong in ['0', '30', text == '10' ? '20' : '10']) {
            expect(
              inked,
              isNot(crop(await reference(centre, wrong), centre)),
              reason: 'the label at $d is not "$wrong"',
            );
          }
        }
      });
    });
  });

  group('on screen', () {
    setUpAll(() async {
      await loadWheelGlyphFonts();
      await loadWheelTextFonts();
    });

    testWidgets('text scale 2.0 draws the same pixels as 1.0', (tester) async {
      const layers = [DegreeScaleLayer()];
      await pumpWheelCanvas(tester, layers: layers, wrap: onSurface());
      final normal = await captureBytes(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpWheelCanvas(
        tester,
        layers: layers,
        wrap: onSurface(textScale: 2),
      );
      expect(await captureBytes(tester), normal);
    });

    // L-6: the scale never mirrors and never changes with the language. The
    // app is really RTL in Hebrew (real delegates) and really swaps the script
    // (the harness builder, as app.dart does), so equal bytes mean the scale
    // ignored both. A new tree between the renders keeps a cached picture from
    // hiding a missing repaint field.
    for (final (table, proportions) in [
      ('desktop', _desktop),
      ('compact', _compact),
    ]) {
      for (final brightness in ui.Brightness.values) {
        testWidgets(
          '$table ${brightness.name}: English and Hebrew are identical',
          (tester) async {
            Future<List<int>> render(String language, double textScale) async {
              await tester.pumpWidget(const SizedBox.shrink());
              await pumpWheelCanvas(
                tester,
                proportions: proportions,
                state: const WheelState(pointerLongitude: 227.05),
                layers: const [DegreeScaleLayer()],
                locale: Locale(language),
                brightness: brightness,
                wrap: onSurface(textScale: textScale),
              );
              await tester.pump(const Duration(seconds: 1));
              return captureBytes(tester);
            }

            final english = await render('en', 1);
            expect(await render('he', 1), english, reason: 'he vs en');
            expect(await render('he', 2), english, reason: 'he at scale 2');
          },
        );
      }
    }

    testWidgets('a theme switch repaints the ticks and the labels', (
      tester,
    ) async {
      // The same tree is re-pumped (no new tree in between), so a stale cached
      // picture or a missing `shouldRepaint` field would keep the old colours.
      // With the pointer at 10° (then 5°) the 10° (5°) tick is vertical at
      // 12 o'clock: x = 322 +- 0.6 (1.2 units wide) or +- 0.5 (1 unit), so the
      // two pixels beside the axis each carry exactly that coverage of the ink,
      // 3 units inside the band's inner edge (y = 334 - 247).
      const layers = [DegreeScaleLayer()];
      Future<List<int>> shot(ui.Brightness brightness, double pointer) async {
        await pumpWheelCanvas(
          tester,
          state: WheelState(pointerLongitude: pointer),
          layers: layers,
          wrap: onSurface(),
          brightness: brightness,
        );
        await tester.pumpAndSettle(); // AnimatedTheme
        return captureBytes(tester);
      }

      void expectTick(
        List<int> bytes,
        ThemeData theme,
        int ink,
        double coverage,
      ) {
        final bg = theme.extension<ZodiannSurfaces>()!.surface.toARGB32();
        for (final x in [321, 322]) {
          final i = (87 * 644 + x) * 4;
          for (var k = 0; k < 3; k++) {
            final shift = 16 - 8 * k;
            final b = (bg >> shift) & 255, c = (ink >> shift) & 255;
            expect(
              bytes[i + k],
              closeTo(b + coverage * (c - b), 4),
              reason: 'x $x channel $k',
            );
          }
        }
      }

      for (final (brightness, theme) in [
        (ui.Brightness.dark, ZodiannTheme.graphite),
        (ui.Brightness.light, ZodiannTheme.porcelain),
        (ui.Brightness.dark, ZodiannTheme.graphite),
      ]) {
        final ten = await shot(brightness, 10);
        expectTick(ten, theme, _text2[brightness]!, 0.6);
        final five = await shot(brightness, 5);
        expectTick(five, theme, _text3[brightness]!, 0.5);
      }
    });

    testWidgets('the default canvas draws the ring, then the scale', (
      tester,
    ) async {
      // The default layers of the harness are the canvas's own (checked in
      // wheel_canvas_test.dart). The ring ends with its three circles; the
      // only lines after them are the ticks.
      await pumpWheelCanvas(tester);
      expect(
        wheelRenderObject(tester),
        paints
          ..circle()
          ..circle()
          ..circle()
          ..line(),
      );
    });
  });
}
