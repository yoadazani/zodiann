// ZOD-UI-007, test only: measures the switch, the orb stepper and a body chip
// the same way on the design's component sheet and on a Flutter render, so
// the two can be compared feature by feature (box, fill, border, thumb, the
// ink of the glyphs and labels).
//
// Every function takes a pixel reader `int Function(int x, int y)` returning
// 0xAARRGGBB, so the sheet's PNG and a captured `RepaintBoundary` are read by
// the same code.
import 'dart:math' as math;

/// Reads a pixel as 0xAARRGGBB.
typedef PixelAt = int Function(int x, int y);

/// A box found by [findBox]; right and bottom are exclusive.
final class PixelBox {
  const PixelBox(this.left, this.top, this.right, this.bottom);

  final int left;
  final int top;
  final int right;
  final int bottom;

  int get width => right - left;
  int get height => bottom - top;

  @override
  String toString() => 'PixelBox($left, $top, $right, $bottom)';
}

/// The largest per-channel difference between two 0xAARRGGBB colours.
int channelDistance(int a, int b) {
  int c(int v, int shift) => (v >> shift) & 255;
  return math.max(
    math.max((c(a, 16) - c(b, 16)).abs(), (c(a, 8) - c(b, 8)).abs()),
    (c(a, 0) - c(b, 0)).abs(),
  );
}

/// The bounding box of the pixels in the window that differ from [bg] by more
/// than [tolerance], or null when there are none.
PixelBox? findBox(
  PixelAt at,
  int x0,
  int y0,
  int x1,
  int y1,
  int bg, {
  int tolerance = 4,
}) {
  var left = x1;
  var top = y1;
  var right = x0 - 1;
  var bottom = y0 - 1;
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      if (channelDistance(at(x, y), bg) > tolerance) {
        left = math.min(left, x);
        right = math.max(right, x);
        top = math.min(top, y);
        bottom = math.max(bottom, y);
      }
    }
  }
  if (right < left) return null;
  return PixelBox(left, top, right + 1, bottom + 1);
}

/// The ink in a window: its bounding box and its strongest pixel (the one
/// furthest from [fill]), or null when the window is plain [fill].
({PixelBox box, int core})? findInk(
  PixelAt at,
  int x0,
  int y0,
  int x1,
  int y1,
  int fill, {
  int tolerance = 40,
}) {
  final box = findBox(at, x0, y0, x1, y1, fill, tolerance: tolerance);
  if (box == null) return null;
  // The core colour is the value furthest from the fill in each channel
  // separately: Chrome's sheet has sub-pixel (LCD) text fringes, so no
  // single pixel of a stem is the pure ink colour, but each channel reaches
  // it somewhere.
  final core = [0, 0, 0];
  final best = [-1, -1, -1];
  for (var y = box.top; y < box.bottom; y++) {
    for (var x = box.left; x < box.right; x++) {
      final p = at(x, y);
      for (var k = 0; k < 3; k++) {
        final shift = 16 - 8 * k;
        final v = (p >> shift) & 255;
        final d = (v - ((fill >> shift) & 255)).abs();
        if (d > best[k]) {
          best[k] = d;
          core[k] = v;
        }
      }
    }
  }
  return (box: box, core: 0xFF000000 | core[0] << 16 | core[1] << 8 | core[2]);
}

/// What [measureSwitch] found. Offsets are relative to the track's left and
/// top; colours are 0xAARRGGBB.
final class SwitchFeatures {
  const SwitchFeatures({
    required this.width,
    required this.height,
    required this.border,
    required this.fill,
    required this.thumbLeft,
    required this.thumbRight,
    required this.thumbTop,
    required this.thumbBottom,
    required this.thumbColor,
  });

  final int width;
  final int height;
  final int border;
  final int fill;
  final int thumbLeft;
  final int thumbRight;
  final int thumbTop;
  final int thumbBottom;
  final int thumbColor;

  PixelBox get thumb => PixelBox(thumbLeft, thumbTop, thumbRight, thumbBottom);
}

/// Measures one switch inside the window; [on] says where the thumb is.
SwitchFeatures measureSwitch(
  PixelAt at,
  int x0,
  int y0,
  int x1,
  int y1,
  int bg, {
  required bool on,
}) {
  final box = findBox(at, x0, y0, x1, y1, bg)!;
  final midY = box.top + box.height ~/ 2;
  // The fill is read where the thumb is not: the far side of the track.
  final fillX = on ? box.left + 8 : box.right - 8;
  final fill = at(fillX, midY);
  final thumbX = on ? box.right - 12 : box.left + 12;
  final thumbColor = at(thumbX, midY);
  // The thumb's extent: the run of pixels equal to its colour around its
  // centre, along the middle row and the centre column.
  var l = thumbX;
  while (channelDistance(at(l - 1, midY), thumbColor) <= 6) {
    l--;
  }
  var r = thumbX;
  while (channelDistance(at(r + 1, midY), thumbColor) <= 6) {
    r++;
  }
  var t = midY;
  while (channelDistance(at(thumbX, t - 1), thumbColor) <= 6) {
    t--;
  }
  var b = midY;
  while (channelDistance(at(thumbX, b + 1), thumbColor) <= 6) {
    b++;
  }
  return SwitchFeatures(
    width: box.width,
    height: box.height,
    border: at(box.left + box.width ~/ 2, box.top),
    fill: fill,
    thumbLeft: l - box.left,
    thumbRight: r + 1 - box.left,
    thumbTop: t - box.top,
    thumbBottom: b + 1 - box.top,
    thumbColor: thumbColor,
  );
}

