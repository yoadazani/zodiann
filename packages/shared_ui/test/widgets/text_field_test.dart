// ZOD-UI-005: ZodiannTextField behaviour: typing, the four states (border,
// outside halo, error message, disabled), the label tap, the leading icon and
// placeholder, invalid-input handling (NFR-R2), text-entry settings, text
// scale, RTL and the L-7 left-to-right value, semantics, lifecycle, themes.
import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_ui/src/widgets/zodiann_text_field.dart';

import '../support/button_harness.dart';
import '../support/load_bundled_fonts.dart';

const _message =
    'Enter a number from 9 to 3,721. The largest square is 61 × 61.';

Widget _field({
  String label = 'Anchor',
  TextEditingController? controller,
  FocusNode? focusNode,
  ZodiannIconData? leadingIcon,
  String? hintText,
  String? errorText,
  bool enabled = true,
  bool ltr = false,
  TextInputType? keyboardType,
  TextInputAction? textInputAction,
  List<TextInputFormatter>? inputFormatters,
  ValueChanged<String>? onChanged,
  ValueChanged<String>? onSubmitted,
  double width = 320,
}) => SizedBox(
  width: width,
  child: ZodiannTextField(
    label: label,
    controller: controller,
    focusNode: focusNode,
    leadingIcon: leadingIcon,
    hintText: hintText,
    errorText: errorText,
    enabled: enabled,
    ltr: ltr,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    inputFormatters: inputFormatters,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
  ),
);

Finder get _box => find.byKey(ZodiannTextField.inputBoxKey);
Finder get _editable => find.byType(EditableText);
Finder _icon(ZodiannIconData d) =>
    find.byWidgetPredicate((w) => w is ZodiannIcon && w.icon == d);
Finder get _halo => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter is ZodiannFieldHaloPainter,
);

ZodiannSurfaces _s(ThemeData t) => t.extension<ZodiannSurfaces>()!;
Color _border(WidgetTester tester) {
  final d = tester.widget<DecoratedBox>(_box).decoration as BoxDecoration;
  return (d.border! as Border).top.color;
}

Color? _haloColor(WidgetTester tester) {
  final f = _halo;
  if (f.evaluate().isEmpty) return null;
  return (tester.widget<CustomPaint>(f).painter! as ZodiannFieldHaloPainter)
      .color;
}

Iterable<SemanticsNode> _textFieldNodes(WidgetTester tester) {
  final out = <SemanticsNode>[];
  void walk(SemanticsNode n) {
    // A node merged up into its parent is the same logical node.
    if (!n.isMergedIntoParent &&
        n.getSemanticsData().flagsCollection.isTextField) {
      out.add(n);
    }
    n.visitChildren((c) {
      walk(c);
      return true;
    });
  }

  // The root pipeline owner has no semantics owner in Flutter 3.50 under test;
  // the deprecated accessor is the one that does.
  // ignore: deprecated_member_use
  walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
  return out;
}

