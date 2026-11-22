// ZOD-UI-006 criterion 1: the three segmented rows of the design's component
// sheet (design-reference/zodiann/components/components_{dark,light}.png:
// "Segmented, mode", "Segmented with icons, drag mode", "Segmented with a
// planned option"), rendered by ZodiannSegmentedControl and measured by the
// same extractor on both sides.
//
// The sheet is 1x. Chrome stretches each track to its grid column, so the
// track's right edge is never compared. Segment offsets and widths are
// Chrome's layout of the source (components.html, kit.css at 1440), measured
// once with headless Chrome; the sheet snaps them to whole pixels, so
// positions and widths are compared within 1 px, fills within 1 per channel,
// ring and ink pixels within 3 per channel. The track's height, the thumb's
// height and its distance from the track's top are exact.
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/load_bundled_fonts.dart';
import '../support/pixels.dart';
import '../support/segment_features.dart';

typedef _Row = ({
  String name,
  List<ZodiannSegment<String>> segments,
  String selected,
  List<SegmentSpec> specs,
  // The y of a pixel inside this row's track, per sheet.
  int darkY,
  int lightY,
});

const _rotate = ZodiannSegment(
  value: 'rotate',
  label: 'Rotate wheel',
  icon: ZodiannIcons.rotate,
);
const _changeDate = ZodiannSegment(
  value: 'date',
  label: 'Change date',
  icon: ZodiannIcons.datewheel,
);

final List<_Row> _rows = [
  (
    name: 'mode',
    segments: const [
      ZodiannSegment(value: 'numbers', label: 'Numbers'),
      ZodiannSegment(value: 'dates', label: 'Dates'),
      ZodiannSegment(value: 'datetime', label: 'Date and time'),
    ],
    selected: 'dates',
    specs: const [
      (rel: 4.0, width: 78.61, hasIcon: false),
      (rel: 84.61, width: 58.31, hasIcon: false),
      (rel: 144.92, width: 107.27, hasIcon: false),
    ],
    darkY: 2235,
    lightY: 2217,
  ),
  (
    name: 'icons',
    segments: const [_rotate, _changeDate],
    selected: 'rotate',
    specs: const [
      (rel: 4.0, width: 124.48, hasIcon: true),
      (rel: 130.48, width: 120.38, hasIcon: true),
    ],
    darkY: 2319,
    lightY: 2301,
  ),
  (
    name: 'planned',
    segments: const [
      ZodiannSegment(value: 'tropical', label: 'Tropical'),
      ZodiannSegment(
        value: 'sidereal',
        label: 'Sidereal (planned)',
        planned: true,
      ),
    ],
    selected: 'tropical',
    specs: const [
      (rel: 4.0, width: 71.75, hasIcon: false),
      (rel: 77.75, width: 133.45, hasIcon: false),
    ],
    darkY: 2402,
    lightY: 2384,
  ),
];

final _themes = {
  'dark': (ZodiannTheme.graphite, graphiteTokens.surfaces),
  'light': (ZodiannTheme.porcelain, porcelainTokens.surfaces),
};

const _boundary = Key('segment-sheet-boundary');
const _originX = 40;
const _originY = 40;

Future<Rgba> _render(WidgetTester tester, _Row row, ThemeData theme) async {
  tester.view.physicalSize = const Size(480, 160);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final s = theme.extension<ZodiannSurfaces>()!;
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
              child: ZodiannSegmentedControl<String>(
                segments: row.segments,
                value: row.selected,
                onChanged: (_) {},
                expand: false,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
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

void main() {
  setUpAll(loadBundledFonts);

  _themes.forEach((themeName, entry) {
    final (theme, s) = entry;
    final line = s.lineSoft.toARGB32();

    for (final row in _rows) {
      testWidgets('$themeName "${row.name}" matches the component sheet', (
        tester,
      ) async {
        final sheet = await tester.runAsync(
          () => decodeDesignPng('components/components_$themeName.png'),
        );
        final selectedIndex = row.segments.indexWhere(
          (e) => e.value == row.selected,
        );
        final want = measureSegmentRow(
          sheet!,
          yHint: themeName == 'dark' ? row.darkY : row.lightY,
          scanFrom: 715,
          line: line,
          segments: row.specs,
          selected: selectedIndex,
        );
        final render = await _render(tester, row, theme);
        final got = measureSegmentRow(
          render,
          yHint: _originY + 22,
          scanFrom: 20,
          line: line,
          segments: row.specs,
          selected: selectedIndex,
        );

        // Exact: the track and thumb heights, and the thumb's inset.
        expect(got.height, want.height, reason: 'track height');
        expect(got.height, 40);
        expect(got.thumbHeight, want.thumbHeight, reason: 'thumb height');
        expect(got.thumbTopOffset, want.thumbTopOffset, reason: 'thumb inset');
        expect(got.left, _originX);
        expect(got.top, _originY + 2, reason: '40 px track in a 44 px box');

        // Positions and widths within 1 px.
        expect(
          (got.thumbLeft - got.left) - (want.thumbLeft - want.left),
          inInclusiveRange(-1, 1),
          reason: 'thumb offset',
        );
        expect(
          got.thumbWidth - want.thumbWidth,
          inInclusiveRange(-1, 1),
          reason: 'thumb width',
        );

        // Colours.
        _near(got.border, want.border, 1, 'track border');
        _near(got.trackFill, want.trackFill, 1, 'track fill');
        _near(got.thumbFill, want.thumbFill, 1, 'thumb fill');
        _near(got.ring, want.ring, 3, 'thumb ring');
        for (var i = 0; i < row.segments.length; i++) {
          _near(
            got.inks[i],
            want.inks[i],
            3,
            'label ink of ${row.segments[i].label}',
          );
          if (row.specs[i].hasIcon) {
            _near(
              got.icons[i],
              want.icons[i],
              // The selected icon (accent-strong) is held to 3. An unselected
              // icon is thin text-2 strokes at a fractional position: the sheet
              // never reaches full coverage (95 %), ours does, so 8 per channel.
              i == selectedIndex ? 3 : 8,
              'icon ink of ${row.segments[i].label}',
            );
          }
        }
      });
    }
  });

  testWidgets('segment widths are Chrome\'s layout widths within 1 px', (
    tester,
  ) async {
    for (final row in _rows) {
      await _render(tester, row, ZodiannTheme.graphite);
      for (var i = 0; i < row.segments.length; i++) {
        final thumb = find
            .ancestor(
              of: find.text(row.segments[i].label),
              matching: find.byType(AnimatedContainer),
            )
            .first;
        expect(
          tester.getSize(thumb).width,
          closeTo(row.specs[i].width, 1),
          reason: row.segments[i].label,
        );
      }
    }
  });
}
