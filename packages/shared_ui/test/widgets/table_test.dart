// ZOD-UI-010: ZodiannTable, ZodiannTableHeader and ZodiannTableRow. Task 2:
// declared columns (flex or fixed), alignment, density padding, overflow
// contract and the table scope. Later tasks add states and interaction.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

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
}
