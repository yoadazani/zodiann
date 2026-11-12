// ZOD-UI-001: the swatch-grid harness shows every token, in the reference's
// groups and order, painting exactly what the reference oracle expects.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/token_swatch_grid.dart';

const _sections = [
  'Surfaces and text',
  'Brand and state',
  'Square of Nine roles',
  'Elements and aspects',
  'Bodies',
  'Not in the reference grid',
];

const _order = [
  // Surfaces and text
  'bg', 'bg-raised', 'surface', 'surface-2', 'surface-3', 'line', 'text',
  'text-2',
  // Brand and state
  'accent', 'accent-line', 'text-3', 'focus', 'danger', 'ok', 'line-soft',
  'on-accent',
  // Square of Nine roles
  'axis-fill', 'axis', 'diag-fill', 'diag', 'eighth-fill', 'today', 'center',
  'sel-outer',
  // Elements and aspects
  'fire', 'earth', 'air', 'water', 'asp-conj', 'asp-soft', 'asp-hard',
  'cell-fill',
  // Bodies
  'sun', 'moon', 'mercury', 'venus', 'mars', 'jupiter', 'saturn', 'uranus',
  'neptune', 'pluto', 'node',
  // Not in the reference grid
  'accent-strong', 'accent-soft', 'scrim', 'axis-ink', 'diag-ink',
  'eighth-ink', 'cell-ink', 'cell-line', 'sel-inner',
];

const _bodyLabels = {
  'sun': 'Sun',
  'moon': 'Moon',
  'mercury': 'Mercury',
  'venus': 'Venus',
  'mars': 'Mars',
  'jupiter': 'Jupiter',
  'saturn': 'Saturn',
  'uranus': 'Uranus',
  'neptune': 'Neptune',
  'pluto': 'Pluto',
  'node': 'Mean node',
};

/// MASTER's rgba value texts, as the reference prints them.
const _rgbaText = {
  'graphite': {
    'accent-soft': 'rgba(255, 255, 255, .07)',
    'accent-line': 'rgba(255, 255, 255, .24)',
    'scrim': 'rgba(0, 0, 0, .72)',
  },
  'porcelain': {
    'accent-soft': 'rgba(11, 12, 14, .06)',
    'accent-line': 'rgba(11, 12, 14, .26)',
    'scrim': 'rgba(11, 12, 14, .40)',
  },
};

Map<String, Color> _all(ZodiannTokens t) => {
  ...t.surfaces.tokens,
  ...t.square.tokens,
  ...t.zodiac.tokens,
  ...t.aspects.tokens,
  ...t.bodies.tokens,
};

String _hexText(Color c) {
  final rgb = c.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

Finder _tile(String token) => find.byKey(Key('swatch-$token'));

Finder _in(String token, Finder f) =>
    find.descendant(of: _tile(token), matching: f);

Future<void> _pump(WidgetTester tester, ThemeData theme) async {
  tester.view.physicalSize = const Size(1440, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: const Scaffold(
        body: SingleChildScrollView(child: TokenSwatchGrid()),
      ),
    ),
  );
}

void main() {
  final themes = {
    'graphite': (ZodiannTheme.graphite, graphiteTokens),
    'porcelain': (ZodiannTheme.porcelain, porcelainTokens),
  };

  themes.forEach((name, entry) {
    final (theme, tokens) = entry;
    final all = _all(tokens);

    group(name, () {
      testWidgets(
        'shows all 52 tokens, reference sections first, in reference order',
        (tester) async {
          await _pump(tester, theme);
          final titles = tester
              .widgetList<Text>(find.byKey(const Key('swatch-section-title')))
              .map((t) => t.data)
              .toList();
          expect(titles, _sections);
          final tiles = tester
              .widgetList(
                find.byWidgetPredicate((w) {
                  final k = w.key;
                  return k is ValueKey<String> &&
                      k.value.startsWith('swatch-') &&
                      _order.contains(k.value.substring(7));
                }),
              )
              .map((w) => (w.key! as ValueKey<String>).value.substring(7))
              .toList();
          expect(tiles, _order);
        },
      );

      testWidgets('each tile paints its token', (tester) async {
        await _pump(tester, theme);
        for (final token in _order) {
          final fill = tester.widget<ColoredBox>(
            _in(token, find.byType(ColoredBox)),
          );
          expect(fill.color, all[token], reason: token);
        }
      });

      testWidgets("each label shows MASTER's name and value", (tester) async {
        await _pump(tester, theme);
        for (final token in _order) {
          final label = _bodyLabels[token] ?? token;
          final value = _rgbaText[name]![token] ?? _hexText(all[token]!);
          expect(_in(token, find.text(label)), findsOneWidget, reason: token);
          expect(_in(token, find.text(value)), findsOneWidget, reason: token);
        }
        final spot = name == 'graphite'
            ? ('#08080A', '#9CA1AB', 'rgba(255, 255, 255, .24)')
            : ('#F5F6F8', '#646A74', 'rgba(11, 12, 14, .26)');
        expect(_in('bg', find.text(spot.$1)), findsOneWidget);
        expect(_in('node', find.text('Mean node')), findsOneWidget);
        expect(_in('node', find.text(spot.$2)), findsOneWidget);
        expect(_in('accent-line', find.text(spot.$3)), findsOneWidget);
      });

      testWidgets(
        'renders to an image, with tile pixels as the reference oracle expects',
        (tester) async {
          await _pump(tester, theme);
          final boundaryFinder = find.byKey(const Key('swatch-grid'));
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            boundaryFinder,
          );
          final origin = tester.getTopLeft(boundaryFinder);
          final centres = {
            for (final token in _order)
              token:
                  tester.getCenter(_in(token, find.byType(ColoredBox))) -
                  origin,
          };
          final dir = Platform.environment['ZODIANN_SWATCH_DIR'];
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final raw = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            int px(int x, int y) {
              final i = (y * image.width + x) * 4;
              return (raw.getUint8(i + 3) << 24) |
                  (raw.getUint8(i) << 16) |
                  (raw.getUint8(i + 1) << 8) |
                  raw.getUint8(i + 2);
            }

            for (final token in _order) {
              final at = centres[token]!;
              final got = px(at.dx.round(), at.dy.round());
              final color = all[token]!;
              final opaque = color.a == 1;
              final want = opaque
                  ? color.toARGB32()
                  : Color.alphaBlend(color, tokens.surfaces.surface).toARGB32();
              for (final shift in [24, 16, 8, 0]) {
                final diff =
                    (((got >> shift) & 0xFF) - ((want >> shift) & 0xFF)).abs();
                expect(
                  diff,
                  lessThanOrEqualTo(opaque ? 0 : 1),
                  reason:
                      '$token: ${got.toRadixString(16)} vs '
                      '${want.toRadixString(16)}',
                );
              }
            }
            if (dir != null) {
              final png = (await image.toByteData(
                format: ui.ImageByteFormat.png,
              ))!;
              File('$dir/token_swatches_$name.png')
                  .writeAsBytesSync(png.buffer.asUint8List());
            }
            image.dispose();
          });
        },
      );
    });
  });
}
