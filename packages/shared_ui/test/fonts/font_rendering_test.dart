// ZOD-FND-007: the bundled fonts really render: each Plex weight is a
// distinct face, and no bundled family renders as the fallback font.
// flutter_test does not load the font manifest, so the fonts are loaded from
// their files with FontLoader under the names the engine sees for package
// fonts (`packages/shared_ui/<family>`).
//
// With ZODIANN_FONT_DIR set, also writes font_specimen.png for visual review.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

const _families = {
  ZodiannFonts.plexSans: [
    'ibm-plex-sans/IBMPlexSans-Light.ttf',
    'ibm-plex-sans/IBMPlexSans-Regular.ttf',
    'ibm-plex-sans/IBMPlexSans-Medium.ttf',
    'ibm-plex-sans/IBMPlexSans-SemiBold.ttf',
  ],
  ZodiannFonts.plexSansHebrew: [
    'ibm-plex-sans-hebrew/IBMPlexSansHebrew-Light.ttf',
    'ibm-plex-sans-hebrew/IBMPlexSansHebrew-Regular.ttf',
    'ibm-plex-sans-hebrew/IBMPlexSansHebrew-Medium.ttf',
    'ibm-plex-sans-hebrew/IBMPlexSansHebrew-SemiBold.ttf',
  ],
  ZodiannFonts.notoSansSymbols: [
    'noto-sans-symbols/NotoSansSymbols-Regular.ttf',
  ],
  ZodiannFonts.notoSansSymbols2: [
    'noto-sans-symbols-2/NotoSansSymbols2-Regular.ttf',
  ],
  ZodiannFonts.notoSans: ['noto-sans/NotoSans-Regular.ttf'],
};

const _latin = 'Zodiann 0123456789';
const _hebrew = 'זודיאן 0123456789';
const _weights = [
  FontWeight.w300,
  FontWeight.w400,
  FontWeight.w500,
  FontWeight.w600,
];
const _missing = 'zodiann-missing-family';

/// The 29 MASTER §3 glyphs, each with U+FE0E (text presentation).
const _glyphs = '♈︎♉︎♊︎♋︎♌︎♍︎♎︎♏︎♐︎♑︎♒︎♓︎ ☉︎☽︎☿︎♀︎♂︎♃︎♄︎♅︎♆︎♇︎☊︎ ℞︎ ☌︎⚹︎□︎△︎☍︎';

double _width(String text, String family, [FontWeight w = FontWeight.w400]) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: family,
        package: family == _missing ? null : ZodiannFonts.package,
        fontSize: 40,
        fontWeight: w,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

Future<void> _loadFonts() async {
  for (final MapEntry(key: family, value: files) in _families.entries) {
    final loader = FontLoader('packages/${ZodiannFonts.package}/$family');
    for (final file in files) {
      final bytes = File('assets/fonts/$file').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadFonts);

  test('IBM Plex Sans renders four distinct weights', () {
    final widths = {
      for (final w in _weights) _width(_latin, ZodiannFonts.plexSans, w),
    };
    expect(widths, hasLength(4), reason: '$widths');
  });

  test('IBM Plex Sans Hebrew renders four distinct weights', () {
    final widths = {
      for (final w in _weights) _width(_hebrew, ZodiannFonts.plexSansHebrew, w),
    };
    expect(widths, hasLength(4), reason: '$widths');
  });

  test('the bundled families do not render as the test fallback font', () {
    const samples = {
      ZodiannFonts.plexSans: 'Zodiann',
      ZodiannFonts.plexSansHebrew: _hebrew,
      ZodiannFonts.notoSansSymbols: '♈☽☌',
      ZodiannFonts.notoSansSymbols2: '☉△□',
      ZodiannFonts.notoSans: '℞',
    };
    samples.forEach((family, text) {
      expect(
        _width(text, family),
        isNot(_width(text, _missing)),
        reason: family,
      );
    });
  });

  testWidgets('specimen', (tester) async {
    final dir = Platform.environment['ZODIANN_FONT_DIR'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    TextStyle style(String family, FontWeight w, {List<String>? fallback}) =>
        TextStyle(
          fontFamily: family,
          package: ZodiannFonts.package,
          fontSize: 28,
          fontWeight: w,
          color: porcelainTokens.surfaces.text,
          fontFamilyFallback: fallback,
        );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: const Key('specimen'),
          child: ColoredBox(
            color: porcelainTokens.surfaces.surface,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final w in _weights) ...[
                    Text(
                      '$_latin  ${w.value}',
                      style: style(ZodiannFonts.plexSans, w),
                    ),
                    Text(
                      '$_hebrew  ${w.value}',
                      style: style(ZodiannFonts.plexSansHebrew, w),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    _glyphs,
                    style: style(
                      ZodiannFonts.plexSans,
                      FontWeight.w400,
                      fallback: ZodiannFonts.glyphFallback,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('specimen')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      File('$dir/font_specimen.png').writeAsBytesSync(png.buffer.asUint8List());
      image.dispose();
    });
  });
}
