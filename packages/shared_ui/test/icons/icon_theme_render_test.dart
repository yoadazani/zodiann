// ZOD-FND-009 criterion 1: every icon renders at 20 and 16 px in light and
// dark, tinted with the theme's text colour and with the same geometry as
// the black render that icon_fidelity_test.dart checks against Chrome.
//
// With ZODIANN_ICON_SPECIMEN_DIR set, also writes icon_specimen_{dark,light}
// .png there for review by eye (both sizes on `surface`, plus back / forward
// in LTR and RTL).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/icon_capture.dart';
import '../support/icon_sheet.dart';

const _black = Color(0xFF000000);

int _channel(double c) => (c * 255).round();

void main() {
  for (final (name, theme) in [
    ('dark', ZodiannTheme.graphite),
    ('light', ZodiannTheme.porcelain),
  ]) {
    final text = theme.extension<ZodiannSurfaces>()!.text;
    for (final s in [16, 20]) {
      testWidgets('$name at $s px: tinted text, same geometry as black', (
        tester,
      ) async {
        final black = await renderIconSheet(tester, s, color: _black);
        final themed = await renderIconSheet(tester, s, theme: theme);
        final problems = <String>[];
        for (final (i, icon) in ZodiannIcons.values.indexed) {
          var opaque = 0;
          for (var y = 0; y < s; y++) {
            for (var x = i * s; x < (i + 1) * s; x++) {
              final a = themed.a(x, y);
              if ((a - black.a(x, y)).abs() > 1) {
                problems.add('${icon.name}: alpha ${black.a(x, y)} → $a');
                break;
              }
              if (a >= 128) {
                opaque++;
                final rgb = [themed.r(x, y), themed.g(x, y), themed.b(x, y)];
                final want = [
                  _channel(text.r),
                  _channel(text.g),
                  _channel(text.b),
                ];
                for (var c = 0; c < 3; c++) {
                  if ((rgb[c] - want[c]).abs() > 2) {
                    problems.add('${icon.name}: rgb $rgb, want $want');
                    break;
                  }
                }
              }
            }
          }
          if (opaque == 0) problems.add('${icon.name}: no opaque pixel');
        }
        expect(problems.toSet(), isEmpty, reason: problems.toSet().join('\n'));
      });
    }

    testWidgets(
      '$name specimen (written only with ZODIANN_ICON_SPECIMEN_DIR)',
      (tester) async {
        final dir = Platform.environment['ZODIANN_ICON_SPECIMEN_DIR'];
        if (dir == null) return;
        Directory(dir).createSync(recursive: true);
        final surfaces = theme.extension<ZodiannSurfaces>()!;
        Widget row(double size) => Row(
          mainAxisSize: MainAxisSize.min,
          spacing: ZodiannSpace.s2,
          children: [
            for (final icon in ZodiannIcons.values)
              ZodiannIcon(icon, size: size),
          ],
        );
        Widget arrows(TextDirection direction) => Directionality(
          textDirection: direction,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: ZodiannSpace.s2,
            children: [iconBack(), iconFwd()],
          ),
        );
        await captureWidget(
          tester,
          ColoredBox(
            color: surfaces.surface,
            child: Padding(
              padding: const EdgeInsets.all(ZodiannSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: ZodiannSpace.s4,
                children: [
                  row(ZodiannSize.icon),
                  row(ZodiannSize.iconSmall),
                  Row(
                    spacing: ZodiannSpace.s8,
                    children: [
                      arrows(TextDirection.ltr),
                      arrows(TextDirection.rtl),
                    ],
                  ),
                ],
              ),
            ),
          ),
          width: 1000,
          height: 140,
          wrap: (child) => Theme(data: theme, child: child),
          savePng: '$dir/icon_specimen_$name.png',
        );
      },
    );
  }
}
