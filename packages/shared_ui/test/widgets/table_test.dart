// ZOD-UI-010: ZodiannTable, ZodiannTableHeader and ZodiannTableRow. Task 2:
// declared columns (flex or fixed), alignment, density padding, overflow
// contract and the table scope. Later tasks add states and interaction.
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

import 'dart:ui' show SemanticsRole;

import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/button_harness.dart' show pumpInApp;
import '../support/load_bundled_fonts.dart';

const _tableKey = Key('table');

Key _k(int row, int col) => Key('r$row c$col');

/// A cell of [w] x 10 keyed by row and column.
Widget _cell(int row, int col, [double w = 10]) =>
    SizedBox(key: _k(row, col), width: w, height: 10);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 600,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = Size(width + 40, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Theme(
      data: theme ?? ZodiannTheme.graphite,
      child: Directionality(
        textDirection: direction,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(key: _tableKey, width: width, child: child),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Runs [body] and returns every error the framework reported while it ran
/// (an error widget in a `Column` also reports an overflow, so
/// `takeException` would see several).
Future<List<Object>> _errors(Future<void> Function() body) async {
  final errors = <Object>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) => errors.add(details.exception);
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

/// The left edge of the cell at [row], [col] relative to the table's left.
double _left(WidgetTester t, int row, int col) =>
    t.getTopLeft(find.byKey(_k(row, col))).dx -
    t.getTopLeft(find.byKey(_tableKey)).dx;

double _right(WidgetTester t, int row, int col) =>
    t.getTopRight(find.byKey(_k(row, col))).dx -
    t.getTopLeft(find.byKey(_tableKey)).dx;

const _two = [
  ZodiannTableColumn(label: 'a', width: 200),
  ZodiannTableColumn(label: 'b', alignment: ZodiannTableAlign.end, width: 200),
];

void main() {
  setUpAll(loadBundledFonts);

  group('columns', () {
    const columns = [
      ZodiannTableColumn(label: 'One', flex: 2),
      ZodiannTableColumn(label: 'Two'),
      ZodiannTableColumn(label: 'Three', width: 80),
    ];

    testWidgets('share their left edges in every row', (tester) async {
      await _pump(
        tester,
        ZodiannTable(
          columns: columns,
          rows: [
            ZodiannTableRow(cells: [_cell(0, 0, 30), _cell(0, 1), _cell(0, 2)]),
            ZodiannTableRow(cells: [_cell(1, 0), _cell(1, 1, 90), _cell(1, 2)]),
          ],
        ),
      );
      // Free width 600 - 80 = 520, split 2:1, then the fixed 80.
      const pad = 16.0;
      const first = (520 * 2) / 3;
      const second = 520 / 3;
      for (final row in [0, 1]) {
        expect(_left(tester, row, 0), closeTo(pad, 0.01), reason: 'row $row');
        expect(
          _left(tester, row, 1),
          closeTo(first + pad, 0.01),
          reason: 'row $row',
        );
        expect(
          _left(tester, row, 2),
          closeTo(first + second + pad, 0.01),
          reason: 'row $row',
        );
      }
    });

    testWidgets('an end-aligned column ends at the end edge (LTR)', (
      tester,
    ) async {
      await _pump(
        tester,
        ZodiannTable(
          columns: _two,
          rows: [
            ZodiannTableRow(cells: [_cell(0, 0), _cell(0, 1, 30)]),
          ],
        ),
      );
      expect(_right(tester, 0, 1), closeTo(400 - 16, 0.01));
    });

    testWidgets('an end-aligned column ends at the end edge (RTL)', (
      tester,
    ) async {
      await _pump(
        tester,
        direction: TextDirection.rtl,
        ZodiannTable(
          columns: _two,
          rows: [
            ZodiannTableRow(cells: [_cell(0, 0), _cell(0, 1, 30)]),
          ],
        ),
      );
      // Column a is the right-hand one (x 400..600), column b the left-hand
      // one (x 200..400); b ends at its left edge plus the padding.
      expect(_left(tester, 0, 1), closeTo(200 + 16, 0.01));
      expect(_right(tester, 0, 0), closeTo(600 - 16, 0.01));
    });

    testWidgets('inline padding is 16 regular and 10 compact', (tester) async {
      Future<void> pumpDensity(ZodiannTableDensity d) => _pump(
        tester,
        ZodiannTable(
          columns: _two,
          density: d,
          rows: [
            ZodiannTableRow(cells: [_cell(0, 0), _cell(0, 1)]),
          ],
        ),
      );
      await pumpDensity(ZodiannTableDensity.regular);
      expect(_left(tester, 0, 0), closeTo(ZodiannSpace.s4, 0.01));
      await pumpDensity(ZodiannTableDensity.compact);
      expect(
        _left(tester, 0, 0),
        closeTo(ZodiannSize.tableCompactPadding, 0.01),
      );
    });

    testWidgets('a narrow parent does not overflow and keeps rows aligned', (
      tester,
    ) async {
      const narrow = [
        ZodiannTableColumn(label: 'a', flex: 3),
        ZodiannTableColumn(label: 'b', flex: 2),
        ZodiannTableColumn(label: 'c', width: 120),
        ZodiannTableColumn(label: 'd'),
      ];
      await _pump(
        tester,
        width: 390,
        ZodiannTable(
          columns: narrow,
          rows: [
            ZodiannTableRow(
              cells: [_cell(0, 0), _cell(0, 1), _cell(0, 2), _cell(0, 3)],
            ),
            ZodiannTableRow(
              cells: [_cell(1, 0, 40), _cell(1, 1), _cell(1, 2), _cell(1, 3)],
            ),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      for (var c = 0; c < 4; c++) {
        expect(_left(tester, 0, c), closeTo(_left(tester, 1, c), 0.01));
      }
    });

    test('a column is flex or fixed, never both, and must be positive', () {
      expect(
        () => ZodiannTableColumn(label: 'x', flex: 2, width: 10),
        throwsAssertionError,
      );
      expect(
        () => ZodiannTableColumn(label: 'x', flex: 0),
        throwsAssertionError,
      );
      expect(
        () => ZodiannTableColumn(label: 'x', width: -1),
        throwsAssertionError,
      );
    });

    test('cells.length must equal columns.length when columns are given', () {
      expect(
        () => ZodiannTableRow(columns: _two, cells: [_cell(0, 0)]),
        throwsAssertionError,
      );
    });

    testWidgets('a table whose row disagrees in length asserts', (
      tester,
    ) async {
      final errors = await _errors(
        () => _pump(
          tester,
          ZodiannTable(
            columns: _two,
            rows: [
              ZodiannTableRow(cells: [_cell(0, 0)]),
            ],
          ),
        ),
      );
      expect(errors.first, isAssertionError);
      expect(errors.first.toString(), contains('one cell per column'));
    });
  });

  group('overflow', () {
    const columns = [
      ZodiannTableColumn(label: 'a'),
      ZodiannTableColumn(label: 'b'),
      ZodiannTableColumn(label: 'c', width: 80),
    ];

    testWidgets('a cell wider than its column moves no other column', (
      tester,
    ) async {
      await _pump(
        tester,
        ZodiannTable(
          columns: columns,
          rows: [
            ZodiannTableRow(
              cells: [
                _cell(0, 0, 500),
                Row(
                  key: _k(0, 1),
                  children: [
                    Flexible(
                      child: Text(
                        'a very long text that cannot fit in its column ' * 4,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                _cell(0, 2),
              ],
            ),
            ZodiannTableRow(cells: [_cell(1, 0), _cell(1, 1), _cell(1, 2)]),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      for (var c = 0; c < 3; c++) {
        expect(_left(tester, 0, c), closeTo(_left(tester, 1, c), 0.01));
      }
      // The wide cell is clamped to its slot less the padding.
      final slot = (600 - 80) / 2;
      expect(
        tester.getSize(find.byKey(_k(0, 0))).width,
        lessThanOrEqualTo(slot - 32 + 0.01),
      );
    });

    testWidgets('a Row of fixed-width children wider than its slot overflows '
        '(the caller wraps it)', (tester) async {
      await _pump(
        tester,
        ZodiannTable(
          columns: _two,
          rows: [
            ZodiannTableRow(
              cells: [
                Row(
                  children: [
                    const SizedBox(width: 150, height: 10),
                    const SizedBox(width: 150, height: 10),
                  ],
                ),
                _cell(0, 1),
              ],
            ),
          ],
        ),
      );
      final e = tester.takeException();
      expect(e, isA<FlutterError>());
      expect(e.toString(), contains('overflowed'));
    });

    testWidgets('an unbounded-width parent asserts with a message', (
      tester,
    ) async {
      await tester.pumpWidget(
        Theme(
          data: ZodiannTheme.graphite,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ZodiannTable(
                  columns: _two,
                  rows: [
                    ZodiannTableRow(cells: [_cell(0, 0), _cell(0, 1)]),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final e = tester.takeException();
      expect(e, isAssertionError);
      expect(e.toString(), contains('bounded width'));
    });
  });

  group('table scope', () {
    testWidgets('a row inside ZodiannTable inherits columns and density', (
      tester,
    ) async {
      await _pump(
        tester,
        ZodiannTable(
          columns: _two,
          density: ZodiannTableDensity.compact,
          rows: [
            ZodiannTableRow(cells: [_cell(0, 0), _cell(0, 1, 30)]),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        _left(tester, 0, 0),
        closeTo(ZodiannSize.tableCompactPadding, 0.01),
      );
      expect(
        _right(tester, 0, 1),
        closeTo(400 - ZodiannSize.tableCompactPadding, 0.01),
      );
    });

    testWidgets('a row that passes its own columns inside a table asserts', (
      tester,
    ) async {
      final errors = await _errors(
        () => _pump(
          tester,
          ZodiannTable(
            columns: _two,
            rows: [
              ZodiannTableRow(columns: _two, cells: [_cell(0, 0), _cell(0, 1)]),
            ],
          ),
        ),
      );
      expect(errors.first, isAssertionError);
      expect(errors.first.toString(), contains('must not pass its own'));
    });

    testWidgets('a row outside a table without columns asserts', (
      tester,
    ) async {
      await _pump(tester, ZodiannTableRow(cells: [_cell(0, 0)]));
      final e = tester.takeException();
      expect(e, isAssertionError);
      expect(e.toString(), contains('needs columns'));
    });

    testWidgets('a standalone row with columns works, and isLast is 43 high', (
      tester,
    ) async {
      await _pump(
        tester,
        Column(
          children: [
            ZodiannTableRow(columns: _two, cells: [_cell(0, 0), _cell(0, 1)]),
            ZodiannTableRow(
              columns: _two,
              isLast: true,
              cells: [_cell(1, 0), _cell(1, 1)],
            ),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      final rows = find.byType(ZodiannTableRow);
      expect(tester.getSize(rows.at(0)).height, ZodiannSize.tableRow);
      expect(tester.getSize(rows.at(1)).height, ZodiannSize.tableRow - 1);
    });

    testWidgets('ZodiannTable gives its last row no divider height', (
      tester,
    ) async {
      await _pump(
        tester,
        ZodiannTable(
          columns: _two,
          rows: [
            ZodiannTableRow(cells: [_cell(0, 0), _cell(0, 1)]),
            ZodiannTableRow(cells: [_cell(1, 0), _cell(1, 1)]),
          ],
        ),
      );
      final rows = find.byType(ZodiannTableRow);
      expect(tester.getSize(rows.at(0)).height, ZodiannSize.tableRow);
      expect(tester.getSize(rows.at(1)).height, ZodiannSize.tableRow - 1);
    });
  });

  group('states', () {
    final s = ZodiannTheme.graphite.extension<ZodiannSurfaces>()!;

    Finder fill(Color c, int row) => find.descendant(
      of: find.byType(ZodiannTableRow).at(row),
      matching: find.byWidgetPredicate((w) => w is ColoredBox && w.color == c),
    );

    Widget table({bool selectedSecond = false, bool tappable = true}) =>
        ZodiannTable(
          columns: _two,
          rows: [
            ZodiannTableRow(
              onTap: tappable ? () {} : null,
              semanticLabel: tappable ? 'row' : null,
              cells: [
                Text('Sun', key: _k(0, 0)),
                Text('17', key: _k(0, 1)),
              ],
            ),
            ZodiannTableRow(
              selected: selectedSecond,
              onTap: tappable ? () {} : null,
              semanticLabel: tappable ? 'row' : null,
              cells: [
                Text('Moon', key: _k(1, 0)),
                Text('18', key: _k(1, 1)),
              ],
            ),
            ZodiannTableRow(
              onTap: tappable ? () {} : null,
              semanticLabel: tappable ? 'row' : null,
              cells: [
                Text('Venus', key: _k(2, 0)),
                Text('22', key: _k(2, 1)),
              ],
            ),
          ],
        );

    Future<TestGesture> mouse(WidgetTester t) async {
      final g = await t.createGesture(kind: PointerDeviceKind.mouse);
      await g.addPointer(location: const Offset(-50, -50));
      addTearDown(g.removePointer);
      return g;
    }

    testWidgets('the header is the label style over text-3 with a rule', (
      tester,
    ) async {
      await _pump(tester, table());
      final style = tester.widget<Text>(find.text('a')).style!;
      final styles = ZodiannTheme.graphite.extension<ZodiannTextStyles>()!;
      expect(style.fontSize, styles.label.fontSize);
      expect(style.fontWeight, styles.label.fontWeight);
      expect(style.color, s.text3);
      final header = find.byType(ZodiannTableHeader);
      final rule = find.descendant(
        of: header,
        matching: find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == s.lineSoft,
        ),
      );
      expect(rule, findsOneWidget);
      final h = tester.getRect(header);
      final r = tester.getRect(rule);
      expect(r.height, ZodiannSize.hairline);
      expect(r.bottom, h.bottom);
      expect(r.width, h.width);
      // 10 + the label's line + 10 above the rule.
      final label = tester.getSize(find.text('a')).height;
      expect(
        h.height,
        closeTo(2 * ZodiannSize.tableHeaderPadding + label + 1, 0.01),
      );
    });

    testWidgets('a header label keeps its case', (tester) async {
      await _pump(
        tester,
        const ZodiannTableHeader(
          columns: [ZodiannTableColumn(label: 'Local date and time')],
        ),
      );
      expect(find.text('Local date and time'), findsOneWidget);
    });

    testWidgets('a row is 44 high including its divider; the last has none', (
      tester,
    ) async {
      await _pump(tester, table());
      for (var i = 0; i < 2; i++) {
        final row = tester.getRect(find.byType(ZodiannTableRow).at(i));
        expect(row.height, ZodiannSize.tableRow);
        final rule = tester.getRect(fill(s.lineSoft, i));
        expect(rule.height, ZodiannSize.hairline);
        expect(rule.bottom, row.bottom);
        expect(rule.width, row.width);
      }
      expect(fill(s.lineSoft, 2), findsNothing);
    });

    testWidgets('hover fills surface-2 on a row with onTap only', (
      tester,
    ) async {
      await _pump(tester, table());
      final g = await mouse(tester);
      await g.moveTo(tester.getCenter(find.byType(ZodiannTableRow).at(0)));
      await tester.pump();
      final row = tester.getRect(find.byType(ZodiannTableRow).at(0));
      expect(fill(s.surface2, 0), findsOneWidget);
      final f = tester.getRect(fill(s.surface2, 0));
      expect(f.left, row.left);
      expect(f.width, row.width);
      expect(f.height, row.height - ZodiannSize.hairline);
      expect(fill(s.surface2, 1), findsNothing);
      await g.moveTo(const Offset(-50, -50));
      await tester.pump();
      expect(fill(s.surface2, 0), findsNothing);
    });

    testWidgets('a row without onTap does not react to hover', (tester) async {
      await _pump(tester, table(tappable: false));
      final g = await mouse(tester);
      await g.moveTo(tester.getCenter(find.byType(ZodiannTableRow).at(0)));
      await tester.pump();
      expect(fill(s.surface2, 0), findsNothing);
    });

    testWidgets('selected fills accent-soft and wins over hover', (
      tester,
    ) async {
      await _pump(tester, table(selectedSecond: true));
      expect(fill(s.accentSoft, 1), findsOneWidget);
      final g = await mouse(tester);
      await g.moveTo(tester.getCenter(find.byType(ZodiannTableRow).at(1)));
      await tester.pump();
      expect(fill(s.accentSoft, 1), findsOneWidget);
      expect(fill(s.surface2, 1), findsNothing);
      expect(fill(s.accentSoft, 0), findsNothing);
    });

    for (final dir in TextDirection.values) {
      testWidgets('the selected bar is 3 wide on the start edge ($dir)', (
        tester,
      ) async {
        await _pump(tester, direction: dir, table(selectedSecond: true));
        final row = tester.getRect(find.byType(ZodiannTableRow).at(1));
        expect(fill(s.accent, 0), findsNothing);
        final bar = tester.getRect(fill(s.accent, 1));
        expect(bar.width, ZodiannSize.tableSelectedBar);
        expect(bar.top, row.top);
        // The bar covers the fill, not the divider row below it.
        expect(bar.height, row.height - ZodiannSize.hairline);
        if (dir == TextDirection.ltr) {
          expect(bar.left, row.left);
        } else {
          expect(bar.right, row.right);
        }
      });
    }

    testWidgets('a row stays 44 at 1.5x text and grows at 3x', (tester) async {
      await _pump(tester, textScale: 1.5, table(selectedSecond: true));
      expect(
        tester.getSize(find.byType(ZodiannTableRow).at(1)).height,
        ZodiannSize.tableRow,
      );
      await _pump(tester, textScale: 3, table(selectedSecond: true));
      final row = tester.getRect(find.byType(ZodiannTableRow).at(1));
      expect(row.height, greaterThan(ZodiannSize.tableRow));
      expect(
        tester.getRect(fill(s.accentSoft, 1)).height,
        row.height - ZodiannSize.hairline,
      );
      expect(
        tester.getRect(fill(s.accent, 1)).height,
        row.height - ZodiannSize.hairline,
      );
      expect(tester.getRect(fill(s.lineSoft, 1)).height, ZodiannSize.hairline);
    });

    testWidgets('an RTL row mirrors the order of the cells', (tester) async {
      await _pump(tester, table());
      expect(_left(tester, 0, 0) < _left(tester, 0, 1), isTrue);
      await _pump(tester, direction: TextDirection.rtl, table());
      expect(_left(tester, 0, 0) > _left(tester, 0, 1), isTrue);
    });

    testWidgets('Hebrew, 1.5x text and a selected row together', (
      tester,
    ) async {
      await _pump(
        tester,
        direction: TextDirection.rtl,
        textScale: 1.5,
        theme: withZodiannScript(ZodiannTheme.graphite, ZodiannScript.hebrew),
        ZodiannTable(
          columns: _two,
          rows: [
            ZodiannTableRow(
              selected: true,
              onTap: () {},
              semanticLabel: 'שמש',
              cells: const [
                Text('שמש', key: Key('he0')),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text('17°03′', key: Key('he1')),
                ),
              ],
            ),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      final row = tester.getRect(find.byType(ZodiannTableRow));
      expect(tester.getRect(fill(s.accent, 0)).right, row.right);
      // Column a is the right-hand one; b is end-aligned to the left edge.
      expect(
        tester.getTopLeft(find.byKey(const Key('he1'))).dx -
            tester.getTopLeft(find.byKey(_tableKey)).dx,
        closeTo(200 + 16, 0.01),
      );
      expect(
        tester.getTopRight(find.byKey(const Key('he0'))).dx,
        lessThanOrEqualTo(row.right - 16 + 0.01),
      );
    });
  });

  group('interaction', () {
    final s = ZodiannTheme.graphite.extension<ZodiannSurfaces>()!;
    final calls = <int>[];

    Widget three({int? readOnly}) => ZodiannTable(
      columns: _two,
      rows: [
        for (var i = 0; i < 3; i++)
          ZodiannTableRow(
            onTap: i == readOnly ? null : () => calls.add(i),
            semanticLabel: i == readOnly ? null : 'row $i',
            cells: [
              Text('n$i', key: _k(i, 0)),
              Text('v$i', key: _k(i, 1)),
            ],
          ),
      ],
    );

    Future<void> pumpKeys(WidgetTester t, Widget child) async {
      calls.clear();
      // A MaterialApp gives the tree its primary focus, shortcuts and
      // traversal actions, as in the app (and in the button tests).
      await pumpInApp(t, SizedBox(width: 600, child: child));
    }

    Finder ring() => find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).border?.top.color == s.focus,
    );

    testWidgets('a tap activates onTap', (tester) async {
      await pumpKeys(tester, three());
      await tester.tap(find.byType(ZodiannTableRow).at(1));
      expect(calls, [1]);
    });

    testWidgets('Enter and Space activate the focused row', (tester) async {
      await pumpKeys(tester, three());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(calls, [0, 0]);
    });

    testWidgets('Tab skips a row without onTap', (tester) async {
      await pumpKeys(tester, three(readOnly: 0));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(calls, [1]);
    });

    testWidgets('the keyboard ring is 2 px, inside the row, keyboard only', (
      tester,
    ) async {
      await pumpKeys(tester, three());
      expect(ring(), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(ring(), findsOneWidget);
      final box =
          tester.widget<DecoratedBox>(ring()).decoration as BoxDecoration;
      expect(box.border!.top.width, ZodiannStates.focusRingWidth);
      final row = tester.getRect(find.byType(ZodiannTableRow).at(0));
      final r = tester.getRect(ring());
      expect(row.contains(r.topLeft), isTrue);
      expect(row.contains(r.bottomRight - const Offset(0.5, 0.5)), isTrue);
      await tester.tap(find.byType(ZodiannTableRow).at(1));
      await tester.pump();
      expect(ring(), findsNothing);
    });

    test('a tappable row needs a semantic label', () {
      expect(
        () => ZodiannTableRow(columns: _two, onTap: () {}, cells: const []),
        throwsAssertionError,
      );
    });
  });

  group('semantics', () {
    List<SemanticsNode> nodes(WidgetTester t) {
      final out = <SemanticsNode>[];
      void walk(SemanticsNode n) {
        out.add(n);
        n.visitChildren((c) {
          walk(c);
          return true;
        });
      }

      // The root owner has no semantics in flutter_test; the deprecated
      // accessor is the one that does.
      // ignore: deprecated_member_use
      walk(t.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
      return out;
    }

    SemanticsRole role(SemanticsNode n) => n.getSemanticsData().role;

    Widget rows({bool header = false}) => Column(
      children: [
        if (header) const ZodiannTableHeader(columns: _two),
        for (var i = 0; i < 3; i++)
          ZodiannTableRow(
            columns: _two,
            isLast: i == 2,
            selected: i == 1,
            onTap: () {},
            semanticLabel: 'row $i',
            cells: [Text('n$i'), Text('v$i')],
          ),
      ],
    );

    testWidgets(
      'inside ZodiannTable: table, row, columnHeader and cell roles',
      (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(
          tester,
          ZodiannTable(
            columns: _two,
            rows: [
              for (var i = 0; i < 3; i++)
                ZodiannTableRow(
                  selected: i == 1,
                  onTap: () {},
                  semanticLabel: 'row $i',
                  cells: [Text('n$i'), Text('v$i')],
                ),
            ],
          ),
        );
        expect(tester.takeException(), isNull);
        final all = nodes(tester);
        int count(SemanticsRole r) => all.where((n) => role(n) == r).length;
        expect(count(SemanticsRole.table), 1);
        expect(count(SemanticsRole.row), 4);
        expect(count(SemanticsRole.columnHeader), 2);
        expect(count(SemanticsRole.cell), 6);
        final table = all.firstWhere((n) => role(n) == SemanticsRole.table);
        final kids = <SemanticsNode>[];
        table.visitChildren((c) {
          kids.add(c);
          return true;
        });
        expect(kids.length, 4);
        expect(kids.every((k) => role(k) == SemanticsRole.row), isTrue);
        handle.dispose();
      },
    );

    testWidgets('standalone rows and header carry no table roles', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, rows(header: true));
      expect(tester.takeException(), isNull);
      for (final n in nodes(tester)) {
        expect(
          {
            SemanticsRole.table,
            SemanticsRole.row,
            SemanticsRole.cell,
            SemanticsRole.columnHeader,
          }.contains(role(n)),
          isFalse,
          reason: 'node ${n.label}',
        );
      }
      expect(
        tester.getSemantics(find.bySemanticsLabel('row 0')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets('selected is a state only on the selected row', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, rows());
      expect(
        tester.getSemantics(find.bySemanticsLabel('row 1')),
        isSemantics(isSelected: true, hasSelectedState: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('row 0')),
        isNot(isSemantics(hasSelectedState: true)),
      );
      handle.dispose();
    });
  });
}
