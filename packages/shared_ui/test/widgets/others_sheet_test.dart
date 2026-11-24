// ZOD-UI-007 criterion 1: the "Others" rows of the design's component sheet
// (design-reference/zodiann/components/components_{dark,light}.png): the
// aspect-orb stepper, the two switches (on, off) and the five body chips,
// rendered by ZodiannOrbStepper, ZodiannSwitch and ZodiannBodyChip and
// measured by the same extractor (test/support/others_features.dart) on the
// sheet and on the render.
//
// The sheet is 1x (the kit's 1440 px viewport). Positions measured once from
// the PNGs (dark; the light sheet is 18 px higher):
//   stepper box   (730, 2465) 122 x 36
//   switch on     (876, 2471) 40 x 24;  off (928, 2471) 40 x 24
//   chips, y 2544, 34 high: Sun x 730 w 67, Moon 805 w 73, Mercury 886 w 88,
//   Venus 982 w 75, Mean node 1065 w 109 (Chrome snaps the fractional layout
//   to whole pixels, so widths and ink are compared within 2 px).
// The track, border and fill colours, the thumb's box and colour and the
// stepper's box are compared within 1 to 2 per channel and 1 px; ink boxes
// within 2 px (a glyph's within 3: Flutter draws the symbol fonts about 2 to
// 3 px higher than Chrome), ink colours within 12 per channel (a glyph's
// within 20; the sheet has LCD text fringes, so each channel is compared at
// its own extreme).
//
// The Hebrew settings screen (screens/04-settings_desktop_he_dark.png, 1x)
// pins the stepper's mirrored order: + on the left, - on the right.
import 'package:astro_core/astro_core.dart' show Body;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/load_bundled_fonts.dart';
import '../support/others_features.dart';
import '../support/pixels.dart';
import '../support/tag_features.dart' show decodeDesignPng;

typedef _Chip = ({Body body, String label, bool on, int x0, int x1});

const List<_Chip> _chips = [
  (body: Body.sun, label: 'Sun', on: true, x0: 724, x1: 803),
  (body: Body.moon, label: 'Moon', on: true, x0: 803, x1: 881),
  (body: Body.mercury, label: 'Mercury', on: true, x0: 881, x1: 980),
  (body: Body.venus, label: 'Venus', on: true, x0: 980, x1: 1062),
  (body: Body.node, label: 'Mean node', on: false, x0: 1062, x1: 1200),
];

const _themes = {'dark': (-0), 'light': (-18)};

