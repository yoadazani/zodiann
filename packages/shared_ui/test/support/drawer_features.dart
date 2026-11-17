// ZOD-NAV-002, test only: one feature extractor for the drawer, run on the
// reference PNGs (cropped to the panel) and on the rendered ZodiannDrawer, so
// both are measured by the same code.
//
// All coordinates are device pixels, *start-relative*: sx = 0 is the panel's
// start edge (the left in English, the right in Hebrew), so a Hebrew panel
// and an English one are comparable feature by feature. The image passed in
// is exactly the panel box (the 1 px inner border included, the outside
// outline and shadow excluded).
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Opaque RGBA pixels.
final class Rgba {
  Rgba(this.width, this.height, this.data);

  final int width;
  final int height;
  final ByteData data;

  int channel(int x, int y, int k) => data.getUint8((y * width + x) * 4 + k);

  int packed(int x, int y) =>
      channel(x, y, 0) << 16 | channel(x, y, 1) << 8 | channel(x, y, 2);

  /// A copy of the [w] × [h] region at ([x], [y]).
  Rgba crop(int x, int y, int w, int h) {
    final out = ByteData(w * h * 4);
    for (var row = 0; row < h; row++) {
      for (var col = 0; col < w; col++) {
        for (var k = 0; k < 4; k++) {
          out.setUint8((row * w + col) * 4 + k, channel(x + col, y + row, k));
        }
      }
    }
    return Rgba(w, h, out);
  }
}

/// Decodes PNG bytes (inside `tester.runAsync` in a widget test).
Future<Rgba> decodePng(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final image = (await codec.getNextFrame()).image;
  final out = await fromUiImage(image);
  image.dispose();
  codec.dispose();
  return out;
}

Future<Rgba> fromUiImage(ui.Image image) async {
  final data = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  return Rgba(image.width, image.height, data!);
}

/// The largest per-channel difference between two packed RGB colours.
int colourDiff(int a, int b) {
  var d = 0;
  for (final shift in [16, 8, 0]) {
    final v = (((a >> shift) & 255) - ((b >> shift) & 255)).abs();
    if (v > d) d = v;
  }
  return d;
}

/// One horizontal band of ink: consecutive rows holding text, icon or logo
/// pixels (a text line, with its icon).
final class Band {
  const Band(this.top, this.bottom, this.left, this.right);

  /// First and last row, first and last start-relative column.
  final int top, bottom, left, right;

  @override
  String toString() => 'Band(y $top–$bottom, sx $left–$right)';
}

/// What the extractor reads off a panel.
final class DrawerFeatures {
  const DrawerFeatures({
    required this.edgeWidth,
    required this.headRule,
    required this.footRule,
    required this.fillTop,
    required this.fillBottom,
    required this.fillLeft,
    required this.fillRight,
    required this.barLeft,
    required this.barRight,
    required this.barTop,
    required this.barBottom,
    required this.textBands,
    required this.sideBands,
  });

  /// Width of the inner-edge line (columns at the end edge off `surface`).
  final int edgeWidth;

  /// The header's bottom rule row and the footer's top rule row.
  final int headRule, footRule;

  /// The active item's fill rectangle (inclusive rows and columns).
  final int fillTop, fillBottom, fillLeft, fillRight;

  /// The active bar's columns and rows (inclusive).
  final int barLeft, barRight, barTop, barBottom;

  /// The ink bands of the text strip (from the top) and of the side strip
  /// (below the header), top to bottom.
  final List<Band> textBands, sideBands;
}

