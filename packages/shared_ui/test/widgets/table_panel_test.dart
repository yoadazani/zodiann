// ZOD-UI-010 decision D4: a table in a ZodiannPanel. The table never clips;
// a panel that holds one passes Clip.antiAlias so a hovered or selected last
// row does not square off the panel's rounded corner (UI-014 left this open).
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/load_bundled_fonts.dart';
import '../support/pixels.dart';
import '../support/table_features.dart' show near;

const _boundary = Key('panel-table');
const _margin = 32.0;

Future<(Pixels, Rect)> _render(WidgetTester tester, Clip clip) async {
  tester.view.physicalSize = const Size(700, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final theme = ZodiannTheme.graphite;
  final s = theme.extension<ZodiannSurfaces>()!;
  await tester.pumpWidget(
    Theme(
      data: theme,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: _boundary,
            child: ColoredBox(
              color: s.bg,
              child: SizedBox(
                width: 600,
                child: Padding(
                  padding: const EdgeInsets.all(_margin),
                  child: ZodiannPanel(
                    clipBehavior: clip,
                    bodyPadding: EdgeInsets.zero,
                    child: ZodiannTable(
                      columns: const [
                        ZodiannTableColumn(label: 'Body'),
                        ZodiannTableColumn(
                          label: 'Position',
                          alignment: ZodiannTableAlign.end,
                        ),
                      ],
                      rows: [
                        ZodiannTableRow(cells: const [Text('Sun'), Text('1')]),
                        ZodiannTableRow(
                          selected: true,
                          cells: const [Text('Moon'), Text('2')],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  final px = await Pixels.capture(
    tester,
    tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary)),
  );
  return (px, tester.getRect(find.byType(ZodiannPanel)));
}

void main() {
  setUpAll(loadBundledFonts);

  final theme = ZodiannTheme.graphite;
  final s = theme.extension<ZodiannSurfaces>()!;

  testWidgets('an antiAlias panel keeps its rounded corner under a selected '
      'last row', (tester) async {
    final (px, panel) = await _render(tester, Clip.antiAlias);
    // Just inside the square corner, outside the 12 px arc, at the end edge
    // (the bar is at the start): the page backdrop shows.
    final x = panel.right.round() - 2;
    final y = panel.bottom.round() - 2;
    expect(near(px.argb(x, y), s.bg.toARGB32()), isTrue, reason: 'corner');
    // Well inside the row the selected fill is there.
    final inside = Color.alphaBlend(s.accentSoft, s.surface).toARGB32();
    expect(
      near(px.argb(panel.right.round() - 40, y), inside, 2),
      isTrue,
      reason: 'row fill',
    );
  });

  testWidgets('the default panel does not clip, so the fill squares the '
      'corner', (tester) async {
    final (px, panel) = await _render(tester, Clip.none);
    final x = panel.right.round() - 2;
    final y = panel.bottom.round() - 2;
    final squared = Color.alphaBlend(s.accentSoft, s.bg).toARGB32();
    expect(near(px.argb(x, y), squared, 2), isTrue, reason: 'corner');
    expect(near(px.argb(x, y), s.bg.toARGB32()), isFalse);
  });
}
