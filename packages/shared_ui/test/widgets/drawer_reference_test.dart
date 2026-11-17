// ZOD-NAV-002: ZodiannDrawer against the design references, in both
// languages and both themes, at the desktop (1440 @1) and phone (390 @2)
// sizes.
//
// Oracles:
// - dark: the designer's own PNGs (screens/00-navigation-drawer_* and
//   responsive/mobile/navigation-drawer_*);
// - light: PNGs *generated* with headless Chrome from kit.css by
//   tool/drawer/render_drawer_references.dart. These are generated visual
//   references, NOT designer-provided assets; kit.css and MASTER.md remain
//   authoritative and the images never override them. The generated dark
//   images are also compared with the designer's dark ones, which proves the
//   generator reproduces the designer's renders.
//
// One extractor (test/support/drawer_features.dart) reads both the PNGs and
// our rendered panel: the inner-edge line, the header and footer rules, the
// active fill and bar, and each line of ink. Run with
// ZODIANN_DRAWER_CALIBRATE=1 to print the measured differences instead of
// asserting them.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/drawer_features.dart';
import '../support/load_bundled_fonts.dart';

final _calibrate = Platform.environment['ZODIANN_DRAWER_CALIBRATE'] == '1';

const _designer = '../../design-reference/zodiann';
const _fixtures = 'test/fixtures/drawer';

// Ceilings, in logical px unless noted. Calibrated on 2026-11-17 (Chrome
// 157, ZODIANN_DRAWER_CALIBRATE=1); the record is in
// docs/plans/ZOD-NAV-002-side-navigation-drawer.md.
typedef _Tol = ({
  double position, // edges, rules, fill and bar: top, left, right
  double bottom, // text-height-driven bottoms: fill, bar, footer rule
  double textX, // text and icon extents across (font rasterisation)
  double textY, // text rows down the list (line-height rounding drift)
  double mean, // per-pixel mean over the panel (0-255)
});

/// Our widget against a reference. Measured worst: positions 1, bottoms 1.5
/// (Flutter rounds the lines of text to whole pixels: the name 20 for 20.3,
/// a description line 17 for 17.4), text x 2, text rows 5.0 by the last list
/// item (that rounding accumulates over 5 names and 7 description lines),
/// mean 4.07.
const _widgetTol = (
  position: 1.0,
  bottom: 2.0,
  textX: 3.0,
  textY: 6.0,
  mean: 9.0,
);

/// The generator against the designer's own render of the same page: both
/// are Chrome, so they must agree tightly. Measured worst: 0.5 logical px,
/// mean 1.2.
const _pipelineTol = (
  position: 1.0,
  bottom: 1.0,
  textX: 2.0,
  textY: 2.0,
  mean: 3.0,
);

typedef _Case = ({
  String name,
  String reference,
  bool generated,
  bool dark,
  bool he,
  bool phone,
});

String _designerPng(bool he, bool phone) => phone
    ? '$_designer/responsive/mobile/navigation-drawer_mobile_${he ? 'he' : 'en'}_dark.png'
    : '$_designer/screens/00-navigation-drawer_desktop_${he ? 'he' : 'en'}_dark.png';

String _generatedPng(bool dark, bool he, bool phone) =>
    '$_fixtures/generated_${dark ? 'dark' : 'light'}_${he ? 'he' : 'en'}_${phone ? 'mobile' : 'desktop'}.png';

final _cases = <_Case>[
  for (final phone in [false, true])
    for (final he in [false, true]) ...[
      (
        name:
            'designer dark ${he ? 'he' : 'en'} ${phone ? 'phone' : 'desktop'}',
        reference: _designerPng(he, phone),
        generated: false,
        dark: true,
        he: he,
        phone: phone,
      ),
      (
        name:
            'generated light ${he ? 'he' : 'en'} ${phone ? 'phone' : 'desktop'}',
        reference: _generatedPng(false, he, phone),
        generated: true,
        dark: false,
        he: he,
        phone: phone,
      ),
    ],
];

int _dpr(bool phone) => phone ? 2 : 1;

/// The panel box of a full reference image: 320 logical px wide, full height,
/// on the start edge (the screen is 1440 wide, or 390 on the phone).
Rgba _panelOf(Rgba full, {required bool he, required bool phone}) {
  final dpr = _dpr(phone);
  final screen = (phone ? 390 : 1440) * dpr;
  final panel = 320 * dpr;
  final height = (phone ? 844 : 900) * dpr;
  return full.crop(he ? screen - panel : 0, 0, panel, height);
}

Future<Rgba> _loadPanel(
  WidgetTester tester,
  String path, {
  required bool he,
  required bool phone,
}) async {
  late Rgba full;
  await tester.runAsync(() async {
    full = await decodePng(File(path).readAsBytesSync());
  });
  return _panelOf(full, he: he, phone: phone);
}

