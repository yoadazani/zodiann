// ZOD-UI-014 criteria 1 and 2: the panel's border, radius, padding and head
// are the token values, and nothing casts a shadow, measured by pixels in both
// themes at desktop (1440) and phone (390) widths, DPR 1.
//
// The panel sits on a `bg` page with a 32 px margin, so the whole ring around
// it can be scanned for shadow.
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/pixels.dart';

const _margin = 32;
const _boundary = Key('panel-pixels-boundary');

final class _Scene {
  _Scene(this.px, this.panel);
  final Pixels px;
  final Rect panel;
}

Future<_Scene> _scene(
  WidgetTester tester,
  Size size,
  ThemeData theme, {
  bool floatingShadow = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final s = theme.extension<ZodiannSurfaces>()!;
  Widget panel = ZodiannPanel(
    head: const ZodiannPanelHead(),
    child: ColoredBox(color: s.accent, child: const SizedBox(height: 40)),
  );
  if (floatingShadow) {
    panel = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: ZodiannRadius.panel,
        boxShadow: theme.extension<ZodiannElevation>()!.floating,
      ),
      child: panel,
    );
  }
  await tester.pumpWidget(
    Theme(
      data: theme,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: _boundary,
          child: ColoredBox(
            color: s.bg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(padding: const EdgeInsets.all(32), child: panel),
              ],
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
  return _Scene(px, tester.getRect(find.byType(ZodiannPanel)));
}

/// How many pixels in the margin ring around [panel] are not [bg].
int _ringStains(Pixels px, Rect panel, int bg) {
  var n = 0;
  final inflated = panel.inflate(_margin.toDouble());
  for (var y = inflated.top.toInt(); y < inflated.bottom.toInt(); y++) {
    for (var x = inflated.left.toInt(); x < inflated.right.toInt(); x++) {
      if (x < 0 || y < 0 || x >= px.width || y >= px.height) continue;
      if (panel.contains(Offset(x + 0.5, y + 0.5))) continue;
      if (px.argb(x, y) != bg) n++;
    }
  }
  return n;
}

void main() {
  final themes = {
    'Graphite': ZodiannTheme.graphite,
    'Porcelain': ZodiannTheme.porcelain,
  };
  final sizes = {
    // MASTER §4: (view, padding, head).
    'desktop 1440': (const Size(1440, 900), 20, 56),
    'phone 390': (const Size(390, 1200), 16, 52),
  };

  themes.forEach((themeName, theme) {
    final s = theme.extension<ZodiannSurfaces>()!;
    final bg = s.bg.toARGB32();
    final surface = s.surface.toARGB32();
    final line = s.lineSoft.toARGB32();
    final accent = s.accent.toARGB32();

    sizes.forEach((sizeName, entry) {
      final (size, padding, head) = entry;
      group('$themeName $sizeName', () {
        testWidgets('border: one lineSoft pixel, then surface', (tester) async {
          final r = await _scene(tester, size, theme);
          final px = r.px;
          final left = r.panel.left.toInt();
          final right = r.panel.right.toInt() - 1;
          final top = r.panel.top.toInt();
          // In the body's padding band, clear of the corners.
          final midY = top + head + 5;
          expect(px.argb(left - 1, midY), bg, reason: 'outside left');
          expect(px.argb(left, midY), line, reason: 'left border');
          expect(px.argb(left + 1, midY), surface, reason: 'inside left');
          expect(px.argb(right, midY), line, reason: 'right border');
          expect(px.argb(right + 1, midY), bg, reason: 'outside right');
          final col = left + 100;
          expect(px.argb(col, top - 1), bg, reason: 'outside top');
          expect(px.argb(col, top), line, reason: 'top border');
          expect(px.argb(col, top + 1), surface, reason: 'inside top');
          final bottom = r.panel.bottom.toInt() - 1;
          expect(px.argb(col, bottom), line, reason: 'bottom border');
          expect(px.argb(col, bottom + 1), bg, reason: 'outside bottom');
        });

        testWidgets('radius: the corner follows a 12 px arc', (tester) async {
          final r = await _scene(tester, size, theme);
          final px = r.px;
          final left = r.panel.left.toInt();
          final top = r.panel.top.toInt();
          expect(px.argb(left, top), bg, reason: 'corner pixel is page');
          // 12 x (1 - 1/sqrt 2) = 3.5: the arc crosses the diagonal there.
          final diagonal = px.argb(left + 3, top + 3);
          expect(diagonal, isNot(bg), reason: 'arc reaches the diagonal');
          expect(diagonal, isNot(surface), reason: 'diagonal is the border');
          // The straight left edge starts where the arc ends, 12 px down.
          final firstFull = px.firstY(left, top, (c) => c == line) - top;
          expect(firstFull, inInclusiveRange(11, 13));
          // The top edge likewise.
          final firstFullX = px.firstX(top, left, (c) => c == line) - left;
          expect(firstFullX, inInclusiveRange(11, 13));
        });

        testWidgets('padding and head are the layout tokens', (tester) async {
          final r = await _scene(tester, size, theme);
          final px = r.px;
          final left = r.panel.left.toInt();
          final top = r.panel.top.toInt();
          final col = left + 40;
          final rule = px.firstY(col, top + 1, (c) => c == line);
          expect(rule - top, head, reason: 'head including its rule');
          final contentY = px.firstY(col, rule + 1, (c) => c == accent);
          expect(contentY - (rule + 1), padding, reason: 'padding above');
          final row = contentY + 5;
          final contentX = px.firstX(row, left, (c) => c == accent);
          expect(contentX - (left + 1), padding, reason: 'padding start');
        });

        testWidgets('no shadow: the ring around the panel is all page', (
          tester,
        ) async {
          final r = await _scene(tester, size, theme);
          expect(_ringStains(r.px, r.panel, bg), 0);
        });

        testWidgets('control: the same scan sees a floating-layer shadow', (
          tester,
        ) async {
          final r = await _scene(tester, size, theme, floatingShadow: true);
          expect(_ringStains(r.px, r.panel, bg), greaterThan(0));
        });
      });
    });
  });
}
