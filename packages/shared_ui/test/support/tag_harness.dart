// ZOD-UI-009, test only: renders one ZodiannTag on the sheet's `surface`
// backdrop at an integer origin and returns its pixels and layout width.
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import 'button_harness.dart';
import 'tag_features.dart';

/// Where the tag sits in its cell: 8 px of backdrop on every side.
const tagCellOrigin = 8;

const _boundaryKey = Key('tag-cell');

/// A rendered tag cell.
typedef TagRender = ({Rgba image, double layoutWidth});

/// Renders `ZodiannTag(variant, label)` at ([tagCellOrigin], [tagCellOrigin])
/// in a 130 × 40 `surface` cell (the next tag on the sheet is only 8 px
/// away, so each tag gets its own cell) at device pixel ratio 1.
Future<TagRender> renderTag(
  WidgetTester tester,
  ThemeData theme,
  ZodiannTagVariant variant,
  String label,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 200);
  addTearDown(tester.view.reset);
  final s = theme.extension<ZodiannSurfaces>()!;
  await pumpInApp(
    tester,
    RepaintBoundary(
      key: _boundaryKey,
      child: ColoredBox(
        color: s.surface,
        child: SizedBox(
          width: 130,
          height: 40,
          child: Stack(
            children: [
              Positioned(
                left: tagCellOrigin.toDouble(),
                top: tagCellOrigin.toDouble(),
                child: ZodiannTag(variant: variant, label: label),
              ),
            ],
          ),
        ),
      ),
    ),
    theme: theme,
  );
  await tester.pumpAndSettle();
  final layoutWidth = tester.getSize(find.byType(ZodiannTag)).width;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundaryKey),
  );
  late Rgba rgba;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    rgba = Rgba(image.width, image.height, data!);
    image.dispose();
  });
  return (image: rgba, layoutWidth: layoutWidth);
}
