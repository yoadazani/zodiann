// ZOD-UI-002: with the bundled fonts loaded, every role renders at its line
// height (the engine rounds a line box to whole pixels), tracking and weight; digits never jitter (criterion 2); Hebrew
// roles take ′ ″ from IBM Plex Sans; glyphs render through the glyph fonts
// with an invisible U+FE0E. With ZODIANN_TYPE_DIR set, also writes the
// typography specimen PNG for side-by-side review against the reference.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/load_bundled_fonts.dart';
import '../support/typography_specimen.dart';

const _missing = 'zodiann-missing-family';

final _styles = {
  for (final script in ZodiannScript.values)
    script: buildZodiannTextStyles(graphiteTokens.surfaces, script),
};

TextDirection _dir(ZodiannScript script) =>
    script == ZodiannScript.hebrew ? TextDirection.rtl : TextDirection.ltr;

TextPainter _layout(String text, TextStyle style, TextDirection dir) =>
    TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: dir,
    )..layout();

double _width(String text, TextStyle style, [TextDirection? dir]) {
  final p = _layout(text, style, dir ?? TextDirection.ltr);
  final w = p.width;
  p.dispose();
  return w;
}

/// The UI roles (everything but the glyph style), by name.
Map<String, TextStyle> _ui(ZodiannScript script) =>
    Map.of(_styles[script]!.roles)..remove('glyph');

/// [s] in the fallback font, with its size, weight and tracking.
TextStyle _inMissing(TextStyle s) => TextStyle(
  fontFamily: _missing,
  fontSize: s.fontSize,
  fontWeight: s.fontWeight,
  letterSpacing: s.letterSpacing,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadBundledFonts);

  const sample = {
    ZodiannScript.latin: 'Zodiann 17°03′',
    ZodiannScript.hebrew: 'זודיאן 17°03′',
  };
  const word = {ZodiannScript.latin: 'Zodiann', ZodiannScript.hebrew: 'זודיאן'};

  for (final script in ZodiannScript.values) {
    group(script.name, () {
      test(
        'every UI role lays out one line at size × line height (whole px)',
        () {
          _ui(script).forEach((role, s) {
            // A finite width: unconstrained RTL layout can wrap one sample (see
            // the ruling in the ZOD-UI-002 notes); this test measures lines.
            final p = TextPainter(
              text: TextSpan(text: sample[script]!, style: s),
              textDirection: _dir(script),
            )..layout(maxWidth: 10000);
            expect(
              p.height,
              (s.fontSize! * s.height!).roundToDouble(),
              reason: role,
            );
            p.dispose();
          });
        },
      );

      test('tracking adds letterSpacing per character', () {
        _ui(script).forEach((role, s) {
          if (s.letterSpacing == 0) return;
          final text = word[script]!;
          final tracked = _width(text, s, _dir(script));
          final plain = _width(
            text,
            s.copyWith(letterSpacing: 0),
            _dir(script),
          );
          expect(
            tracked - plain,
            closeTo(s.letterSpacing! * text.length, 0.05),
            reason: role,
          );
        });
      });

      test('each role renders in its own weight', () {
        _ui(script).forEach((role, s) {
          if (s.fontWeight == FontWeight.w400) return;
          expect(
            _width(sample[script]!, s, _dir(script)),
            isNot(
              _width(
                sample[script]!,
                s.copyWith(fontWeight: FontWeight.w400),
                _dir(script),
              ),
            ),
            reason: role,
          );
        });
      });

      test('digits do not jitter', () {
        _ui(script).forEach((role, s) {
          final digits = {
            for (var d = 0; d < 10; d++) _width('$d', s, _dir(script)),
          };
          expect(digits, hasLength(1), reason: '$role digits $digits');
          final readouts = <double>{};
          for (var a = 0; a < 10; a++) {
            for (var b = 0; b < 10; b++) {
              readouts.add(_width('$a$b°$a$b′', s, _dir(script)));
            }
          }
          expect(readouts, hasLength(1), reason: '$role readouts $readouts');
          expect(
            readouts.single,
            isNot(_width('00°00′', _inMissing(s))),
            reason: '$role renders as the fallback font',
          );
          expect(
            _width('il', s, _dir(script)),
            isNot(_width('mw', s, _dir(script))),
            reason: '$role: a monospaced (fallback) font would hide jitter',
          );
        });
      });
    });
  }

  test('Hebrew roles draw ′ and ″ from IBM Plex Sans', () {
    final latin = _ui(ZodiannScript.latin);
    _ui(ZodiannScript.hebrew).forEach((role, he) {
      for (final mark in ['′', '″']) {
        final w = _width(mark, he, TextDirection.rtl);
        expect(
          w,
          closeTo(_width(mark, latin[role]!), 0.01),
          reason: '$role $mark',
        );
        if (mark == '″' || he.fontWeight != FontWeight.w300) {
          final noto = TextStyle(
            fontFamily: ZodiannFonts.notoSans,
            package: ZodiannFonts.package,
            fontSize: he.fontSize,
            fontWeight: he.fontWeight,
            letterSpacing: he.letterSpacing,
          );
          expect(
            (w - _width(mark, noto)).abs(),
            greaterThan(0.05),
            reason: '$role $mark comes from Noto Sans',
          );
        }
      }
    });
  });

  test('glyphs render through the glyph fonts with an invisible selector', () {
    final glyph = _styles[ZodiannScript.latin]!.glyph.copyWith(fontSize: 40);
    for (final g in ZodiannGlyphs.all) {
      final base = String.fromCharCode(g.runes.first);
      final w = _width(g, glyph);
      expect(w, closeTo(_width(base, glyph), 0.01), reason: g);
      expect(
        w,
        isNot(_width(g, const TextStyle(fontFamily: _missing, fontSize: 40))),
        reason: '$g renders as the fallback font',
      );
    }
  });

  testWidgets('specimen', (tester) async {
    final dir = Platform.environment['ZODIANN_TYPE_DIR'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ZodiannTheme.graphite,
        home: const Scaffold(body: TypographySpecimen()),
      ),
    );
    expect(tester.takeException(), isNull);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('typography-specimen')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      File('$dir/typography_specimen_graphite.png')
          .writeAsBytesSync(png.buffer.asUint8List());
      image.dispose();
    });
  });
}
