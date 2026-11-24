// ZOD-UI-007: ZodiannSwitch behaviour: activation by tap, mouse and keyboard,
// the 40 x 24 drawn track in a 44 x 44 slot, colours in both themes and both
// states, RTL, semantics, the disabled state, the 120 ms linear crossfade,
// the keyboard-only focus ring with the track's own corner, theme switching.
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_ui/src/widgets/zodiann_pressable.dart';

import '../support/button_harness.dart';
import '../support/load_bundled_fonts.dart';

const _trackKey = ValueKey('zodiann-switch-track');
const _thumbKey = ValueKey('zodiann-switch-thumb');

Widget _controlled({bool initial = false, ValueChanged<bool>? spy}) =>
    _Holder(initial: initial, spy: spy);

class _Holder extends StatefulWidget {
  const _Holder({required this.initial, this.spy});
  final bool initial;
  final ValueChanged<bool>? spy;

  @override
  State<_Holder> createState() => _HolderState();
}

class _HolderState extends State<_Holder> {
  late bool value = widget.initial;

  @override
  Widget build(BuildContext context) => ZodiannSwitch(
    value: value,
    semanticLabel: 'Reduced motion',
    onChanged: (v) {
      widget.spy?.call(v);
      setState(() => value = v);
    },
  );
}

Widget _switch({bool value = false, ValueChanged<bool>? onChanged}) =>
    ZodiannSwitch(
      value: value,
      onChanged: onChanged,
      semanticLabel: 'Reduced motion',
    );

/// The decoration as painted now (an `AnimatedContainer`'s own field is its
/// target, not the value mid-animation).
BoxDecoration _decoration(WidgetTester tester, Key key) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byKey(key),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

Rect _rect(WidgetTester tester, Key key) => tester.getRect(find.byKey(key));

ZodiannFocusRingPainter _ring(WidgetTester tester) =>
    tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .firstWhere((w) => w.foregroundPainter is ZodiannFocusRingPainter)
            .foregroundPainter!
        as ZodiannFocusRingPainter;

