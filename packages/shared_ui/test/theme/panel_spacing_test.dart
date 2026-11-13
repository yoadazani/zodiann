// ZOD-UI-003 criterion 2: a panel built from the layout tokens renders with
// MASTER §4's gutter, panel gap, panel padding and head height, measured
// pixel by pixel at desktop (1440) and phone (390) widths, DPR 1.
//
// The render is pixel-aligned, so each measurement is exact. The CSS box is
// border-box: padding is counted inside the panel's 1 px border, and the head
// height includes its 1 px rule.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/token_panel_harness.dart';

final class _Pixels {
  _Pixels(this.width, this.height, this.raw);
  final int width;
  final int height;
  final ByteData raw;

  int argb(int x, int y) {
    final i = (y * width + x) * 4;
    return (raw.getUint8(i + 3) << 24) |
        (raw.getUint8(i) << 16) |
        (raw.getUint8(i + 1) << 8) |
        raw.getUint8(i + 2);
  }

  int firstX(int y, int from, bool Function(int argb) test) {
    for (var x = from; x < width; x++) {
      if (test(argb(x, y))) return x;
    }
    fail('row $y: no match from x $from');
  }

  int firstY(int x, int from, bool Function(int argb) test) {
    for (var y = from; y < height; y++) {
      if (test(argb(x, y))) return y;
    }
    fail('column $x: no match from y $from');
  }
}

void main() {
  final s = graphiteTokens.surfaces;
  final bg = s.bg.toARGB32();
  final lineSoft = s.lineSoft.toARGB32();
  final accent = s.accent.toARGB32();
  bool isBg(int c) => c == bg;
  bool notBg(int c) => c != bg;
  bool isLine(int c) => c == lineSoft;
  bool isAccent(int c) => c == accent;

  final cases = {
    // MASTER §4, typed in: (view, stacked, gutter, gap, padding, head).
    'desktop 1440': (const Size(1440, 900), false, 24, 20, 20, 56),
    'phone 390': (const Size(390, 1200), true, 16, 16, 16, 52),
  };

  cases.forEach((name, entry) {
    final (size, stacked, gutterPx, gapPx, paddingPx, headPx) = entry;
    testWidgets('$name: gutter, padding, gap and head are the tokens', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        Theme(
          data: ZodiannTheme.graphite,
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: TokenPanelHarness(),
          ),
        ),
      );

      final row = tester
          .getCenter(find.byKey(TokenPanelHarness.firstContentKey))
          .dy
          .floor();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(TokenPanelHarness.boundaryKey),
      );
      final dir = Platform.environment['ZODIANN_PANEL_DIR'];
      late _Pixels px;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final raw = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        px = _Pixels(image.width, image.height, raw);
        if (dir != null) {
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$dir/panel_${size.width.toInt()}.png')
              .writeAsBytesSync(png!.buffer.asUint8List());
        }
        image.dispose();
      });

      // Gutter: the first non-bg pixel on the content row is panel A's
      // left border.
      final gutter = px.firstX(row, 0, notBg);
      expect(px.argb(gutter, row), lineSoft, reason: 'left border');
      expect(gutter, equals(gutterPx), reason: 'gutter');

      // Padding: inside the 1 px border, up to the content block.
      final content = px.firstX(row, gutter, isAccent);
      expect(content - (gutter + 1), equals(paddingPx));

      // Head: on a column clear of the 12 px corner radius, from the first
      // pixel inside the top border to the head rule, inclusive.
      final col = gutter + 40;
      final top = px.firstY(col, 0, notBg);
      expect(top, equals(gutterPx), reason: 'top gutter');
      expect(px.argb(col, top), lineSoft, reason: 'top border');
      final rule = px.firstY(col, top + 1, isLine);
      expect(rule - top, equals(headPx), reason: 'head');

      // Gap: the bg run between the two panels' borders.
      final int gapStart;
      final int gapEnd;
      if (!stacked) {
        final afterContent = px.firstX(row, content, (c) => c != accent);
        gapStart = px.firstX(row, afterContent, isBg);
        gapEnd = px.firstX(row, gapStart, notBg);
        expect(px.argb(gapStart - 1, row), lineSoft, reason: 'A right');
        expect(px.argb(gapEnd, row), lineSoft, reason: 'B left');
      } else {
        gapStart = px.firstY(col, rule + 1, isBg);
        gapEnd = px.firstY(col, gapStart, notBg);
        expect(px.argb(col, gapStart - 1), lineSoft, reason: 'A bottom');
        expect(px.argb(col, gapEnd), lineSoft, reason: 'B top');
      }
      expect(gapEnd - gapStart, equals(gapPx), reason: 'gap');
    });
  });
}
