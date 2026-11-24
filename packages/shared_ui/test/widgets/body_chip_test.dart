// ZOD-UI-007: ZodiannBodyChip behaviour: toggling, the 34 px pill in a 44 px
// slot, colours in both themes and states, the checked semantics and the
// measured on / off difference (the owner chose sheet-exact chips: no check
// icon), the 120 ms linear crossfade, RTL, narrow and scaled text, disabled.
import 'package:astro_core/astro_core.dart' show Body;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_ui/src/widgets/zodiann_pressable.dart';

import '../support/button_harness.dart';
import '../support/load_bundled_fonts.dart';

const _boxKey = ValueKey('zodiann-chip-box');
const _glyphKey = ValueKey('zodiann-chip-glyph');

Widget _chip({
  Body body = Body.sun,
  String label = 'Sun',
  bool selected = false,
  ValueChanged<bool>? onChanged,
}) => ZodiannBodyChip(
  body: body,
  label: label,
  selected: selected,
  onChanged: onChanged,
);

BoxDecoration _decoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byKey(_boxKey),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

Color _border(WidgetTester tester) =>
    (_decoration(tester).border! as Border).top.color;

Rect _glyph(WidgetTester tester) => tester.getRect(find.byKey(_glyphKey));
Rect _text(WidgetTester tester, String label) =>
    tester.getRect(find.text(label));

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

ZodiannFocusRingPainter _ring(WidgetTester tester) =>
    tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .firstWhere((w) => w.foregroundPainter is ZodiannFocusRingPainter)
            .foregroundPainter!
        as ZodiannFocusRingPainter;

