// ZOD-NAV-001: ZodiannTopBar against the design reference. The same feature
// extractor runs on the rendered PNGs (the Square screen's top bar, desktop
// at DPR 1 and phone at DPR 2, en and he) and on our bar rendered at the same
// size over `bg` with the real fonts:
//
// - the bottom rule's row;
// - "ink runs": column ranges where any row above the rule differs from the
//   bar's background pixel by more than a small threshold, merging gaps
//   narrower than 6 logical px (letter and word spacing). Runs are, from the
//   start: the hamburger icon, the titles, then each action.
//
// The hamburger and action runs must match at both edges and the titles run
// at its start edge, within 1 logical px (1 device px at DPR 1, 2 at DPR 2).
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/load_bundled_fonts.dart';

final class _Image {
  _Image(this.width, this.height, this.rgba);
  final int width;
  final int height;
  final ByteData rgba;

  int _c(int x, int y, int k) => rgba.getUint8((y * width + x) * 4 + k);

  /// The largest per-channel difference between (x, y) and (bx, by).
  int diff(int x, int y, int bx, int by) =>
      [for (var k = 0; k < 3; k++) (_c(x, y, k) - _c(bx, by, k)).abs()]
          .reduce(math.max);
}

Future<_Image> _fromImage(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return _Image(image.width, image.height, data!);
}

/// The ink threshold: any channel more than this away from the background.
const _threshold = 8;

/// The features of a bar image whose rows [0, rows) are the bar.
({int rule, List<(int, int)> runs}) _features(
  _Image img,
  int rows,
  double dpr, {
  required int ruleColumn,
}) {
  // Background sample: inside the bar, clear of every control.
  const bx = 0, by = 1;
  var rule = -1;
  for (var y = rows ~/ 2; y < rows; y++) {
    if (img.diff(ruleColumn, y, bx, by) > _threshold) {
      rule = y;
      break;
    }
  }
  expect(rule, greaterThan(0), reason: 'no bottom rule');
  final inkColumns = <int>[
    for (var x = 0; x < img.width; x++)
      if (Iterable<int>.generate(rule)
          .any((y) => img.diff(x, y, bx, by) > _threshold))
        x,
  ];
  final mergeGap = (6 * dpr).round();
  final runs = <(int, int)>[];
  for (final x in inkColumns) {
    if (runs.isNotEmpty && x - runs.last.$2 <= mergeGap) {
      runs[runs.length - 1] = (runs.last.$1, x);
    } else {
      runs.add((x, x));
    }
  }
  return (rule: rule, runs: runs);
}

Future<_Image> _decode(String path, int rows) async {
  final bytes = File('../../design-reference/zodiann/$path').readAsBytesSync();
  final codec = await ui.instantiateImageCodec(bytes);
  final image = (await codec.getNextFrame()).image;
  final full = await _fromImage(image);
  image.dispose();
  return _Image(full.width, rows, full.rgba);
}

final _key = GlobalKey();

