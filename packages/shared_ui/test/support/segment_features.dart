// ZOD-UI-006, test only: measures a segmented-control row the same way on the
// design's component sheet and on a Flutter render, so the two can be compared
// feature by feature (track box and colours, the selected thumb, the ink of
// every label and icon).
//
// The sheet stretches each track to its grid column; only the left, top and
// height of the track are compared, never its right edge.
import 'tag_features.dart';

export 'tag_features.dart' show Rgba, decodeDesignPng, hex;

/// One segment of a row, as laid out by Chrome (the source layout).
typedef SegmentSpec = ({
  /// Left edge relative to the track's left border pixel.
  double rel,
  double width,
  bool hasIcon,
});

/// What [measureSegmentRow] found. All colours are 8-bit ARGB.
final class SegmentFeatures {
  const SegmentFeatures({
    required this.left,
    required this.top,
    required this.height,
    required this.border,
    required this.trackFill,
    required this.thumbLeft,
    required this.thumbWidth,
    required this.thumbHeight,
    required this.thumbTopOffset,
    required this.thumbFill,
    required this.ring,
    required this.inks,
    required this.icons,
  });

  final int left;
  final int top;

  /// Border to border, inclusive (40 when correct).
  final int height;

  /// The track's left border pixel and its fill 2 px inside.
  final int border;
  final int trackFill;

  /// The selected thumb: left edge, width, height, and where its top edge is
  /// below the track's top border.
  final int thumbLeft;
  final int thumbWidth;
  final int thumbHeight;
  final int thumbTopOffset;

  /// The thumb's fill (6 px in from its left edge) and the pixel of its top
  /// ring on the thumb's middle column.
  final int thumbFill;
  final int ring;

  /// Per segment, the label pixel farthest from the local fill, and for
  /// segments with an icon the icon pixel farthest from it (else 0).
  final List<int> inks;
  final List<int> icons;

  @override
  String toString() =>
      'SegmentFeatures(left: $left, top: $top, height: $height, '
      'border: ${hex(border)}, trackFill: ${hex(trackFill)}, thumb: '
      '$thumbLeft/$thumbWidth x $thumbHeight at +$thumbTopOffset, '
      'thumbFill: ${hex(thumbFill)}, ring: ${hex(ring)}, '
      'inks: ${inks.map(hex).toList()}, icons: ${icons.map(hex).toList()})';
}

int _distance(int a, int b) {
  var sum = 0;
  for (final shift in [16, 8, 0]) {
    sum += (((a >> shift) & 0xFF) - ((b >> shift) & 0xFF)).abs();
  }
  return sum;
}

/// The pixel in the box that is farthest (RGB) from [reference].
int _farthest(Rgba px, int x0, int x1, int y0, int y1, int reference) {
  var best = reference;
  var bestDistance = -1;
  for (var y = y0; y <= y1; y++) {
    for (var x = x0; x <= x1; x++) {
      final c = px.argb(x, y);
      final d = _distance(c, reference);
      if (d > bestDistance) {
        bestDistance = d;
        best = c;
      }
    }
  }
  return best;
}

/// Measures one row. [yHint] is any y inside the track; [scanFrom] an x left
/// of the track and right of anything else on that line; [line] is the
/// track's border colour (`line-soft`); [selected] indexes [segments].
SegmentFeatures measureSegmentRow(
  Rgba px, {
  required int yHint,
  required int scanFrom,
  required int line,
  required List<SegmentSpec> segments,
  required int selected,
}) {
  var left = scanFrom;
  while (px.argb(left, yHint) != line) {
    left++;
  }
  // The track's top and bottom borders, on a column past the 8 px corners.
  final col = left + 12;
  var top = yHint;
  while (px.argb(col, top) != line) {
    top--;
  }
  var bottom = yHint;
  while (px.argb(col, bottom) != line) {
    bottom++;
  }
  final trackFill = px.argb(left + 2, top + 20);

  // The thumb, on the row 8 px below the top border (above any label).
  final row = top + 8;
  var thumbLeft = left + 3;
  while (px.argb(thumbLeft, row) == trackFill) {
    thumbLeft++;
  }
  var thumbRight = thumbLeft + 20;
  while (px.argb(thumbRight, row) != trackFill) {
    thumbRight++;
  }
  thumbRight--;
  final thumbCol = thumbLeft + 15;
  var thumbTop = top + 1;
  while (px.argb(thumbCol, thumbTop) == trackFill) {
    thumbTop++;
  }
  var thumbBottom = thumbTop + 10;
  while (px.argb(thumbCol, thumbBottom) != trackFill) {
    thumbBottom++;
  }
  thumbBottom--;
  final thumbFill = px.argb(thumbLeft + 6, row);

  final inks = <int>[];
  final icons = <int>[];
  for (var i = 0; i < segments.length; i++) {
    final s = segments[i];
    final x0 = (left + s.rel).round() + 12;
    final x1 = (left + s.rel + s.width).round() - 12;
    final reference = i == selected ? thumbFill : trackFill;
    final y0 = top + 10;
    final y1 = top + 30;
    if (s.hasIcon) {
      icons.add(_farthest(px, x0, x0 + 16, y0, y1, reference));
      inks.add(_farthest(px, x0 + 22, x1, y0, y1, reference));
    } else {
      icons.add(0);
      inks.add(_farthest(px, x0, x1, y0, y1, reference));
    }
  }

  return SegmentFeatures(
    left: left,
    top: top,
    height: bottom - top + 1,
    border: px.argb(left, top + 20),
    trackFill: trackFill,
    thumbLeft: thumbLeft,
    thumbWidth: thumbRight - thumbLeft + 1,
    thumbHeight: thumbBottom - thumbTop + 1,
    thumbTopOffset: thumbTop - top,
    thumbFill: thumbFill,
    ring: px.argb(thumbCol, thumbTop),
    inks: inks,
    icons: icons,
  );
}
