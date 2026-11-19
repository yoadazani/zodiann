// Finds the zodiac wheel in one of the designer's screenshots (ZOD-WHL-002,
// ZOD-WHL-003): the wheel panel sits on a different side in each file, so each
// wheel's centre and size are found from the picture itself.
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:test/test.dart';

/// The four element colours blended at the sign tint over the wheel panel's
/// surface (kit.css: dark --surface #111114, tint .10; light #FFFFFF, .09).
List<List<int>> wheelTints(bool dark) {
  const elements = {
    true: [0xF2735A, 0x7CC47F, 0xE8D06E, 0x5AA9FF],
    false: [0xD9472B, 0x2F8F3E, 0xA88600, 0x1F6FD6],
  };
  final surface = dark ? 0x111114 : 0xFFFFFF;
  final tint = dark ? 0.10 : 0.09;
  return [
    for (final e in elements[dark]!)
      [
        for (final shift in [16, 8, 0])
          (((e >> shift) & 255) * tint +
                  ((surface >> shift) & 255) * (1 - tint))
              .round(),
      ],
  ];
}

/// A wheel found in a screenshot: centre and the sign band's outer radius.
class Wheel {
  Wheel(this.cx, this.cy, this.rim, this.tintPixels);
  final double cx, cy, rim;
  final int tintPixels;

  /// Pixels per kit unit (the band's outer edge is 296 units).
  double get unit => rim / 296;
}

Wheel findWheel(img.Image image, bool dark) {
  final tints = wheelTints(dark);

  final hits = <(int, int)>[];
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      for (final t in tints) {
        if ((p.r - t[0]).abs() <= 1 &&
            (p.g - t[1]).abs() <= 1 &&
            (p.b - t[2]).abs() <= 1) {
          hits.add((x, y));
          break;
        }
      }
    }
  }
  expect(hits.length, greaterThan(20000), reason: 'sign tints not found');
  // Other UI can share a pale tint (light theme): iteratively keep only the
  // pixels within 1.3 x the median distance of the current centroid.
  var kept = hits;
  var cx = 0.0, cy = 0.0;
  for (var round = 0; round < 6; round++) {
    cx = kept.map((h) => h.$1).reduce((a, b) => a + b) / kept.length;
    cy = kept.map((h) => h.$2).reduce((a, b) => a + b) / kept.length;
    final dist = [
      for (final (x, y) in kept)
        math.sqrt(math.pow(x - cx, 2) + math.pow(y - cy, 2)),
    ]..sort();
    final limit = dist[dist.length ~/ 2] * 1.3;
    kept = [
      for (final h in kept)
        if (math.sqrt(math.pow(h.$1 - cx, 2) + math.pow(h.$2 - cy, 2)) <= limit)
          h,
    ];
  }
  var rim = 0.0;
  for (final (x, y) in kept) {
    rim = math.max(rim, math.sqrt(math.pow(x - cx, 2) + math.pow(y - cy, 2)));
  }
  return Wheel(cx, cy, rim, kept.length);
}