void main() {
  setUpAll(loadBundledFonts);
  final graphite = ZodiannTheme.graphite;
  final porcelain = ZodiannTheme.porcelain;

  testWidgets('1. typing reports the text and the controller holds it', (
    tester,
  ) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    final seen = <String>[];
    await pumpInApp(tester, _field(controller: c, onChanged: seen.add));
    await tester.enterText(_editable, '15/04/2026');
    expect(seen, ['15/04/2026']);
    expect(c.text, '15/04/2026');
  });

  testWidgets(
    '2. default: line border, no halo, 40 high, 12/500 text-2 label',
    (tester) async {
      await pumpInApp(tester, _field());
      final s = _s(graphite);
      expect(_border(tester), s.line);
      expect(_halo, findsNothing);
      expect(tester.getSize(_box).height, 40);
      final label = tester.widget<Text>(find.text('Anchor'));
      expect(label.style!.fontSize, 12);
      expect(label.style!.fontWeight, FontWeight.w500);
      expect(label.style!.color, s.text2);
      expect(
        tester.getBottomLeft(find.text('Anchor')).dy,
        lessThanOrEqualTo(tester.getTopLeft(_box).dy),
        reason: 'the label is above the field',
      );
      expect(
        tester.getTopLeft(_box).dy -
            tester.getBottomLeft(find.text('Anchor')).dy,
        lessThanOrEqualTo(ZodiannSize.fieldGap + 6),
      );
      expect(
        tester.widget<DecoratedBox>(_box).decoration,
        isA<BoxDecoration>(),
      );
      final d = tester.widget<DecoratedBox>(_box).decoration as BoxDecoration;
      expect(d.color, s.bgRaised);
      expect(d.borderRadius, ZodiannRadius.control);
    },
  );

  testWidgets('3. focus: accent border and a 3 px accent-soft halo outside', (
    tester,
  ) async {
    await pumpInApp(tester, _field());
    final s = _s(graphite);
    final before = tester.getSize(find.byType(ZodiannTextField));
    await tester.tap(_editable);
    await tester.pump();
    expect(_border(tester), s.accent);
    expect(_haloColor(tester), s.accentSoft);
    final p =
        tester.widget<CustomPaint>(_halo).painter! as ZodiannFieldHaloPainter;
    expect(p.width, ZodiannSize.fieldHalo);
    expect(p.radius, ZodiannRadius.control.topLeft.x);
    expect(
      tester.getSize(find.byType(ZodiannTextField)),
      before,
      reason: 'the halo takes no layout',
    );
  });

  testWidgets('4. error: danger border, danger-soft halo, message with icon', (
    tester,
  ) async {
    await pumpInApp(tester, _field(errorText: _message));
    final s = _s(graphite);
    expect(_border(tester), s.danger);
    expect(_haloColor(tester), s.dangerSoft);
    expect(find.text(_message), findsOneWidget);
    expect(_icon(ZodiannIcons.alert), findsOneWidget);
    final t = tester.widget<Text>(find.text(_message));
    expect(t.style!.color, s.danger);
    expect(t.style!.fontSize, 12);
    // Error wins over focus.
    await tester.tap(_editable);
    await tester.pump();
    expect(_border(tester), s.danger);
    expect(_haloColor(tester), s.dangerSoft);
    // The halo and the message take no layout beyond the message row.
    final noError = tester.getSize(_box);
    expect(noError.height, 40);
  });

  testWidgets('4b. an error halo does not change the field size', (
    tester,
  ) async {
    await pumpInApp(tester, _field());
    final plain =
        tester.getTopLeft(_box) -
        tester.getTopLeft(find.byType(ZodiannTextField));
    await pumpInApp(tester, _field(errorText: _message));
    expect(
      tester.getTopLeft(_box) -
          tester.getTopLeft(find.byType(ZodiannTextField)),
      plain,
      reason: 'the message goes below; the halo takes no layout',
    );
    expect(tester.getSize(_box).height, 40);
  });

  testWidgets('5. empty or blank errorText asserts; disabled ignores it', (
    tester,
  ) async {
    expect(
      () => ZodiannTextField(label: 'x', errorText: ''),
      throwsAssertionError,
    );
    expect(
      () => ZodiannTextField(label: 'x', errorText: '  '),
      throwsAssertionError,
    );
    await pumpInApp(tester, _field(errorText: _message, enabled: false));
    final s = _s(graphite);
    expect(_border(tester), s.line);
    expect(_halo, findsNothing);
    expect(find.text(_message), findsNothing);
    expect(_icon(ZodiannIcons.alert), findsNothing);
  });

  testWidgets('6. disabled: 45 % box, full-strength label, inert', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    final seen = <String>[];
    await pumpInApp(
      tester,
      _field(enabled: false, focusNode: node, onChanged: seen.add),
    );
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: _box, matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, ZodiannStates.fieldDisabledOpacity);
    expect(
      find.ancestor(of: find.text('Anchor'), matching: find.byType(Opacity)),
      findsNothing,
    );
    await tester.tap(_editable, warnIfMissed: false);
    await tester.pump();
    expect(node.hasFocus, isFalse);
    expect(_halo, findsNothing);
    final editable = tester.widget<EditableText>(_editable);
    expect(editable.readOnly, isTrue);
    expect(seen, isEmpty);
  });

  testWidgets('7. the label focuses the field; the hit area is 44 or more', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await pumpInApp(tester, _field(focusNode: node));
    await tester.tap(find.text('Anchor'));
    await tester.pump();
    expect(node.hasFocus, isTrue);
    node.unfocus();
    await tester.pump();
    // The 6 px gap between label and input counts as inside the label area.
    final labelBottom = tester.getBottomLeft(find.text('Anchor')).dy;
    final boxTop = tester.getTopLeft(_box).dy;
    expect(boxTop - labelBottom, greaterThan(0));
    await tester.tapAt(
      Offset(tester.getTopLeft(_box).dx + 20, (labelBottom + boxTop) / 2),
    );
    await tester.pump();
    expect(node.hasFocus, isTrue);
    node.unfocus();
    await tester.pump();
    // Outside the column nothing focuses.
    await tester.tapAt(const Offset(2, 2));
    await tester.pump();
    expect(node.hasFocus, isFalse);
    // The tappable region (label plus input) is at least 44 px high.
    final region =
        tester.getBottomLeft(_box).dy -
        tester.getTopLeft(find.text('Anchor')).dy;
    expect(region, greaterThanOrEqualTo(ZodiannSize.minTouchTarget));
  });

  testWidgets('8. placeholder only while empty; leading icon 16 px text-3', (
    tester,
  ) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await pumpInApp(
      tester,
      _field(
        controller: c,
        hintText: 'dd/mm/yyyy',
        leadingIcon: ZodiannIcons.calendar,
      ),
    );
    final s = _s(graphite);
    expect(find.text('dd/mm/yyyy'), findsOneWidget);
    expect(tester.widget<Text>(find.text('dd/mm/yyyy')).style!.color, s.text3);
    final icon = tester.widget<ZodiannIcon>(_icon(ZodiannIcons.calendar));
    expect(icon.size, ZodiannSize.iconSmall);
    expect(icon.color, s.text3);
    await tester.enterText(_editable, '1');
    await tester.pump();
    expect(find.text('dd/mm/yyyy'), findsNothing);
    await pumpInApp(tester, _field());
    expect(find.byType(ZodiannIcon), findsNothing);
  });

  group('9. invalid input never crashes (NFR-R2)', () {
    final fuzz = <String>[
      '',
      'abc',
      'x' * 10000,
      '‏‎15/04‏',
      '😀📅',
      '\u0000',
      'line one\nline two',
      '\uD800',
    ];
    testWidgets('a parser harness turns text in a date field into an error', (
      tester,
    ) async {
      final c = TextEditingController();
      addTearDown(c.dispose);
      String? error;
      late StateSetter set;
      await pumpInApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return _field(
              controller: c,
              errorText: error,
              onChanged: (v) => set(
                () => error =
                    RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(v) || v.isEmpty
                    ? null
                    : 'Enter a date like 15/04/2026.',
              ),
            );
          },
        ),
      );
      await tester.enterText(_editable, 'abc');
      await tester.pump();
      expect(find.text('Enter a date like 15/04/2026.'), findsOneWidget);
      expect(_border(tester), _s(graphite).danger);
      await tester.enterText(_editable, '15/04/2026');
      await tester.pump();
      expect(find.text('Enter a date like 15/04/2026.'), findsNothing);
      expect(_border(tester), isNot(_s(graphite).danger));
    });
    for (final input in fuzz) {
      testWidgets('accepts ${input.length}-char input without an exception', (
        tester,
      ) async {
        await pumpInApp(tester, _field(errorText: 'bad', ltr: true));
        await tester.enterText(_editable, input);
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('10. entry settings reach the EditableText', (tester) async {
    final calls = <String>[];
    final fmt = FilteringTextInputFormatter.digitsOnly;
    await pumpInApp(
      tester,
      _field(
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [fmt],
        onSubmitted: calls.add,
      ),
    );
    final e = tester.widget<EditableText>(_editable);
    final s = _s(graphite);
    expect(e.keyboardType, TextInputType.number);
    expect(e.textInputAction, TextInputAction.done);
    expect(e.inputFormatters, contains(fmt));
    expect(e.autocorrect, isFalse);
    expect(e.enableSuggestions, isFalse);
    expect(e.maxLines, 1);
    expect(e.cursorColor, s.accent);
    expect(e.selectionColor, s.accentLine);
    expect(e.scrollPadding, isNot(EdgeInsets.zero));
    await tester.enterText(_editable, '12ab3');
    expect(tester.widget<EditableText>(_editable).controller.text, '123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(calls, ['123']);
  });

  testWidgets('10b. a long ltr value in an RTL layout scrolls, no overflow', (
    tester,
  ) async {
    await pumpInApp(tester, _field(ltr: true, width: 160), hebrew: true);
    await tester.enterText(_editable, '0123456789' * 20);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('11. text scale 2.0: the field grows, the message wraps', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(
          theme: graphite,
          home: Material(
            child: Center(child: _field(errorText: _message, width: 300)),
          ),
        ),
      ),
    );
    expect(tester.getSize(_box).height, greaterThan(40));
    expect(tester.takeException(), isNull);
    final msg = tester.getSize(find.text(_message));
    expect(msg.height, greaterThan(2 * 12 * 1.45), reason: 'wrapped');
    expect(msg.width, lessThanOrEqualTo(300));
  });

  testWidgets('12. RTL mirrors; ltr keeps the value left-to-right', (
    tester,
  ) async {
    final c = TextEditingController(text: '15/04/2026');
    addTearDown(c.dispose);
    await pumpInApp(
      tester,
      _field(controller: c, leadingIcon: ZodiannIcons.calendar, ltr: true),
      hebrew: true,
    );
    final box = tester.getRect(_box);
    final icon = tester.getRect(_icon(ZodiannIcons.calendar));
    expect(
      icon.right,
      greaterThan(box.center.dx),
      reason: 'the icon sits at the start (right in RTL)',
    );
    final e = tester.widget<EditableText>(_editable);
    expect(e.textDirection, TextDirection.ltr);
    expect(e.textAlign, TextAlign.start);
    expect(
      tester.getRect(_editable).left,
      lessThan(icon.left),
      reason: 'the editable fills the row beside the icon',
    );
    final style = e.style;
    expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(style.color, _s(graphite).text);
    expect(style.fontSize, 14);
    // Without ltr the value follows the app direction.
    await pumpInApp(tester, _field(controller: c), hebrew: true);
    expect(tester.widget<EditableText>(_editable).textDirection, isNull);
    await pumpInApp(tester, _field(controller: c), hebrew: false);
    expect(
      tester.widget<EditableText>(_editable).style.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  testWidgets('13. semantics: one text-field node with label, hint, value', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final c = TextEditingController(text: '4,000');
    addTearDown(c.dispose);
    await pumpInApp(
      tester,
      _field(
        controller: c,
        hintText: 'cells',
        errorText: _message,
        leadingIcon: ZodiannIcons.calendar,
      ),
    );
    final nodes = _textFieldNodes(tester).toList();
    expect(nodes, hasLength(1));
    final data = nodes.single.getSemanticsData();
    expect(data.label, contains('Anchor'));
    expect(data.hint, contains('cells'));
    expect(data.hint, contains(_message));
    expect(data.value, '4,000');
    expect(data.flagsCollection.isEnabled, Tristate.isTrue);
    expect(
      find.bySemanticsLabel('Anchor'),
      findsOneWidget,
      reason: 'the visible label text is excluded, not a second node',
    );
    // The message row is a live region.
    final live = tester.getSemantics(find.text(_message));
    expect(live.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
    await pumpInApp(tester, _field(controller: c, enabled: false));
    final off = _textFieldNodes(tester).single.getSemanticsData();
    expect(off.flagsCollection.isEnabled, Tristate.isFalse);
    expect(off.hint, isNot(contains(_message)));
    handle.dispose();
  });

  group('14. lifecycle', () {
    testWidgets('an owned controller and node live and die with the widget', (
      tester,
    ) async {
      await pumpInApp(tester, _field());
      await tester.enterText(_editable, 'kept');
      final e = tester.widget<EditableText>(_editable);
      final c = e.controller;
      final n = e.focusNode;
      await tester.pumpWidget(const SizedBox());
      expect(
        () => c.addListener(() {}),
        throwsFlutterError,
        reason: 'the owned controller was disposed',
      );
      expect(() => n.addListener(() {}), throwsFlutterError);
    });

    testWidgets('a supplied controller and node are never disposed', (
      tester,
    ) async {
      final c = TextEditingController(text: 'mine');
      final n = FocusNode();
      await pumpInApp(tester, _field(controller: c, focusNode: n));
      await tester.pumpWidget(const SizedBox());
      c.addListener(() {});
      n.addListener(() {});
      c.dispose();
      n.dispose();
    });

    testWidgets('swapping controller, node and enabled keeps working', (
      tester,
    ) async {
      final c1 = TextEditingController(text: 'one');
      final c2 = TextEditingController(text: 'two');
      final n1 = FocusNode();
      final n2 = FocusNode();
      addTearDown(() {
        c1.dispose();
        c2.dispose();
        n1.dispose();
        n2.dispose();
      });
      await pumpInApp(tester, _field(controller: c1, focusNode: n1));
      await tester.tap(_editable);
      await tester.pump();
      expect(n1.hasFocus, isTrue);
      await pumpInApp(tester, _field(controller: c2, focusNode: n2));
      expect(tester.widget<EditableText>(_editable).controller, c2);
      expect(tester.widget<EditableText>(_editable).focusNode, n2);
      await tester.tap(_editable);
      await tester.pump();
      expect(_border(tester), _s(graphite).accent, reason: 'follows n2');
      await pumpInApp(
        tester,
        _field(controller: c2, focusNode: n2, enabled: false),
      );
      await tester.pump();
      expect(n2.hasFocus, isFalse, reason: 'disabling drops focus');
      expect(c2.text, 'two');
      expect(_border(tester), _s(graphite).line);
    });
  });

  testWidgets('15. both themes read their own surfaces', (tester) async {
    for (final theme in [graphite, porcelain]) {
      await pumpInApp(tester, _field(errorText: _message), theme: theme);
      await tester.pumpAndSettle();
      final s = _s(theme);
      expect(_border(tester), s.danger);
      expect(_haloColor(tester), s.dangerSoft);
      final d = tester.widget<DecoratedBox>(_box).decoration as BoxDecoration;
      expect(d.color, s.bgRaised);
      await pumpInApp(tester, _field(), theme: theme);
      await tester.pumpAndSettle();
      expect(_border(tester), s.line);
      expect(tester.widget<Text>(find.text('Anchor')).style!.color, s.text2);
    }
  });
}
