// ZOD-UI-005 criterion 1: the four text fields of the design's component sheet
// (design-reference/zodiann/components/components_{dark,light}.png, "Inputs
// and selectors": Anchor, Anchor focused, Cells in error, Cells disabled),
// rendered by ZodiannTextField and measured by the same extractor on both
// sides. The Body select (a chevron selector) is not built by this task.
//
// The sheet is 1x. Everything is relative to the box's top-left border pixel.
// The box height is exact; the width, text boxes and icon boxes are compared
// within the tolerances below (Chrome and Flutter place anti-aliased glyphs
// slightly differently); fills and the halo within 1 per channel, ink within
// 3 per channel (the disabled field's blended ink within 4).
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/field_features.dart';
import '../support/load_bundled_fonts.dart';
import '../support/pixels.dart';

typedef _Spec = ({
  String name,
  String label,
  String value,
  ZodiannIconData? icon,
  String? error,
  bool focused,
  bool disabled,
  // The box's top border row on the sheet, dark and light.
  int darkTop,
  int lightTop,
});

const _message =
    'Enter a number from 9 to 3,721. The largest square is 61 × 61.';

final List<_Spec> _specs = [
  (
    name: 'default',
    label: 'Anchor',
    value: '15/04/2026',
    icon: ZodiannIcons.calendar,
    error: null,
    focused: false,
    disabled: false,
    darkTop: 2215,
    lightTop: 2197,
  ),
  (
    name: 'focused',
    label: 'Anchor, focused',
    value: '01/11/2026 00:00',
    icon: ZodiannIcons.clock,
    error: null,
    focused: true,
    disabled: false,
    darkTop: 2298,
    lightTop: 2281,
  ),
  (
    name: 'error',
    label: 'Cells',
    value: '4,000',
    icon: null,
    error: _message,
    focused: false,
    disabled: false,
    darkTop: 2381,
    lightTop: 2364,
  ),
  (
    name: 'disabled',
    label: 'Cells, disabled until Custom is chosen',
    value: '289',
    icon: null,
    error: null,
    focused: false,
    disabled: true,
    darkTop: 2571,
    lightTop: 2554,
  ),
];

final _themes = {
  'dark': (ZodiannTheme.graphite, graphiteTokens.surfaces),
  'light': (ZodiannTheme.porcelain, porcelainTokens.surfaces),
};

const _boundary = Key('field-sheet-boundary');

/// The sheet's field column: every field is this wide; the disabled Cells
/// input is narrowed to 120 px inside it, its label keeps the column.
const double _fieldWidth = 645;

