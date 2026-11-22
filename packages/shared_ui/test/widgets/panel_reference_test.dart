// ZOD-UI-014: the panel shell against the designer's settings screen
// (04-settings_desktop_en_dark.png, 1440 wide, so 1x): the border, fill and
// page colours, the head rule 56 below the panel's top, and the 12 px arc.
//
// Only the shell and the head are compared. The settings rows are owned by the
// SET tasks. Chrome smears the panel's top border over two rows, so the top is
// the first non-page row and everything is measured from it.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/pixels.dart';

const _reference =
    '../../design-reference/zodiann/screens/04-settings_desktop_en_dark.png';
const _boundary = Key('panel-reference-boundary');

/// What the reference and the widget must agree on.
typedef _Facts = ({
  int outside,
  int border,
  int inside,
  int ruleBelowTop,
  int arcEndsBelowTop,
  int width,
});

_Facts _measure(Pixels px, {required int atRow, required int fromY}) {
  final page = px.argb(2, atRow);
  final left = px.firstX(atRow, 0, (c) => c != page);
  // The panel's top: the first non-page row down a column inside the panel.
  final probeX = left + 300;
  final top = px.firstY(probeX, fromY, (c) => c != page);
  final border = px.argb(left, top + 30);
  final right = px.firstX(top + 30, left + 1, (c) => c == border);
  final rule = px.firstY(probeX, top + 1, (c) => c == border);
  final arcEnd = px.firstY(left, top, (c) => c == border);
  return (
    outside: px.argb(left - 1, top + 30),
    border: border,
    inside: px.argb(left + 1, top + 30),
    ruleBelowTop: rule - top,
    arcEndsBelowTop: arcEnd - top,
    width: right - left + 1,
  );
}

void main() {
  final file = File(_reference);
  final present = file.existsSync();

  testWidgets(
    'the panel shell matches the settings reference',
    // Skipped only when the designer's file is absent (never copied here).
    skip: !present,
    (tester) async {
      // The reference.
      late Pixels ref;
      await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(file.readAsBytesSync());
        final image = (await codec.getNextFrame()).image;
        final raw = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        ref = Pixels(image.width, image.height, raw);
        image.dispose();
      });
      expect(ref.width, 1440, reason: 'the reference is 1x');
      // Row 300 crosses the first settings panel's body, below the top bar
      // (its rule is at y = 63).
      final expected = _measure(ref, atRow: 300, fromY: 70);
      expect(expected.ruleBelowTop, 56, reason: 'reference head is 56');
      expect(expected.width, 556, reason: 'reference panel width');

      // The widget, at the reference panel's width.
      tester.view.physicalSize = const Size(1440, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final s = ZodiannTheme.graphite.extension<ZodiannSurfaces>()!;
      await tester.pumpWidget(
        Theme(
          data: ZodiannTheme.graphite,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: _boundary,
              child: ColoredBox(
                color: s.bg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: expected.width.toDouble(),
                          child: const ZodiannPanel(
                            head: ZodiannPanelHead(),
                            child: SizedBox(height: 200),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final ours = await Pixels.capture(
        tester,
        tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary)),
      );
      final actual = _measure(ours, atRow: 200, fromY: 0);

      expect(actual.outside, expected.outside, reason: 'page colour');
      expect(actual.border, expected.border, reason: 'border colour');
      expect(actual.inside, expected.inside, reason: 'fill colour');
      expect(actual.width, expected.width, reason: 'panel width');
      expect(actual.ruleBelowTop, expected.ruleBelowTop, reason: 'head rule');
      expect(
        actual.arcEndsBelowTop,
        closeTo(expected.arcEndsBelowTop, 1),
        reason: 'where the 12 px arc ends',
      );
    },
  );
}
