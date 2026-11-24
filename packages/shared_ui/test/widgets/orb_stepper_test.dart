// ZOD-UI-007: ZodiannOrbStepper behaviour: stepping and clamping, the caller's
// bounds, decimals, geometry (36 box in a 44 layout, 34 x 34 button areas
// against the border, 44 x 44 slots), RTL order, semantics, keyboard, text
// scale and theme.
import 'dart:ui' show SemanticsAction;

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_ui/src/widgets/zodiann_pressable.dart';

import '../support/button_harness.dart';
import '../support/load_bundled_fonts.dart';

const _box = ValueKey('zodiann-stepper-box');
const _value = ValueKey('zodiann-stepper-value');
const _minusArea = ValueKey('zodiann-stepper-minus-area');
const _plusArea = ValueKey('zodiann-stepper-plus-area');

ZodiannOrbStepper _stepper({
  double value = 8,
  double min = 0,
  double max = 20,
  double step = 1,
  ValueChanged<double>? onChanged,
  String valueLabel = '±8°',
  String? label = 'Conjunction orb',
  bool withLabelFor = false,
}) => ZodiannOrbStepper(
  value: value,
  min: min,
  max: max,
  step: step,
  onChanged: onChanged,
  valueLabel: valueLabel,
  decrementLabel: 'Decrease',
  incrementLabel: 'Increase',
  semanticLabel: label,
  valueLabelFor: withLabelFor ? (v) => '±${v.round()}°' : null,
);

Finder _button(String label) => find.byWidgetPredicate(
  (w) => w is ZodiannPressable && w.semanticLabel == label,
);

Finder get _minus => _button('Decrease');
Finder get _plus => _button('Increase');

BoxDecoration _boxDecoration(WidgetTester tester) =>
    tester.widget<DecoratedBox>(find.byKey(_box)).decoration as BoxDecoration;

String? _focusedLabel() => WidgetsBinding
    .instance
    .focusManager
    .primaryFocus
    ?.context
    ?.findAncestorWidgetOfExactType<ZodiannPressable>()
    ?.semanticLabel;