Future<_Image> _render(
  WidgetTester tester, {
  required double width,
  required double dpr,
  required bool hebrew,
  required String title,
  required String subtitle,
  required String save,
  required String export,
}) async {
  final height = ZodiannTopBar.heightFor(width);
  tester.view.physicalSize = Size(width * dpr, height * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
  final theme = hebrew
      ? withZodiannScript(ZodiannTheme.graphite, ZodiannScript.hebrew)
      : ZodiannTheme.graphite;
  final bg = theme.extension<ZodiannSurfaces>()!.bg;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Directionality(
        textDirection: hebrew ? TextDirection.rtl : TextDirection.ltr,
        child: RepaintBoundary(
          key: _key,
          child: ColoredBox(
            color: bg,
            child: ZodiannTopBar(
              title: title,
              subtitle: subtitle,
              menuLabel: 'menu',
              onMenuPressed: () {},
              actions: [
                ZodiannTopBarAction(
                  icon: ZodiannIcons.save,
                  label: save,
                  onPressed: () {},
                ),
                ZodiannTopBarAction(
                  icon: ZodiannIcons.download,
                  label: export,
                  variant: ZodiannButtonVariant.primary,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_key));
  late _Image img;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: dpr);
    img = await _fromImage(image);
    image.dispose();
  });
  return img;
}

typedef _Case = ({
  String name,
  String png,
  double width,
  double dpr,
  bool hebrew,
  String title,
  String subtitle,
  String save,
  String export,
});

const _cases = <_Case>[
  (
    name: 'desktop en',
    png: 'screens/02-square-of-nine_dates_desktop_en_dark.png',
    width: 1440,
    dpr: 1,
    hebrew: false,
    title: 'Gann Square of Nine',
    subtitle: 'Spiral, angles and highlights',
    save: 'Save',
    export: 'Export to Excel',
  ),
  (
    name: 'desktop he',
    png: 'screens/02-square-of-nine_dates_desktop_he_dark.png',
    width: 1440,
    dpr: 1,
    hebrew: true,
    title: 'ריבוע התשע של גאן',
    subtitle: 'ספירלה, זוויות והדגשות',
    save: 'שמירה',
    export: 'ייצוא לאקסל',
  ),
  (
    name: 'phone en',
    png: 'responsive/mobile/square-of-nine_datetime_mobile_en_dark.png',
    width: 390,
    dpr: 2,
    hebrew: false,
    title: 'Gann Square of Nine',
    subtitle: 'Spiral, angles and highlights',
    save: 'Save',
    export: 'Export to Excel',
  ),
  (
    name: 'phone he',
    png: 'responsive/mobile/square-of-nine_datetime_mobile_he_dark.png',
    width: 390,
    dpr: 2,
    hebrew: true,
    title: 'ריבוע התשע של גאן',
    subtitle: 'ספירלה, זוויות והדגשות',
    save: 'שמירה',
    export: 'ייצוא לאקסל',
  ),
];

void main() {
  setUpAll(loadBundledFonts);

  test('the extractor reads the known desktop en values off the PNG', () async {
    final png = await _decode(_cases.first.png, 64);
    final f = _features(png, 64, 1, ruleColumn: 700);
    expect(f.rule, 63);
    expect(f.runs.first, (27, 42), reason: 'hamburger ink');
    expect(f.runs[1].$1, 70, reason: 'title start');
    expect(f.runs[f.runs.length - 2], (1164, 1251), reason: 'Save box');
    expect(f.runs.last, (1260, 1415), reason: 'Export box');
  });

  for (final c in _cases) {
    testWidgets('${c.name} matches the reference', (tester) async {
      final height = ZodiannTopBar.heightFor(c.width);
      final rows = (height * c.dpr).round();
      late _Image png;
      await tester.runAsync(() async => png = await _decode(c.png, rows));
      final ours = await _render(
        tester,
        width: c.width,
        dpr: c.dpr,
        hebrew: c.hebrew,
        title: c.title,
        subtitle: c.subtitle,
        save: c.save,
        export: c.export,
      );
      expect(ours.width, png.width);
      // A column clear of the titles and the actions, mirrored in Hebrew.
      final clear = ((c.width >= 700 ? 700 : 260) * c.dpr).round();
      final ruleColumn = c.hebrew ? png.width - 1 - clear : clear;
      final want = _features(png, rows, c.dpr, ruleColumn: ruleColumn);
      final got = _features(ours, rows, c.dpr, ruleColumn: ruleColumn);
      final tol = c.dpr;

      expect(got.rule, closeTo(want.rule, tol), reason: 'bottom rule');
      expect(
        got.runs.length,
        want.runs.length,
        reason: 'runs: ours ${got.runs} vs reference ${want.runs}',
      );
      // From the start side: hamburger, titles, actions.
      final wantRuns = c.hebrew ? want.runs.reversed.toList() : want.runs;
      final gotRuns = c.hebrew ? got.runs.reversed.toList() : got.runs;
      for (var i = 0; i < wantRuns.length; i++) {
        final (wl, wr) = wantRuns[i];
        final (gl, gr) = gotRuns[i];
        final label = i == 0
            ? 'hamburger'
            : i == 1
            ? 'titles'
            : 'action ${i - 1}';
        if (i == 1) {
          // The titles' start edge only (text width varies with rasterising).
          if (c.hebrew) {
            expect(gr, closeTo(wr, tol), reason: '$label start');
          } else {
            expect(gl, closeTo(wl, tol), reason: '$label start');
          }
        } else {
          expect(
            gl,
            closeTo(wl, tol),
            reason: '$label left: ${gotRuns[i]} vs ${wantRuns[i]}',
          );
          expect(
            gr,
            closeTo(wr, tol),
            reason: '$label right: ${gotRuns[i]} vs ${wantRuns[i]}',
          );
        }
      }
    });
  }
}