/// Reads the features off [panel]. [dpr] is the device pixel ratio the panel
/// was drawn at; [rtl] says the start edge is on the right.
DrawerFeatures extractDrawerFeatures(
  Rgba panel, {
  required int dpr,
  required bool rtl,
}) {
  final w = panel.width, h = panel.height;
  int px(int sx, int y) => panel.packed(rtl ? w - 1 - sx : sx, y);

  // The surface: a blank spot below the last item, above the footer.
  final sampleRow = (h * 0.75).round();
  final surface = px(w ~/ 2, sampleRow);

  // The inner-edge line: columns at the end edge that differ from surface.
  var edgeWidth = 0;
  for (var sx = w - 1; sx >= 0; sx--) {
    if (colourDiff(px(sx, sampleRow), surface) <= 6) break;
    edgeWidth++;
  }
  final contentEnd = w - edgeWidth; // exclusive

  // The header rule and the footer rule, down a column clear of any ink.
  final ruleX = 6 * dpr;
  var headRule = -1;
  for (var y = 4 * dpr; y < h; y++) {
    if (colourDiff(px(ruleX, y), surface) > 4) {
      headRule = y;
      break;
    }
  }
  var footRule = -1;
  for (var y = h - 1; y > 0; y--) {
    if (colourDiff(px(ruleX, y), surface) > 4) {
      footRule = y;
      break;
    }
  }

  // The active fill: down a column inside the item's left padding.
  final fillX = 16 * dpr;
  var fillTop = -1, fillBottom = -1;
  for (var y = headRule + 4 * dpr; y < footRule; y++) {
    final on = colourDiff(px(fillX, y), surface) > 6;
    if (on && fillTop < 0) fillTop = y;
    if (!on && fillTop >= 0) break;
    if (on) fillBottom = y;
  }
  final fillRow = fillTop + 4 * dpr;
  var fillLeft = -1, fillRight = -1;
  for (var sx = 0; sx < contentEnd; sx++) {
    if (colourDiff(px(sx, fillRow), surface) > 6) {
      fillLeft = sx;
      break;
    }
  }
  for (var sx = contentEnd - 1; sx >= 0; sx--) {
    if (colourDiff(px(sx, fillRow), surface) > 6) {
      fillRight = sx;
      break;
    }
  }

  // The active bar: bright columns near the fill's start edge, mid-height.
  final midRow = (fillTop + fillBottom) ~/ 2;
  final fillColour = px(fillX, midRow);
  var barLeft = -1, barRight = -1;
  for (var sx = fillLeft; sx < fillLeft + 10 * dpr; sx++) {
    if (colourDiff(px(sx, midRow), fillColour) > 60) {
      if (barLeft < 0) barLeft = sx;
      barRight = sx;
    }
  }
  var barTop = -1, barBottom = -1;
  final barX = (barLeft + barRight) ~/ 2;
  for (var y = fillTop; y <= fillBottom; y++) {
    if (colourDiff(px(barX, y), fillColour) > 60) {
      if (barTop < 0) barTop = y;
      barBottom = y;
    }
  }

  // Ink bands, per column strip (so an icon never merges with the text beside
  // it): the text strip (names, descriptions, the wordmark and its close
  // button: sx from 80 px, past the short group labels) from the top, and the
  // side strip (icons, group labels, footer: sx 20 to 56 px) below the
  // header. A pixel is ink when it differs from its row's commonest colour
  // (the background) by more than 40.
  final modes = List<int>.generate(h, (y) {
    final counts = <int, int>{};
    for (var sx = 0; sx < contentEnd; sx++) {
      counts.update(px(sx, y), (n) => n + 1, ifAbsent: () => 1);
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  });
  List<Band> bandsIn(int sx0, int sx1, int y0) {
    final bands = <Band>[];
    int? top, left, right;
    var last = -1;
    void close() {
      if (top != null) bands.add(Band(top!, last, left!, right!));
      top = null;
    }

    for (var y = y0; y < h; y++) {
      int? rowLeft, rowRight;
      for (var sx = sx0; sx < sx1 && sx < contentEnd; sx++) {
        if (colourDiff(px(sx, y), modes[y]) > 40) {
          rowLeft ??= sx;
          rowRight = sx;
        }
      }
      if (rowLeft == null) {
        if (top != null && y - last > 2 * dpr) close();
        continue;
      }
      if (top == null) {
        top = y;
        left = rowLeft;
        right = rowRight;
      } else {
        if (rowLeft < left!) left = rowLeft;
        if (rowRight! > right!) right = rowRight;
      }
      last = y;
    }
    close();
    return bands;
  }

  final textBands = bandsIn(80 * dpr, w, 0);
  final sideBands = bandsIn(20 * dpr, 56 * dpr, headRule + 1);

  return DrawerFeatures(
    edgeWidth: edgeWidth,
    headRule: headRule,
    footRule: footRule,
    fillTop: fillTop,
    fillBottom: fillBottom,
    fillLeft: fillLeft,
    fillRight: fillRight,
    barLeft: barLeft,
    barRight: barRight,
    barTop: barTop,
    barBottom: barBottom,
    textBands: textBands,
    sideBands: sideBands,
  );
}

/// The extreme pixel of the region (rows [y0, y1], start-relative columns
/// [sx0, sx1]): the brightest when [brightest], else the darkest, by channel
/// sum. Returns the packed RGB.
int extremePixel(
  Rgba panel, {
  required bool rtl,
  required int y0,
  required int y1,
  required int sx0,
  required int sx1,
  required bool brightest,
}) {
  final w = panel.width;
  var best = -1;
  var bestSum = brightest ? -1 : 1 << 20;
  for (var y = y0; y <= y1; y++) {
    for (var sx = sx0; sx <= sx1; sx++) {
      final c = panel.packed(rtl ? w - 1 - sx : sx, y);
      final sum = (c >> 16 & 255) + (c >> 8 & 255) + (c & 255);
      if (brightest ? sum > bestSum : sum < bestSum) {
        bestSum = sum;
        best = c;
      }
    }
  }
  return best;
}

/// The mean over all pixels of the largest per-channel difference between
/// two same-size images.
double meanAbsDiff(Rgba a, Rgba b) {
  assert(a.width == b.width && a.height == b.height);
  var total = 0;
  for (var y = 0; y < a.height; y++) {
    for (var x = 0; x < a.width; x++) {
      total += colourDiff(a.packed(x, y), b.packed(x, y));
    }
  }
  return total / (a.width * a.height);
}
