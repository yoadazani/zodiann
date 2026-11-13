// ZOD-UI-004, test only: measures a button cell the same way on a design
// PNG and on a Flutter render, so the two can be compared feature by
// feature (geometry, fill, border, focus ring, label colour).
import 'dart:typed_data';

/// An RGBA image.
final class Rgba {
  const Rgba(this.width, this.height, this.data);

  final int width;
  final int height;
  final ByteData data;

  /// The pixel at (x, y) as 8-bit ARGB.
  int argb(int x, int y) {
    final i = (y * width + x) * 4;
    return (data.getUint8(i + 3) << 24) |
        (data.getUint8(i) << 16) |
        (data.getUint8(i + 1) << 8) |
        data.getUint8(i + 2);
  }
}

/// What [measureButton] found. Box fields are null for a boxless cell
/// (a quiet button outside the focus column).
final class ButtonFeatures {
  const ButtonFeatures({
    required this.label,
    this.left,
    this.top,
    this.width,
    this.height,
    this.fill,
    this.border,
    this.inkStart,
    this.ring,
  });

  /// The drawn box's left edge (x).
  final int? left;

  /// The drawn box's top edge (y).
  final int? top;

  /// The drawn box's width and height.
  final int? width;
  final int? height;

  /// The pixel at (left + 4, mid) and at (left, mid).
  final int? fill;
  final int? border;

  /// Boxless cells: the first ink x relative to the origin.
  final int? inkStart;

  /// The label pixel farthest (RGB) from the fill, or from the board.
  final int label;

  /// The four pixels from the ring's outer edge to the box (ring, ring, gap,
  /// gap), when a focus ring is present.
  final List<int>? ring;

  @override
  String toString() =>
      'ButtonFeatures(left: $left, top: $top, width: $width, '
      'height: $height, fill: ${_hex(fill)}, border: ${_hex(border)}, '
      'inkStart: $inkStart, label: ${_hex(label)}, '
      'ring: ${ring?.map(_hex).toList()})';
}

String? _hex(int? argb) =>
    argb?.toRadixString(16).padLeft(8, '0').toUpperCase();

int _distance(int a, int b) {
  var sum = 0;
  for (final shift in [16, 8, 0]) {
    final d = ((a >> shift) & 0xFF) - ((b >> shift) & 0xFF);
    sum += d * d;
  }
  return sum;
}

/// Measures the button whose cell starts at ([originX], [originY]): the
/// drawn box's top is at [originY] (+1 when pressed) and its left edge 8 px
/// right of [originX]; [spanX] bounds the cell on the right.
ButtonFeatures measureButton(
  Rgba img, {
  required int originX,
  required int originY,
  required int drawnHeight,
  required int spanX,
  required int board,
  required int focus,
  required int padding,
  bool icon = false,
  bool boxless = false,
}) {
  final mid = originY + drawnHeight ~/ 2;
  bool isBoard(int x, int y) => img.argb(x, y) == board;

  var x = originX;
  while (isBoard(x, mid)) {
    x++;
  }
  final hasRing =
      img.argb(x, mid) == focus &&
      img.argb(x + 1, mid) == focus &&
      isBoard(x + 2, mid) &&
      isBoard(x + 3, mid);
  final ring = hasRing
      ? [for (var i = 0; i < 4; i++) img.argb(x + i, mid)]
      : null;

  var right = originX + spanX;
  while (isBoard(right, mid)) {
    right--;
  }
  if (hasRing) right -= 4;

  int extreme(int from, int to, int ref) {
    var best = ref;
    var bestD = -1;
    for (var y = mid - 5; y <= mid + 5; y++) {
      for (var xx = from; xx <= to; xx++) {
        final c = img.argb(xx, y);
        final d = _distance(c, ref);
        if (d > bestD) {
          bestD = d;
          best = c;
        }
      }
    }
    return best;
  }

  if (boxless && !hasRing) {
    return ButtonFeatures(
      inkStart: x - originX,
      label: extreme(x, right, board),
    );
  }

  final left = hasRing ? x + 4 : x;
  final col = left + 8;

  // Top: skip a ring's top segment and its 2 px gap.
  var y = originY - 6;
  while (isBoard(col, y)) {
    y++;
  }
  final ringTop = hasRing ? y : null;
  if (hasRing) {
    while (img.argb(col, y) == focus) {
      y++;
    }
    while (isBoard(col, y)) {
      y++;
    }
  }
  // Bottom: the same from below.
  var b = originY + drawnHeight + 6;
  while (isBoard(col, b)) {
    b--;
  }
  final ringBottom = hasRing ? b : null;
  if (hasRing) {
    while (img.argb(col, b) == focus) {
      b--;
    }
    while (isBoard(col, b)) {
      b--;
    }
  }

  final int top;
  final int height;
  if (boxless) {
    // A quiet box is invisible: measure it from its ring.
    top = ringTop! + 4;
    height = ringBottom! - ringTop - 7;
  } else {
    top = y;
    height = b - y + 1;
  }

  final fill = img.argb(left + 4, mid);
  return ButtonFeatures(
    left: left,
    top: top,
    width: right - left + 1,
    height: height,
    fill: boxless ? null : fill,
    border: boxless ? null : img.argb(left, mid),
    ring: ring,
    label: extreme(
      left + 1 + padding + (icon ? 16 + 8 : 0),
      right - 1 - padding,
      boxless ? board : fill,
    ),
  );
}