void main() {
  setUpAll(loadBundledFonts);

  group('activation', () {
    testWidgets('tap, mouse, Enter and Space call onChanged(!selected)', (
      tester,
    ) async {
      final calls = <bool>[];
      await pumpInApp(tester, _chip(onChanged: calls.add));
      await tester.tap(find.byType(ZodiannBodyChip));
      expect(calls, [true]);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      final c = tester.getCenter(find.byType(ZodiannBodyChip));
      await mouse.moveTo(c);
      await mouse.down(c);
      await mouse.up();
      expect(calls, [true, true]);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(calls, [true, true, true, true]);
    });

    testWidgets('selected: true reports false on activation', (tester) async {
      final calls = <bool>[];
      await pumpInApp(tester, _chip(selected: true, onChanged: calls.add));
      await tester.tap(find.byType(ZodiannBodyChip));
      expect(calls, [false]);
    });
  });

  group('geometry', () {
    testWidgets('34 high pill, border 1, 44 slot', (tester) async {
      await pumpInApp(tester, _chip(onChanged: (_) {}));
      expect(tester.getSize(find.byKey(_boxKey)).height, 34);
      expect(tester.getSize(find.byType(ZodiannPressable)).height, 44);
      final d = _decoration(tester);
      expect(d.borderRadius, ZodiannRadius.chip);
      expect((d.border! as Border).top.width, 1);
    });

    testWidgets('padding 10 and 12 inside the border, glyph 15, gap 8', (
      tester,
    ) async {
      await pumpInApp(tester, _chip(onChanged: (_) {}));
      final box = tester.getRect(find.byKey(_boxKey));
      final glyph = _glyph(tester);
      final text = _text(tester, 'Sun');
      expect(glyph.left - box.left, 11, reason: '1 border + 10 padding');
      expect(box.right - text.right, 13, reason: '1 border + 12 padding');
      expect(text.left - glyph.right, 8);
      expect(
        tester.widget<Text>(find.byKey(_glyphKey)).style!.fontSize,
        ZodiannSize.bodyChipGlyph,
      );
    });

    testWidgets('the glyph is the body glyph with its selector', (
      tester,
    ) async {
      for (final b in Body.values) {
        await pumpInApp(tester, _chip(body: b, onChanged: (_) {}));
        expect(
          tester.widget<Text>(find.byKey(_glyphKey)).data,
          ZodiannGlyphs.body(b),
        );
      }
    });

    testWidgets('five sheet chips wrap inside a phone width', (tester) async {
      await pumpInApp(
        tester,
        SizedBox(
          width: 390 - 32,
          child: Wrap(
            spacing: 8,
            children: [
              for (final b in [
                Body.sun,
                Body.moon,
                Body.mercury,
                Body.venus,
                Body.node,
              ])
                ZodiannBodyChip(
                  body: b,
                  label: b == Body.node ? 'Mean node' : b.name,
                  selected: b != Body.node,
                  onChanged: (_) {},
                ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('colours', () {
    for (final entry in {
      'Graphite': (ZodiannTheme.graphite, graphiteTokens),
      'Porcelain': (ZodiannTheme.porcelain, porcelainTokens),
    }.entries) {
      testWidgets('${entry.key}: on, off and every body glyph colour', (
        tester,
      ) async {
        final s = entry.value.$2.surfaces;
        final bodies = entry.value.$1.extension<BodyColors>()!;
        await pumpInApp(tester, _chip(), theme: entry.value.$1);
        expect(_decoration(tester).color, s.accentSoft.withAlpha(0));
        expect(_border(tester), s.line);
        expect(tester.widget<Text>(find.text('Sun')).style!.color, s.text);

        await pumpInApp(tester, _chip(selected: true), theme: entry.value.$1);
        await tester.pumpAndSettle();
        expect(_decoration(tester).color, s.accentSoft);
        expect(_border(tester), s.accentLine);

        for (final b in Body.values) {
          await pumpInApp(tester, _chip(body: b), theme: entry.value.$1);
          expect(
            tester.widget<Text>(find.byKey(_glyphKey)).style!.color,
            bodies.of(b),
            reason: '${entry.key} ${b.name}',
          );
        }
      });
    }

    testWidgets('a live theme switch repaints the chip', (tester) async {
      await pumpInApp(tester, _chip(selected: true));
      await tester.pumpAndSettle();
      await pumpInApp(
        tester,
        _chip(selected: true),
        theme: ZodiannTheme.porcelain,
      );
      await tester.pumpAndSettle();
      expect(_border(tester), porcelainTokens.surfaces.accentLine);
    });
  });

  group('accessibility', () {
    testWidgets('checked follows selected, the label is read, the glyph not', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      for (final on in [true, false]) {
        await pumpInApp(tester, _chip(selected: on, onChanged: (_) {}));
        expect(
          tester.getSemantics(find.byType(ZodiannPressable)),
          isSemantics(
            label: 'Sun',
            isButton: true,
            hasCheckedState: true,
            isChecked: on,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
          reason: 'selected: $on',
        );
      }
      handle.dispose();
    });

    // The owner chose sheet-exact chips (no check icon, 2026-11-24): the on
    // state differs from the off state by a border and a tint, which is a
    // change of lightness, not hue, plus `checked`. These are the sheet's own
    // numbers, well under WCAG's 3:1 for non-text contrast (recorded for
    // ZOD-NFR-008), so the test pins that the difference exists, not more.
    for (final entry in {
      'Graphite': graphiteTokens,
      'Porcelain': porcelainTokens,
    }.entries) {
      test('${entry.key}: the on border and fill differ from the off ones', () {
        final s = entry.value.surfaces;
        Color over(Color c) => Color.alphaBlend(c, s.bgRaised);
        expect(
          _contrast(over(s.accentLine), over(s.line)),
          greaterThanOrEqualTo(1.45),
          reason: 'border on vs off (measured 1.56 Graphite, 1.50 Porcelain)',
        );
        expect(
          _contrast(over(s.accentLine), s.bgRaised),
          greaterThanOrEqualTo(1.7),
          reason: 'on border vs the track (measured 2.11, 1.80)',
        );
        expect(
          _contrast(over(s.accentSoft), s.bgRaised),
          greaterThanOrEqualTo(1.1),
          reason: 'fill on vs the track (measured 1.17, 1.13)',
        );
      });
    }

    testWidgets('a keyboard focus ring with the pill corner, tap shows none', (
      tester,
    ) async {
      await pumpInApp(tester, _chip(onChanged: (_) {}));
      await tester.tap(find.byType(ZodiannBodyChip));
      await tester.pump();
      expect(_ring(tester).show, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_ring(tester).show, isTrue);
      expect(_ring(tester).radius, ZodiannRadius.pill);
    });
  });

  group('motion', () {
    Widget app(bool selected, {bool reduce = false}) => MaterialApp(
      theme: ZodiannTheme.graphite,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
        child: child!,
      ),
      home: Material(
        child: Center(
          child: _chip(selected: selected, onChanged: (_) {}),
        ),
      ),
    );

    testWidgets('linear over 120 ms from alpha 0 of the same colours', (
      tester,
    ) async {
      final s = graphiteTokens.surfaces;
      await tester.pumpWidget(app(false));
      await tester.pumpWidget(app(true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final fill = _decoration(tester).color!;
      final wantFill = Color.lerp(
        s.accentSoft.withAlpha(0),
        s.accentSoft,
        0.5,
      )!;
      expect(fill.a, closeTo(wantFill.a, 0.01));
      expect(fill.r, closeTo(wantFill.r, 0.01));
      expect(fill.g, closeTo(wantFill.g, 0.01));
      expect(fill.b, closeTo(wantFill.b, 0.01));
      final border = _border(tester);
      final wantBorder = Color.lerp(s.line, s.accentLine, 0.5)!;
      expect(border.a, closeTo(wantBorder.a, 0.01));
      expect(border.r, closeTo(wantBorder.r, 0.01));
      await tester.pump(const Duration(milliseconds: 60));
      expect(_decoration(tester).color, s.accentSoft);
      expect(_border(tester), s.accentLine);
    });

    testWidgets('instant under reduced motion', (tester) async {
      await tester.pumpWidget(app(false, reduce: true));
      await tester.pumpWidget(app(true, reduce: true));
      await tester.pump();
      expect(_border(tester), graphiteTokens.surfaces.accentLine);
    });
  });

  group('RTL and text', () {
    testWidgets('the glyph sits at the start (right) with mirrored padding', (
      tester,
    ) async {
      await pumpInApp(tester, _chip(onChanged: (_) {}), hebrew: true);
      final box = tester.getRect(find.byKey(_boxKey));
      expect(box.right - _glyph(tester).right, 11);
      expect(_text(tester, 'Sun').left - box.left, 13);
    });

    testWidgets('a long label ellipsizes on one line in a narrow parent', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        SizedBox(
          width: 110,
          child: _chip(label: 'A very long body name', onChanged: (_) {}),
        ),
      );
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.text('A very long body name'));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.getSize(find.byKey(_boxKey)).width, lessThanOrEqualTo(110));
    });

    testWidgets('text scale 2 grows the chip past 34', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ZodiannTheme.graphite,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Material(
            child: Center(child: _chip(onChanged: (_) {})),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(_boxKey)).height, greaterThan(34));
      expect(tester.takeException(), isNull);
    });
  });

  group('disabled', () {
    testWidgets('0.42 opacity, inert; on keeps its colours', (tester) async {
      final calls = <bool>[];
      await pumpInApp(tester, _chip(selected: true));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Opacity>(
              find
                  .descendant(
                    of: find.byType(ZodiannPressable),
                    matching: find.byType(Opacity),
                  )
                  .first,
            )
            .opacity,
        ZodiannStates.disabledOpacity,
      );
      expect(_border(tester), graphiteTokens.surfaces.accentLine);
      await tester.tap(find.byType(ZodiannBodyChip));
      expect(calls, isEmpty);
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byType(ZodiannPressable)),
        isSemantics(
          hasEnabledState: true,
          isEnabled: false,
          hasCheckedState: true,
          isChecked: true,
        ),
      );
      handle.dispose();
    });
  });
}
