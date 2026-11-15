// ZOD-FND-009: ZodiannIcon's size, colour, layout and semantics.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_ui/src/icons/zodiann_icon.dart' show ZodiannIconPainter;

import '../support/button_harness.dart';
import '../support/icon_capture.dart';

const _black = Color(0xFF000000);

ZodiannIconPainter _painter(WidgetTester tester, [Finder? icon]) =>
    tester
            .widget<CustomPaint>(
              find.descendant(
                of: icon ?? find.byType(ZodiannIcon),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!
        as ZodiannIconPainter;

int _peakAlpha(Pixels p) {
  var peak = 0;
  for (var y = 0; y < p.height; y++) {
    for (var x = 0; x < p.width; x++) {
      peak = math.max(peak, p.a(x, y));
    }
  }
  return peak;
}

void main() {
  group('size', () {
    testWidgets(
      'default size is ZodiannSize.icon (20) under the Zodiann theme',
      (tester) async {
        await pumpInApp(tester, const ZodiannIcon(ZodiannIcons.x));
        expect(
          tester.getSize(find.byType(ZodiannIcon)),
          const Size.square(ZodiannSize.icon),
        );
        expect(_painter(tester).size, ZodiannSize.icon);
      },
    );

    testWidgets('no ambient size → 20, never the Material 24 fallback', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: ZodiannIcon(ZodiannIcons.x)),
        ),
      );
      expect(
        tester.getSize(find.byType(ZodiannIcon)),
        const Size.square(ZodiannSize.icon),
      );
    });

    testWidgets('IconTheme with colour only keeps 20', (tester) async {
      await pumpInApp(
        tester,
        const IconTheme(
          data: IconThemeData(color: _black),
          child: ZodiannIcon(ZodiannIcons.x),
        ),
      );
      expect(
        tester.getSize(find.byType(ZodiannIcon)),
        const Size.square(ZodiannSize.icon),
      );
    });

    testWidgets('explicit size: ZodiannSize.iconSmall gives 16', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        const ZodiannIcon(ZodiannIcons.x, size: ZodiannSize.iconSmall),
      );
      expect(
        tester.getSize(find.byType(ZodiannIcon)),
        const Size.square(ZodiannSize.iconSmall),
      );
    });

    testWidgets('an ambient IconTheme size wins over the theme', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        const IconTheme(
          data: IconThemeData(size: ZodiannSize.iconSmall),
          child: ZodiannIcon(ZodiannIcons.x),
        ),
      );
      expect(
        tester.getSize(find.byType(ZodiannIcon)),
        const Size.square(ZodiannSize.iconSmall),
      );
    });

    testWidgets(
      'inside ZodiannButton the icon is 16 and tinted with the label colour',
      (tester) async {
        await pumpInApp(
          tester,
          ZodiannButton(
            label: 'Save',
            onPressed: () {},
            variant: ZodiannButtonVariant.primary,
            icon: const ZodiannIcon(ZodiannIcons.save),
          ),
        );
        final surfaces = ZodiannTheme.graphite.extension<ZodiannSurfaces>()!;
        final painter = _painter(tester);
        expect(painter.size, ZodiannSize.iconSmall);
        expect(
          painter.color,
          ZodiannButtonColors.resolve(
            surfaces,
            ZodiannButtonVariant.primary,
          ).label,
        );
      },
    );

    testWidgets('textScaler 2.0 does not change the size', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: ZodiannIcon(ZodiannIcons.x)),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(ZodiannIcon)),
        const Size.square(ZodiannSize.icon),
      );
    });
  });

  testWidgets('tight 100 × 40 box draws a centred 20 px icon', (tester) async {
    final p = await captureWidget(
      tester,
      const ZodiannIcon(ZodiannIcons.x, color: _black),
      width: 100,
      height: 40,
    );
    var minX = p.width, minY = p.height, maxX = -1, maxY = -1;
    for (var y = 0; y < p.height; y++) {
      for (var x = 0; x < p.width; x++) {
        if (p.a(x, y) > 0) {
          minX = math.min(minX, x);
          maxX = math.max(maxX, x);
          minY = math.min(minY, y);
          maxY = math.max(maxY, y);
        }
      }
    }
    expect(maxX, greaterThanOrEqualTo(0), reason: 'nothing painted');
    expect((minX + maxX + 1) / 2, closeTo(50, 0.5));
    expect((minY + maxY + 1) / 2, closeTo(20, 0.5));
    expect(maxX - minX + 1, lessThanOrEqualTo(ZodiannSize.icon));
    expect(maxY - minY + 1, lessThanOrEqualTo(ZodiannSize.icon));
  });

  group('colour', () {
    for (final (name, theme) in [
      ('graphite', ZodiannTheme.graphite),
      ('porcelain', ZodiannTheme.porcelain),
    ]) {
      testWidgets('$name: default is the theme text colour', (tester) async {
        await pumpInApp(
          tester,
          const ZodiannIcon(ZodiannIcons.x),
          theme: theme,
        );
        expect(
          _painter(tester).color,
          theme.extension<ZodiannSurfaces>()!.text,
        );
      });

      testWidgets('$name: an explicit colour wins', (tester) async {
        final accent = theme.extension<ZodiannSurfaces>()!.accent;
        await pumpInApp(
          tester,
          ZodiannIcon(ZodiannIcons.x, color: accent),
          theme: theme,
        );
        expect(_painter(tester).color, accent);
      });
    }
  });

  testWidgets('IconTheme opacity 0.5 halves the painted alpha', (tester) async {
    Future<int> peak(double opacity) async => _peakAlpha(
      await captureWidget(
        tester,
        const Center(child: ZodiannIcon(ZodiannIcons.check)),
        width: 20,
        height: 20,
        wrap: (child) => IconTheme(
          data: IconThemeData(color: _black, opacity: opacity),
          child: child,
        ),
      ),
    );
    final full = await peak(1);
    final half = await peak(0.5);
    expect(full, greaterThan(200));
    expect(half, closeTo(full / 2, 2));
  });

  group('semantics', () {
    testWidgets('decorative by default', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInApp(tester, const ZodiannIcon(ZodiannIcons.x));
      expect(
        find.descendant(
          of: find.byType(ZodiannIcon),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('.+')), findsNothing);
      handle.dispose();
    });

    testWidgets('labelled icons are announced as images', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInApp(
        tester,
        const ZodiannIcon(ZodiannIcons.x, semanticLabel: 'Close'),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Close')),
        matchesSemantics(label: 'Close', isImage: true),
      );
      handle.dispose();
    });
  });

  group('every icon paints', () {
    for (final s in [ZodiannSize.iconSmall, ZodiannSize.icon]) {
      final n = s.toInt();
      for (final icon in ZodiannIcons.values) {
        testWidgets('${icon.name} at $n', (tester) async {
          final p = await captureWidget(
            tester,
            Center(
              child: ZodiannIcon(icon, size: s, color: _black),
            ),
            width: 2 * n,
            height: 2 * n,
          );
          var inked = false;
          for (var y = 0; y < p.height; y++) {
            for (var x = 0; x < p.width; x++) {
              final inside =
                  x >= n ~/ 2 &&
                  x < n ~/ 2 + n &&
                  y >= n ~/ 2 &&
                  y < n ~/ 2 + n;
              if (!inside) {
                expect(p.a(x, y), 0, reason: 'ink outside at ($x, $y)');
              } else if (p.a(x, y) > 127) {
                inked = true;
              }
            }
          }
          expect(inked, isTrue);
        });
      }
    }
  });
}
