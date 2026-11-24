// ZOD-UI-008 criterion 1: the "Ephemeris source" block of the settings
// screens (design-reference/zodiann/screens/04-settings_desktop_{en_dark,
// he_dark,he_light}.png) against ZodiannRadioList, measured by the same code
// (test/support/others_features.dart) on the screen and on a render. The
// component sheet has no radio list, so the settings screens are the only
// visual source (see test/fixtures/radio/README.md).
//
// The screens are 1x. The block is 514 px wide (English x 751..1265, Hebrew
// x 175..689); dot boxes (18 x 18) measured once from the PNGs:
//   English dark   tops 707, 745, 784 at x 751
//   Hebrew dark    tops 707, 745, 784 at x 671 (right edge 689)
//   Hebrew light   the same as Hebrew dark
// The mock's rows are about 38.3 px apart; the widget's are 44 (owner
// decision O1, 2026-11-24: MASTER section 14's 44 px target; the 8 px gap
// between targets is waived), so every comparison is relative to the row's
// own centre (the dot's centre) and to the block's own edge, never to the
// absolute vertical position.
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/load_bundled_fonts.dart';
import '../support/others_features.dart';
import '../support/pixels.dart';
import '../support/tag_features.dart' show decodeDesignPng;

const _blockWidth = 514;

typedef _Case = ({
  String name,
  String screen,
  bool rtl,
  ThemeData theme,
  int left,
  List<int> dotTops,
  int bgX,
  int bgY,
  List<ZodiannRadioOption<String>> options,
});

const _enOptions = [
  ZodiannRadioOption(
    value: 'files',
    label: 'Swiss Ephemeris, data files',
    badge: 'Recommended',
  ),
  ZodiannRadioOption(
    value: 'moshier',
    label: 'Swiss Ephemeris, built-in (Moshier)',
  ),
  ZodiannRadioOption(
    value: 'engine',
    label: 'astronomy-engine',
    badge: 'Backup',
  ),
];

const _heOptions = [
  ZodiannRadioOption(
    value: 'files',
    label: 'Swiss Ephemeris, קובצי נתונים',
    badge: 'מומלץ',
  ),
  ZodiannRadioOption(
    value: 'moshier',
    label: 'Swiss Ephemeris, מובנה (Moshier)',
  ),
  ZodiannRadioOption(
    value: 'engine',
    label: 'astronomy-engine',
    badge: 'גיבוי',
  ),
];

final List<_Case> _cases = [
  (
    name: 'English dark',
    screen: 'screens/04-settings_desktop_en_dark.png',
    rtl: false,
    theme: ZodiannTheme.graphite,
    left: 751,
    dotTops: const [707, 745, 784],
    bgX: 740,
    bgY: 735,
    options: _enOptions,
  ),
  (
    name: 'Hebrew dark',
    screen: 'screens/04-settings_desktop_he_dark.png',
    rtl: true,
    theme: withZodiannScript(ZodiannTheme.graphite, ZodiannScript.hebrew),
    left: 175,
    dotTops: const [707, 745, 784],
    bgX: 700,
    bgY: 735,
    options: _heOptions,
  ),
  (
    name: 'Hebrew light',
    screen: 'screens/04-settings_desktop_he_light.png',
    rtl: true,
    theme: withZodiannScript(ZodiannTheme.porcelain, ZodiannScript.hebrew),
    left: 175,
    dotTops: const [707, 745, 784],
    bgX: 700,
    bgY: 735,
    options: _heOptions,
  ),
];

/// What one row looks like, relative to the block's edges and its own centre.
final class _Row {
  const _Row({
    required this.dot,
    required this.dotCentreY,
    required this.label,
    required this.badge,
    required this.selectedRing,
    required this.offRing,
    required this.hole,
  });

  final PixelBox dot;
  final int dotCentreY;
  final PixelBox label;
  final PixelBox? badge;
  final int selectedRing;
  final int offRing;
  final int hole;
}

/// Measures the row whose dot centre is on [cy]; [left] is the block's left
/// edge in the pixel space of [at].
_Row _measureRow(
  PixelAt at, {
  required int left,
  required int cy,
  required bool rtl,
  required int bg,
}) {
  final right = left + _blockWidth;
  final y0 = cy - 14;
  final y1 = cy + 14;
  final dot = rtl
      ? findBox(at, right - 22, y0, right + 3, y1, bg, tolerance: 12)
      : findBox(at, left - 3, y0, left + 22, y1, bg, tolerance: 12);
  expect(dot, isNotNull, reason: 'a dot at $cy');
  final label = rtl
      ? findInk(at, left + 100, y0, right - 24, y1, bg)
      : findInk(at, left + 24, y0, right - 100, y1, bg);
  expect(label, isNotNull, reason: 'a label at $cy');
  final badge = rtl
      ? findInk(at, left - 2, y0, left + 100, y1, bg)
      : findInk(at, right - 100, y0, right + 2, y1, bg);
  final edge = rtl ? dot!.right - 3 : dot!.left + 2;
  final offEdge = rtl ? dot.right - 1 : dot.left;
  final centre = rtl ? dot.right - 9 : dot.left + 9;
  return _Row(
    dot: dot,
    dotCentreY: (dot.top + dot.bottom) ~/ 2,
    label: label!.box,
    badge: badge?.box,
    selectedRing: at(edge, (dot.top + dot.bottom) ~/ 2),
    offRing: at(offEdge, (dot.top + dot.bottom) ~/ 2),
    hole: at(centre, (dot.top + dot.bottom) ~/ 2),
  );
}

