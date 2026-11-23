// ZOD-UI-013, test only: reads a dialog's geometry the same way from the
// designer's PNGs, the generated references and a Flutter render, so they
// compare feature by feature (box, ring, rows of ink, button boxes).
import 'dart:io';
import 'dart:ui' as ui;

import 'table_features.dart';

/// Decodes a PNG file (a path relative to `packages/shared_ui`).
Future<({int width, int height, int Function(int x, int y) at})> decodeFile(
  String path,
) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  final image = (await codec.getNextFrame()).image;
  final data = (await image.toByteData())!;
  final w = image.width;
  final h = image.height;
  image.dispose();
  int at(int x, int y) {
    final i = (y * w + x) * 4;
    return (data.getUint8(i + 3) << 24) |
        (data.getUint8(i) << 16) |
        (data.getUint8(i + 1) << 8) |
        data.getUint8(i + 2);
  }

  return (width: w, height: h, at: at);
}

/// What [measureDialog] found. Coordinates are absolute pixels of the image.
final class DialogFeatures {
  const DialogFeatures({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.fill,
    required this.ringSide,
    required this.ringTop,
    required this.ringBottom,
    required this.ink,
    required this.buttons,
  });

  /// The box's first and last fill column and row (inclusive).
  final int left;
  final int right;
  final int top;
  final int bottom;

  int get width => right - left + 1;
  int get height => bottom - top + 1;

  /// The box's fill colour (ARGB).
  final int fill;

  /// The ring pixel outside the left edge, above the top edge and below the
  /// bottom edge (all measured on a column or row clear of text).
  final int ringSide;
  final int ringTop;
  final int ringBottom;

  /// Rows of ink inside the padding box, as (first, last) row, in order:
  /// the title, each message line, the field if any, the buttons.
  final List<(int, int)> ink;

  /// Interior boxes of the buttons on a row inside the last ink group but
  /// clear of their labels, as (first column, length).
  final List<(int, int)> buttons;
}

/// Measures the dialog around (`probeX`, `probeY`): a point inside the box's
/// fill on a row with straight edges and no ink (20 below the top edge) and
/// left of any text.
DialogFeatures measureDialog(
  int Function(int x, int y) at, {
  required int probeX,
  required int probeY,
  int padding = 24,
}) {
  final fill = at(probeX, probeY);
  var left = probeX;
  while (at(left - 1, probeY) == fill) {
    left--;
  }
  var right = probeX;
  while (at(right + 1, probeY) == fill) {
    right++;
  }
  // Vertical scans on a column inside the left padding, clear of text and
  // outside the 16 radius.
  final col = left + 20;
  var top = probeY;
  while (at(col, top - 1) == fill) {
    top--;
  }
  var bottom = probeY;
  while (at(col, bottom + 1) == fill) {
    bottom++;
  }
  final ink = <(int, int)>[];
  int? start;
  for (var y = top; y <= bottom; y++) {
    var any = false;
    for (var x = left + padding; x <= right - padding; x++) {
      if (at(x, y) != fill) {
        any = true;
        break;
      }
    }
    if (any) {
      start ??= y;
    } else if (start != null) {
      ink.add((start, y - 1));
      start = null;
    }
  }
  if (start != null) ink.add((start, bottom));
  final last = ink.last;
  final buttonRow = last.$1 + 3;
  final buttons = <(int, int)>[
    for (final run in horizontalRuns(at, buttonRow, left + 1, right - 1))
      if (!near(run.color, fill, 2) && run.length >= 20)
        (run.start, run.length),
  ];
  return DialogFeatures(
    left: left,
    right: right,
    top: top,
    bottom: bottom,
    fill: fill,
    ringSide: at(left - 1, probeY),
    ringTop: at(col, top - 1),
    ringBottom: at(col, bottom + 1),
    ink: ink,
    buttons: buttons,
  );
}
