// ZOD-FND-009, test only: renders a widget into a fixed-size transparent
// boundary (devicePixelRatio 1 unless asked, ZOD-FND-008) and reads its
// straight-alpha RGBA pixels, as button_sheet_test.dart does.
import 'dart:io';
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
/// [child] gets tight [width] × [height] logical constraints; wrap it in
/// `Center` for loose ones. [wrap] adds ancestors outside the boundary (a
/// theme, an `IconTheme`); the default is just a `Directionality`. At a
/// [devicePixelRatio] above 1 the returned [Pixels] are
/// `width·dpr × height·dpr`.
Future<Pixels> captureWidget(
  WidgetTester tester,
  Widget child, {
  required int width,
  required int height,
  double devicePixelRatio = 1,
  TextDirection direction = TextDirection.ltr,
  Widget Function(Widget boundary)? wrap,
  String? savePng,
}) async {
  tester.view.physicalSize = Size(
    width * devicePixelRatio,
    height * devicePixelRatio,
  );
  tester.view.devicePixelRatio = devicePixelRatio;
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
    final image = await render.toImage(pixelRatio: devicePixelRatio);
    final data = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    pixels = Pixels(data!, image.width, image.height);
    if (savePng != null) {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File(savePng).writeAsBytesSync(png!.buffer.asUint8List());
    }
    image.dispose();
  });
  return pixels;
}
