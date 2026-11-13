// ZOD-UI-004: ZodiannButton structure and layout — the 44 × 44 target
// around the unchanged 40 / 32 drawn box (D3), CSS border-box padding
// (17 / 13), the 16 px icon slot, label styles and variant decoration.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/button_harness.dart';
import '../support/load_bundled_fonts.dart';

const _iconKey = Key('icon');

void main() {
  setUpAll(loadBundledFonts);

  final sizes = {
    ZodiannButtonSize.regular: (drawn: 40.0, inset: 17.0),
    ZodiannButtonSize.small: (drawn: 32.0, inset: 13.0),
  };

  group('the target is at least 44 × 44 and the drawn box is unchanged', () {
    for (final MapEntry(key: size, value: spec) in sizes.entries) {
      for (final label in ['Save', 'OK', '1']) {
        testWidgets('$size "$label"', (tester) async {
          await pumpInApp(
            tester,
            ZodiannButton(label: label, onPressed: () {}, size: size),
          );
          final target = tester.getRect(find.byType(ZodiannButton));
          final drawn = tester.getRect(drawnBox());
          final labelWidth = tester.getSize(labelText()).width;

          expect(drawn.height, spec.drawn);
          expect(drawn.width, closeTo(2 * spec.inset + labelWidth, 0.01));
          expect(target.size, Size(math.max(drawn.width, 44), 44));
          expect(
            drawn.left - target.left,
            closeTo(target.right - drawn.right, 0.5),
            reason: 'centred horizontally',
          );
          expect(
            drawn.top - target.top,
            closeTo(target.bottom - drawn.bottom, 0.5),
            reason: 'centred vertically',
          );

          await pumpInApp(
            tester,
            SizedBox(
              height: 300,
              child: Row(
                children: [
                  ZodiannButton(label: label, onPressed: () {}, size: size),
                ],
              ),
            ),
          );
          final inRow = tester.getSize(find.byType(ZodiannButton));
          final drawnInRow = tester.getSize(drawnBox());
          expect(inRow.height, 44, reason: 'in a 300-high Row');
          expect(inRow.width, math.max(drawnInRow.width, 44));
        });
      }
    }

    testWidgets('narrow labels take the minWidth path; a margin tap '
        'activates', (tester) async {
      for (final (size, label) in [
        (ZodiannButtonSize.regular, '1'),
        (ZodiannButtonSize.small, 'OK'),
        (ZodiannButtonSize.small, '1'),
      ]) {
        await pumpInApp(
          tester,
          ZodiannButton(label: label, onPressed: () {}, size: size),
        );
        expect(
          tester.getSize(drawnBox()).width,
          lessThan(44),
          reason: '$size "$label" is drawn narrower than 44',
        );
        expect(tester.getSize(find.byType(ZodiannButton)).width, 44);
      }

      var taps = 0;
      await pumpInApp(
        tester,
        ZodiannButton(
          label: '1',
          onPressed: () => taps++,
          size: ZodiannButtonSize.small,
        ),
      );
      final target = tester.getRect(find.byType(ZodiannButton));
      final drawn = tester.getRect(drawnBox());
      expect(target.left + 1, lessThan(drawn.left), reason: 'margin > 1 px');
      await tester.tapAt(Offset(target.left + 1, target.center.dy));
      expect(taps, 1);
    });
  });

  testWidgets('border-box padding, gap and icon slot', (tester) async {
    for (final MapEntry(key: size, value: spec) in sizes.entries) {
      for (final withIcon in [true, false]) {
        await pumpInApp(
          tester,
          ZodiannButton(
            label: 'Save',
            onPressed: () {},
            size: size,
            icon: withIcon ? const SizedBox(key: _iconKey) : null,
          ),
        );
        final box = tester.getRect(drawnBox());
        final text = tester.getRect(labelText());
        final why = '$size icon: $withIcon';
        expect(
          text.left - box.left,
          closeTo(spec.inset + (withIcon ? 16 + 8 : 0), 0.01),
          reason: why,
        );
        expect(box.right - text.right, closeTo(spec.inset, 0.01), reason: why);
        if (withIcon) {
          final icon = tester.getRect(find.byKey(_iconKey));
          expect(icon.left - box.left, closeTo(spec.inset, 0.01), reason: why);
          expect(icon.size, const Size(16, 16), reason: why);
        }
      }
    }
  });

  for (final (themeName, theme) in [
    ('Graphite', ZodiannTheme.graphite),
    ('Porcelain', ZodiannTheme.porcelain),
  ]) {
    testWidgets('$themeName: label style and decoration per variant', (
      tester,
    ) async {
      final s = theme.extension<ZodiannSurfaces>()!;
      final styles = theme.extension<ZodiannTextStyles>()!;
      for (final variant in ZodiannButtonVariant.values) {
        for (final size in ZodiannButtonSize.values) {
          await pumpInApp(
            tester,
            ZodiannButton(
              label: 'Save',
              onPressed: () {},
              variant: variant,
              size: size,
            ),
            theme: theme,
          );
          final why = '$variant $size';
          final colors = ZodiannButtonColors.resolve(s, variant);
          final style = tester.widget<Text>(labelText()).style!;
          expect(style.color, colors.label, reason: why);
          expect(
            style.fontWeight,
            variant == ZodiannButtonVariant.primary
                ? FontWeight.w600
                : FontWeight.w500,
            reason: why,
          );
          expect(
            style.fontSize,
            size == ZodiannButtonSize.regular ? 14 : 13,
            reason: why,
          );
          expect(style.fontFamily, styles.body.fontFamily, reason: why);

          final decoration =
              tester.widget<DecoratedBox>(drawnBox()).decoration
                  as BoxDecoration;
          expect(decoration.color, colors.fill, reason: why);
          expect(
            decoration.border,
            Border.all(color: colors.border),
            reason: why,
          );
          expect(decoration.borderRadius, ZodiannRadius.control, reason: why);
        }
      }
    });
  }

  for (final hebrew in [false, true]) {
    testWidgets('a tight-width slot stretches the drawn box and centres its '
        'content (${hebrew ? 'RTL' : 'LTR'})', (tester) async {
      // MASTER §6: at phone width controls go full width (saved.html,
      // square.html: `.btn { width: 100% }`).
      for (final withIcon in [false, true]) {
        await pumpInApp(
          tester,
          SizedBox(
            width: 300,
            child: ZodiannButton(
              label: 'Save',
              onPressed: () {},
              icon: withIcon ? const SizedBox(key: _iconKey) : null,
            ),
          ),
          hebrew: hebrew,
        );
        final why = 'icon: $withIcon';
        final target = tester.getRect(find.byType(ZodiannButton));
        final box = tester.getRect(drawnBox());
        expect(target.size, const Size(300, 44), reason: why);
        expect(box.width, 300, reason: why);
        expect(box.height, 40, reason: why);
        final text = tester.getRect(labelText());
        final contentLeft = withIcon && !hebrew
            ? tester.getRect(find.byKey(_iconKey)).left
            : text.left;
        final contentRight = withIcon && hebrew
            ? tester.getRect(find.byKey(_iconKey)).right
            : text.right;
        expect(
          contentLeft - box.left,
          closeTo(box.right - contentRight, 0.5),
          reason: '$why: content centred',
        );
      }
    });
  }

  testWidgets('RTL puts the icon on the start side', (tester) async {
    await pumpInApp(
      tester,
      ZodiannButton(
        label: 'שמירה',
        onPressed: () {},
        icon: const SizedBox(key: _iconKey),
      ),
      hebrew: true,
    );
    expect(
      Directionality.of(tester.element(find.byType(ZodiannButton))),
      TextDirection.rtl,
    );
    final box = tester.getRect(drawnBox());
    final icon = tester.getRect(find.byKey(_iconKey));
    final text = tester.getRect(labelText());
    expect(icon.left, greaterThan(text.left));
    expect(box.right - icon.right, closeTo(17, 0.01));
  });
}
