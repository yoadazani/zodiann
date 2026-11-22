// Test only: raw RGBA pixels of a `RepaintBoundary`, with row and column scans.
// Moved out of panel_spacing_test.dart (ZOD-UI-014) so the panel tests share it.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';

/// The pixels of a rendered image (DPR 1), read as 0xAARRGGBB.
final class Pixels {
  Pixels(this.width, this.height, this.raw);

  /// Captures [boundary] at pixel ratio 1.
  static Future<Pixels> capture(
    WidgetTester tester,
    RenderRepaintBoundary boundary,
  ) async {
    late Pixels px;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final raw = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      px = Pixels(image.width, image.height, raw);
      image.dispose();
    });
    return px;
  }

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
