// ZOD-UI-002 criterion 3: no astrological glyph renders as a colour emoji.
// Each glyph is painted in near-black on white and every pixel must be grey
// (colour emoji have chroma). Fonts come from the app's font manifest.
// Run on emulator-5554 as an app and read logcat (Flutter 3.50 refuses
// `flutter test -d` there):
//   fvm flutter build apk --debug -t integration_test/glyph_presentation_test.dart
//   adb install -r build/app/outputs/flutter-apk/app-debug.apk
//   adb shell am start -n com.zodiann.app/.MainActivity
//   adb logcat -s flutter   (expect "All tests passed!")
// Elsewhere: fvm flutter test integration_test/glyph_presentation_test.dart -d <device>
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

final _ink = porcelainTokens.surfaces.text;
final _paper = porcelainTokens.surfaces.surface;

/// Paints [text] in [style] at 64 px, near-black on white, and counts the
/// inked pixels and the coloured ones.
Future<(int dark, int coloured)> _inkOf(String text, TextStyle style) async {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: style.copyWith(fontSize: 64, color: _ink),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final w = painter.width.ceil() + 8;
  final h = painter.height.ceil() + 8;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawRect(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..color = _paper,
    );
  painter.paint(canvas, const Offset(4, 4));
  painter.dispose();
  final image = await recorder.endRecording().toImage(w, h);
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  image.dispose();
  var dark = 0;
  var coloured = 0;
  for (var i = 0; i < data.lengthInBytes; i += 4) {
    final r = data.getUint8(i);
    final g = data.getUint8(i + 1);
    final b = data.getUint8(i + 2);
    final hi = math.max(r, math.max(g, b));
    final lo = math.min(r, math.min(g, b));
    if (hi < 200) dark++;
    if (hi - lo > 24) coloured++;
  }
  return (dark, coloured);
}

Future<void> _expectMonochrome(TextStyle style, String label) async {
  for (final g in ZodiannGlyphs.all) {
    final (dark, coloured) = await _inkOf(g, style);
    expect(dark, greaterThan(50), reason: '$label $g draws nothing');
    expect(coloured, 0, reason: '$label $g renders in colour (emoji)');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final latin = buildZodiannTextStyles(
    porcelainTokens.surfaces,
    ZodiannScript.latin,
  );
  final hebrew = buildZodiannTextStyles(
    porcelainTokens.surfaces,
    ZodiannScript.hebrew,
  );

  test('every astrological glyph renders as monochrome text, not colour '
      'emoji', () async {
    await _expectMonochrome(latin.glyph, 'glyph style');
  });

  test('glyphs inside UI text also stay monochrome', () async {
    await _expectMonochrome(latin.body, 'Latin body');
    await _expectMonochrome(hebrew.body, 'Hebrew body');
  });
}
