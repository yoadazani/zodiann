// ZOD-UI-010 criteria 1 and 2: the table's header, rows, hover and selected
// look match the designer's pixels in both themes, and the selected bar sits
// on the logical start edge in LTR and RTL.
//
// Oracles (design-reference/zodiann/): the component sheet's four-row table
// (components_{dark,light}.png), the desktop wheel screens' Positions panel
// (English: bar on the left; Hebrew: bar on the right) and the mobile wheel
// screen (a 2x capture) for the compact density. Chrome snaps its box edges
// to whole pixels where Flutter does not, so the comparison reads runs of
// colour along a column and a row: colours within 1 per channel, row lengths
// exact, the header's length within 1 (the same 38.4 snapped differently in
// the two sheets). Measured facts are in docs/plans/ZOD-UI-010-table-component.md.
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/load_bundled_fonts.dart';
import '../support/pixels.dart';
import '../support/table_features.dart';
import '../support/tag_features.dart' show decodeDesignPng;

const _boundary = Key('table-sheet');

/// The sheet table's column widths (measured; the table is 890 wide).
const _sheetColumns = [
  ZodiannTableColumn(label: 'Body', flex: 183),
  ZodiannTableColumn(label: 'Sign', flex: 152),
  ZodiannTableColumn(label: 'Position', flex: 104),
  ZodiannTableColumn(label: 'Motion', flex: 149),
  ZodiannTableColumn(label: 'State', flex: 302),
];

typedef _Render = ({Pixels image, double headerHeight});

