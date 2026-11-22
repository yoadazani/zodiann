// ZOD-NAV-001: ZodiannPressable, the interaction layer extracted unchanged
// from ZodiannButton (UI-004) and shared with ZodiannIconButton. Driven
// directly here with a plain 40 × 40 box; the UI-004 suites cover it through
// ZodiannButton.
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_ui/src/widgets/zodiann_pressable.dart';

import '../support/button_harness.dart';

const _box = SizedBox.square(
  dimension: 40,
  child: ColoredBox(color: Color(0xFF336699)),
);

Finder _in(Type type) => find.descendant(
  of: find.byType(ZodiannPressable),
  matching: find.byType(type),
);

double _k(WidgetTester tester) => double.parse(
  RegExp(r'\[([\d.]+)')
      .firstMatch(
        tester.widget<ColorFiltered>(_in(ColorFiltered)).colorFilter.toString(),
      )!
      .group(1)!,
);

double _dy(WidgetTester tester) =>
    tester.widget<Transform>(_in(Transform)).transform.getTranslation().y;

ZodiannFocusRingPainter _ring(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(ZodiannPressable),
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is CustomPaint &&
                      w.foregroundPainter is ZodiannFocusRingPainter,
                ),
              ),
            )
            .foregroundPainter!
        as ZodiannFocusRingPainter;

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onPressed,
  bool reduceMotion = false,
}) => pumpInApp(
  tester,
  MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: ZodiannPressable(
      onPressed: onPressed,
      semanticLabel: 'Box',
      child: _box,
    ),
  ),
);

Future<TestGesture> _mouse(WidgetTester tester) async {
  final g = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
  await g.addPointer(location: Offset.zero);
  addTearDown(g.removePointer);
  return g;
}

void main() {
  testWidgets(
    'disabledOpacity overrides the disabled opacity, enabled stays 1',
    (tester) async {
      await pumpInApp(
        tester,
        const ZodiannPressable(
          onPressed: null,
          semanticLabel: 'Item',
          disabledOpacity: 0.4,
          child: _box,
        ),
      );
      expect(tester.widget<Opacity>(_in(Opacity)).opacity, 0.4);
      await pumpInApp(
        tester,
        ZodiannPressable(
          onPressed: () {},
          semanticLabel: 'Item',
          disabledOpacity: 0.4,
          child: _box,
        ),
      );
      expect(tester.widget<Opacity>(_in(Opacity)).opacity, 1.0);
    },
  );
  testWidgets(
    'disabled: 42 % opacity, not focusable, forbidden cursor, enabled: false',
    (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      expect(
        tester.widget<Opacity>(_in(Opacity)).opacity,
        ZodiannStates.disabledOpacity,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_ring(tester).show, isFalse);
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(find.byType(ZodiannPressable)));
      await tester.pump();
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.forbidden,
      );
      expect(
        tester.getSemantics(find.byType(ZodiannPressable)),
        matchesSemantics(
          label: 'Box',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    },
  );

  testWidgets('tap and Enter / Space call onPressed once each', (tester) async {
    var taps = 0;
    await _pump(tester, onPressed: () => taps++);
    await tester.tap(find.byType(ZodiannPressable));
    expect(taps, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(taps, 3);
  });

  testWidgets('pressed moves the child 1 px down and applies 0.94 brightness', (
    tester,
  ) async {
    await _pump(tester, onPressed: () {});
    expect(_dy(tester), 0);
    expect(_k(tester), 1);
    final g = await tester.startGesture(
      tester.getCenter(find.byType(ZodiannPressable)),
    );
    await tester.pump();
    expect(_dy(tester), ZodiannStates.pressedOffset);
    expect(_k(tester), ZodiannStates.pressedBrightness);
    await g.up();
    await tester.pump();
    expect(_dy(tester), 0);
    expect(_k(tester), 1);
  });

  testWidgets(
    'hover eases to 1.12 over 150 ms; instant under disableAnimations',
    (tester) async {
      await _pump(tester, onPressed: () {});
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(find.byType(ZodiannPressable)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));
      expect(_k(tester), allOf(greaterThan(1), lessThan(1.12)));
      await tester.pump(const Duration(milliseconds: 75));
      expect(_k(tester), closeTo(ZodiannStates.hoverBrightness, 1e-9));
      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();

      await _pump(tester, onPressed: () {}, reduceMotion: true);
      await mouse.moveTo(tester.getCenter(find.byType(ZodiannPressable)));
      await tester.pump();
      await tester.pump();
      expect(_k(tester), closeTo(ZodiannStates.hoverBrightness, 1e-9));
    },
  );

  testWidgets('keyboard focus shows the ring; a pointer tap does not', (
    tester,
  ) async {
    await _pump(tester, onPressed: () {});
    await tester.tap(find.byType(ZodiannPressable));
    await tester.pump();
    expect(_ring(tester).show, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_ring(tester).show, isTrue);
  });

  testWidgets('a 40 × 40 child gets a 44 × 44 hit box, centred', (
    tester,
  ) async {
    var taps = 0;
    await _pump(tester, onPressed: () => taps++);
    final target = tester.getRect(find.byType(ZodiannPressable));
    expect(target.size, const Size.square(ZodiannSize.minTouchTarget));
    final child = tester.getRect(find.byWidget(_box));
    expect(child.center, target.center);
    await tester.tapAt(target.topLeft + const Offset(1, 1));
    expect(taps, 1);
  });
}
