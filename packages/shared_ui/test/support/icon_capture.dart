// ZOD-FND-009, test only: renders a widget into a fixed-size transparent
// boundary at devicePixelRatio 1 and reads its straight-alpha RGBA pixels,
// as button_sheet_test.dart does.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Straight-alpha RGBA pixels, row-major.
final class Pixels {
  Pixels(this.data, this.width, this.height);

  final ByteData data;
  final int width;
  final int height;

  int _i(int x, int y) => (y * width + x) * 4;

  int r(int x, int y) => data.getUint8(_i(x, y));
  int g(int x, int y) => data.getUint8(_i(x, y) + 1);
  int b(int x, int y) => data.getUint8(_i(x, y) + 2);
  int a(int x, int y) => data.getUint8(_i(x, y) + 3);

  List<int> get bytes =>
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

final _boundaryKey = GlobalKey();

/// Pumps [child] at the top-left of a [width] × [height] transparent
/// boundary (the view is exactly that size) and captures it.
///
/// [child] gets tight [width] × [height] constraints; wrap it in `Center`
/// for loose ones. [wrap] adds ancestors outside the boundary (a theme, an
/// `IconTheme`); the default is just a `Directionality`.
Future<Pixels> captureWidget(
  WidgetTester tester,
  Widget child, {
  required int width,
  required int height,
  TextDirection direction = TextDirection.ltr,
  Widget Function(Widget boundary)? wrap,
}) async {
  tester.view.physicalSize = Size(width.toDouble(), height.toDouble());
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final boundary = RepaintBoundary(
    key: _boundaryKey,
    child: SizedBox(
      width: width.toDouble(),
      height: height.toDouble(),
      child: child,
    ),
  );
  await tester.pumpWidget(
    Directionality(
      textDirection: direction,
      child: Align(
        alignment: Alignment.topLeft,
        child: wrap == null ? boundary : wrap(boundary),
      ),
    ),
  );
  final render = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundaryKey),
  );
  late Pixels pixels;
  await tester.runAsync(() async {
    final image = await render.toImage(pixelRatio: 1);
    final data = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    pixels = Pixels(data!, image.width, image.height);
    image.dispose();
  });
  return pixels;
}