/// Renders the sheet's four rows (default, hover, selected, default) at the
/// origin of a `surface` cell and returns the pixels.
Future<_Render> _render(
  WidgetTester tester,
  ThemeData theme, {
  TextDirection direction = TextDirection.ltr,
  ZodiannTableDensity density = ZodiannTableDensity.regular,
  int selected = 2,
  int? hover = 1,
}) async {
  tester.view.physicalSize = const Size(1000, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final s = theme.extension<ZodiannSurfaces>()!;
  await tester.pumpWidget(
    Theme(
      data: theme,
      child: Directionality(
        textDirection: direction,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: _boundary,
            child: ColoredBox(
              color: s.surface,
              child: SizedBox(
                width: 890,
                child: ZodiannTable(
                  columns: _sheetColumns,
                  density: density,
                  rows: [
                    for (var i = 0; i < 4; i++)
                      ZodiannTableRow(
                        selected: i == selected,
                        onTap: () {},
                        semanticLabel: 'row $i',
                        cells: [for (var c = 0; c < 5; c++) Text('r$i c$c')],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  if (hover != null) {
    final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await g.addPointer(location: const Offset(-50, -50));
    addTearDown(g.removePointer);
    await g.moveTo(tester.getCenter(find.byType(ZodiannTableRow).at(hover)));
    await tester.pump();
  }
  final headerHeight = tester.getSize(find.byType(ZodiannTableHeader)).height;
  final image = await Pixels.capture(
    tester,
    tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary)),
  );
  return (image: image, headerHeight: headerHeight);
}

/// The runs from the header's top down at x, over the header, its rule and
/// three rows with their rules (8 runs, the last one the fourth row's start).
List<Run> _columnRuns(int Function(int, int) at, int x, int top, int rows) =>
    verticalRuns(at, x, top, top + 39 + 44 * rows);

void main() {
  setUpAll(loadBundledFonts);

  for (final entry in {
    'dark': (ZodiannTheme.graphite, 'components/components_dark.png', 3484),
    'light': (ZodiannTheme.porcelain, 'components/components_light.png', 3467),
  }.entries) {
    testWidgets('rows match the component sheet (${entry.key})', (
      tester,
    ) async {
      final (theme, path, headerTop) = entry.value;
      final s = theme.extension<ZodiannSurfaces>()!;
      final sheet = (await tester.runAsync(() => decodeDesignPng(path)))!;
      int sheetAt(int x, int y) => sheet.argb(x, y);
      // The panel's left border, then the table's x origin just inside it.
      final border = horizontalRuns(
        sheetAt,
        headerTop + 39 + 20, // inside the first row (the header has none)
        470,
        540,
      ).firstWhere((r) => near(r.color, s.lineSoft.toARGB32())).start;
      final originX = border + 1;

      final mine = await _render(tester, theme);
      int mineAt(int x, int y) => mine.image.argb(x, y);

      // Colours down a column inside the first column's padding (no text, no
      // bar): header, rule, default, rule, hover, rule, selected, rule.
      final want = _columnRuns(sheetAt, originX + 8, headerTop, 3);
      final got = _columnRuns(mineAt, 8, 0, 3);
      String dump(List<Run> r) => r
          .map((e) => '${e.start}+${e.length}:${e.color.toRadixString(16)}')
          .join(' ');
      printOnFailure('sheet: ${dump(want)}');
      printOnFailure('mine:  ${dump(got)}');
      expect(
        got.length,
        want.length,
        reason: 'run count (header, rows, rules)',
      );
      for (var i = 0; i < 8; i++) {
        expect(
          near(got[i].color, want[i].color),
          isTrue,
          reason:
              'run $i colour ${got[i].color.toRadixString(16)} vs '
              '${want[i].color.toRadixString(16)}',
        );
        final tolerance = i == 0 ? 1 : 0; // the header's snapped height
        expect(
          (got[i].length - want[i].length).abs(),
          lessThanOrEqualTo(tolerance),
          reason: 'run $i length ${got[i].length} vs ${want[i].length}',
        );
      }
      // Pin the pieces the runs imply: rules are 1 px, rows 43 + rule.
      for (final i in [1, 3, 5, 7]) {
        expect(got[i].length, 1, reason: 'rule $i');
        expect(near(got[i].color, s.lineSoft.toARGB32()), isTrue);
      }
      for (final i in [2, 4, 6]) {
        expect(got[i].length, 43, reason: 'row run $i');
      }
      expect(
        near(got[4].color, s.surface2.toARGB32(), 2),
        isTrue,
        reason: 'hover fill',
      );
      expect(got[2].color, isNot(got[6].color));

      // The bar: accent, 3 px, at the start of the selected row's middle.
      final wantMid = want[6].start + 21;
      final gotMid = got[6].start + 21;
      final wantBar = horizontalRuns(sheetAt, wantMid, originX, originX + 40);
      final gotBar = horizontalRuns(mineAt, gotMid, 0, 40);
      expect(gotBar.first.length, 3, reason: 'bar width');
      expect(wantBar.first.length, 3, reason: 'sheet bar width');
      expect(near(gotBar.first.color, wantBar.first.color), isTrue);
      expect(near(gotBar.first.color, s.accent.toARGB32()), isTrue);
      // The bar stops above the rules: the rule rows have no bar.
      expect(near(mineAt(1, got[7].start), s.lineSoft.toARGB32()), isTrue);
      expect(near(mineAt(1, got[5].start), s.lineSoft.toARGB32()), isTrue);
    });
  }

  testWidgets('the selected bar is on the right edge in RTL, as in the Hebrew '
      'screen', (tester) async {
    final theme = ZodiannTheme.graphite;
    final s = theme.extension<ZodiannSurfaces>()!;
    final he = (await tester.runAsync(
      () => decodeDesignPng('screens/01-zodiac-wheel_desktop_he_dark.png'),
    ))!;
    int heAt(int x, int y) => he.argb(x, y);
    // Positions panel 24..493 (borders), Sun row at y 509..551.
    final heRow = horizontalRuns(heAt, 530, 25, 492);
    final heBar = heRow.last;
    expect(heBar.length, 3);
    expect(near(heBar.color, s.accent.toARGB32()), isTrue);
    expect(heRow.first.start, 25, reason: 'no bar at the left edge');
    expect(near(heRow.first.color, s.accentSoft.toARGB32(), 2), isFalse);

    final mine = await _render(
      tester,
      theme,
      direction: TextDirection.rtl,
      hover: null,
    );
    int mineAt(int x, int y) => mine.image.argb(x, y);
    final col = _columnRuns(mineAt, 8, 0, 3);
    final y = col[6].start + 21;
    final row = horizontalRuns(mineAt, y, 0, 889);
    expect(row.last.length, 3, reason: 'bar width');
    expect(row.last.start, 887, reason: 'bar at the right edge');
    expect(near(row.last.color, heBar.color), isTrue);
    expect(row.first.start, 0);
    expect(near(row.first.color, s.accent.toARGB32()), isFalse);
  });

  testWidgets('the compact density matches the mobile screen (2x)', (
    tester,
  ) async {
    final theme = ZodiannTheme.graphite;
    final s = theme.extension<ZodiannSurfaces>()!;
    final mob = (await tester.runAsync(
      () =>
          decodeDesignPng('responsive/mobile/zodiac-wheel_mobile_en_dark.png'),
    ))!;
    int mobAt(int x, int y) => mob.argb(x, y);
    // Positions panel at x 32..33 border; header from y 2254 (2x).
    final want = verticalRuns(mobAt, 50, 2254, 2254 + 2 * 39 + 2 * 44 * 2);
    final mine = await _render(
      tester,
      theme,
      density: ZodiannTableDensity.compact,
      selected: 0,
      hover: null,
    );
    int mineAt(int x, int y) => mine.image.argb(x, y);
    final got = verticalRuns(mineAt, 8, 0, 39 + 44 * 2);
    // header (37 or 38), rule, selected row, rule, default row, rule.
    expect((got[0].length * 2 - want[0].length).abs(), lessThanOrEqualTo(2));
    expect(got[1].length * 2, want[1].length, reason: 'rule');
    expect(got[2].length * 2, want[2].length, reason: 'selected row');
    expect(got[3].length * 2, want[3].length, reason: 'rule below');
    expect(got[4].length * 2, want[4].length, reason: 'default row');
    expect(near(got[2].color, want[2].color), isTrue);
    expect(near(got[2].color, s.accentSoft.toARGB32(), 2), isFalse);
  });
}
