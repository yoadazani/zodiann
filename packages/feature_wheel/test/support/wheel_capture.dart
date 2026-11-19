import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Theme;
import 'package:shared_ui/shared_ui.dart';

final _frame = GlobalKey();

/// A `wrap` for `pumpWheelCanvas`: the canvas in a 644 x 656 box on the
/// theme's `surface` (what the kit panel draws on), inside a boundary that
/// wraps the background, so a translucent tint blends as it does on screen.
Widget Function(Widget) onSurface({double textScale = 1}) =>
    (canvas) => Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: RepaintBoundary(
          key: _frame,
          child: ColoredBox(
            color: Theme.of(context).extension<ZodiannSurfaces>()!.surface,
            child: SizedBox(width: 644, height: 656, child: canvas),
          ),
        ),
      ),
    );

/// The pixels of the last `onSurface` frame, as straight RGBA bytes.
Future<List<int>> captureBytes(WidgetTester tester) async {
  final boundary =
      _frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = (await tester.runAsync(boundary.toImage))!;
  final data = await tester.runAsync(image.toByteData);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Decodes a PNG file's bytes into straight RGBA.
Future<List<int>> decodePng(WidgetTester tester, List<int> png) async {
  final codec = (await tester.runAsync(
    () => ui.instantiateImageCodec(Uint8List.fromList(png)),
  ))!;
  final frame = (await tester.runAsync(codec.getNextFrame))!;
  final data = await tester.runAsync(frame.image.toByteData);
  frame.image.dispose();
  codec.dispose();
  return data!.buffer.asUint8List();
}