void main() {
  setUpAll(loadBundledFonts);

  group('activation', () {
    testWidgets('tap, mouse, Enter and Space toggle once each', (tester) async {
      final calls = <bool>[];
      await pumpInApp(tester, _controlled(spy: calls.add));
      await tester.tap(find.byType(ZodiannSwitch));
      await tester.pump();
      expect(calls, [true]);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(ZodiannSwitch)));
      await mouse.down(tester.getCenter(find.byType(ZodiannSwitch)));
      await mouse.up();
      await tester.pump();
      expect(calls, [true, false]);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(calls, [true, false, true]);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(calls, [true, false, true, false]);
    });

    testWidgets('a controlled rebuild shows the new state', (tester) async {
      await pumpInApp(tester, _controlled());
      expect(_rect(tester, _thumbKey).left - _rect(tester, _trackKey).left, 4);
      await tester.tap(find.byType(ZodiannSwitch));
      await tester.pumpAndSettle();
      expect(_rect(tester, _thumbKey).left - _rect(tester, _trackKey).left, 20);
    });

    testWidgets('a tap just outside the drawn track still hits (44 slot)', (
      tester,
    ) async {
      final calls = <bool>[];
      await pumpInApp(tester, _switch(onChanged: calls.add));
      final c = tester.getCenter(find.byKey(_trackKey));
      await tester.tapAt(c + const Offset(0, -16));
      await tester.tapAt(c + const Offset(0, 16));
      expect(calls, [true, true]);
      await tester.tapAt(c + const Offset(0, 23));
      expect(calls, [true, true], reason: 'beyond the 44 slot');
    });
  });

  group('geometry', () {
    testWidgets('40 x 24 track, 16 thumb 4 px in, 44 x 44 slot', (
      tester,
    ) async {
      await pumpInApp(tester, _switch());
      expect(tester.getSize(find.byKey(_trackKey)), const Size(40, 24));
      expect(tester.getSize(find.byType(ZodiannPressable)), const Size(44, 44));
      final track = _rect(tester, _trackKey);
      final off = _rect(tester, _thumbKey);
      expect(off.size, const Size.square(16));
      expect(off.left - track.left, 4);
      expect(off.top - track.top, 4);

      await pumpInApp(tester, _switch(value: true));
      await tester.pumpAndSettle();
      final on = _rect(tester, _thumbKey);
      expect(on.left - _rect(tester, _trackKey).left, 20);
      expect(_rect(tester, _trackKey).right - on.right, 4);
    });

    testWidgets('track radius 12, thumb is a circle, border 1', (tester) async {
      await pumpInApp(tester, _switch());
      final d = _decoration(tester, _trackKey);
      expect(d.borderRadius, BorderRadius.circular(ZodiannRadius.lg));
      expect((d.border! as Border).top.width, 1);
      expect(_decoration(tester, _thumbKey).shape, BoxShape.circle);
    });

    testWidgets('text scale 2 leaves the size unchanged', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ZodiannTheme.graphite,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Material(child: Center(child: _switch())),
        ),
      );
      expect(tester.getSize(find.byKey(_trackKey)), const Size(40, 24));
    });
  });

  group('colours', () {
    for (final entry in {
      'Graphite': (ZodiannTheme.graphite, graphiteTokens),
      'Porcelain': (ZodiannTheme.porcelain, porcelainTokens),
    }.entries) {
      testWidgets('${entry.key}: off and on come from the tokens', (
        tester,
      ) async {
        final s = entry.value.$2.surfaces;
        await pumpInApp(tester, _switch(), theme: entry.value.$1);
        var track = _decoration(tester, _trackKey);
        expect(track.color, s.surface3);
        expect((track.border! as Border).top.color, s.line);
        expect(_decoration(tester, _thumbKey).color, s.text3);

        await pumpInApp(tester, _switch(value: true), theme: entry.value.$1);
        await tester.pumpAndSettle();
        track = _decoration(tester, _trackKey);
        expect(track.color, s.accent);
        expect((track.border! as Border).top.color, s.accent);
        expect(_decoration(tester, _thumbKey).color, s.onAccent);
      });
    }

    testWidgets('a live theme switch repaints with the new colours', (
      tester,
    ) async {
      await pumpInApp(tester, _switch(value: true));
      await tester.pumpAndSettle();
      await pumpInApp(
        tester,
        _switch(value: true),
        theme: ZodiannTheme.porcelain,
      );
      await tester.pumpAndSettle();
      expect(
        _decoration(tester, _trackKey).color,
        porcelainTokens.surfaces.accent,
      );
    });
  });

  group('RTL', () {
    testWidgets('the thumb starts on the right and mirrors the LTR offsets', (
      tester,
    ) async {
      await pumpInApp(tester, _switch(), hebrew: true);
      final track = _rect(tester, _trackKey);
      expect(track.right - _rect(tester, _thumbKey).right, 4);
      await pumpInApp(tester, _switch(value: true), hebrew: true);
      await tester.pumpAndSettle();
      expect(_rect(tester, _thumbKey).left - _rect(tester, _trackKey).left, 4);
    });
  });

  group('semantics', () {
    testWidgets('one labelled button node with the toggle state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      for (final on in [false, true]) {
        await pumpInApp(tester, _switch(value: on, onChanged: (_) {}));
        expect(
          tester.getSemantics(find.byType(ZodiannPressable)),
          isSemantics(
            label: 'Reduced motion',
            isButton: true,
            hasToggledState: true,
            isToggled: on,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
          reason: 'on: $on',
        );
      }
      handle.dispose();
    });

    testWidgets('a disabled switch reports enabled: false', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInApp(tester, _switch());
      expect(
        tester.getSemantics(find.byType(ZodiannPressable)),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });
  });

  group('disabled', () {
    testWidgets('0.42 opacity, inert, unfocusable, forbidden cursor', (
      tester,
    ) async {
      await pumpInApp(tester, _switch());
      expect(
        tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(ZodiannPressable),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        ZodiannStates.disabledOpacity,
      );
      await tester.tap(find.byType(ZodiannSwitch));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        WidgetsBinding.instance.focusManager.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<ZodiannPressable>(),
        isNull,
      );
      final region = tester.widget<MouseRegion>(
        find
            .descendant(
              of: find.byType(ZodiannPressable),
              matching: find.byType(MouseRegion),
            )
            .first,
      );
      expect(region.cursor, SystemMouseCursors.forbidden);
    });
  });

  group('motion', () {
    Widget app(bool value, {bool reduce = false}) => MaterialApp(
      theme: ZodiannTheme.graphite,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
        child: child!,
      ),
      home: Material(
        child: Center(
          child: _switch(value: value, onChanged: (_) {}),
        ),
      ),
    );

    testWidgets('mid-way at 60 ms, final at 120 ms, linear', (tester) async {
      final s = graphiteTokens.surfaces;
      await tester.pumpWidget(app(false));
      await tester.pumpWidget(app(true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final track = _rect(tester, _trackKey);
      expect(_rect(tester, _thumbKey).left - track.left, closeTo(12, 0.01));
      final fill = _decoration(tester, _trackKey).color!;
      final want = Color.lerp(s.surface3, s.accent, 0.5)!;
      expect(fill.r, closeTo(want.r, 0.01));
      expect(fill.g, closeTo(want.g, 0.01));
      expect(fill.b, closeTo(want.b, 0.01));
      await tester.pump(const Duration(milliseconds: 60));
      expect(_rect(tester, _thumbKey).left - track.left, 20);
      expect(_decoration(tester, _trackKey).color, s.accent);
    });

    testWidgets('instant under reduced motion', (tester) async {
      await tester.pumpWidget(app(false, reduce: true));
      await tester.pumpWidget(app(true, reduce: true));
      await tester.pump();
      expect(_rect(tester, _thumbKey).left - _rect(tester, _trackKey).left, 20);
    });
  });

  group('focus ring', () {
    testWidgets('keyboard only, with the track corner (12)', (tester) async {
      await pumpInApp(tester, _switch(onChanged: (_) {}));
      await tester.tap(find.byType(ZodiannSwitch));
      await tester.pump();
      expect(_ring(tester).show, isFalse, reason: 'a tap shows no ring');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final ring = _ring(tester);
      expect(ring.show, isTrue);
      expect(ring.radius, ZodiannRadius.lg);
    });
  });
}
