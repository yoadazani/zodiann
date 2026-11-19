import 'package:feature_wheel/feature_wheel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/wheel_harness.dart';

int widgetsUnderCanvas(WidgetTester tester) => find
    .descendant(
      of: find.byType(WheelCanvas),
      matching: find.byWidgetPredicate((_) => true),
    )
    .evaluate()
    .length;

void main() {
  group('one canvas (ARCH-5)', () {
    testWidgets(
      'one CustomPaint, one RepaintBoundary, no per-element widgets',
      (tester) async {
        await pumpWheelCanvas(tester);
        expect(wheelPaint(), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(WheelCanvas),
            matching: find.byType(CustomPaint),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(WheelCanvas),
            matching: find.byType(RepaintBoundary),
          ),
          findsOneWidget,
        );
        for (final type in [Positioned, Transform, Text, Stack, Opacity]) {
          expect(
            find.descendant(
              of: find.byType(WheelCanvas),
              matching: find.byType(type),
            ),
            findsNothing,
            reason: '$type',
          );
        }
      },
    );

    testWidgets('the widget count does not depend on pointer or layers', (
      tester,
    ) async {
      await pumpWheelCanvas(tester);
      final base = widgetsUnderCanvas(tester);
      await pumpWheelCanvas(
        tester,
        state: const WheelState(pointerLongitude: 123.4),
      );
      expect(widgetsUnderCanvas(tester), base);
      await pumpWheelCanvas(
        tester,
        layers: [
          const ProportionGridLayer(),
          OrientationProbeLayer(),
          OrientationProbeLayer(),
        ],
      );
      expect(widgetsUnderCanvas(tester), base);
    });
  });

  group('never mirrors (L-6)', () {
    testWidgets(
      'an RTL app draws the same marks as an LTR one, in an LTR island',
      (tester) async {
        final ltr = OrientationProbeLayer();
        await pumpWheelCanvas(tester, layers: [ltr]);
        expect(
          Directionality.of(tester.element(find.byType(WheelCanvas))),
          TextDirection.ltr,
        );
        final ltrTransform = tester
            .renderObject<RenderBox>(wheelPaint())
            .getTransformTo(null);

        final rtl = OrientationProbeLayer();
        await pumpWheelCanvas(
          tester,
          layers: [rtl],
          locale: const Locale('he'),
        );
        // Control: the ambient direction really is RTL.
        expect(
          Directionality.of(tester.element(find.byType(WheelCanvas))),
          TextDirection.rtl,
        );
        // The island is LTR, and layers are handed LTR.
        final nearest = tester.widget<Directionality>(
          find
              .ancestor(of: wheelPaint(), matching: find.byType(Directionality))
              .first,
        );
        expect(nearest.textDirection, TextDirection.ltr);
        expect(rtl.directions, isNotEmpty);
        expect(rtl.directions.toSet(), {TextDirection.ltr});
        // Longitude 90 (pointer 0) is left of the centre, in both.
        expect(rtl.points.last, ltr.points.last);
        expect(rtl.points.last.dx, lessThan(322));
        // Nothing is mirrored at widget level either: same transform to the
        // root, and no flip or fit widget under the canvas in RTL.
        expect(
          tester.renderObject<RenderBox>(wheelPaint()).getTransformTo(null),
          ltrTransform,
        );
        for (final type in [Transform, FittedBox]) {
          expect(
            find.descendant(
              of: find.byType(WheelCanvas),
              matching: find.byType(type),
            ),
            findsNothing,
            reason: "$type under RTL",
          );
        }
      },
    );
  });

  group('sizing', () {
    testWidgets('a 644 x 656 box gives R 300 (halo ring radius 306)', (
      tester,
    ) async {
      await pumpWheelCanvas(tester);
      expect(
        wheelRenderObject(tester),
        paints..something((method, args) {
          return method == #drawCircle &&
              ((args[1] as double) - 306).abs() < 1e-6;
        }),
      );
    });

    testWidgets('a wider box centres the drawing', (tester) async {
      final probe = OrientationProbeLayer();
      await pumpWheelCanvas(
        tester,
        size: const Size(1000, 656),
        layers: [probe],
      );
      // 90° on the unit ring is 300 px left of the centre at x = 500.
      expect(probe.points.last.dx, closeTo(200, 1e-6));
      expect(probe.points.last.dy, closeTo(334, 1e-6));
    });

    testWidgets('unbounded height takes it from the width (scroll view)', (
      tester,
    ) async {
      await pumpWheelCanvas(
        tester,
        wrap: (canvas) =>
            SizedBox(width: 322, child: SingleChildScrollView(child: canvas)),
      );
      expect(tester.takeException(), isNull);
      final size = tester.getSize(wheelPaint());
      expect(size.width, 322);
      expect(size.height, closeTo(322 / (644 / 656), 1e-9));
    });

    testWidgets('unbounded width takes it from the height (Row)', (
      tester,
    ) async {
      await pumpWheelCanvas(
        tester,
        wrap: (canvas) => SizedBox(height: 328, child: Row(children: [canvas])),
      );
      expect(tester.takeException(), isNull);
      final size = tester.getSize(wheelPaint());
      expect(size.height, 328);
      expect(size.width, closeTo(328 * 644 / 656, 1e-9));
    });

    testWidgets('unbounded both ways is empty and throws nothing', (
      tester,
    ) async {
      await pumpWheelCanvas(
        tester,
        wrap: (canvas) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(child: canvas),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(wheelPaint()), Size.zero);
      expect(wheelRenderObject(tester), paintsNothing);
    });
    for (final (name, size) in [
      ('shrink', Size.zero),
      ('0 x 100', const Size(0, 100)),
      ('100 x 0', const Size(100, 0)),
    ]) {
      testWidgets('a $name box paints nothing and throws nothing', (
        tester,
      ) async {
        await pumpWheelCanvas(tester, size: size);
        expect(tester.takeException(), isNull);
        expect(wheelRenderObject(tester), paintsNothing);
      });
    }
  });

  test('the default layers are the sign ring, then the degree scale', () {
    const canvas = WheelCanvas(
      proportions: WheelProportions.desktop,
      state: WheelState(),
    );
    expect(canvas.layers, hasLength(2));
    expect(canvas.layers[0], isA<SignRingLayer>());
    expect(canvas.layers[1], isA<DegreeScaleLayer>());
  });

  group('theme inputs for layers', () {
    for (final (name, theme, brightness) in [
      ('graphite', ZodiannTheme.graphite, Brightness.dark),
      ('porcelain', ZodiannTheme.porcelain, Brightness.light),
    ]) {
      testWidgets(
        '$name: layers get the theme zodiac colours and glyph style',
        (tester) async {
          final probe = OrientationProbeLayer();
          await pumpWheelCanvas(
            tester,
            layers: [probe],
            brightness: brightness,
          );
          expect(probe.zodiacs.last, theme.extension<ZodiacColors>());
          expect(
            probe.glyphStyles.last,
            theme.extension<ZodiannTextStyles>()!.glyph,
          );
        },
      );
      testWidgets(
        '$name: layers get the micro role as the label style, with tabular '
        'figures',
        (tester) async {
          final probe = OrientationProbeLayer();
          await pumpWheelCanvas(
            tester,
            layers: [probe],
            brightness: brightness,
          );
          expect(
            probe.labelStyles.last,
            theme.extension<ZodiannTextStyles>()!.micro,
          );
          expect(
            probe.labelStyles.last.fontFeatures,
            contains(const FontFeature.tabularFigures()),
          );
        },
      );
    }
  });

  group('repaint', () {
    WheelPainter painter({
      WheelProportions proportions = WheelProportions.desktop,
      WheelState state = const WheelState(),
      ZodiannSurfaces? surfaces,
      TextDirection direction = TextDirection.ltr,
      ZodiacColors? zodiac,
      TextStyle? glyphStyle,
      TextStyle? labelStyle,
      List<WheelLayer> layers = const [ProportionGridLayer()],
    }) => WheelPainter(
      proportions: proportions,
      state: state,
      surfaces: surfaces ?? ZodiannTheme.graphite.extension<ZodiannSurfaces>()!,
      textDirection: direction,
      zodiac: zodiac ?? ZodiannTheme.graphite.extension<ZodiacColors>()!,
      glyphStyle:
          glyphStyle ??
          ZodiannTheme.graphite.extension<ZodiannTextStyles>()!.glyph,
      labelStyle:
          labelStyle ??
          ZodiannTheme.graphite.extension<ZodiannTextStyles>()!.micro,
      layers: layers,
    );

    test('an identical painter does not repaint', () {
      expect(painter().shouldRepaint(painter()), isFalse);
    });

    test('a changed pointer, table, theme, direction or layers repaint', () {
      final base = painter();
      expect(
        base.shouldRepaint(
          painter(state: const WheelState(pointerLongitude: 1)),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(painter(proportions: WheelProportions.compact)),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          painter(
            surfaces: ZodiannTheme.porcelain.extension<ZodiannSurfaces>()!,
          ),
        ),
        isTrue,
      );
      expect(base.shouldRepaint(painter(direction: TextDirection.rtl)), isTrue);
      expect(base.shouldRepaint(painter(layers: const [])), isTrue);
      expect(
        base.shouldRepaint(
          painter(zodiac: ZodiannTheme.porcelain.extension<ZodiacColors>()!),
        ),
        isTrue,
        reason: 'only the zodiac colours changed',
      );
      expect(
        base.shouldRepaint(painter(glyphStyle: const TextStyle(fontSize: 99))),
        isTrue,
        reason: 'only the glyph style changed',
      );
      expect(
        base.shouldRepaint(painter(labelStyle: const TextStyle(fontSize: 99))),
        isTrue,
        reason: 'only the label style changed',
      );
    });

    testWidgets('switching dark to light repaints with the light colours', (
      tester,
    ) async {
      await pumpWheelCanvas(tester);
      final dark =
          (tester.widget<CustomPaint>(wheelPaint()).painter! as WheelPainter)
              .surfaces;
      await pumpWheelCanvas(tester, brightness: Brightness.light);
      await tester.pumpAndSettle(); // the theme change animates
      final light =
          (tester.widget<CustomPaint>(wheelPaint()).painter! as WheelPainter)
              .surfaces;
      expect(light.line, isNot(dark.line));
    });
  });
}
