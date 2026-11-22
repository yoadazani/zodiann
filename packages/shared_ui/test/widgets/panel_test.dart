// ZOD-UI-014: ZodiannPanel and ZodiannPanelHead: decoration, head sizing
// (56 / 52 minimum, grows), head placement and wrapping, RTL, text scale,
// semantics and the no-clip default that keeps focus rings visible.
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/load_bundled_fonts.dart';
import '../support/pixels.dart';

const _desktop = Size(1440, 900);
const _phone = Size(390, 1200);
const _margin = 32.0;
const _boundary = Key('panel-test-boundary');
const _probe = Key('probe');
const _lead = Key('lead');
const _end = Key('end');

final _themes = {
  'Graphite': ZodiannTheme.graphite,
  'Porcelain': ZodiannTheme.porcelain,
};

Future<void> _pump(
  WidgetTester tester,
  Widget panel, {
  Size size = _desktop,
  ThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final data = theme ?? ZodiannTheme.graphite;
  await tester.pumpWidget(
    Theme(
      data: data,
      child: Directionality(
        textDirection: direction,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: RepaintBoundary(
              key: _boundary,
              child: ColoredBox(
                color: data.extension<ZodiannSurfaces>()!.bg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(_margin),
                      child: panel,
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
}

Widget _box(Key key, double w, double h) =>
    SizedBox(key: key, width: w, height: h);

Rect _panelRect(WidgetTester t) => t.getRect(find.byType(ZodiannPanel));

double _padding(Size size) =>
    size == _phone ? ZodiannLayout.phone.panelPadding : 20;

/// The head's height, read from where the body's probe starts.
Future<double> _headHeight(
  WidgetTester tester,
  ZodiannPanelHead head, {
  Size size = _desktop,
  double textScale = 1,
}) async {
  await _pump(
    tester,
    ZodiannPanel(head: head, child: _box(_probe, 10, 10)),
    size: size,
    textScale: textScale,
  );
  return tester.getTopLeft(find.byKey(_probe)).dy -
      _panelRect(tester).top -
      ZodiannSize.hairline -
      _padding(size);
}

BoxDecoration _decoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(ZodiannPanel),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

void main() {
  setUpAll(loadBundledFonts);

  _themes.forEach((name, theme) {
    testWidgets('$name: surface fill, 1 px line-soft border, 12 radius, no '
        'shadow', (tester) async {
      final s = theme.extension<ZodiannSurfaces>()!;
      await _pump(
        tester,
        ZodiannPanel(child: _box(_probe, 10, 10)),
        theme: theme,
      );
      final d = _decoration(tester);
      expect(d.color, s.surface);
      expect(d.border, Border.all(color: s.lineSoft, width: 1));
      expect(d.borderRadius, ZodiannRadius.panel);
      expect(d.boxShadow == null || d.boxShadow!.isEmpty, isTrue);
    });
  });

  testWidgets('a head-less panel has no rule and 1 + padding above the child', (
    tester,
  ) async {
    await _pump(tester, ZodiannPanel(child: _box(_probe, 10, 10)));
    final panel = _panelRect(tester);
    final probe = tester.getRect(find.byKey(_probe));
    expect(probe.top - panel.top, 1 + 20);
    expect(probe.left - panel.left, 1 + 20);
    expect(panel.height, 1 + 20 + 10 + 20 + 1, reason: 'no head, no rule');
  });

  testWidgets('bodyPadding zero puts the child flush inside the border', (
    tester,
  ) async {
    await _pump(
      tester,
      ZodiannPanel(bodyPadding: EdgeInsets.zero, child: _box(_probe, 10, 10)),
    );
    final probe = tester.getTopLeft(find.byKey(_probe));
    final panel = _panelRect(tester);
    expect(probe - panel.topLeft, const Offset(1, 1));
  });

  testWidgets('an empty head is exactly 56 / 52 including its rule', (
    tester,
  ) async {
    expect(await _headHeight(tester, const ZodiannPanelHead()), 56);
    expect(
      await _headHeight(tester, const ZodiannPanelHead(), size: _phone),
      52,
    );
  });

  testWidgets('head height: a one-line title keeps the minimum, taller '
      'content grows it', (tester) async {
    expect(
      await _headHeight(tester, const ZodiannPanelHead(title: 'Time')),
      56,
    );
    expect(
      await _headHeight(
        tester,
        const ZodiannPanelHead(title: 'Time'),
        size: _phone,
      ),
      52,
    );
    // padding 16 / 12 either side, the child, and the 1 px rule.
    expect(
      await _headHeight(tester, ZodiannPanelHead(leading: _box(_lead, 50, 40))),
      16 + 40 + 16 + 1,
    );
    expect(
      await _headHeight(
        tester,
        ZodiannPanelHead(leading: _box(_lead, 50, 40)),
        size: _phone,
      ),
      12 + 40 + 12 + 1,
    );
    expect(
      await _headHeight(tester, ZodiannPanelHead(leading: _box(_lead, 50, 72))),
      16 + 72 + 16 + 1,
    );
  });

  for (final size in [_desktop, _phone]) {
    testWidgets('head variants lay out without overflow at ${size.width}', (
      tester,
    ) async {
      final heads = <ZodiannPanelHead>[
        const ZodiannPanelHead(title: 'Time'),
        const ZodiannPanelHead(title: 'Positions', meta: 'Ten bodies'),
        ZodiannPanelHead(
          title: 'Degree crossings',
          meta: '12 in range',
          end: _box(_end, 96, 32),
        ),
        ZodiannPanelHead(leading: _box(_lead, 200, 38)),
      ];
      for (final head in heads) {
        await _pump(
          tester,
          ZodiannPanel(head: head, child: _box(_probe, 10, 10)),
          size: size,
        );
        expect(tester.takeException(), isNull);
      }
    });
  }

  group('head placement', () {
    // Each case builds a head and names its two probes. Returns the rects
    // relative to the panel's left edge, plus the panel's width.
    final longTitle = List.filled(40, 'Wide').join(' ');
    final longHint = List.filled(24, 'hint').join(' ');
    final cases = <String, (Size, ZodiannPanelHead, Finder, Finder)>{
      'a: short start and end share one line': (
        _desktop,
        ZodiannPanelHead(
          leading: _box(_lead, 100, 20),
          end: _box(_end, 96, 20),
        ),
        find.byKey(_lead),
        find.byKey(_end),
      ),
      'b: a long title wraps beside the end': (
        _desktop,
        ZodiannPanelHead(title: longTitle, end: _box(_end, 96, 20)),
        find.text(longTitle),
        find.byKey(_end),
      ),
      'c: on a phone the end drops below a full-width start': (
        _phone,
        ZodiannPanelHead(
          leading: const SizedBox(
            key: _lead,
            width: double.infinity,
            height: 30,
          ),
          end: Text(longHint, key: _end),
        ),
        find.byKey(_lead),
        find.byKey(_end),
      ),
    };

    Future<(Rect, Rect, Rect)> place(
      WidgetTester tester,
      (Size, ZodiannPanelHead, Finder, Finder) c,
      TextDirection direction,
    ) async {
      await _pump(
        tester,
        ZodiannPanel(head: c.$2, child: _box(_probe, 10, 10)),
        size: c.$1,
        direction: direction,
      );
      expect(tester.takeException(), isNull);
      return (_panelRect(tester), tester.getRect(c.$3), tester.getRect(c.$4));
    }

    cases.forEach((name, c) {
      testWidgets(name, (tester) async {
        final pad = _padding(c.$1);
        final (panel, start, end) = await place(tester, c, TextDirection.ltr);
        final inner = Rect.fromLTRB(
          panel.left + 1 + pad,
          panel.top,
          panel.right - 1 - pad,
          panel.bottom,
        );
        expect(start.left, inner.left, reason: 'start at the start edge');
        expect(end.right, inner.right, reason: 'end at the end edge');
        expect(start.right, lessThanOrEqualTo(inner.right));
        if (name.startsWith('c')) {
          expect(end.top, greaterThanOrEqualTo(start.bottom), reason: 'below');
        } else {
          expect(
            end.center.dy,
            inInclusiveRange(start.top, start.bottom),
            reason: 'same line',
          );
          expect(end.left, greaterThanOrEqualTo(start.right + 12 - 0.01));
          if (name.startsWith('b')) {
            expect(start.height, greaterThan(2 * 20), reason: 'title wraps');
          }
        }

        // RTL mirrors every offset: left' = width - (left + w).
        final (rPanel, rStart, rEnd) = await place(
          tester,
          c,
          TextDirection.rtl,
        );
        double mirror(Rect r, Rect p) =>
            p.width - ((r.left - p.left) + r.width);
        expect(rStart.left - rPanel.left, closeTo(mirror(start, panel), 0.01));
        expect(rEnd.left - rPanel.left, closeTo(mirror(end, panel), 0.01));
        expect(rStart.top, start.top);
        expect(rEnd.top, end.top);
      });
    });
  });

  testWidgets('RTL: the title is at the right edge, the end at the left', (
    tester,
  ) async {
    await _pump(
      tester,
      ZodiannPanel(
        head: ZodiannPanelHead(title: 'Time', end: _box(_end, 96, 20)),
        child: _box(_probe, 10, 10),
      ),
      direction: TextDirection.rtl,
    );
    final panel = _panelRect(tester);
    expect(tester.getRect(find.text('Time')).right, panel.right - 1 - 20);
    expect(tester.getRect(find.byKey(_end)).left, panel.left + 1 + 20);
  });

  testWidgets('text scale 2: the head grows without overflow and a long '
      'title wraps in full', (tester) async {
    final one = await _headHeight(
      tester,
      const ZodiannPanelHead(title: 'Time'),
    );
    final two = await _headHeight(
      tester,
      const ZodiannPanelHead(title: 'Time'),
      textScale: 2,
    );
    expect(two, greaterThan(one));
    expect(tester.takeException(), isNull);

    final title = List.filled(40, 'Long').join(' ');
    expect(title.length, greaterThan(150));
    await _pump(
      tester,
      ZodiannPanel(
        head: ZodiannPanelHead(title: title),
        child: _box(_probe, 10, 10),
      ),
      textScale: 2,
    );
    final text = tester.widget<Text>(find.text(title));
    expect(text.maxLines, isNull);
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    expect(tester.getSize(find.text(title)).height, greaterThan(3 * 20));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the title is a header; meta and the end widget are not', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      ZodiannPanel(
        head: ZodiannPanelHead(
          title: 'Positions',
          meta: 'Ten bodies',
          end: Text('Export', key: _end),
        ),
        child: _box(_probe, 10, 10),
      ),
    );
    expect(
      tester.getSemantics(find.text('Positions')),
      matchesSemantics(label: 'Positions', isHeader: true),
    );
    expect(
      tester.getSemantics(find.text('Ten bodies')),
      matchesSemantics(label: 'Ten bodies'),
    );
    expect(
      tester.getSemantics(find.byKey(_end)),
      matchesSemantics(label: 'Export'),
    );
    handle.dispose();
  });

  group('clip contract', () {
    Future<int> stripPixel(WidgetTester tester, Clip clip) async {
      await _pump(
        tester,
        ZodiannPanel(
          bodyPadding: EdgeInsets.zero,
          clipBehavior: clip,
          child: Transform.translate(
            offset: const Offset(-4, 0),
            child: const ColoredBox(
              color: Color(0xFFFF0000),
              child: SizedBox(width: 30, height: 30),
            ),
          ),
        ),
      );
      final px = await Pixels.capture(
        tester,
        tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary)),
      );
      // Outside the panel's outer left edge (x = 32), inside the probe's rows.
      return px.argb((_margin - 2).toInt(), (_margin + 15).toInt());
    }

    testWidgets('by default a child may paint outside the panel (focus ring '
        'is not cut)', (tester) async {
      expect(await stripPixel(tester, Clip.none), 0xFFFF0000);
    });

    testWidgets('Clip.antiAlias clips it', (tester) async {
      expect(
        await stripPixel(tester, Clip.antiAlias),
        ZodiannTheme.graphite.extension<ZodiannSurfaces>()!.bg.toARGB32(),
      );
    });

    testWidgets('the default clipBehavior is Clip.none', (tester) async {
      expect(ZodiannPanel(child: const SizedBox()).clipBehavior, Clip.none);
    });
  });
}
