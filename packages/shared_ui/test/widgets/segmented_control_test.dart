// ZOD-UI-006: ZodiannSegmentedControl behaviour: selection by tap, mouse and
// keyboard, the inert planned option, semantics, geometry (40 px track in a
// 44 px layout), expansion, the panel head, RTL, text scale, the 120 ms linear
// crossfade, theme switching and the shared pressable's opacity.
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_ui/src/widgets/zodiann_pressable.dart';

import '../support/button_harness.dart';
import '../support/load_bundled_fonts.dart';

const _numbers = ZodiannSegment(value: 'numbers', label: 'Numbers');
const _dates = ZodiannSegment(value: 'dates', label: 'Dates');
const _dateTime = ZodiannSegment(value: 'datetime', label: 'Date and time');
const _tropical = ZodiannSegment(value: 'tropical', label: 'Tropical');
const _sidereal = ZodiannSegment(
  value: 'sidereal',
  label: 'Sidereal (planned)',
  planned: true,
);
const _three = [_numbers, _dates, _dateTime];
const _withPlanned = [_tropical, _sidereal, _dates];

Widget _control({
  List<ZodiannSegment<String>> segments = _three,
  String value = 'dates',
  ValueChanged<String>? onChanged,
  bool? expand,
  String? label = 'Mode',
}) => ZodiannSegmentedControl<String>(
  segments: segments,
  value: value,
  onChanged: onChanged,
  expand: expand,
  semanticLabel: label,
);

Finder _controlFinder() => find.byType(ZodiannSegmentedControl<String>);

Finder _slot(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(ZodiannPressable),
);

Finder _thumb(String label) =>
    find.descendant(of: _slot(label), matching: find.byType(AnimatedContainer));

Finder _track() => find
    .descendant(of: _controlFinder(), matching: find.byType(DecoratedBox))
    .first;

String? _focusedLabel() => WidgetsBinding
    .instance
    .focusManager
    .primaryFocus
    ?.context
    ?.findAncestorWidgetOfExactType<ZodiannPressable>()
    ?.semanticLabel;

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

