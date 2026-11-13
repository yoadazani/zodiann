// ZOD-UI-003: the per-breakpoint layout tokens match the design reference's
// rendered settings screens (desktop and tablet at DPR 1, mobile at DPR 2),
// measured along fixed scan lines (see the plan's Facts). Each measurement
// is within 1 logical px of its token.
//
// The mobile PNG's panel gap and head height are not checked: the reference
// HTML does not apply MASTER's phone values there (MASTER wins; see the
// ZOD-UI-003 task Notes).
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

final class _Png {
  _Png(this.width, this.height, this.rgba);
  final int width;
  final int height;
  final ByteData rgba;

  /// The pixel at (x, y) as 8-bit ARGB.
  int argb(int x, int y) {
    final i = (y * width + x) * 4;
    return (rgba.getUint8(i + 3) << 24) |
        (rgba.getUint8(i) << 16) |
        (rgba.getUint8(i + 1) << 8) |
        rgba.getUint8(i + 2);
  }

  /// The first x ≥ [from] on row [y] where [test] holds.
  int firstX(int y, int from, bool Function(int argb) test) {
    for (var x = from; x < width; x++) {
      if (test(argb(x, y))) return x;
    }
    fail('row $y: no match from x $from');
  }

  /// The first y ≥ [from] on column [x] where [test] holds.
  int firstY(int x, int from, bool Function(int argb) test) {
    for (var y = from; y < height; y++) {
      if (test(argb(x, y))) return y;
    }
    fail('column $x: no match from y $from');
  }
}

Future<_Png> _decode(String path) async {
  final bytes = File('../../design-reference/zodiann/$path').readAsBytesSync();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final png = _Png(image.width, image.height, data!);
  image.dispose();
  return png;
}

const _desktop = 'screens/04-settings_desktop_en_dark.png';
const _tablet = 'responsive/tablet/settings_tablet_en_dark.png';
const _mobile = 'responsive/mobile/settings_mobile_he_dark.png';

void main() {
  final s = graphiteTokens.surfaces;
  final bg = s.bg.toARGB32();
  final lineSoft = s.lineSoft.toARGB32();
  final surface = s.surface.toARGB32();
  bool isBg(int c) => c == bg;
  bool notBg(int c) => c != bg;
  bool isLine(int c) => c == lineSoft;
  bool isSurface(int c) => c == surface;
  bool notSurface(int c) => c != surface;

  const regular = ZodiannLayout.regular;
  const phone = ZodiannLayout.phone;

  final pngs = <String, _Png>{};
  setUpAll(() async {
    for (final path in [_desktop, _tablet, _mobile]) {
      pngs[path] = await _decode(path);
    }
  });

  test('the reference images are the expected size', () {
    expect((pngs[_desktop]!.width, pngs[_desktop]!.height), (1440, 1241));
    expect((pngs[_tablet]!.width, pngs[_tablet]!.height), (834, 2147));
    expect((pngs[_mobile]!.width, pngs[_mobile]!.height), (780, 4918));
  });

  group('desktop (1440, DPR 1)', () {
    test('horizontal panel gap', () {
      final png = pngs[_desktop]!;
      const y = 100;
      final gapStart = png.firstX(y, 160, isBg);
      final gapEnd = png.firstX(y, gapStart, notBg);
      expect(png.argb(gapStart - 1, y), lineSoft, reason: 'panel A border');
      expect(png.argb(gapEnd, y), lineSoft, reason: 'panel B border');
      expect(gapEnd - gapStart, closeTo(regular.panelGap, 1));
    });

    test('panel head height and vertical panel gap', () {
      final png = pngs[_desktop]!;
      const x = 400;
      final top = png.firstY(x, 70, isLine);
      final rule = png.firstY(x, top + 1, isLine);
      expect(rule - top, closeTo(ZodiannSize.panelHead, 1), reason: 'head');
      final gapStart = png.firstY(x, rule + 1, isBg);
      final gapEnd = png.firstY(x, gapStart, notBg);
      expect(png.argb(x, gapStart - 1), lineSoft, reason: 'panel bottom');
      expect(png.argb(x, gapEnd), lineSoft, reason: 'next panel top');
      expect(gapEnd - gapStart, closeTo(regular.panelGap, 1), reason: 'gap');
    });

    test('panel padding', () {
      final png = pngs[_desktop]!;
      const y = 176;
      final inner = png.firstX(y, 150, isSurface);
      expect(png.argb(inner - 1, y), lineSoft, reason: 'left border');
      final content = png.firstX(y, inner, notSurface);
      expect(content - inner, closeTo(regular.panelPadding, 1));
    });
  });

  group('tablet (834, DPR 1)', () {
    test('gutter', () {
      final png = pngs[_tablet]!;
      final edge = png.firstX(150, 0, notBg);
      expect(png.argb(edge, 150), lineSoft, reason: 'panel border');
      expect(edge, closeTo(regular.gutter, 1));
    });

    test('panel padding', () {
      final png = pngs[_tablet]!;
      const y = 176;
      final inner = png.firstX(y, 0, isSurface);
      expect(png.argb(inner - 1, y), lineSoft, reason: 'left border');
      final content = png.firstX(y, inner, notSurface);
      expect(content - inner, closeTo(regular.panelPadding, 1));
    });
  });

  group('mobile (390, DPR 2)', () {
    const dpr = 2;
    const y = 400;

    test('gutter', () {
      final png = pngs[_mobile]!;
      final edge = png.firstX(y, 0, notBg);
      expect(png.argb(edge, y), lineSoft, reason: 'panel border');
      expect(edge / dpr, closeTo(phone.gutter, 1));
    });

    test('panel padding', () {
      final png = pngs[_mobile]!;
      final inner = png.firstX(y, 0, isSurface);
      final content = png.firstX(y, inner, notSurface);
      expect((content - inner) / dpr, closeTo(phone.panelPadding, 1));
    });
  });
}
