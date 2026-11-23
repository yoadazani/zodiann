// ZOD-UI-005, test only: measures one input field (label, box, halo, value,
// icon, error message) the same way on the design's component sheet and on a
// Flutter render, so the two can be compared feature by feature.
//
// Everything is measured relative to the box's top-left border pixel, because
// the sheet and a Flutter layout round the fractional label height
// differently.
import 'tag_features.dart';

export 'tag_features.dart' show Rgba, decodeDesignPng, hex;

/// What [measureField] found. Colours are 8-bit ARGB; boxes are
/// `(left, top, right, bottom)` relative to the box's top-left border pixel.
final class FieldFeatures {
  const FieldFeatures({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.border,
    required this.fill,
    required this.haloSide,
    required this.haloTop,
    required this.outsideClear,
    required this.labelInk,
    required this.labelBox,
    required this.valueInk,
    required this.valueBox,
    required this.iconInk,
    required this.iconBox,
    required this.messageInk,
    required this.messageBox,
  });

  /// Absolute x and y of the box's top-left border pixel.
  final int left;
  final int top;

  /// Border to border, inclusive.
  final int width;
  final int height;

  /// The left border pixel (mid row) and the fill 4 px inside it.
  final int border;
  final int fill;

  /// The pixel 2 px outside the left border (mid row) and 2 px above the top
  /// border (mid column): the halo, or the backdrop when there is none.
  final int haloSide;
  final int haloTop;

  /// Whether 4 px outside the box is all backdrop (a halo is exactly 3).
  final bool outsideClear;

  /// Per text or icon: the pixel nearest to the expected ink colour (LCD
  /// fringes make the farthest pixel unreliable), and the bounding box of
  /// pixels far from the local background (null when there is none).
  final int labelInk;
  final List<int>? labelBox;
  final int valueInk;
  final List<int>? valueBox;
  final int iconInk;
  final List<int>? iconBox;
  final int messageInk;
  final List<int>? messageBox;

  @override
  String toString() =>
      'FieldFeatures(at $left,$top ${width}x$height border: ${hex(border)} '
      'fill: ${hex(fill)} haloSide: ${hex(haloSide)} haloTop: ${hex(haloTop)} '
      'clear: $outsideClear label: ${hex(labelInk)} $labelBox value: '
      '${hex(valueInk)} $valueBox icon: ${hex(iconInk)} $iconBox message: '
      '${hex(messageInk)} $messageBox)';
}

int _distance(int a, int b) {
  var sum = 0;
  for (final shift in [16, 8, 0]) {
    sum += (((a >> shift) & 0xFF) - ((b >> shift) & 0xFF)).abs();
  }
  return sum;
}

/// The pixel nearest to [target] in the box, and the bounding box (relative to
/// ([ox], [oy])) of pixels farther than [threshold] from [bg].
(int, List<int>?) _ink(
  Rgba px,
  int x0,
  int x1,
  int y0,
  int y1,
  int bg,
  int target,
  int ox,
  int oy, {
  int threshold = 90,
}) {
  var best = bg;
  var bestD = 1 << 30;
  int? l, t, r, b;
  for (var y = y0; y <= y1; y++) {
    for (var x = x0; x <= x1; x++) {
      final c = px.argb(x, y);
      final nearest = _distance(c, target);
      if (nearest < bestD) {
        bestD = nearest;
        best = c;
      }
      final d = _distance(c, bg);
      if (d > threshold) {
        l = l == null || x < l ? x : l;
        r = r == null || x > r ? x : r;
        t = t == null || y < t ? y : t;
        b = b == null || y > b ? y : b;
      }
    }
  }
  return (best, l == null ? null : [l - ox, t! - oy, r! - ox, b! - oy]);
}

/// Measures the field whose top border row is [top]. The box's left and right
/// edges are the first and last pixel that is not [backdrop] on the mid row
/// between [scanFrom] and [scanTo], less [haloWidth] (0 when the field has no
/// halo; a halo is exactly 3 px outside the border).
///
/// [backdrop] is the colour behind the field (the panel's `surface`),
/// [boxFill] the box's fill, [hasIcon] and [hasMessage] say what the field
/// holds.
FieldFeatures measureField(
  Rgba px, {
  required int top,
  required int scanFrom,
  required int scanTo,
  required int haloWidth,
  required int backdrop,
  required bool hasIcon,
  required bool hasMessage,
  required int boxFill,
  required int labelColour,
  required int valueColour,
  required int iconColour,
  required int messageColour,
  int? valueRight,
}) {
  final mid = top + 20;
  var left = scanFrom;
  while (px.argb(left, mid) == backdrop) {
    left++;
  }
  left += haloWidth;
  var right = scanTo;
  while (px.argb(right, mid) == backdrop) {
    right--;
  }
  right -= haloWidth;
  // A column near the right edge, clear of the value text.
  final col = right - 12;
  // Down the column to the first row that is not fill: the bottom border.
  var bottom = top + 1;
  // Within 6 of the fill: a disabled box is blended and rounds differently.
  while (_distance(px.argb(col, bottom), boxFill) <= 6) {
    bottom++;
  }
  final height = bottom - top + 1;

  final labelBox = _ink(
    px,
    left,
    left + 320,
    top - 24,
    top - 8,
    backdrop,
    labelColour,
    left,
    top,
  );
  final valueX0 = hasIcon ? left + 34 : left + 8;
  final value = _ink(
    px,
    valueX0,
    valueRight == null ? right - 8 : left + valueRight,
    top + 8,
    top + height - 9,
    boxFill,
    valueColour,
    left,
    top,
  );
  final icon = hasIcon
      ? _ink(
          px,
          left + 8,
          left + 30,
          top + 8,
          top + height - 9,
          boxFill,
          iconColour,
          left,
          top,
          threshold: 60,
        )
      : (0, null);
  final message = hasMessage
      ? _ink(
          px,
          left,
          left + 600,
          top + height + 4,
          top + height + 30,
          backdrop,
          messageColour,
          left,
          top,
        )
      : (0, null);

  var clear = true;
  for (var y = top - 6; y <= bottom + 6 && clear; y += 3) {
    if (px.argb(left - 4, y) != backdrop) clear = false;
  }
  for (var x = left; x <= right && clear; x += 11) {
    if (px.argb(x, top - 4) != backdrop) clear = false;
  }

  return FieldFeatures(
    left: left,
    top: top,
    width: right - left + 1,
    height: height,
    border: px.argb(left, mid),
    fill: px.argb(left + 4, mid),
    haloSide: px.argb(left - 2, mid),
    haloTop: px.argb(left + 100 > right ? left + 30 : left + 100, top - 2),
    outsideClear: clear,
    labelInk: labelBox.$1,
    labelBox: labelBox.$2,
    valueInk: value.$1,
    valueBox: value.$2,
    iconInk: icon.$1,
    iconBox: icon.$2,
    messageInk: message.$1,
    messageBox: message.$2,
  );
}