Future<PixelAt> _render(
  WidgetTester tester,
  Widget child,
  ThemeData theme,
  int bg, {
  bool rtl = false,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: Material(
          type: MaterialType.transparency,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: Color(bg),
                child: SizedBox(
                  width: 320,
                  height: 120,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Align(alignment: Alignment.topLeft, child: child),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final px = await Pixels.capture(
    tester,
    tester.renderObject<RenderRepaintBoundary>(find.byKey(key)),
  );
  return px.argb;
}

void _expectColour(int got, int want, int tolerance, String what) {
  expect(
    channelDistance(got, want),
    lessThanOrEqualTo(tolerance),
    reason:
        '$what: ${got.toRadixString(16)} vs sheet ${want.toRadixString(16)}',
  );
}

void _expectBox(PixelBox? got, PixelBox? want, int tolerance, String what) {
  expect(want, isNotNull, reason: '$what: the sheet has ink here');
  expect(got, isNotNull, reason: '$what: the render has ink here');
  expect(
    (got!.left - want!.left).abs(),
    lessThanOrEqualTo(tolerance),
    reason: '$what left $got vs sheet $want',
  );
  expect(
    (got.right - want.right).abs(),
    lessThanOrEqualTo(tolerance),
    reason: '$what right $got vs sheet $want',
  );
  expect(
    (got.top - want.top).abs(),
    lessThanOrEqualTo(tolerance),
    reason: '$what top $got vs sheet $want',
  );
  expect(
    (got.bottom - want.bottom).abs(),
    lessThanOrEqualTo(tolerance),
    reason: '$what bottom $got vs sheet $want',
  );
}

void main() {
  setUpAll(loadBundledFonts);

  testWidgets('a Hebrew stepper mirrors as on the settings screen', (
    tester,
  ) async {
    final img = await tester.runAsync(
      () => decodeDesignPng('screens/04-settings_desktop_he_dark.png'),
    );
    final screen = img!.argb;
    final bg = screen(170, 350);
    // The first orb stepper, 175..297 by 355..391.
    final want = measureStepper(screen, 170, 350, 302, 396, bg);
    final px = await _render(
      tester,
      ZodiannOrbStepper(
        value: 8,
        min: 0,
        max: 20,
        onChanged: (_) {},
        valueLabel: '±8°',
        decrementLabel: 'Decrease',
        incrementLabel: 'Increase',
      ),
      ZodiannTheme.graphite,
      bg,
      rtl: true,
    );
    final got = measureStepper(px, 0, 0, 320, 120, bg);
    expect(got.width, want.width);
    expect(got.height, want.height);
    // Left column: the plus (a tall mark); right column: the minus (a line).
    expect(want.minus!.height, greaterThan(want.plus!.height));
    expect(got.minus!.height, greaterThan(got.plus!.height));
    _expectBox(got.minus, want.minus, 2, 'left (plus)');
    _expectBox(got.plus, want.plus, 2, 'right (minus)');
  });

  for (final entry in _themes.entries) {
    final name = entry.key;
    final dy = entry.value;
    final theme = name == 'dark'
        ? ZodiannTheme.graphite
        : ZodiannTheme.porcelain;
    late PixelAt sheet;
    late int bg;

    group('$name sheet', () {
      setUp(() {});

      Future<void> load(WidgetTester tester) async {
        final img = await tester.runAsync(
          () => decodeDesignPng('components/components_$name.png'),
        );
        sheet = img!.argb;
        bg = sheet(722, 2460 + dy);
      }

      testWidgets('the orb stepper matches the sheet', (tester) async {
        await load(tester);
        final want = measureStepper(sheet, 722, 2460 + dy, 862, 2510 + dy, bg);
        final px = await _render(
          tester,
          ZodiannOrbStepper(
            value: 8,
            min: 0,
            max: 20,
            onChanged: (_) {},
            valueLabel: '±8°',
            decrementLabel: 'Decrease',
            incrementLabel: 'Increase',
          ),
          theme,
          bg,
        );
        final got = measureStepper(px, 0, 0, 320, 120, bg);
        expect(got.width, want.width);
        expect(got.height, want.height);
        _expectColour(got.border, want.border, 1, 'border');
        _expectColour(got.fill, want.fill, 1, 'fill');
        _expectBox(got.minus, want.minus, 2, 'minus');
        _expectBox(got.value, want.value, 2, 'value');
        _expectBox(got.plus, want.plus, 2, 'plus');
      });

      for (final on in [true, false]) {
        testWidgets('the ${on ? 'on' : 'off'} switch matches the sheet', (
          tester,
        ) async {
          await load(tester);
          final x0 = on ? 868 : 922;
          final x1 = on ? 922 : 992;
          final want = measureSwitch(
            sheet,
            x0,
            2462 + dy,
            x1,
            2505 + dy,
            bg,
            on: on,
          );
          final px = await _render(
            tester,
            ZodiannSwitch(
              value: on,
              onChanged: (_) {},
              semanticLabel: 'Switch',
            ),
            theme,
            bg,
          );
          final got = measureSwitch(px, 0, 0, 320, 120, bg, on: on);
          expect(got.width, want.width);
          expect(got.height, want.height);
          _expectColour(got.border, want.border, 1, 'border');
          _expectColour(got.fill, want.fill, 1, 'fill');
          _expectColour(got.thumbColor, want.thumbColor, 2, 'thumb');
          _expectBox(got.thumb, want.thumb, 1, 'thumb box');
        });
      }

      for (final chip in _chips) {
        testWidgets('the ${chip.label} chip matches the sheet', (tester) async {
          await load(tester);
          final want = measureChip(
            sheet,
            chip.x0,
            2538 + dy,
            chip.x1,
            2590 + dy,
            bg,
          );
          final px = await _render(
            tester,
            ZodiannBodyChip(
              body: chip.body,
              label: chip.label,
              selected: chip.on,
              onChanged: (_) {},
            ),
            theme,
            bg,
          );
          final got = measureChip(px, 0, 0, 320, 120, bg);
          expect(got.height, want.height);
          expect(
            (got.width - want.width).abs(),
            lessThanOrEqualTo(2),
            reason: 'width ${got.width} vs sheet ${want.width}',
          );
          _expectColour(got.border, want.border, 1, 'border');
          _expectColour(got.fill, want.fill, 1, 'fill');
          _expectBox(got.glyph, want.glyph, 3, 'glyph');
          _expectBox(got.label, want.label, 2, 'label');
          _expectColour(got.glyphColor, want.glyphColor, 20, 'glyph ink');
          _expectColour(got.labelColor, want.labelColor, 12, 'label ink');
        });
      }
    });
  }
}