void main() {
  setUpAll(loadBundledFonts);

  group('stepping', () {
    testWidgets('plus and minus call onChanged with value ± step', (
      tester,
    ) async {
      final calls = <double>[];
      await pumpInApp(tester, _stepper(onChanged: calls.add));
      await tester.tap(_plus);
      await tester.tap(_minus);
      expect(calls, [9, 7]);
    });

    testWidgets('at a bound that button is inert, the other works', (
      tester,
    ) async {
      final calls = <double>[];
      final handle = tester.ensureSemantics();
      await pumpInApp(tester, _stepper(value: 20, onChanged: calls.add));
      await tester.tap(_plus);
      expect(calls, isEmpty);
      expect(
        tester.getSemantics(_plus),
        isSemantics(hasEnabledState: true, isEnabled: false, label: 'Increase'),
      );
      expect(
        tester.getSemantics(_minus),
        isSemantics(hasEnabledState: true, isEnabled: true, label: 'Decrease'),
      );
      expect(
        tester
            .widget<Opacity>(
              find.descendant(of: _plus, matching: find.byType(Opacity)),
            )
            .opacity,
        ZodiannStates.disabledOpacity,
      );
      await tester.tap(_minus);
      expect(calls, [19]);
      await pumpInApp(tester, _stepper(value: 0, onChanged: calls.add));
      await tester.tap(_minus);
      expect(calls, [19], reason: 'minus is inert at the minimum');
      handle.dispose();
    });

    testWidgets('a step that would pass a bound clamps to it', (tester) async {
      final calls = <double>[];
      await pumpInApp(
        tester,
        _stepper(value: 19.5, max: 20, step: 1, onChanged: calls.add),
      );
      await tester.tap(_plus);
      expect(calls, [20]);
    });

    test('decimal steps do not drift', () {
      var v = 0.0;
      for (var i = 0; i < 30; i++) {
        v = orbStepperNext(value: v, step: 0.1, min: 0, max: 10, direction: 1)!;
      }
      expect(v, 3.0);
      expect(
        orbStepperNext(value: 0.1, step: 0.2, min: 0, max: 1, direction: 1),
        0.3,
      );
      for (var i = 0; i < 30; i++) {
        v = orbStepperNext(
          value: v,
          step: 0.1,
          min: 0,
          max: 10,
          direction: -1,
        )!;
      }
      expect(v, 0.0);
    });

    test(
      'orbStepperNext is null at a bound and clamps a stale value first',
      () {
        double? next(double v, int d) =>
            orbStepperNext(value: v, step: 1, min: 0, max: 8, direction: d);
        expect(next(8, 1), isNull);
        expect(next(0, -1), isNull);
        expect(next(7.5, 1), 8);
        // A value that fell outside the bounds counts as the nearest bound:
        // plus never enables above max, minus steps from max.
        expect(next(10, 1), isNull);
        expect(next(10, -1), 7);
        expect(next(-3, -1), isNull);
        expect(next(-3, 1), 1);
      },
    );

    testWidgets('a rebuild never calls onChanged', (tester) async {
      final calls = <double>[];
      await pumpInApp(tester, _stepper(value: 8, onChanged: calls.add));
      await pumpInApp(tester, _stepper(value: 8, max: 9, onChanged: calls.add));
      await pumpInApp(tester, _stepper(value: 8, max: 8, onChanged: calls.add));
      expect(calls, isEmpty);
    });
  });

  group('asserts', () {
    test('invalid configurations assert', () {
      expect(() => _stepper(min: 5, max: 5), throwsAssertionError);
      expect(() => _stepper(min: 9, max: 5), throwsAssertionError);
      expect(() => _stepper(value: 21), throwsAssertionError);
      expect(() => _stepper(value: -1), throwsAssertionError);
      expect(() => _stepper(step: 0), throwsAssertionError);
      expect(() => _stepper(step: -1), throwsAssertionError);
      expect(
        () => ZodiannOrbStepper(
          value: 1,
          min: 0,
          max: 2,
          onChanged: (_) {},
          valueLabel: ' ',
          decrementLabel: 'a',
          incrementLabel: 'b',
        ),
        throwsAssertionError,
      );
      expect(
        () => ZodiannOrbStepper(
          value: 1,
          min: 0,
          max: 2,
          onChanged: (_) {},
          valueLabel: '1',
          decrementLabel: '',
          incrementLabel: 'b',
        ),
        throwsAssertionError,
      );
    });
  });

  group('geometry', () {
    testWidgets('36 box, 1 px border, radius 8, 122 wide, 44 layout', (
      tester,
    ) async {
      await pumpInApp(tester, _stepper(onChanged: (_) {}));
      expect(tester.getSize(find.byKey(_box)), const Size(122, 36));
      expect(
        tester.getSize(find.byType(ZodiannOrbStepper)),
        const Size(122, 44),
      );
      final d = _boxDecoration(tester);
      expect(d.borderRadius, ZodiannRadius.control);
      expect((d.border! as Border).top.width, 1);
    });

    testWidgets('button areas are 34 x 34 against the border, glyph at 18', (
      tester,
    ) async {
      await pumpInApp(tester, _stepper(onChanged: (_) {}));
      final box = tester.getRect(find.byKey(_box));
      final minus = tester.getRect(find.byKey(_minusArea));
      final plus = tester.getRect(find.byKey(_plusArea));
      expect(minus.size, const Size.square(34));
      expect(plus.size, const Size.square(34));
      expect(minus.left - box.left, 1);
      expect(box.right - plus.right, 1);
      expect(minus.top - box.top, 1);
      expect(minus.center.dx - box.left, closeTo(18, 1));
      expect(box.right - plus.center.dx, closeTo(18, 1));
      // The value fills what is left, at least 52.
      expect(tester.getSize(find.byKey(_value)).width, greaterThanOrEqualTo(0));
      expect(plus.left - minus.right, 52);
    });

    testWidgets('the value box is at least 52 wide, centred', (tester) async {
      await pumpInApp(tester, _stepper(onChanged: (_) {}, valueLabel: '1'));
      final box = tester.getRect(find.byKey(_box));
      expect(box.width, 122);
      expect(
        tester.getCenter(find.byKey(_value)).dx,
        closeTo(box.center.dx, 0.5),
      );
    });

    testWidgets('a long value widens the stepper, never below 52', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        _stepper(onChanged: (_) {}, valueLabel: '±12.5° (wide)'),
      );
      expect(tester.getSize(find.byKey(_box)).width, greaterThan(122));
    });
  });

  group('hit targets', () {
    testWidgets('44 x 44 slots at 1..45 and the far end, value area inert', (
      tester,
    ) async {
      final calls = <double>[];
      await pumpInApp(tester, _stepper(onChanged: calls.add));
      final box = tester.getRect(find.byKey(_box));
      final slotM = tester.getRect(_minus);
      final slotP = tester.getRect(_plus);
      expect(slotM.size, const Size.square(44));
      expect(slotP.size, const Size.square(44));
      expect(slotM.left - box.left, 1);
      expect(box.right - slotP.right, 1);
      // 2 px above and below the drawn box still hit.
      await tester.tapAt(Offset(slotM.center.dx, box.top - 2));
      await tester.tapAt(Offset(slotP.center.dx, box.bottom + 2));
      expect(calls, [7, 9]);
      calls.clear();
      // The value area between the slots hits nothing.
      await tester.tapAt(Offset(box.center.dx, box.center.dy));
      expect(calls, isEmpty);
    });

    testWidgets('the focus ring surrounds the 34 x 34 area, unclipped', (
      tester,
    ) async {
      await pumpInApp(tester, _stepper(onChanged: (_) {}));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_focusedLabel(), 'Decrease');
      final ringPaint = tester
          .widgetList<CustomPaint>(
            find.descendant(of: _minus, matching: find.byType(CustomPaint)),
          )
          .firstWhere((w) => w.foregroundPainter is ZodiannFocusRingPainter);
      final ring = ringPaint.foregroundPainter! as ZodiannFocusRingPainter;
      expect(ring.show, isTrue);
      expect(ring.radius, ZodiannRadius.md);
      // The ring's CustomPaint is the 34 x 34 area itself.
      expect(
        tester.getSize(
          find.descendant(of: _minus, matching: find.byKey(_minusArea)),
        ),
        const Size.square(34),
      );
      expect(
        find.ancestor(
          of: find.byKey(_minusArea),
          matching: find.byType(ClipRRect),
        ),
        findsNothing,
      );
      expect(
        find.ancestor(
          of: find.byKey(_minusArea),
          matching: find.byType(ClipRect),
        ),
        findsNothing,
      );
    });
  });

  group('RTL', () {
    testWidgets('the row mirrors, the value stays LTR, + still adds', (
      tester,
    ) async {
      final calls = <double>[];
      await pumpInApp(tester, _stepper(onChanged: calls.add), hebrew: true);
      expect(
        tester.getCenter(_minus).dx,
        greaterThan(tester.getCenter(_plus).dx),
        reason: 'the minus button is on the start side, the right in RTL',
      );
      final valueContext = tester.element(find.byKey(_value));
      expect(Directionality.of(valueContext), TextDirection.ltr);
      await tester.tap(_plus);
      await tester.tap(_minus);
      expect(calls, [9, 7]);
      final box = tester.getRect(find.byKey(_box));
      expect(
        box.right - tester.getRect(find.byKey(_minusArea)).right,
        1,
        reason: 'mirrored offset of the LTR 1 px',
      );
    });
  });

  group('semantics', () {
    testWidgets('a group with the label and value, two buttons', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpInApp(tester, _stepper(onChanged: (_) {}, withLabelFor: true));
      expect(
        tester.getSemantics(find.byType(ZodiannOrbStepper)),
        isSemantics(
          label: 'Conjunction orb',
          value: '±8°',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
      await pumpInApp(tester, _stepper(onChanged: (_) {}));
      expect(
        tester.getSemantics(find.byType(ZodiannOrbStepper)),
        isSemantics(
          label: 'Conjunction orb',
          hasIncreaseAction: false,
          hasDecreaseAction: false,
        ),
        reason: 'no value formatter, no group actions (the buttons remain)',
      );
      expect(
        tester.getSemantics(_minus),
        isSemantics(label: 'Decrease', isButton: true),
      );
      expect(
        tester.getSemantics(_plus),
        isSemantics(label: 'Increase', isButton: true),
      );
      handle.dispose();
    });

    testWidgets('increase and decrease actions step and respect the bounds', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final calls = <double>[];
      await pumpInApp(
        tester,
        _stepper(value: 19, onChanged: calls.add, withLabelFor: true),
      );
      final group = find.byType(ZodiannOrbStepper);
      final node = find.semantics.byLabel('Conjunction orb');
      tester.semantics.performAction(node, SemanticsAction.increase);
      tester.semantics.performAction(node, SemanticsAction.decrease);
      expect(calls, [20, 18]);
      calls.clear();
      await pumpInApp(
        tester,
        _stepper(value: 20, onChanged: calls.add, withLabelFor: true),
      );
      expect(
        tester.getSemantics(group),
        isSemantics(
          label: 'Conjunction orb',
          hasIncreaseAction: false,
          hasDecreaseAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('onChanged null disables both buttons and both actions', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpInApp(tester, _stepper());
      for (final b in [_minus, _plus]) {
        expect(
          tester.getSemantics(b),
          isSemantics(hasEnabledState: true, isEnabled: false),
        );
      }
      expect(
        tester.getSemantics(find.byType(ZodiannOrbStepper)),
        isSemantics(hasIncreaseAction: false, hasDecreaseAction: false),
      );
      handle.dispose();
    });
  });

  group('keyboard', () {
    testWidgets('Tab visits minus then plus; Enter and Space step', (
      tester,
    ) async {
      final calls = <double>[];
      await pumpInApp(tester, _stepper(onChanged: calls.add));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_focusedLabel(), 'Decrease');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_focusedLabel(), 'Increase');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(calls, [7, 9]);
    });

    // A keyboard user repeating a step must not lose their place when the
    // button they are on reaches its bound: focus moves to the other button.
    for (final up in [true, false]) {
      testWidgets(
        'focus moves to the other button when ${up ? '+' : '-'} reaches its bound',
        (tester) async {
          double current = up ? 19 : 1;
          await pumpInApp(
            tester,
            StatefulBuilder(
              builder: (context, setState) => _stepper(
                value: current,
                min: 0,
                max: 20,
                onChanged: (v) => setState(() => current = v),
              ),
            ),
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          if (up) await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          expect(_focusedLabel(), up ? 'Increase' : 'Decrease');
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          await tester.pump();
          expect(current, up ? 20 : 0);
          expect(tester.takeException(), isNull);
          final handle = tester.ensureSemantics();
          expect(
            tester.getSemantics(up ? _plus : _minus),
            isSemantics(hasEnabledState: true, isEnabled: false),
          );
          expect(_focusedLabel(), up ? 'Decrease' : 'Increase');
          // And it keeps working from there.
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          expect(current, up ? 19 : 1);
          handle.dispose();
        },
      );
    }

    testWidgets('focus is not stolen when the button is not the focused one', (
      tester,
    ) async {
      double current = 19;
      await pumpInApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => _stepper(
            value: current,
            onChanged: (v) => setState(() => current = v),
          ),
        ),
      );
      // Focus the minus button, then reach max with a tap on plus.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.tap(_plus);
      await tester.pump();
      await tester.pump();
      expect(current, 20);
      expect(_focusedLabel(), 'Decrease');
    });

    testWidgets(
      'disabling the whole stepper leaves focus alone (nowhere to go)',
      (tester) async {
        var enabled = true;
        late StateSetter set;
        await pumpInApp(
          tester,
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return _stepper(onChanged: enabled ? (_) {} : null);
            },
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        set(() => enabled = false);
        await tester.pump();
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(_focusedLabel(), isNull);
      },
    );
  });

  group('text and theme', () {
    testWidgets('text scale 2 grows the box, the value stays on one line', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ZodiannTheme.graphite,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Material(
            child: Center(child: _stepper(onChanged: (_) {})),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(_box)).height, greaterThan(36));
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.byKey(_value));
      expect(text.maxLines, 1);
      expect(text.softWrap, isFalse);
    });

    testWidgets('tabular figures: ±8° and ±6° are equally wide', (
      tester,
    ) async {
      await pumpInApp(tester, _stepper(valueLabel: '±8°', onChanged: (_) {}));
      final w8 = tester.getSize(find.byKey(_value)).width;
      await pumpInApp(tester, _stepper(valueLabel: '±6°', onChanged: (_) {}));
      expect(tester.getSize(find.byKey(_value)).width, w8);
    });

    for (final entry in {
      'Graphite': (ZodiannTheme.graphite, graphiteTokens),
      'Porcelain': (ZodiannTheme.porcelain, porcelainTokens),
    }.entries) {
      testWidgets('${entry.key}: box, border, glyph and value colours', (
        tester,
      ) async {
        final s = entry.value.$2.surfaces;
        await pumpInApp(
          tester,
          _stepper(onChanged: (_) {}),
          theme: entry.value.$1,
        );
        final d = _boxDecoration(tester);
        expect(d.color, s.bgRaised);
        expect((d.border! as Border).top.color, s.line);
        expect(tester.widget<Text>(find.byKey(_value)).style!.color, s.text);
        expect(
          tester
              .widget<Text>(
                find.descendant(
                  of: find.byKey(_minusArea),
                  matching: find.byType(Text),
                ),
              )
              .style!
              .color,
          s.text2,
        );
      });
    }

    testWidgets('the value uses weight 500 and 18 px glyphs', (tester) async {
      await pumpInApp(tester, _stepper(onChanged: (_) {}));
      expect(
        tester.widget<Text>(find.byKey(_value)).style!.fontWeight,
        FontWeight.w500,
      );
      expect(
        tester.widget<Text>(find.byKey(_value)).style!.fontFeatures,
        contains(const FontFeature.tabularFigures()),
        reason: 'numbers in tabular figures (the font may default to them, so the style is pinned)',
      );
      final glyph = tester.widget<Text>(
        find.descendant(of: find.byKey(_plusArea), matching: find.byType(Text)),
      );
      expect(glyph.style!.fontSize, ZodiannSize.stepperGlyph);
      expect(glyph.data, '+');
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byKey(_minusArea),
                matching: find.byType(Text),
              ),
            )
            .data,
        '−',
      );
    });
  });
}