/// What [measureStepper] found. Ink boxes are relative to the box's left and
/// top.
final class StepperFeatures {
  const StepperFeatures({
    required this.width,
    required this.height,
    required this.border,
    required this.fill,
    required this.minus,
    required this.value,
    required this.plus,
  });

  final int width;
  final int height;
  final int border;
  final int fill;
  final PixelBox? minus;
  final PixelBox? value;
  final PixelBox? plus;
}

PixelBox? _relative(({PixelBox box, int core})? ink, PixelBox origin) {
  if (ink == null) return null;
  final b = ink.box;
  return PixelBox(
    b.left - origin.left,
    b.top - origin.top,
    b.right - origin.left,
    b.bottom - origin.top,
  );
}

/// Measures the stepper inside the window: its box and the ink of the minus,
/// the value and the plus (the three columns inside the border).
StepperFeatures measureStepper(
  PixelAt at,
  int x0,
  int y0,
  int x1,
  int y1,
  int bg,
) {
  final box = findBox(at, x0, y0, x1, y1, bg)!;
  final fill = at(box.left + 4, box.top + box.height ~/ 2);
  PixelBox? ink(int from, int to) =>
      _relative(findInk(at, from, box.top + 3, to, box.bottom - 3, fill), box);
  return StepperFeatures(
    width: box.width,
    height: box.height,
    border: at(box.left + box.width ~/ 2, box.top),
    fill: fill,
    minus: ink(box.left + 3, box.left + 36),
    value: ink(box.left + 36, box.right - 36),
    plus: ink(box.right - 36, box.right - 3),
  );
}

/// What [measureChip] found. Ink boxes are relative to the chip's left and
/// top.
final class ChipFeatures {
  const ChipFeatures({
    required this.width,
    required this.height,
    required this.border,
    required this.fill,
    required this.glyph,
    required this.glyphColor,
    required this.label,
    required this.labelColor,
  });

  final int width;
  final int height;
  final int border;
  final int fill;
  final PixelBox? glyph;
  final int glyphColor;
  final PixelBox? label;
  final int labelColor;
}

/// Measures one chip inside the window: box, border, fill, and the ink of
/// the glyph and of the label. The glyph is the first run of inked columns
/// and the label what follows the first gap of 4 or more empty columns (the
/// kit puts 8 px between them, and no glyph has a gap that wide).
ChipFeatures measureChip(PixelAt at, int x0, int y0, int x1, int y1, int bg) {
  final box = findBox(at, x0, y0, x1, y1, bg)!;
  final fill = at(box.left + box.width ~/ 2, box.top + 3);
  const tolerance = 24;
  // Inside the pill's curve: at 6 px from the top or bottom the border is
  // still at least 4 px from the sides this window keeps clear.
  final top = box.top + 6;
  final bottom = box.bottom - 6;
  bool inked(int x) {
    for (var y = top; y < bottom; y++) {
      if (channelDistance(at(x, y), fill) > tolerance) return true;
    }
    return false;
  }

  final from = box.left + 8;
  final to = box.right - 9;
  var x = from;
  while (x < to && !inked(x)) {
    x++;
  }
  final glyphFrom = x;
  var empty = 0;
  var glyphTo = x;
  for (; x < to; x++) {
    if (inked(x)) {
      glyphTo = x;
      empty = 0;
    } else if (++empty >= 4) {
      break;
    }
  }
  var labelFrom = glyphTo + 1;
  while (labelFrom < to && !inked(labelFrom)) {
    labelFrom++;
  }
  final glyph = findInk(
    at,
    glyphFrom,
    top,
    glyphTo + 1,
    bottom,
    fill,
    tolerance: tolerance,
  );
  final label = findInk(
    at,
    labelFrom,
    top,
    to,
    bottom,
    fill,
    tolerance: tolerance,
  );
  return ChipFeatures(
    width: box.width,
    height: box.height,
    border: at(box.left + box.width ~/ 2, box.top),
    fill: fill,
    glyph: _relative(glyph, box),
    glyphColor: glyph?.core ?? fill,
    label: _relative(label, box),
    labelColor: label?.core ?? fill,
  );
}
