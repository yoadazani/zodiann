// ZOD-UI-008: ZodiannRadioList behaviour: activation, the roving tab stop,
// arrow keys that select (LTR and RTL, wrapping), a parent that rejects a
// change, edge cases, semantics, the disabled list, asserts and the keyboard
// focus ring; then the drawn row (geometry, colours, RTL, wrapping, text
// scale, motion, theme switching).
import 'dart:ui' show SemanticsRole;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_ui/src/widgets/zodiann_pressable.dart';

import '../support/button_harness.dart';
import '../support/load_bundled_fonts.dart';

const _options = [
  ZodiannRadioOption(
    value: 'files',
    label: 'Swiss Ephemeris, data files',
    badge: 'Recommended',
  ),
  ZodiannRadioOption(
    value: 'moshier',
    label: 'Swiss Ephemeris, built-in (Moshier)',
  ),
  ZodiannRadioOption(
    value: 'engine',
    label: 'astronomy-engine',
    badge: 'Backup',
  ),
];

Key _dotKey(int i) => ValueKey('zodiann-radio-dot-$i');

/// A list in a column between two probe focus nodes, held in state so a
/// controlled parent (or one that rejects changes) can be simulated.
class _Scene extends StatefulWidget {
  const _Scene({
    required this.before,
    required this.after,
    this.options = _options,
    this.initial,
    this.accept = true,
    this.spy,
    this.enabled = true,
    this.width = 360,
    this.autofocus = false,
  });

  final FocusNode before;
  final FocusNode after;
  final List<ZodiannRadioOption<String>> options;
  final String? initial;
  final bool accept;
  final ValueChanged<String>? spy;
  final bool enabled;
  final double width;
  final bool autofocus;

  @override
  State<_Scene> createState() => _SceneState();
}

class _SceneState extends State<_Scene> {
  late String? value = widget.initial;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Focus(
        focusNode: widget.before,
        child: const SizedBox(width: 10, height: 10),
      ),
      SizedBox(
        width: widget.width,
        child: ZodiannRadioList<String>(
          options: widget.options,
          value: value,
          semanticLabel: 'Ephemeris source',
          autofocus: widget.autofocus,
          onChanged: widget.enabled
              ? (v) {
                  widget.spy?.call(v);
                  if (widget.accept) setState(() => value = v);
                }
              : null,
        ),
      ),
      Focus(
        focusNode: widget.after,
        child: const SizedBox(width: 10, height: 10),
      ),
    ],
  );
}

({FocusNode before, FocusNode after}) _probes() => (
  before: FocusNode(debugLabel: 'before'),
  after: FocusNode(debugLabel: 'after'),
);

String? _focused() => FocusManager.instance.primaryFocus?.debugLabel;

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

Future<void> _shiftTab(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pump();
}

/// Enters the list from the probe before it with Tab.
Future<void> _enter(WidgetTester tester, FocusNode before) async {
  before.requestFocus();
  await tester.pump();
  await _key(tester, LogicalKeyboardKey.tab);
}

/// The dot's decoration as painted now.
BoxDecoration _dot(WidgetTester tester, int i) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byKey(_dotKey(i)),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

double _dotBorder(WidgetTester tester, int i) =>
    ((_dot(tester, i).border! as Border).top).width;

Finder _row(int i) => find.byType(ZodiannPressable).at(i);

ZodiannFocusRingPainter? _ring(WidgetTester tester, int i) {
  final paints = tester.widgetList<CustomPaint>(
    find.descendant(of: _row(i), matching: find.byType(CustomPaint)),
  );
  for (final p in paints) {
    final painter = p.foregroundPainter;
    if (painter is ZodiannFocusRingPainter) return painter;
  }
  return null;
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool hebrew = false,
  ThemeData? theme,
}) => pumpInApp(tester, child, hebrew: hebrew, theme: theme);