Future<Rgba> _render(
  WidgetTester tester,
  _Spec spec,
  ThemeData theme,
  double? inputWidth,
) async {
  tester.view.physicalSize = const Size(800, 220);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final s = theme.extension<ZodiannSurfaces>()!;
  final node = FocusNode();
  addTearDown(node.dispose);
  final c = TextEditingController(text: spec.value);
  addTearDown(c.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: RepaintBoundary(
        key: _boundary,
        child: ColoredBox(
          color: s.surface,
          child: Padding(
            padding: const EdgeInsets.only(left: 40, top: 40),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: _fieldWidth,
                child: ZodiannTextField(
                  label: spec.label,
                  controller: c,
                  focusNode: node,
                  leadingIcon: spec.icon,
                  errorText: spec.error,
                  enabled: !spec.disabled,
                  ltr: true,
                  inputWidth: inputWidth,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  if (spec.focused) {
    node.requestFocus();
  }
  await tester.pump(const Duration(milliseconds: 50));
  final px = await Pixels.capture(
    tester,
    tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary)),
  );
  return Rgba(px.width, px.height, px.raw);
}

void _near(int actual, int expected, int tolerance, String reason) {
  for (final shift in [16, 8, 0]) {
    final a = (actual >> shift) & 0xFF;
    final e = (expected >> shift) & 0xFF;
    expect(
      (a - e).abs(),
      lessThanOrEqualTo(tolerance),
      reason: '$reason: ${hex(actual)} vs ${hex(expected)} (channel at $shift)',
    );
  }
}

void _box(
  List<int>? actual,
  List<int>? expected,
  List<int> tolerance,
  String reason,
) {
  expect(actual == null, expected == null, reason: '$reason: present');
  if (actual == null) return;
  for (var i = 0; i < 4; i++) {
    expect(
      (actual[i] - expected![i]).abs(),
      lessThanOrEqualTo(tolerance[i]),
      reason: '$reason: edge $i, got $actual, sheet $expected',
    );
  }
}

void main() {
  setUpAll(loadBundledFonts);

  _themes.forEach((themeName, entry) {
    final (theme, s) = entry;
    final surface = s.surface.toARGB32();
    final fill = s.bgRaised.toARGB32();
    final disabledFill = Color.lerp(
      s.surface,
      s.bgRaised,
      ZodiannStates.fieldDisabledOpacity,
    )!.toARGB32();
    final disabledText = Color.lerp(
      s.surface,
      s.text,
      ZodiannStates.fieldDisabledOpacity,
    )!.toARGB32();

    for (final spec in _specs) {
      testWidgets('$themeName "${spec.name}" matches the component sheet', (
        tester,
      ) async {
        final sheet = await tester.runAsync(
          () => decodeDesignPng('components/components_$themeName.png'),
        );
        final hasHalo = spec.focused || spec.error != null;
        final boxFill = spec.disabled ? disabledFill : fill;
        FieldFeatures measure(
          Rgba px,
          int top,
          int scanFrom,
          int scanTo, {
          int? valueRight,
        }) => measureField(
          px,
          top: top,
          scanFrom: scanFrom,
          scanTo: scanTo,
          haloWidth: hasHalo ? 3 : 0,
          backdrop: surface,
          hasIcon: spec.icon != null,
          hasMessage: spec.error != null,
          boxFill: boxFill,
          labelColour: s.text2.toARGB32(),
          valueColour: spec.disabled ? disabledText : s.text.toARGB32(),
          iconColour: s.text3.toARGB32(),
          messageColour: s.danger.toARGB32(),
          valueRight: valueRight,
        );
        var sheetTop = themeName == 'dark' ? spec.darkTop : spec.lightTop;
        if (spec.disabled) {
          // The disabled field's row is an estimate: take the first row below
          // the label that is not the panel, on a column inside the box.
          sheetTop -= 4;
          while (sheet!.argb(65 + 110, sheetTop) == surface) {
            sheetTop++;
          }
        }
        final want = measure(sheet!, sheetTop, 42, 715);
        final render = await _render(
          tester,
          spec,
          theme,
          spec.disabled ? want.width.toDouble() : null,
        );
        // The render's box top, from the layout (the label above is
        // fractional; the border is painted on the nearest row).
        final top = tester
            .getTopLeft(find.byKey(ZodiannTextField.inputBoxKey))
            .dy
            .round();
        final got = measure(render, top, 5, 790);
        // The focused field's caret (a tall bar after the last glyph) would
        // stretch the value's box, so its text is measured short of the last
        // glyph on both sides.
        final limit = spec.focused ? want.valueBox![2] - 6 : null;
        final gotValue = spec.focused
            ? measure(render, top, 5, 790, valueRight: limit!)
            : got;
        final wantValue = spec.focused
            ? measure(sheet, sheetTop, 42, 715, valueRight: limit!)
            : want;

        // Exact: the height and the left edge.
        expect(got.height, want.height, reason: 'box height');
        expect(got.height, 40);
        expect(got.width, want.width, reason: 'width follows the parent');

        // Colours.
        _near(got.border, want.border, 1, 'border');
        _near(got.fill, want.fill, 1, 'fill');
        _near(got.haloSide, want.haloSide, 1, 'halo, side');
        _near(got.haloTop, want.haloTop, 1, 'halo, top');
        expect(want.outsideClear, isTrue, reason: 'sheet: halo is 3 px');
        expect(got.outsideClear, isTrue, reason: 'halo is exactly 3 px');
        // Each text has a pixel within 3 of its token colour, on both sides.
        final inks = <(String, int, int, int)>[
          ('label', got.labelInk, want.labelInk, s.text2.toARGB32()),
          (
            'value',
            got.valueInk,
            want.valueInk,
            spec.disabled ? disabledText : s.text.toARGB32(),
          ),
          if (spec.icon != null)
            ('icon', got.iconInk, want.iconInk, s.text3.toARGB32()),
          if (spec.error != null)
            ('message', got.messageInk, want.messageInk, s.danger.toARGB32()),
        ];
        for (final (name, g, w, token) in inks) {
          // Thin icon strokes never reach full coverage on the sheet (about 95
          // percent), so the icon is held to 12 of its token and 8 of the
          // sheet; text reaches its token within 3.
          final loose = name == 'icon';
          _near(w, token, loose ? 12 : 3, 'sheet $name ink');
          _near(g, token, loose ? 12 : 3, 'render $name ink');
          _near(g, w, 8, '$name ink, render against sheet');
        }

        // Geometry of the ink: left, top, right, bottom.
        // The label's bottom edge differs by up to 3 rows: Chrome snaps the
        // baseline to a pixel row, Flutter draws it at a fractional one, so
        // faint anti-aliased rows count at the edges.
        _box(got.labelBox, want.labelBox, [1, 2, 2, 3], 'label');
        _box(gotValue.valueBox, wantValue.valueBox, [2, 2, 2, 2], 'value');
        if (spec.icon != null) {
          _box(got.iconBox, want.iconBox, [1, 1, 1, 1], 'icon');
        }
        if (spec.error != null) {
          _box(got.messageBox, want.messageBox, [1, 2, 3, 3], 'message');
        }
      });
    }
  });
}
