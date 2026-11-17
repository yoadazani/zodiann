// ZOD-UI-009, test only: measures a tag the same way on the design's
// component sheet and on a Flutter render, so the two can be compared
// feature by feature (box, fill, corners, outline, label colour).
import 'dart:io';
import 'dart:ui' as ui;

import 'button_features.dart';

export 'button_features.dart' show Rgba;

/// Decodes a PNG under `design-reference/zodiann/` (relative to
/// `packages/shared_ui`).
Future<Rgba> decodeDesignPng(String path) async {
  final bytes = File('../../design-reference/zodiann/$path').readAsBytesSync();
  final codec = await ui.instantiateImageCodec(bytes);
  final image = (await codec.getNextFrame()).image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final rgba = Rgba(image.width, image.height, data!);
  image.dispose();
  return rgba;
}

/// What [measureTag] found. All colours are 8-bit ARGB.
final class TagFeatures {
  const TagFeatures({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.fill,
    required this.cornerOuter,
    required this.cornerInner,
    required this.label,
    this.outlinePixels,
  });

  /// The box's left and right edges (x of the first and last pixel that is
  /// not backdrop).
  final int left;
  final int right;

  /// The box's top and bottom (y of the first and last such pixel).
  final int top;
  final int bottom;

  int get width => right - left + 1;
  int get height => bottom - top + 1;

  /// The pixel 4 px inside the left edge, on the mid row.
  final int fill;

  /// Whether (left + 1, top + 1) is nearer the backdrop than the box colour
  /// (true for radius 6, false for radius 4).
  final bool cornerOuter;

  /// Whether (left + 2, top + 1) is nearer the box colour than the backdrop
  /// (true for radius 6, false for radius 8 or more).
  final bool cornerInner;

  /// The content-area pixel farthest (RGB) from [fill].
  final int label;

  /// Outline tags: (left, mid), (left + 1, mid), (col, top), (col, top + 1).
  final List<int>? outlinePixels;

  @override
  String toString() =>
      'TagFeatures(left: $left, right: $right, top: $top, bottom: $bottom, '
      'width: $width, height: $height, fill: ${hex(fill)}, '
      'cornerOuter: $cornerOuter, cornerInner: $cornerInner, '
      'label: ${hex(label)}, '
      'outline: ${outlinePixels?.map(hex).toList()})';
}

/// 8-digit upper-case hex of an ARGB value.
String hex(int argb) => argb.toRadixString(16).padLeft(8, '0').toUpperCase();

int _distance(int a, int b) {
  var sum = 0;
  for (final shift in [16, 8, 0]) {
    final d = ((a >> shift) & 0xFF) - ((b >> shift) & 0xFF);
    sum += d * d;
  }
  return sum;
}

/// Measures the tag whose box starts at [left] with its top at [top].
///
/// [spanRight] is an x on the backdrop side of the tag's right edge (the
/// known right edge + 3 on the sheet, origin + 100 on a Flutter cell), and
/// [backdrop] the colour around it. [outline] is the outline colour for
/// the center and today tags, whose fill is the backdrop itself.
///
/// `mid` is `top + 12`, the middle row of a 24 px tag.
TagFeatures measureTag(
  Rgba image, {
  required int left,
  required int top,
  required int spanRight,
  required int backdrop,
  int? outline,
}) {
  final mid = top + 12;
  bool isBackdrop(int x, int y) => image.argb(x, y) == backdrop;

  var l = left - 4;
  while (isBackdrop(l, mid)) {
    l++;
  }
  var r = spanRight;
  while (isBackdrop(r, mid)) {
    r--;
  }

  // Near a corner the top reads one pixel off from anti-aliasing: measure at
  // a column at least 8 px from the left edge.
  final col = l + 8;
  var t = top - 6;
  while (isBackdrop(col, t)) {
    t++;
  }
  var b = top + 24 + 6;
  while (isBackdrop(col, b)) {
    b--;
  }

  final fill = image.argb(l + 4, mid);
  final reference = outline ?? fill;
  final outer = image.argb(l + 1, t + 1);
  final inner = image.argb(l + 2, t + 1);

  var label = fill;
  var best = -1;
  for (var y = mid - 5; y <= mid + 5; y++) {
    for (var x = l + 2 + 8; x <= r - 2 - 8; x++) {
      final c = image.argb(x, y);
      final d = _distance(c, fill);
      if (d > best) {
        best = d;
        label = c;
      }
    }
  }

  return TagFeatures(
    left: l,
    right: r,
    top: t,
    bottom: b,
    fill: fill,
    cornerOuter: _distance(outer, backdrop) < _distance(outer, reference),
    cornerInner: _distance(inner, reference) < _distance(inner, backdrop),
    label: label,
    outlinePixels: outline == null
        ? null
        : [
            image.argb(l, mid),
            image.argb(l + 1, mid),
            image.argb(col, t),
            image.argb(col, t + 1),
          ],
  );
}
