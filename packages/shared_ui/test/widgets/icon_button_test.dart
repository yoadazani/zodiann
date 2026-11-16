// ZOD-NAV-001: ZodiannIconButton, 46 × 46 (MASTER §4, NAV-1), plain and
// boxed (kit.css `.icon-btn`, `.icon-btn.boxed`), with UI-004's states via
// ZodiannPressable.
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_ui/src/icons/zodiann_icon.dart' show ZodiannIconPainter;
import 'package:shared_ui/src/widgets/zodiann_pressable.dart';

import '../support/button_harness.dart';

Finder _in(Type type) => find.descendant(
  of: find.byType(ZodiannIconButton),
  matching: find.byType(type),
);

Finder _drawn() => find
    .descendant(
      of: find.byType(ZodiannIconButton),
      matching: find.byType(DecoratedBox),
    )
    .first;

BoxDecoration _decoration(WidgetTester tester) =>
    tester.widget<DecoratedBox>(_drawn()).decoration as BoxDecoration;

ZodiannIconPainter _painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(ZodiannIcon),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!
        as ZodiannIconPainter;

ZodiannIconButton _button({
  ZodiannIconButtonVariant variant = ZodiannIconButtonVariant.plain,
  VoidCallback? onPressed,
  Widget icon = const ZodiannIcon(ZodiannIcons.menu),
}) => ZodiannIconButton(
  icon: icon,
  semanticLabel: 'Open menu',
  variant: variant,
  onPressed: onPressed,
);

const _themes = {'graphite': true, 'porcelain': false};

ThemeData _theme(bool dark) =>
    dark ? ZodiannTheme.graphite : ZodiannTheme.porcelain;

void main() {
  testWidgets('46 × 46 box, hit box 46 × 46 (already ≥ 44)', (tester) async {
    await pumpInApp(tester, _button(onPressed: () {}));
    expect(tester.getSize(_drawn()), const Size.square(ZodiannSize.iconButton));
    expect(
      tester.getSize(find.byType(ZodiannIconButton)),
      const Size.square(ZodiannSize.iconButton),
    );
  });

  for (final MapEntry(key: name, value: dark) in _themes.entries) {
    testWidgets('$name: icon is 20 px, centred, text colour', (tester) async {
      await pumpInApp(tester, _button(onPressed: () {}), theme: _theme(dark));
      final painter = _painter(tester);
      expect(painter.size, ZodiannSize.icon);
      expect(painter.color, _theme(dark).extension<ZodiannSurfaces>()!.text);
      expect(
        tester.getCenter(find.byType(ZodiannIcon)),
        tester.getCenter(_drawn()),
      );
    });

    testWidgets(
      '$name: plain is transparent with no border; boxed is surface with a '
      '1 px line border, radius 8',
      (tester) async {
        final s = _theme(dark).extension<ZodiannSurfaces>()!;
        await pumpInApp(tester, _button(onPressed: () {}), theme: _theme(dark));
        final plain = _decoration(tester);
        expect(plain.color?.a ?? 0, 0);
        expect(plain.border, isNull);
        expect(plain.borderRadius, ZodiannRadius.control);

        await pumpInApp(
          tester,
          _button(variant: ZodiannIconButtonVariant.boxed, onPressed: () {}),
          theme: _theme(dark),
        );
        final boxed = _decoration(tester);
        expect(boxed.color, s.surface);
        expect(boxed.border, Border.all(color: s.line));
        expect(boxed.borderRadius, ZodiannRadius.control);
      },
    );
  }

  testWidgets('labelled for screen readers; disabled when onPressed is null', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpInApp(tester, _button(onPressed: () {}));
    expect(
      tester.getSemantics(find.byType(ZodiannIconButton)),
      matchesSemantics(
        label: 'Open menu',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    await pumpInApp(tester, _button());
    // The focus semantics settle one frame after the enabled → disabled
    // change (ZodiannButton behaves the same).
    await tester.pump();
    expect(
      tester.getSemantics(find.byType(ZodiannIconButton)),
      matchesSemantics(
        label: 'Open menu',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });

  testWidgets("states are UI-004's (via ZodiannPressable)", (tester) async {
    var taps = 0;
    await pumpInApp(tester, _button(onPressed: () => taps++));
    expect(_in(ZodiannPressable), findsOneWidget);
    double k() => double.parse(
      RegExp(r'\[([\d.]+)')
          .firstMatch(
            tester
                .widget<ColorFiltered>(_in(ColorFiltered))
                .colorFilter
                .toString(),
          )!
          .group(1)!,
    );
    double dy() =>
        tester.widget<Transform>(_in(Transform)).transform.getTranslation().y;

    final mouse = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(ZodiannIconButton)));
    await tester.pump();
    await tester.pump(ZodiannStates.hoverDuration);
    expect(k(), closeTo(ZodiannStates.hoverBrightness, 1e-9));

    final press = await tester.startGesture(
      tester.getCenter(find.byType(ZodiannIconButton)),
    );
    await tester.pump();
    expect(k(), ZodiannStates.pressedBrightness);
    expect(dy(), ZodiannStates.pressedOffset);
    await press.up();
    expect(taps, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final ring =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(ZodiannIconButton),
                    matching: find.byWidgetPredicate(
                      (w) =>
                          w is CustomPaint &&
                          w.foregroundPainter is ZodiannFocusRingPainter,
                    ),
                  ),
                )
                .foregroundPainter!
            as ZodiannFocusRingPainter;
    expect(ring.show, isTrue);

    await pumpInApp(tester, _button());
    expect(
      tester.widget<Opacity>(_in(Opacity)).opacity,
      ZodiannStates.disabledOpacity,
    );
  });

  testWidgets('iconBack() inside flips with Directionality', (tester) async {
    await pumpInApp(tester, _button(icon: iconBack(), onPressed: () {}));
    expect(
      tester.widget<ZodiannIcon>(find.byType(ZodiannIcon)).icon,
      ZodiannIcons.chevL,
    );
    await pumpInApp(
      tester,
      _button(icon: iconBack(), onPressed: () {}),
      hebrew: true,
    );
    expect(
      tester.widget<ZodiannIcon>(find.byType(ZodiannIcon)).icon,
      ZodiannIcons.chevR,
    );
  });
}
