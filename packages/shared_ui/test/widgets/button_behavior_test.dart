// ZOD-UI-004: ZodiannButton states and behaviour — hover (+12 % over
// 150 ms, instant under reduced motion), press (1 px down, −6 %), the
// keyboard-only focus ring, activation by tap / hit margin / Enter / Space /
// screen reader, and disabled (42 %, inert, not focusable).
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_ui/src/widgets/zodiann_button.dart'
    show ZodiannFocusRingPainter;

import '../support/button_harness.dart';
import '../support/load_bundled_fonts.dart';

ColorFilter _matrix(double k) => ColorFilter.matrix(<double>[
  k, 0, 0, 0, 0, //
  0, k, 0, 0, 0, //
  0, 0, k, 0, 0, //
  0, 0, 0, 1, 0, //
]);

final _identity = _matrix(1);
final _hover = _matrix(1.12);
final _pressed = _matrix(0.94);

Finder _in(Finder button, Type type) =>
    find.descendant(of: button, matching: find.byType(type));

ColorFilter _filter(WidgetTester tester, [Finder? button]) => tester
    .widget<ColorFiltered>(
      _in(button ?? find.byType(ZodiannButton), ColorFiltered),
    )
    .colorFilter;

double _translation(WidgetTester tester, [Finder? button]) => tester
    .widget<Transform>(_in(button ?? find.byType(ZodiannButton), Transform))
    .transform
    .getTranslation()
    .y;

double _opacity(WidgetTester tester) =>
    tester.widget<Opacity>(_in(find.byType(ZodiannButton), Opacity)).opacity;

ZodiannFocusRingPainter _ring(WidgetTester tester, Finder button) =>
    tester
            .widget<CustomPaint>(
              find.descendant(
                of: button,
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is CustomPaint &&
                      w.foregroundPainter is ZodiannFocusRingPainter,
                ),
              ),
            )
            .foregroundPainter!
        as ZodiannFocusRingPainter;

/// The diagonal k of a brightness matrix, parsed from its description.
double _k(ColorFilter f) =>
    double.parse(RegExp(r'\[([\d.]+)').firstMatch(f.toString())!.group(1)!);

Future<TestGesture> _mouse(WidgetTester tester) async {
  final g = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
  await g.addPointer(location: Offset.zero);
  addTearDown(g.removePointer);
  return g;
}

Future<void> _shiftTab(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
}