void main() {
  setUpAll(loadBundledFonts);

  group('selection', () {
    testWidgets('tap and mouse select an unselected segment, once', (
      tester,
    ) async {
      final calls = <String>[];
      await pumpInApp(tester, _control(onChanged: calls.add));
      await tester.tap(find.text('Numbers'));
      await tester.pump();
      expect(calls, ['numbers']);
      final mouse = await tester.startGesture(
        tester.getCenter(find.text('Date and time')),
        kind: PointerDeviceKind.mouse,
      );
      await mouse.up();
      await tester.pump();
      expect(calls, ['numbers', 'datetime']);
    });

    testWidgets('the selected segment does not fire again', (tester) async {
      final calls = <String>[];
      await pumpInApp(tester, _control(onChanged: calls.add));
      await tester.tap(find.text('Dates'));
      await tester.pump();
      expect(calls, isEmpty);
    });

    testWidgets('a 2 px miss above or below the track still selects (44 px)', (
      tester,
    ) async {
      final calls = <String>[];
      await pumpInApp(tester, _control(onChanged: calls.add));
      final track = tester.getRect(_track());
      final x = tester.getCenter(find.text('Numbers')).dx;
      await tester.tapAt(Offset(x, track.top - 1));
      await tester.tapAt(Offset(x, track.bottom + 1));
      expect(calls, ['numbers', 'numbers']);
    });
  });

  group('the planned option is inert', () {
    testWidgets('tap, mouse, Enter and Space never select it', (tester) async {
      final calls = <String>[];
      await pumpInApp(
        tester,
        _control(
          segments: _withPlanned,
          value: 'tropical',
          onChanged: calls.add,
        ),
      );
      await tester.tap(find.text('Sidereal (planned)'), warnIfMissed: false);
      final mouse = await tester.startGesture(
        tester.getCenter(find.text('Sidereal (planned)')),
        kind: PointerDeviceKind.mouse,
      );
      await mouse.up();
      await tester.pump();
      expect(calls, isEmpty);
      // Focus the neighbour, then try to reach the planned one.
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focusedLabel(), 'Tropical');
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(
        _focusedLabel(),
        'Dates',
        reason: 'the arrow jumps over the planned one',
      );
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(_focusedLabel(), 'Tropical', reason: 'and back over it');
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focusedLabel(), 'Dates', reason: 'Tab skips the planned one');
      expect(calls, isEmpty);
    });

    testWidgets('it is disabled for focus, cursor and semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpInApp(
        tester,
        _control(segments: _withPlanned, value: 'tropical', onChanged: (_) {}),
      );
      final detector = tester.widget<FocusableActionDetector>(
        find.descendant(
          of: _slot('Sidereal (planned)'),
          matching: find.byType(FocusableActionDetector),
        ),
      );
      expect(detector.enabled, isFalse);
      expect(detector.mouseCursor, SystemMouseCursors.forbidden);
      expect(
        tester.getSemantics(_slot('Sidereal (planned)')),
        isSemantics(
          label: 'Sidereal (planned)',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('its single Opacity is 0.4, not 0.42 and not 0.17', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        _control(segments: _withPlanned, value: 'tropical', onChanged: (_) {}),
      );
      final opacities = find.descendant(
        of: _slot('Sidereal (planned)'),
        matching: find.byType(Opacity),
      );
      expect(opacities, findsOneWidget);
      expect(
        tester.widget<Opacity>(opacities).opacity,
        ZodiannStates.plannedOpacity,
      );
    });

    testWidgets('with onChanged null the others are 0.42, planned stays 0.4', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        _control(segments: _withPlanned, value: 'tropical'),
      );
      double opacity(String label) => tester
          .widget<Opacity>(
            find.descendant(of: _slot(label), matching: find.byType(Opacity)),
          )
          .opacity;
      expect(opacity('Tropical'), ZodiannStates.disabledOpacity);
      expect(opacity('Dates'), ZodiannStates.disabledOpacity);
      expect(opacity('Sidereal (planned)'), ZodiannStates.plannedOpacity);
    });
  });

  group('keyboard', () {
    testWidgets('Tab walks the segments, Enter and Space select, arrows move '
        'focus only', (tester) async {
      final calls = <String>[];
      await pumpInApp(tester, _control(onChanged: calls.add));
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focusedLabel(), 'Numbers');
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_focusedLabel(), 'Dates');
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_focusedLabel(), 'Date and time');
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_focusedLabel(), 'Date and time', reason: 'stops at the end');
      expect(calls, isEmpty, reason: 'arrows never select');
      await _key(tester, LogicalKeyboardKey.enter);
      expect(calls, ['datetime']);
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(_focusedLabel(), 'Numbers', reason: 'stops at the start');
      await _key(tester, LogicalKeyboardKey.space);
      expect(calls, ['datetime', 'numbers']);
    });

    testWidgets('in RTL the arrows follow what is on screen', (tester) async {
      await pumpInApp(tester, _control(onChanged: (_) {}), hebrew: true);
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focusedLabel(), 'Numbers', reason: 'logical order');
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(_focusedLabel(), 'Dates', reason: 'left is the next one in RTL');
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_focusedLabel(), 'Numbers');
    });

    testWidgets('left and right are consumed by the control, up and down fall '
        'through to the default', (tester) async {
      final seen = <TraversalDirection>[];
      await pumpInApp(
        tester,
        Actions(
          actions: {
            DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
              onInvoke: (i) {
                seen.add(i.direction);
                return null;
              },
            ),
          },
          child: _control(onChanged: (_) {}),
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(seen, isEmpty);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(seen, [TraversalDirection.down, TraversalDirection.up]);
    });
  });

  testWidgets('Up and Down are not swallowed when the outer handler is '
      'disabled, but Left and Right always are', (tester) async {
    await pumpInApp(
      tester,
      Actions(
        actions: {DirectionalFocusIntent: _DisabledDirectional()},
        child: _control(onChanged: (_) {}),
      ),
    );
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focusedLabel(), 'Numbers');
    final upHandled = await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    final downHandled = await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    final rightHandled = await tester.sendKeyEvent(
      LogicalKeyboardKey.arrowRight,
    );
    expect(upHandled, isFalse, reason: 'no enabled outer handler for Up');
    expect(downHandled, isFalse, reason: 'nor for Down');
    expect(rightHandled, isTrue, reason: 'Right moves focus inside');
    expect(_focusedLabel(), 'Dates');
  });

  testWidgets('at the ends the arrows keep focus inside, even with focusable '
      'neighbours', (tester) async {
    await pumpInApp(
      tester,
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Focus(child: SizedBox(width: 40, height: 44)),
          _control(onChanged: (_) {}),
          const Focus(child: SizedBox(width: 40, height: 44)),
        ],
      ),
    );
    for (var i = 0; i < 4 && _focusedLabel() != 'Numbers'; i++) {
      await _key(tester, LogicalKeyboardKey.tab);
    }
    expect(_focusedLabel(), 'Numbers');
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(
      _focusedLabel(),
      'Numbers',
      reason: 'the left neighbour must not steal it',
    );
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focusedLabel(), 'Date and time', reason: 'nor the right one');
  });

  testWidgets('the keyboard focus ring shows for Tab, not for a tap', (
    tester,
  ) async {
    await pumpInApp(tester, _control(onChanged: (_) {}));
    bool ring(String label) =>
        (tester
                    .widget<CustomPaint>(
                      find.descendant(
                        of: _slot(label),
                        matching: find.byWidgetPredicate(
                          (w) =>
                              w is CustomPaint &&
                              w.foregroundPainter is ZodiannFocusRingPainter,
                        ),
                      ),
                    )
                    .foregroundPainter!
                as ZodiannFocusRingPainter)
            .show;
    await tester.tap(find.text('Numbers'));
    await tester.pump();
    expect(ring('Numbers'), isFalse, reason: 'a tap gives no ring');
    await _key(tester, LogicalKeyboardKey.tab);
    final focused = _focusedLabel()!;
    expect(ring(focused), isTrue, reason: 'keyboard focus gives the ring');
  });

  testWidgets('removing the focused segment, or turning onChanged null, '
      'leaves no stale focus and no error', (tester) async {
    await pumpInApp(tester, _control(onChanged: (_) {}));
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focusedLabel(), 'Dates');
    await pumpInApp(
      tester,
      _control(
        segments: const [_numbers, _dateTime],
        value: 'numbers',
        onChanged: (_) {},
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_focusedLabel(), isNot('Dates'));
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focusedLabel(), anyOf('Numbers', 'Date and time', isNull));
    await pumpInApp(
      tester,
      _control(value: 'numbers', segments: const [_numbers, _dateTime]),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _key(tester, LogicalKeyboardKey.tab);
    expect(
      _focusedLabel(),
      isNull,
      reason: 'a disabled control has no tab stop',
    );
  });

  testWidgets('semantics: a named group of buttons, one selected', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpInApp(tester, _control(onChanged: (_) {}));
    expect(find.bySemanticsLabel('Mode'), findsOneWidget);
    for (final s in _three) {
      final node = tester.getSemantics(_slot(s.label));
      expect(
        node,
        isSemantics(
          label: s.label,
          isButton: true,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
      final selected = s.value == 'dates';
      expect(
        node,
        selected
            ? isSemantics(isSelected: true)
            : isNot(isSemantics(hasSelectedState: true)),
      );
    }
    handle.dispose();
  });

  group('geometry (Graphite, LTR)', () {
    testWidgets('40 px track in a 44 px layout, 32 px thumbs, 4 px inside', (
      tester,
    ) async {
      await pumpInApp(tester, _control(onChanged: (_) {}));
      final control = tester.getRect(_controlFinder());
      final track = tester.getRect(_track());
      expect(control.height, 44);
      expect(track.height, 40);
      expect(track.top - control.top, 2);
      final dates = tester.getRect(_thumb('Dates'));
      final numbers = tester.getRect(_thumb('Numbers'));
      expect(dates.height, 32);
      expect(numbers.left - track.left, 4, reason: '1 border + 3 inset');
      expect(dates.top - track.top, 4);
      expect(dates.left - numbers.right, ZodiannSize.segmentGap);
      expect(track.right - tester.getRect(_thumb('Date and time')).right, 4);
      // Content box: 12 px from the thumb's edge to the label.
      expect(tester.getRect(find.text('Dates')).left - dates.left, 12);
      expect(
        tester.getRect(find.text('Dates')).center.dy,
        closeTo(dates.center.dy, 1),
      );
    });

    testWidgets('radii: track 8, thumb 6', (tester) async {
      await pumpInApp(tester, _control(onChanged: (_) {}));
      final trackDecoration =
          tester.widget<DecoratedBox>(_track()).decoration as BoxDecoration;
      expect(trackDecoration.borderRadius, ZodiannRadius.control);
      final thumb = tester.widget<AnimatedContainer>(_thumb('Dates'));
      expect(
        (thumb.decoration! as BoxDecoration).borderRadius,
        ZodiannRadius.segmentThumb,
      );
    });

    testWidgets('an icon is 16 px with a 6 px gap to the label', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        _control(
          segments: const [
            ZodiannSegment(
              value: 'rotate',
              label: 'Rotate wheel',
              icon: ZodiannIcons.rotate,
            ),
            ZodiannSegment(
              value: 'date',
              label: 'Change date',
              icon: ZodiannIcons.datewheel,
            ),
          ],
          value: 'rotate',
          onChanged: (_) {},
        ),
      );
      final icon = tester.getRect(
        find.descendant(
          of: _slot('Rotate wheel'),
          matching: find.byType(ZodiannIcon),
        ),
      );
      final label = tester.getRect(find.text('Rotate wheel'));
      expect(icon.width, ZodiannSize.iconSmall);
      expect(label.left - icon.right, ZodiannSize.segmentIconGap);
    });

    testWidgets('a press moves the thumb 1 px down (shared pressable)', (
      tester,
    ) async {
      await pumpInApp(tester, _control(onChanged: (_) {}));
      final before = tester.getRect(_thumb('Numbers')).top;
      final g = await tester.startGesture(
        tester.getCenter(find.text('Numbers')),
      );
      await tester.pump();
      expect(tester.getRect(_thumb('Numbers')).top, before + 1);
      await g.up();
    });
  });

  group('expansion', () {
    testWidgets('phone: fills the row with equal segments; desktop: content '
        'wide; expand overrides both', (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpInApp(tester, _control(onChanged: (_) {}));
      expect(tester.getSize(_controlFinder()).width, 390);
      final widths = [
        for (final s in _three) tester.getSize(_thumb(s.label)).width,
      ];
      expect(widths[0], closeTo(widths[1], 0.5));
      expect(widths[1], closeTo(widths[2], 0.5));
      await pumpInApp(tester, _control(expand: false, onChanged: (_) {}));
      expect(tester.getSize(_controlFinder()).width, lessThan(390));

      tester.view.physicalSize = const Size(1440, 900);
      await pumpInApp(tester, _control(onChanged: (_) {}));
      expect(tester.getSize(_controlFinder()).width, lessThan(600));
      await pumpInApp(tester, _control(expand: true, onChanged: (_) {}));
      expect(tester.getSize(_controlFinder()).width, 1440);
    });

    testWidgets(
      'a narrow parent ellipsizes on one line and does not overflow',
      (tester) async {
        await pumpInApp(
          tester,
          SizedBox(width: 120, child: _control(onChanged: (_) {})),
        );
        expect(tester.takeException(), isNull);
        expect(tester.getSize(_controlFinder()).width, lessThanOrEqualTo(120));
        final text = tester.widget<DefaultTextStyle>(
          find
              .ancestor(
                of: find.text('Date and time'),
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        );
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);
      },
    );

    testWidgets('an expanded control in an unbounded width lays out at content '
        'width', (tester) async {
      await pumpInApp(
        tester,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _control(expand: true, onChanged: (_) {}),
        ),
      );
      expect(tester.takeException(), isNull);
      final track = tester.getRect(_track());
      final first = tester.getRect(_thumb('Numbers'));
      final last = tester.getRect(_thumb('Date and time'));
      expect(track.width, closeTo(last.right - first.left + 8, 0.5));
    });

    testWidgets('inside a panel head: stacked on a phone, one row on desktop', (
      tester,
    ) async {
      Widget panel() => ZodiannPanel(
        head: ZodiannPanelHead(
          leading: _control(onChanged: (_) {}),
          end: const Text('hint', key: Key('hint')),
        ),
        child: const SizedBox(height: 10),
      );
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpInApp(tester, panel());
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byKey(const Key('hint'))).top,
        greaterThanOrEqualTo(tester.getRect(_controlFinder()).bottom),
      );
      tester.view.physicalSize = const Size(1440, 900);
      await pumpInApp(tester, panel());
      final hint = tester.getRect(find.byKey(const Key('hint')));
      final control = tester.getRect(_controlFinder());
      expect(hint.center.dy, inInclusiveRange(control.top, control.bottom));
    });
  });

  testWidgets('RTL mirrors the order and every offset', (tester) async {
    await pumpInApp(tester, _control(onChanged: (_) {}));
    final control = tester.getRect(_controlFinder());
    final ltr = {
      for (final s in _three) s.label: tester.getRect(_thumb(s.label)),
    };
    await pumpInApp(tester, _control(onChanged: (_) {}), hebrew: true);
    final rtlControl = tester.getRect(_controlFinder());
    expect(rtlControl.width, control.width);
    for (final s in _three) {
      final r = tester.getRect(_thumb(s.label));
      final mirrored =
          control.width - ((ltr[s.label]!.left - control.left) + r.width);
      expect(r.left - rtlControl.left, closeTo(mirrored, 0.5), reason: s.label);
    }
    expect(
      tester.getRect(_thumb('Numbers')).left,
      greaterThan(tester.getRect(_thumb('Dates')).left),
    );
  });

  for (final scale in [2.0, 3.0]) {
    testWidgets('text scale $scale grows the thumb and the track, the thumb '
        'stays centred 4 px inside, no overflow', (tester) async {
      await pumpInApp(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: _control(onChanged: (_) {}),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final thumb = tester.getRect(_thumb('Dates'));
      final track = tester.getRect(_track());
      expect(thumb.height, greaterThan(32));
      expect(track.height, greaterThan(40));
      expect(thumb.top - track.top, 4, reason: 'top inset');
      expect(track.bottom - thumb.bottom, 4, reason: 'bottom inset');
      // The control's box holds the whole track, centred.
      final control = tester.getRect(_controlFinder());
      expect(track.top, greaterThanOrEqualTo(control.top));
      expect(track.bottom, lessThanOrEqualTo(control.bottom));
      expect(
        track.top - control.top,
        closeTo(control.bottom - track.bottom, 0.01),
      );
    });
  }

  group('crossfade', () {
    // The animated, in-flight decoration (the AnimatedContainer's own widget
    // only holds the target).
    Color fill(WidgetTester tester, String label) =>
        (tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: _thumb(label),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration)
            .color!;

    Widget app(String value, {bool reduce = false}) => MaterialApp(
      theme: ZodiannTheme.graphite,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
        child: child!,
      ),
      home: Material(
        child: Center(
          child: _control(value: value, onChanged: (_) {}),
        ),
      ),
    );

    testWidgets('linear over 120 ms from alpha 0 of the same colour', (
      tester,
    ) async {
      final s = graphiteTokens.surfaces;
      await tester.pumpWidget(app('dates'));
      await tester.pumpWidget(app('numbers'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final mid = fill(tester, 'Numbers');
      final want = Color.lerp(s.surface3.withAlpha(0), s.surface3, 0.5)!;
      expect(mid.a, closeTo(want.a, 0.01));
      expect(mid.r, closeTo(want.r, 0.01));
      expect(mid.g, closeTo(want.g, 0.01));
      expect(mid.b, closeTo(want.b, 0.01));
      await tester.pump(const Duration(milliseconds: 60));
      expect(fill(tester, 'Numbers'), s.surface3);
    });

    testWidgets('instant under reduced motion', (tester) async {
      final s = graphiteTokens.surfaces;
      await tester.pumpWidget(app('dates', reduce: true));
      await tester.pumpWidget(app('numbers', reduce: true));
      await tester.pump();
      expect(fill(tester, 'Numbers'), s.surface3);
    });
  });

  testWidgets('switching Graphite to Porcelain re-colours the control', (
    tester,
  ) async {
    await pumpInApp(tester, _control(onChanged: (_) {}));
    Color trackFill() =>
        (tester.widget<DecoratedBox>(_track()).decoration as BoxDecoration)
            .color!;
    expect(trackFill(), graphiteTokens.surfaces.bgRaised);
    await pumpInApp(
      tester,
      _control(onChanged: (_) {}),
      theme: ZodiannTheme.porcelain,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(trackFill(), porcelainTokens.surfaces.bgRaised);
  });

  group('dynamic changes and asserts', () {
    testWidgets('segments changing keeps focus and leaks no node', (
      tester,
    ) async {
      await pumpInApp(tester, _control(onChanged: (_) {}));
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_focusedLabel(), 'Dates');
      await pumpInApp(
        tester,
        _control(segments: const [_dates, _dateTime], onChanged: (_) {}),
      );
      expect(_focusedLabel(), 'Dates');
      await pumpInApp(tester, const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    test('invalid configurations assert', () {
      expect(
        () => _control(segments: const [], onChanged: (_) {}),
        throwsAssertionError,
      );
      expect(
        () => _control(segments: const [_dates, _dates], onChanged: (_) {}),
        throwsAssertionError,
      );
      expect(
        () => _control(value: 'missing', onChanged: (_) {}),
        throwsAssertionError,
      );
      expect(
        () => _control(
          segments: _withPlanned,
          value: 'sidereal',
          onChanged: (_) {},
        ),
        throwsAssertionError,
      );
    });
  });
}

/// An outer directional-focus handler that reports itself disabled.
class _DisabledDirectional extends Action<DirectionalFocusIntent> {
  @override
  bool isEnabled(DirectionalFocusIntent intent) => false;

  @override
  Object? invoke(DirectionalFocusIntent intent) => null;
}