void main() {
  setUpAll(loadBundledFonts);

  group('activation', () {
    testWidgets('tap and click select an unselected row once; the selected '
        'row calls nothing', (tester) async {
      final p = _probes();
      final calls = <String>[];
      await _pump(
        tester,
        _Scene(
          before: p.before,
          after: p.after,
          initial: 'files',
          spy: calls.add,
        ),
      );
      await tester.tap(_row(1));
      await tester.pump();
      expect(calls, ['moshier']);
      await tester.pumpAndSettle();
      expect(_dotBorder(tester, 1), 5);

      await tester.tap(_row(1));
      await tester.pump();
      expect(calls, ['moshier'], reason: 'already selected');

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(_row(2)));
      await mouse.down(tester.getCenter(_row(2)));
      await mouse.up();
      await tester.pump();
      expect(calls, ['moshier', 'engine']);
    });

    testWidgets('Enter and Space on a focused unselected row select it', (
      tester,
    ) async {
      final p = _probes();
      final calls = <String>[];
      await _pump(
        tester,
        _Scene(
          before: p.before,
          after: p.after,
          initial: 'files',
          accept: false,
          spy: calls.add,
        ),
      );
      await _enter(tester, p.before);
      expect(_focused(), 'radio-row-0');
      await _key(tester, LogicalKeyboardKey.enter);
      expect(calls, isEmpty, reason: 'the selected row');
      await _key(tester, LogicalKeyboardKey.arrowDown); // rejected, focus moves
      expect(calls, ['moshier']);
      expect(_focused(), 'radio-row-1');
      await _key(tester, LogicalKeyboardKey.enter);
      await _key(tester, LogicalKeyboardKey.space);
      expect(calls, ['moshier', 'moshier', 'moshier']);
    });
  });

  group('the roving tab stop', () {
    testWidgets('Tab enters at the selected row and the next Tab leaves', (
      tester,
    ) async {
      final p = _probes();
      await _pump(
        tester,
        _Scene(before: p.before, after: p.after, initial: 'moshier'),
      );
      await _enter(tester, p.before);
      expect(_focused(), 'radio-row-1');
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused(), 'after');
      await _shiftTab(tester);
      expect(_focused(), 'radio-row-1');
      await _shiftTab(tester);
      expect(_focused(), 'before');
    });

    testWidgets('with no selection Tab enters at the first row', (
      tester,
    ) async {
      final p = _probes();
      await _pump(tester, _Scene(before: p.before, after: p.after));
      await _enter(tester, p.before);
      expect(_focused(), 'radio-row-0');
    });

    testWidgets('autofocus focuses the tab-stop row', (tester) async {
      final p = _probes();
      await _pump(
        tester,
        _Scene(
          before: p.before,
          after: p.after,
          initial: 'engine',
          autofocus: true,
        ),
      );
      await tester.pump();
      expect(_focused(), 'radio-row-2');
    });
  });

  group('arrow keys select', () {
    testWidgets('Down and Right next, Up and Left previous, wrapping (LTR)', (
      tester,
    ) async {
      final p = _probes();
      final calls = <String>[];
      await _pump(
        tester,
        _Scene(
          before: p.before,
          after: p.after,
          initial: 'files',
          spy: calls.add,
        ),
      );
      await _enter(tester, p.before);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(calls, ['moshier']);
      expect(_focused(), 'radio-row-1');
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(calls, ['moshier', 'engine']);
      await _key(tester, LogicalKeyboardKey.arrowRight); // wraps to the first
      expect(calls.last, 'files');
      expect(_focused(), 'radio-row-0');
      await _key(tester, LogicalKeyboardKey.arrowUp); // wraps to the last
      expect(calls.last, 'engine');
      expect(_focused(), 'radio-row-2');
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(calls.last, 'moshier');
      expect(calls.length, 5);
      await tester.pumpAndSettle();
      expect(_dotBorder(tester, 1), 5);
      expect(_dotBorder(tester, 2), 1.5);

      await _key(tester, LogicalKeyboardKey.home);
      await _key(tester, LogicalKeyboardKey.end);
      await _key(tester, LogicalKeyboardKey.keyA);
      expect(calls.length, 5, reason: 'other keys do nothing');
    });

    testWidgets('Left is next and Right previous in Hebrew', (tester) async {
      final p = _probes();
      final calls = <String>[];
      await _pump(
        tester,
        _Scene(
          before: p.before,
          after: p.after,
          initial: 'files',
          spy: calls.add,
        ),
        hebrew: true,
      );
      await _enter(tester, p.before);
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(calls, ['moshier']);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(calls, ['moshier', 'files']);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(calls.last, 'moshier');
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(calls.last, 'files');
    });

    testWidgets('a parent that ignores the change keeps the tab stop on the '
        'selected row', (tester) async {
      final p = _probes();
      final calls = <String>[];
      await _pump(
        tester,
        _Scene(
          before: p.before,
          after: p.after,
          initial: 'files',
          accept: false,
          spy: calls.add,
        ),
      );
      await _enter(tester, p.before);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focused(), 'radio-row-1');
      expect(calls, ['moshier']);
      expect(_dotBorder(tester, 0), 5, reason: 'still selected');
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused(), 'after');
      // A fresh Tab from before lands on the selected row, not on row 1.
      await _enter(tester, p.before);
      expect(_focused(), 'radio-row-0');
      p.after.requestFocus();
      await tester.pump();
      await _shiftTab(tester);
      expect(_focused(), 'radio-row-0');
    });

    testWidgets('after a rejected arrow one Tab leaves the group, either way', (
      tester,
    ) async {
      // Forward: the stop is row 1, an Up is rejected, focus sits on row 0.
      final p = _probes();
      await _pump(
        tester,
        _Scene(
          before: p.before,
          after: p.after,
          initial: 'moshier',
          accept: false,
        ),
      );
      await _enter(tester, p.before);
      expect(_focused(), 'radio-row-1');
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_focused(), 'radio-row-0');
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused(), 'after', reason: 'Tab leaves from the off-stop row');

      // Backward: the stop is row 0, a Down is rejected, focus sits on row 1.
      await _pump(tester, const SizedBox());
      final q = _probes();
      await _pump(
        tester,
        _Scene(
          before: q.before,
          after: q.after,
          initial: 'files',
          accept: false,
        ),
      );
      await _enter(tester, q.before);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focused(), 'radio-row-1');
      await _shiftTab(tester);
      expect(_focused(), 'before', reason: 'Shift+Tab leaves too');
    });

    testWidgets('with a row focused an outer handler does not see the '
        'arrows; Tab and other keys still pass through', (tester) async {
      final p = _probes();
      final seen = <TraversalDirection>[];
      await _pump(
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
          child: _Scene(before: p.before, after: p.after, initial: 'files'),
        ),
      );
      await _enter(tester, p.before);
      for (final key in [
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
      ]) {
        await _key(tester, key);
      }
      expect(seen, isEmpty);
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused(), 'after');
    });

    testWidgets('edge cases: one option, no selection, changing options', (
      tester,
    ) async {
      final p = _probes();
      final calls = <String>[];
      await _pump(
        tester,
        _Scene(
          before: p.before,
          after: p.after,
          options: const [ZodiannRadioOption(value: 'only', label: 'Only')],
          initial: 'only',
          spy: calls.add,
        ),
      );
      await _enter(tester, p.before);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(calls, isEmpty);
      expect(_focused(), 'radio-row-0');

      // No selection: Down selects the first row, Up the last.
      await _pump(tester, const SizedBox());
      final p2 = _probes();
      final calls2 = <String>[];
      await _pump(
        tester,
        _Scene(before: p2.before, after: p2.after, spy: calls2.add),
      );
      await _enter(tester, p2.before);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(calls2, ['files']);

      await _pump(tester, const SizedBox());
      final p3 = _probes();
      final calls3 = <String>[];
      await _pump(
        tester,
        _Scene(before: p3.before, after: p3.after, spy: calls3.add),
      );
      await _enter(tester, p3.before);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(calls3, ['engine']);
    });

    testWidgets('options and value changing at runtime re-derive the stop', (
      tester,
    ) async {
      final p = _probes();
      Widget list(List<ZodiannRadioOption<String>> options, String? value) =>
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Focus(
                focusNode: p.before,
                child: const SizedBox(width: 10, height: 10),
              ),
              SizedBox(
                width: 360,
                child: ZodiannRadioList<String>(
                  options: options,
                  value: value,
                  onChanged: (_) {},
                  semanticLabel: 'x',
                ),
              ),
            ],
          );
      await _pump(tester, list(_options, 'engine'));
      await _enter(tester, p.before);
      expect(_focused(), 'radio-row-2');
      // The focused option disappears, the value moves.
      await _pump(tester, list(_options.sublist(0, 2), 'moshier'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await _enter(tester, p.before);
      expect(_focused(), 'radio-row-1');
      // An option is added in front.
      await _pump(
        tester,
        list([
          const ZodiannRadioOption(value: 'new', label: 'New'),
          ..._options,
        ], 'moshier'),
      );
      await _enter(tester, p.before);
      expect(_focused(), 'radio-row-2');
      expect(tester.takeException(), isNull);
    });

    testWidgets('an option inserted in front keeps focus on the focused row', (
      tester,
    ) async {
      final p = _probes();
      Widget list(List<ZodiannRadioOption<String>> options) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Focus(
            focusNode: p.before,
            child: const SizedBox(width: 10, height: 10),
          ),
          SizedBox(
            width: 360,
            child: ZodiannRadioList<String>(
              options: options,
              value: 'moshier',
              onChanged: (_) {},
              semanticLabel: 'x',
            ),
          ),
        ],
      );
      await _pump(tester, list(_options));
      await _enter(tester, p.before);
      expect(_focused(), 'radio-row-1');
      // An option arrives in front while the keyboard focus is on a row.
      await _pump(
        tester,
        list([
          const ZodiannRadioOption(value: 'new', label: 'New'),
          ..._options,
        ]),
      );
      await tester.pump();
      expect(_focused(), 'radio-row-2', reason: 'still on the moshier row');
      // The dot states follow the options, not the positions.
      await tester.pumpAndSettle();
      expect(_dotBorder(tester, 2), 5);
      expect(_dotBorder(tester, 1), 1.5);
    });

    testWidgets('inside a scroll view an arrow scrolls the row into view', (
      tester,
    ) async {
      final p = _probes();
      final many = [
        for (var i = 0; i < 12; i++)
          ZodiannRadioOption(value: 'v$i', label: 'Option $i'),
      ];
      await _pump(
        tester,
        SizedBox(
          height: 120,
          child: SingleChildScrollView(
            child: _Scene(
              before: p.before,
              after: p.after,
              options: many,
              initial: 'v0',
            ),
          ),
        ),
      );
      await _enter(tester, p.before);
      for (var i = 0; i < 8; i++) {
        await _key(tester, LogicalKeyboardKey.arrowDown);
      }
      expect(_focused(), 'radio-row-8');
      final viewport = tester.getRect(find.byType(SingleChildScrollView));
      final row = tester.getRect(_row(8));
      expect(row.bottom, lessThanOrEqualTo(viewport.bottom + 0.5));
      expect(row.top, greaterThanOrEqualTo(viewport.top - 0.5));
    });
  });

  group('accessibility', () {
    testWidgets('a radio group of checked, exclusive rows with badge hints', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final p = _probes();
      await _pump(
        tester,
        _Scene(before: p.before, after: p.after, initial: 'files'),
      );
      final group = tester.getSemantics(find.byType(ZodiannRadioList<String>));
      expect(group.label, 'Ephemeris source');
      expect(group.getSemanticsData().role, SemanticsRole.radioGroup);
      for (var i = 0; i < 3; i++) {
        final o = _options[i];
        expect(
          tester.getSemantics(_row(i)),
          isSemantics(
            label: o.label,
            hint: o.badge,
            isButton: true,
            hasCheckedState: true,
            isChecked: i == 0,
            isInMutuallyExclusiveGroup: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true,
          ),
          reason: 'row $i',
        );
      }
      // The dot and the visible badge add no nodes of their own.
      expect(find.bySemanticsLabel('Recommended'), findsNothing);
      handle.dispose();
    });
  });

  group('disabled', () {
    testWidgets('onChanged null: inert, unfocusable, 0.42, forbidden', (
      tester,
    ) async {
      final p = _probes();
      final calls = <String>[];
      await _pump(
        tester,
        _Scene(
          before: p.before,
          after: p.after,
          initial: 'files',
          enabled: false,
          spy: calls.add,
        ),
      );
      await tester.tap(_row(1));
      await tester.pump();
      await _enter(tester, p.before);
      expect(_focused(), 'after', reason: 'no row takes focus');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(calls, isEmpty);
      for (var i = 0; i < 3; i++) {
        final o = tester.widget<Opacity>(
          find.descendant(of: _row(i), matching: find.byType(Opacity)).first,
        );
        expect(o.opacity, 0.42, reason: 'row $i');
      }
      expect(_dotBorder(tester, 0), 5, reason: 'the selected row stays on');
      final region = tester.widget<MouseRegion>(
        find.descendant(of: _row(0), matching: find.byType(MouseRegion)).first,
      );
      expect(region.cursor, isNotNull);
    });

    testWidgets('a row that held focus loses it when the list is disabled', (
      tester,
    ) async {
      final p = _probes();
      final holder = ValueNotifier<bool>(true);
      await _pump(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: holder,
          builder: (_, enabled, _) =>
              _DisableProbe(before: p.before, after: p.after, enabled: enabled),
        ),
      );
      await _enter(tester, p.before);
      expect(_focused(), 'radio-row-0');
      holder.value = false;
      await tester.pump();
      await tester.pump();
      expect(_focused(), isNot('radio-row-0'));
    });
  });

  group('asserts', () {
    ZodiannRadioList<String> build({
      List<ZodiannRadioOption<String>> options = _options,
      String? value,
    }) => ZodiannRadioList<String>(
      options: options,
      value: value,
      onChanged: (_) {},
      semanticLabel: 'x',
    );

    testWidgets('empty, duplicate, blank and unknown values assert', (
      tester,
    ) async {
      for (final bad in <Widget Function()>[
        () => build(options: const []),
        () => build(
          options: const [
            ZodiannRadioOption(value: 'a', label: 'A'),
            ZodiannRadioOption(value: 'a', label: 'B'),
          ],
        ),
        () => build(
          options: const [ZodiannRadioOption(value: 'a', label: '  ')],
        ),
        () => build(value: 'nope'),
      ]) {
        await expectLater(() async => _pump(tester, bad()), throwsA(anything));
        tester.takeException();
      }
    });
  });

  group('the drawn row', () {
    Rect rect(WidgetTester tester, Finder f) => tester.getRect(f);

    testWidgets(
      'dot, label, badge and rows sit where settings.html puts them',
      (tester) async {
        final p = _probes();
        await _pump(
          tester,
          _Scene(before: p.before, after: p.after, initial: 'files'),
        );
        await tester.pumpAndSettle();
        final list = rect(tester, find.byType(ZodiannRadioList<String>));
        expect(list.width, 360);
        for (var i = 0; i < 3; i++) {
          final dot = rect(tester, find.byKey(_dotKey(i)));
          expect(dot.size, const Size.square(18), reason: 'dot $i');
          expect(_dot(tester, i).shape, BoxShape.circle);
          final label = rect(tester, find.text(_options[i].label));
          expect(label.left - dot.right, 12, reason: 'gap $i');
          final slot = rect(tester, _row(i));
          expect(slot.height, greaterThanOrEqualTo(44), reason: 'row $i');
          expect(slot.width, 360, reason: 'row $i full width');
          expect(dot.center.dy, closeTo(slot.center.dy, 0.5), reason: 'dot $i');
          if (i > 0) {
            expect(
              slot.top,
              rect(tester, _row(i - 1)).bottom,
              reason: 'no gap',
            );
          }
          final badge = _options[i].badge;
          if (badge != null) {
            expect(rect(tester, find.text(badge)).right, list.right);
          }
        }
        expect(_dotBorder(tester, 0), 5);
        expect(_dotBorder(tester, 1), 1.5);
        // An 8 px hole: 18 minus two 5 px rings.
        expect(18 - 2 * _dotBorder(tester, 0), 8);
      },
    );

    testWidgets('a tap on the seam between rows reaches the row it is in', (
      tester,
    ) async {
      final p = _probes();
      final calls = <String>[];
      await _pump(
        tester,
        _Scene(
          before: p.before,
          after: p.after,
          initial: 'files',
          accept: false,
          spy: calls.add,
        ),
      );
      final seam = rect(tester, _row(1)).bottom;
      await tester.tapAt(Offset(rect(tester, _row(1)).center.dx, seam - 1));
      await tester.tapAt(Offset(rect(tester, _row(1)).center.dx, seam + 1));
      expect(calls, ['moshier', 'engine']);
    });

    for (final entry in {
      'Graphite': (ZodiannTheme.graphite, graphiteTokens),
      'Porcelain': (ZodiannTheme.porcelain, porcelainTokens),
    }.entries) {
      testWidgets('${entry.key}: label text, badge text-3, dot per state', (
        tester,
      ) async {
        final t = entry.value.$2.surfaces;
        final p = _probes();
        await _pump(
          tester,
          _Scene(before: p.before, after: p.after, initial: 'files'),
          theme: entry.value.$1,
        );
        await tester.pumpAndSettle();
        final label = tester.widget<Text>(find.text(_options[0].label));
        expect(label.style!.color, t.text);
        expect(label.style!.fontSize, 14);
        final badge = tester.widget<Text>(find.text('Recommended')).style!;
        expect(badge.color, t.text3);
        expect(badge.fontSize, 12);
        expect(badge.fontWeight, FontWeight.w400);
        expect(((_dot(tester, 0).border! as Border).top).color, t.accent);
        expect(((_dot(tester, 1).border! as Border).top).color, t.line);
      });
    }

    testWidgets('Hebrew: dot at the right edge, badge at the left', (
      tester,
    ) async {
      final p = _probes();
      await _pump(
        tester,
        _Scene(before: p.before, after: p.after, initial: 'files'),
        hebrew: true,
      );
      await tester.pumpAndSettle();
      final list = rect(tester, find.byType(ZodiannRadioList<String>));
      final dot = rect(tester, find.byKey(_dotKey(0)));
      expect(dot.right, list.right);
      final label = rect(tester, find.text(_options[0].label));
      expect(dot.left - label.right, 12);
      expect(rect(tester, find.text('Recommended')).left, list.left);
      expect(rect(tester, find.text('Backup')).left, list.left);
    });

    testWidgets('a long label wraps, the row grows, nothing overflows', (
      tester,
    ) async {
      final p = _probes();
      await _pump(
        tester,
        _Scene(before: p.before, after: p.after, initial: 'files', width: 170),
      );
      expect(tester.takeException(), isNull);
      expect(rect(tester, _row(1)).height, greaterThan(44));
      final badge = rect(tester, find.text('Recommended'));
      final label = rect(tester, find.text(_options[0].label));
      expect(label.right, lessThanOrEqualTo(badge.left));
    });

    testWidgets('text scale 2: rows grow, nothing clips, the dot stays 18', (
      tester,
    ) async {
      final p = _probes();
      await _pump(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: _Scene(before: p.before, after: p.after, initial: 'files'),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(rect(tester, _row(0)).height, greaterThan(44));
      expect(rect(tester, find.byKey(_dotKey(0))).size, const Size.square(18));
    });

    testWidgets('the ring crossfades over 120 ms, linearly', (tester) async {
      final p = _probes();
      await _pump(
        tester,
        _Scene(before: p.before, after: p.after, initial: 'files'),
      );
      await tester.pumpAndSettle();
      final t = graphiteTokens.surfaces;
      await tester.tap(_row(1));
      await tester.pump(); // starts the animation
      await tester.pump(const Duration(milliseconds: 60));
      expect(_dotBorder(tester, 1), closeTo(1.5 + (5 - 1.5) / 2, 0.15));
      expect(_dotBorder(tester, 0), closeTo(5 - (5 - 1.5) / 2, 0.15));
      final mid = (_dot(tester, 1).border! as Border).top.color;
      expect(mid, Color.lerp(t.line, t.accent, 0.5));
      await tester.pump(const Duration(milliseconds: 60));
      expect(_dotBorder(tester, 1), 5);
      expect(_dotBorder(tester, 0), 1.5);
    });

    testWidgets('instant under reduced motion', (tester) async {
      final p = _probes();
      await _pump(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: _Scene(before: p.before, after: p.after, initial: 'files'),
          ),
        ),
      );
      await tester.tap(_row(1));
      await tester.pump();
      expect(_dotBorder(tester, 1), 5);
      expect(_dotBorder(tester, 0), 1.5);
    });

    testWidgets('a live theme switch leaves no stale colours', (tester) async {
      final p = _probes();
      final scene = _Scene(before: p.before, after: p.after, initial: 'files');
      await _pump(tester, scene, theme: ZodiannTheme.graphite);
      await tester.pumpAndSettle();
      await _pump(tester, scene, theme: ZodiannTheme.porcelain);
      await tester.pumpAndSettle();
      final t = porcelainTokens.surfaces;
      expect(
        tester.widget<Text>(find.text(_options[0].label)).style!.color,
        t.text,
      );
      expect((_dot(tester, 0).border! as Border).top.color, t.accent);
      expect((_dot(tester, 1).border! as Border).top.color, t.line);
    });
  });

  group('keyboard focus ring', () {
    testWidgets('shows for keyboard focus only', (tester) async {
      final p = _probes();
      await _pump(
        tester,
        _Scene(before: p.before, after: p.after, initial: 'files'),
      );
      await tester.tap(_row(0));
      await tester.pump();
      expect(_ring(tester, 0)!.show, isFalse, reason: 'pointer');
      await _enter(tester, p.before);
      expect(_ring(tester, 0)!.show, isTrue, reason: 'keyboard');
      expect(_ring(tester, 1)!.show, isFalse);
    });
  });
}

/// A list whose enabled flag is driven from outside, to disable it while a
/// row holds focus.
class _DisableProbe extends StatelessWidget {
  const _DisableProbe({
    required this.before,
    required this.after,
    required this.enabled,
  });

  final FocusNode before;
  final FocusNode after;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Focus(focusNode: before, child: const SizedBox(width: 10, height: 10)),
      SizedBox(
        width: 360,
        child: ZodiannRadioList<String>(
          options: _options,
          value: 'files',
          semanticLabel: 'x',
          onChanged: enabled ? (_) {} : null,
        ),
      ),
      Focus(focusNode: after, child: const SizedBox(width: 10, height: 10)),
    ],
  );
}