/// A box's distance from the block's start edge (left in English, right in
/// Hebrew), and from its end edge.
int _fromStart(PixelBox b, int left, bool rtl) =>
    rtl ? left + _blockWidth - b.right : b.left - left;

int _fromEnd(PixelBox b, int left, bool rtl) =>
    rtl ? b.left - left : left + _blockWidth - b.right;

void _near(num got, num want, num tolerance, String what) {
  expect(
    (got - want).abs(),
    lessThanOrEqualTo(tolerance),
    reason: '$what: $got vs screen $want',
  );
}

Future<PixelAt> _render(
  WidgetTester tester,
  _Case c,
  int bg,
  String selected,
) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: c.theme,
      home: Directionality(
        textDirection: c.rtl ? TextDirection.rtl : TextDirection.ltr,
        child: Material(
          type: MaterialType.transparency,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: Color(bg),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: _blockWidth.toDouble(),
                    child: ZodiannRadioList<String>(
                      options: c.options,
                      value: selected,
                      onChanged: (_) {},
                      semanticLabel: 'Ephemeris source',
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
  await tester.pumpAndSettle();
  final px = await Pixels.capture(
    tester,
    tester.renderObject<RenderRepaintBoundary>(find.byKey(key)),
  );
  return px.argb;
}

void main() {
  setUpAll(loadBundledFonts);

  for (final c in _cases) {
    testWidgets('${c.name}: the radio list matches the settings screen', (
      tester,
    ) async {
      final img = await tester.runAsync(() => decodeDesignPng(c.screen));
      final screen = img!.argb;
      final bg = screen(c.bgX, c.bgY);

      final want = [
        for (final top in c.dotTops)
          _measureRow(screen, left: c.left, cy: top + 9, rtl: c.rtl, bg: bg),
      ];
      final px = await _render(tester, c, bg, 'files');
      final got = [
        for (var i = 0; i < 3; i++)
          _measureRow(px, left: 24, cy: 24 + 44 * i + 22, rtl: c.rtl, bg: bg),
      ];

      for (var i = 0; i < 3; i++) {
        final g = got[i];
        final w = want[i];
        final row = '${c.name} row $i';
        // The dot: 18 x 18, on the start edge, on the row's centre.
        expect(g.dot.width, 18, reason: '$row dot width');
        expect(g.dot.height, 18, reason: '$row dot height');
        _near(
          _fromStart(g.dot, 24, c.rtl),
          _fromStart(w.dot, c.left, c.rtl),
          1,
          '$row dot start',
        );
        _near(g.dotCentreY - (24 + 44 * i + 22), 0, 1, '$row dot centre');
        // Ring colours: a 5 px accent ring and an 8 px hole when selected, a
        // 1.5 px line ring otherwise (anti-aliasing differs a little).
        if (i == 0) {
          expect(
            channelDistance(g.selectedRing, w.selectedRing),
            lessThan(8),
            reason:
                '$row selected ring '
                '${g.selectedRing.toRadixString(16)} vs '
                '${w.selectedRing.toRadixString(16)}',
          );
          expect(
            channelDistance(g.hole, w.hole),
            lessThan(8),
            reason: '$row hole',
          );
        } else {
          expect(
            channelDistance(g.offRing, w.offRing),
            lessThan(24),
            reason:
                '$row off ring '
                '${g.offRing.toRadixString(16)} vs '
                '${w.offRing.toRadixString(16)}',
          );
        }
        // The label: 30 px from the start edge, 13 px of ink height, on the
        // row's centre (relative to the dot).
        _near(
          _fromStart(g.label, 24, c.rtl),
          _fromStart(w.label, c.left, c.rtl),
          2,
          '$row label start',
        );
        // A mixed Hebrew and Latin label is wider on the screen: Chrome sets
        // the comma between the runs with about 8 px of space on each side,
        // which Flutter's paragraph does not (same visual order; the
        // component draws the caller's text). Width is compared for the
        // Latin-only labels; the start edge, height and centre for all.
        if (!RegExp(r'[֐-׿]').hasMatch(c.options[i].label)) {
          _near(g.label.width, w.label.width, 4, '$row label width');
        }
        _near(g.label.height, w.label.height, 2, '$row label height');
        _near(
          (g.label.top + g.label.bottom) / 2 - g.dotCentreY,
          (w.label.top + w.label.bottom) / 2 - w.dotCentreY,
          2,
          '$row label centre',
        );
        // The badge: on the end edge.
        expect(g.badge == null, w.badge == null, reason: '$row badge exists');
        final gb = g.badge;
        final wb = w.badge;
        if (gb != null && wb != null) {
          _near(
            _fromEnd(gb, 24, c.rtl),
            _fromEnd(wb, c.left, c.rtl),
            2,
            '$row badge end',
          );
          _near(gb.width, wb.width, 3, '$row badge width');
          _near(
            (gb.top + gb.bottom) / 2 - g.dotCentreY,
            (wb.top + wb.bottom) / 2 - w.dotCentreY,
            2,
            '$row badge centre',
          );
        }
      }
    });
  }
}