void main() {
  setUpAll(loadBundledFonts);

  testWidgets('tap calls onPressed once', (tester) async {
    var taps = 0;
    await pumpInApp(
      tester,
      ZodiannButton(label: 'Save', onPressed: () => taps++),
    );
    await tester.tap(find.byType(ZodiannButton));
    expect(taps, 1);
  });

  testWidgets('hit margin taps activate', (tester) async {
    for (final (size, margin) in [
      (ZodiannButtonSize.regular, 1.0),
      (ZodiannButtonSize.small, 3.0),
    ]) {
      var taps = 0;
      await pumpInApp(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZodiannButton(label: 'Save', size: size, onPressed: () => taps++),
          ],
        ),
      );
      final target = tester.getRect(find.byType(ZodiannButton));
      final drawn = tester.getRect(drawnBox());
      final inMargin = Offset(target.center.dx, target.top + margin);
      expect(inMargin.dy, lessThan(drawn.top), reason: '$size margin');
      await tester.tapAt(inMargin);
      expect(taps, 1, reason: '$size');
      await tester.tapAt(Offset(target.center.dx, target.top - 1));
      expect(taps, 1, reason: '$size: outside the 44 box');
    }

    var taps = 0;
    await pumpInApp(
      tester,
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 10),
          ZodiannButton(
            label: '1',
            size: ZodiannButtonSize.small,
            onPressed: () => taps++,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
    final target = tester.getRect(find.byType(ZodiannButton));
    expect(target.left + 1, lessThan(tester.getRect(drawnBox()).left));
    await tester.tapAt(Offset(target.left + 1, target.center.dy));
    expect(taps, 1, reason: 'horizontal margin of a narrow button');
  });

  testWidgets('hover lightens over 150 ms', (tester) async {
    await pumpInApp(tester, ZodiannButton(label: 'Save', onPressed: () {}));
    final mouse = await _mouse(tester);
    await mouse.moveTo(tester.getCenter(find.byType(ZodiannButton)));
    await tester.pump();
    expect(_filter(tester), _identity, reason: 'the animation just started');

    await tester.pump(const Duration(milliseconds: 75));
    final mid = _filter(tester);
    expect(mid, isNot(_identity));
    expect(mid, isNot(_hover));
    expect(_k(mid), closeTo(1 + 0.12 * Curves.ease.transform(0.5), 1e-3));

    await tester.pump(const Duration(milliseconds: 75));
    expect(_filter(tester), _hover);

    await mouse.moveTo(const Offset(1, 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(_filter(tester), _identity);
  });

  testWidgets('hover is instant under reduced motion', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpInApp(tester, ZodiannButton(label: 'Save', onPressed: () {}));
    final mouse = await _mouse(tester);
    await mouse.moveTo(tester.getCenter(find.byType(ZodiannButton)));
    await tester.pump();
    expect(_filter(tester), _hover);
  });

  testWidgets('hover shows in touch highlight mode', (tester) async {
    await pumpInApp(tester, ZodiannButton(label: 'Save', onPressed: () {}));
    await tester.tapAt(const Offset(2, 2));
    await tester.pump();
    expect(FocusManager.instance.highlightMode, FocusHighlightMode.touch);
    final mouse = await _mouse(tester);
    await mouse.moveTo(tester.getCenter(find.byType(ZodiannButton)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(_filter(tester), _hover);
  });

  testWidgets('press moves 1 px down and darkens', (tester) async {
    var taps = 0;
    await pumpInApp(
      tester,
      ZodiannButton(label: 'Save', onPressed: () => taps++),
    );
    final g = await tester.startGesture(
      tester.getCenter(find.byType(ZodiannButton)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(_translation(tester), 1);
    expect(_filter(tester), _pressed);
    await g.up();
    await tester.pump();
    expect(_translation(tester), 0);
    expect(_filter(tester), _identity);
    expect(taps, 1);
  });

  for (final (themeName, theme) in [
    ('Graphite', ZodiannTheme.graphite),
    ('Porcelain', ZodiannTheme.porcelain),
  ]) {
    testWidgets('$themeName: keyboard focus shows the focus ring; a tap '
        'does not', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      const a = Key('a');
      await pumpInApp(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZodiannButton(
              key: a,
              label: 'Save',
              focusNode: node,
              onPressed: () {},
            ),
            ZodiannButton(label: 'Next', onPressed: () {}),
          ],
        ),
        theme: theme,
      );
      final button = find.byKey(a);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(node.hasFocus, isTrue);
      expect(_ring(tester, button).show, isTrue);
      expect(
        _ring(tester, button).color,
        theme.extension<ZodiannSurfaces>()!.focus,
      );

      await tester.tap(button);
      await tester.pump();
      expect(node.hasFocus, isTrue, reason: 'a tap keeps focus');
      expect(_ring(tester, button).show, isFalse, reason: 'no ring on touch');

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(node.hasFocus, isFalse, reason: "Tab moved to 'Next'");
      await _shiftTab(tester);
      await tester.pump();
      expect(node.hasFocus, isTrue);
      expect(_ring(tester, button).show, isTrue);
    });

    testWidgets('$themeName: focus ring is painted completely when '
        'unclipped', (tester) async {
      final s = theme.extension<ZodiannSurfaces>()!;
      for (final (size, label) in [
        (ZodiannButtonSize.regular, 'Save'),
        (ZodiannButtonSize.small, 'Save'),
        (ZodiannButtonSize.small, '1'),
      ]) {
        const boundaryKey = Key('boundary');
        await pumpInApp(
          tester,
          RepaintBoundary(
            key: boundaryKey,
            child: ColoredBox(
              color: s.surface,
              child: SizedBox(
                width: 200,
                height: 80,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ZodiannButton(
                      label: label,
                      size: size,
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
          theme: theme,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        final origin = tester.getTopLeft(find.byKey(boundaryKey));
        final box = tester.getRect(drawnBox()).shift(-origin);
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(boundaryKey),
        );
        late ByteData raw;
        late int width;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          width = image.width;
          raw = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
          image.dispose();
        });
        int px(int x, int y) {
          final i = (y * width + x) * 4;
          return (raw.getUint8(i + 3) << 24) |
              (raw.getUint8(i) << 16) |
              (raw.getUint8(i + 1) << 8) |
              raw.getUint8(i + 2);
        }

        final focus = s.focus.toARGB32();
        final ground = s.surface.toARGB32();
        final midY = box.center.dy.floor();
        final midX = box.center.dx.floor();
        final l = box.left.ceil();
        final r = box.right.floor();
        final t = box.top.ceil();
        final b = box.bottom.floor();
        final why = '$size "$label"';
        expect(px(l - 4, midY), focus, reason: '$why left ring');
        expect(px(l - 2, midY), ground, reason: '$why left gap');
        expect(px(r + 3, midY), focus, reason: '$why right ring');
        expect(px(r + 1, midY), ground, reason: '$why right gap');
        expect(px(midX, t - 4), focus, reason: '$why top ring');
        expect(px(midX, t - 2), ground, reason: '$why top gap');
        expect(px(midX, b + 3), focus, reason: '$why bottom ring');
        expect(px(midX, b + 1), ground, reason: '$why bottom gap');
      }
    });
  }

  testWidgets('Enter and Space activate the focused button', (tester) async {
    var taps = 0;
    await pumpInApp(
      tester,
      ZodiannButton(label: 'Save', onPressed: () => taps++),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(taps, 2);
  });

  testWidgets('semantics: a focusable button with one label and a tap '
      'action', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpInApp(
      tester,
      ZodiannButton(label: 'Save', onPressed: () => taps++),
    );
    expect(
      tester.getSemantics(find.byType(ZodiannButton)),
      matchesSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
        label: 'Save',
      ),
    );
    tester.semantics.tap(find.semantics.byLabel('Save'));
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('disabled: 42 % opacity, no feedback, not focusable, no '
      'callback', (tester) async {
    final handle = tester.ensureSemantics();
    final next = FocusNode();
    addTearDown(next.dispose);
    var taps = 0;
    Widget tree(VoidCallback? onPressed) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ZodiannButton(key: const Key('d'), label: 'Save', onPressed: onPressed),
        ZodiannButton(label: 'Next', focusNode: next, onPressed: () {}),
      ],
    );
    final d = find.byKey(const Key('d'));
    await pumpInApp(tester, tree(null));

    expect(
      tester.widget<Opacity>(_in(d, Opacity)).opacity,
      ZodiannStates.disabledOpacity,
    );
    expect(
      tester.getSemantics(d),
      matchesSemantics(isButton: true, hasEnabledState: true, label: 'Save'),
    );

    final mouse = await _mouse(tester);
    await mouse.moveTo(tester.getCenter(d));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(_filter(tester, d), _identity, reason: 'no hover');

    final g = await tester.startGesture(tester.getCenter(d));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_translation(tester, d), 0, reason: 'no press');
    expect(_filter(tester, d), _identity, reason: 'no press');
    await g.up();
    await tester.pump();
    expect(taps, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(next.hasFocus, isTrue, reason: 'Tab skips the disabled button');

    await pumpInApp(tester, tree(() => taps++));
    await tester.pumpAndSettle();
    expect(_filter(tester, d), _hover, reason: 're-enabled under the mouse');
    handle.dispose();
  });

  testWidgets('disabling mid-press clears the pressed state', (tester) async {
    var taps = 0;
    await pumpInApp(
      tester,
      ZodiannButton(label: 'Save', onPressed: () => taps++),
    );
    final g = await tester.startGesture(
      tester.getCenter(find.byType(ZodiannButton)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(_translation(tester), 1);

    await pumpInApp(
      tester,
      const ZodiannButton(label: 'Save', onPressed: null),
    );
    await g.up();
    await tester.pump();
    expect(_translation(tester), 0);
    expect(_filter(tester), _identity);
    expect(_opacity(tester), ZodiannStates.disabledOpacity);
    expect(taps, 0);
  });

  for (final hebrew in [false, true]) {
    testWidgets('long label ellipsizes (${hebrew ? 'Hebrew' : 'English'})', (
      tester,
    ) async {
      final label = hebrew
          ? 'ייצוא כל הריבועים השמורים לקובץ אקסל אחד גדול מאוד'
          : 'Export every saved square to one very large Excel workbook';
      await pumpInApp(
        tester,
        SizedBox(
          width: 120,
          child: ZodiannButton(label: label, onPressed: () {}),
        ),
        hebrew: hebrew,
      );
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(labelText());
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.getSize(drawnBox()).width, lessThanOrEqualTo(120));
    });
  }

  testWidgets('text scale 2.0 grows the button', (tester) async {
    await pumpInApp(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: ZodiannButton(label: 'Save', onPressed: () {}),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(drawnBox()).height,
      greaterThanOrEqualTo(tester.getSize(labelText()).height + 2),
    );
  });
}