const _enNames = [
  'Zodiac wheel',
  'Gann Square of Nine',
  'Saved squares',
  'Settings',
  'About and sources',
];
const _enDescs = [
  'Planet positions, aspects and degree crossings',
  'Numbers, days or 4-hour blocks on the spiral',
  'Return to squares you named',
  'Language, theme, orbs, defaults',
  'Computation sources and method',
];
const _heNames = [
  'גלגל המזלות',
  'ריבוע התשע של גאן',
  'ריבועים שמורים',
  'הגדרות',
  'אודות ומקורות',
];
const _heDescs = [
  'מיקומי כוכבים, היבטים ומעברי מעלות',
  'מספרים, ימים או בלוקים של 4 שעות בספירלה',
  'חזרה לריבועים ששמרת בשם',
  'שפה, ערכת נושא, אורבים',
  'מקורות החישוב והשיטה',
];

final _boundary = GlobalKey();

Future<Rgba> _renderPanel(
  WidgetTester tester, {
  required bool dark,
  required bool he,
  required bool phone,
}) async {
  final dpr = _dpr(phone).toDouble();
  final screenW = phone ? 390.0 : 1440.0;
  final screenH = phone ? 844.0 : 900.0;
  tester.view.physicalSize = Size(screenW * dpr, screenH * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
  final names = he ? _heNames : _enNames;
  final descs = he ? _heDescs : _enDescs;
  ZodiannDrawerItem item(int i) => ZodiannDrawerItem(
    icon: [
      ZodiannIcons.wheel,
      ZodiannIcons.grid,
      ZodiannIcons.folder,
      ZodiannIcons.sliders,
      ZodiannIcons.info,
    ][i],
    name: names[i],
    description: descs[i],
    selected: i == 0,
    onTap: () {},
  );
  var theme = dark ? ZodiannTheme.graphite : ZodiannTheme.porcelain;
  if (he) theme = withZodiannScript(theme, ZodiannScript.hebrew);
  final drawer = RepaintBoundary(
    key: _boundary,
    child: ZodiannDrawer(
      wordmark: 'Zodiann',
      groups: [
        ZodiannDrawerGroup(
          label: he ? 'ניתוח' : 'Analysis',
          items: [item(0), item(1)],
        ),
        ZodiannDrawerGroup(
          label: he ? 'ספרייה ואפליקציה' : 'Library and app',
          items: [item(2), item(3), item(4)],
        ),
      ],
      closeLabel: he ? 'סגירת תפריט' : 'Close menu',
      onClose: () {},
      versionLabel: he ? 'גרסה 1.0.0' : 'Version 1.0.0',
      offlineLabel: he
          ? 'כל הנתונים נשארים במכשיר'
          : 'All data stays on this device',
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      builder: he
          ? (context, child) =>
                Directionality(textDirection: TextDirection.rtl, child: child!)
          : null,
      home: Align(alignment: AlignmentDirectional.centerStart, child: drawer),
    ),
  );
  // Decode the logo before capturing: images decode outside fake-async.
  final image = tester.widget<Image>(find.byType(Image));
  await tester.runAsync(
    () => precacheImage(image.image, tester.element(find.byType(Image))),
  );
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  late Rgba out;
  await tester.runAsync(() async {
    final img = await boundary.toImage(pixelRatio: dpr);
    out = await fromUiImage(img);
    img.dispose();
  });
  return out;
}

/// Differences in device px (positions) between two feature sets.
typedef _Deltas = ({
  int edge,
  int headRule,
  int footRule,
  int fillTop,
  int fillBottom,
  int fillLeft,
  int fillRight,
  int barLeft,
  int barRight,
  int barTop,
  int barBottom,
  int textBandCount,
  int sideBandCount,
  int textX,
  int textY,
  int sideX,
  int sideY,
});

_Deltas _compare(DrawerFeatures a, DrawerFeatures b) {
  int d(int x, int y) => (x - y).abs();
  // Worst horizontal and vertical difference over paired bands.
  (int, int) worst(List<Band> p, List<Band> q) {
    var x = 0, y = 0;
    final n = p.length < q.length ? p.length : q.length;
    for (var i = 0; i < n; i++) {
      for (final v in [d(p[i].left, q[i].left), d(p[i].right, q[i].right)]) {
        if (v > x) x = v;
      }
      for (final v in [d(p[i].top, q[i].top), d(p[i].bottom, q[i].bottom)]) {
        if (v > y) y = v;
      }
    }
    return (x, y);
  }

  final (textX, textY) = worst(a.textBands, b.textBands);
  final (sideX, sideY) = worst(a.sideBands, b.sideBands);
  return (
    edge: d(a.edgeWidth, b.edgeWidth),
    headRule: d(a.headRule, b.headRule),
    footRule: d(a.footRule, b.footRule),
    fillTop: d(a.fillTop, b.fillTop),
    fillBottom: d(a.fillBottom, b.fillBottom),
    fillLeft: d(a.fillLeft, b.fillLeft),
    fillRight: d(a.fillRight, b.fillRight),
    barLeft: d(a.barLeft, b.barLeft),
    barRight: d(a.barRight, b.barRight),
    barTop: d(a.barTop, b.barTop),
    barBottom: d(a.barBottom, b.barBottom),
    textBandCount: d(a.textBands.length, b.textBands.length),
    sideBandCount: d(a.sideBands.length, b.sideBands.length),
    textX: textX,
    textY: textY,
    sideX: sideX,
    sideY: sideY,
  );
}

void _expectWithin(
  String name,
  _Deltas dl,
  double meanDiff,
  int dpr,
  _Tol tol,
) {
  if (_calibrate) {
    // ignore: avoid_print
    print('CAL $name: $dl mean=${meanDiff.toStringAsFixed(3)}');
    return;
  }
  final pos = tol.position * dpr;
  final bottom = tol.bottom * dpr;
  expect(dl.edge, 0, reason: '$name edge width');
  expect(dl.headRule, lessThanOrEqualTo(pos), reason: '$name header rule');
  expect(dl.footRule, lessThanOrEqualTo(bottom), reason: '$name footer rule');
  expect(dl.fillTop, lessThanOrEqualTo(pos), reason: '$name fill top');
  expect(dl.fillBottom, lessThanOrEqualTo(bottom), reason: '$name fill bottom');
  expect(dl.fillLeft, lessThanOrEqualTo(pos), reason: '$name fill left');
  expect(dl.fillRight, lessThanOrEqualTo(pos), reason: '$name fill right');
  expect(dl.barLeft, lessThanOrEqualTo(pos), reason: '$name bar left');
  expect(dl.barRight, lessThanOrEqualTo(pos), reason: '$name bar right');
  expect(dl.barTop, lessThanOrEqualTo(pos), reason: '$name bar top');
  expect(dl.barBottom, lessThanOrEqualTo(bottom), reason: '$name bar bottom');
  expect(dl.textBandCount, 0, reason: '$name text band count');
  expect(dl.sideBandCount, 0, reason: '$name side band count');
  expect(dl.textX, lessThanOrEqualTo(tol.textX * dpr), reason: '$name text x');
  expect(dl.textY, lessThanOrEqualTo(tol.textY * dpr), reason: '$name text y');
  expect(dl.sideX, lessThanOrEqualTo(tol.textX * dpr), reason: '$name side x');
  expect(dl.sideY, lessThanOrEqualTo(tol.textY * dpr), reason: '$name side y');
  expect(meanDiff, lessThanOrEqualTo(tol.mean), reason: '$name mean');
}

void main() {
  setUpAll(loadBundledFonts);

  testWidgets('the extractor reads the known designer values (self-check)', (
    tester,
  ) async {
    final desktop = await _loadPanel(
      tester,
      _designerPng(false, false),
      he: false,
      phone: false,
    );
    final f = extractDrawerFeatures(desktop, dpr: 1, rtl: false);
    expect(f.edgeWidth, 1, reason: 'inner-edge border column');
    expect(f.headRule, 75, reason: 'header rule row');
    expect(f.fillLeft, 12);
    expect(f.barLeft, 12);
    expect(f.barRight - f.barLeft + 1, 3, reason: 'active bar width');

    final phone = await _loadPanel(
      tester,
      _designerPng(true, true),
      he: true,
      phone: true,
    );
    final p = extractDrawerFeatures(phone, dpr: 2, rtl: true);
    expect(p.edgeWidth, 2);
    expect(p.headRule, 150);
    // 3 logical px at @2: 6 device px, 5 above the ink threshold.
    expect(p.barRight - p.barLeft + 1, inInclusiveRange(5, 6));
  });

  for (final c in _cases.where((c) => c.dark)) {
    testWidgets('the generator reproduces the designer image: ${c.name}', (
      tester,
    ) async {
      final designer = await _loadPanel(
        tester,
        c.reference,
        he: c.he,
        phone: c.phone,
      );
      final generated = await _loadPanel(
        tester,
        _generatedPng(true, c.he, c.phone),
        he: c.he,
        phone: c.phone,
      );
      final dpr = _dpr(c.phone);
      final a = extractDrawerFeatures(designer, dpr: dpr, rtl: c.he);
      final b = extractDrawerFeatures(generated, dpr: dpr, rtl: c.he);
      _expectWithin(
        'pipeline ${c.name}',
        _compare(a, b),
        meanAbsDiff(designer, generated),
        dpr,
        _pipelineTol,
      );
    });
  }

  for (final c in _cases) {
    testWidgets('ZodiannDrawer matches the reference: ${c.name}', (
      tester,
    ) async {
      final reference = await _loadPanel(
        tester,
        c.reference,
        he: c.he,
        phone: c.phone,
      );
      final ours = await _renderPanel(
        tester,
        dark: c.dark,
        he: c.he,
        phone: c.phone,
      );
      expect(
        (ours.width, ours.height),
        (reference.width, reference.height),
        reason: 'the panel is the same size',
      );
      final dpr = _dpr(c.phone);
      final a = extractDrawerFeatures(reference, dpr: dpr, rtl: c.he);
      final b = extractDrawerFeatures(ours, dpr: dpr, rtl: c.he);
      if (_calibrate) {
        // ignore: avoid_print
        print(
          'CAL bands ${c.name}: text ${a.textBands.length}/${b.textBands.length} side ${a.sideBands.length}/${b.sideBands.length}',
        );
      }
      _expectWithin(
        c.name,
        _compare(a, b),
        meanAbsDiff(reference, ours),
        dpr,
        _widgetTol,
      );
    });
  }

  testWidgets('the active name is accent-strong and inactive names are text', (
    tester,
  ) async {
    for (final c in _cases) {
      final dpr = _dpr(c.phone);
      final theme = c.dark ? ZodiannTheme.graphite : ZodiannTheme.porcelain;
      final s = theme.extension<ZodiannSurfaces>()!;
      final strong = s.accentStrong.toARGB32() & 0xFFFFFF;
      final plain = s.text.toARGB32() & 0xFFFFFF;

      Future<(int, int)> measure(Rgba panel) async {
        final f = extractDrawerFeatures(panel, dpr: dpr, rtl: c.he);
        // The name's rows: 12 below the item top, 20 high; the second item
        // starts 2 below the fill.
        final y0 = f.fillTop + 12 * dpr;
        final second = f.fillBottom + 2 * dpr;
        int extreme(int top) => extremePixel(
          panel,
          rtl: c.he,
          y0: top + 12 * dpr,
          y1: top + 12 * dpr + 18 * dpr,
          sx0: 30 * dpr,
          sx1: 300 * dpr,
          brightest: c.dark,
        );
        return (extreme(y0 - 12 * dpr), extreme(second));
      }

      int dist(int a, int b) => colourDiff(a, b);
      void check(String what, int active, int inactive, {required bool exact}) {
        if (exact) {
          expect(
            dist(active, strong),
            lessThanOrEqualTo(1),
            reason: '$what active name is accent-strong',
          );
          expect(
            dist(inactive, plain),
            lessThanOrEqualTo(1),
            reason: '$what inactive name is text',
          );
        } else {
          expect(
            dist(active, strong),
            lessThan(dist(active, plain)),
            reason: '$what active name nearer accent-strong than text',
          );
          expect(
            dist(inactive, plain),
            lessThan(dist(inactive, strong)),
            reason: '$what inactive name nearer text than accent-strong',
          );
        }
      }

      if (_calibrate) continue;
      final reference = await _loadPanel(
        tester,
        c.reference,
        he: c.he,
        phone: c.phone,
      );
      final (refActive, refInactive) = await measure(reference);
      // Exact on the designer's dark PNGs; nearest token elsewhere (the two
      // light tokens are only 11 levels apart, and hinting-off text may not
      // reach a fully inked pixel).
      check('${c.name} PNG', refActive, refInactive, exact: !c.generated);
      final ours = await _renderPanel(
        tester,
        dark: c.dark,
        he: c.he,
        phone: c.phone,
      );
      final (ourActive, ourInactive) = await measure(ours);
      // Light theme: the widget's darkest pixel is ~37 levels from either
      // token (unhinted 14 px text never fully inks) while the two tokens are
      // 11 apart, so a pixel extreme cannot tell them apart; the exact proof
      // for light is drawer_test's accentStrong style and icon assertions.
      if (c.dark) {
        check('${c.name} widget', ourActive, ourInactive, exact: false);
      }
    }
  });

  test('the manifest hashes still match the kit files', () {
    final manifest = jsonDecode(
      File('$_fixtures/manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final hashes = (manifest['sha256'] as Map<String, dynamic>)
        .cast<String, String>();
    expect(hashes, isNotEmpty);
    hashes.forEach((path, hash) {
      final text = File('../../$path')
          .readAsStringSync()
          .replaceAll('\r\n', '\n');
      expect(
        sha256.convert(utf8.encode(text)).toString(),
        hash,
        reason:
            '$path changed: regenerate the references '
            '(fvm dart run tool/drawer/render_drawer_references.dart)',
      );
    });
  });

  test('the README states that the images are generated', () {
    final readme = File('$_fixtures/README.md').readAsStringSync();
    expect(readme, contains('generated visual references'));
    expect(readme, contains('not designer-provided'));
    expect(readme, contains('kit.css'));
  });
}
