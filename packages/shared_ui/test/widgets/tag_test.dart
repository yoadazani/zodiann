// ZOD-UI-009: ZodiannTag structure and layout: 24 high, 8 padding, 6 gap,
// the NFR-X4 marks, the inside outline, RTL / Hebrew, text scale, squeeze,
// semantics and live theme switching.
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/button_harness.dart';
import '../support/load_bundled_fonts.dart';

const _label = 'Label';
const _plus = '+';
const _times = '\u{00D7}';

final _themes = {
  'Graphite': ZodiannTheme.graphite,
  'Porcelain': ZodiannTheme.porcelain,
};

Finder _tag() => find.byType(ZodiannTag);

Finder _box() =>
    find.descendant(of: _tag(), matching: find.byType(DecoratedBox)).first;

BoxDecoration _decoration(WidgetTester tester) =>
    tester.widget<DecoratedBox>(_box()).decoration as BoxDecoration;

Finder _text(String s) => find.descendant(of: _tag(), matching: find.text(s));

ZodiannTagStyle _style(ThemeData theme, ZodiannTagVariant v) =>
    ZodiannTagStyle.of(
      v,
      theme.extension<SquareColors>()!,
      theme.extension<ZodiannSurfaces>()!,
    );

const _marked = {ZodiannTagVariant.axis, ZodiannTagVariant.diagonal};

void main() {
  setUpAll(loadBundledFonts);

  group('geometry', () {
    for (final v in ZodiannTagVariant.values) {
      testWidgets(
        'is exactly 24 high with 8 start and end padding, radius 6: $v',
        (tester) async {
          await pumpInApp(tester, ZodiannTag(variant: v, label: _label));
          final box = tester.getRect(_box());
          expect(box.height, ZodiannSize.tag);
          final label = tester.getRect(_text(_label));
          expect(
            label.center.dy,
            closeTo(box.center.dy, 0.5),
            reason: 'label vertically centred',
          );
          expect(label.right, closeTo(box.right - ZodiannSpace.s2, 0.01));
          final startContent = _marked.contains(v)
              ? tester.getRect(_text(v.mark!))
              : label;
          expect(startContent.left, closeTo(box.left + ZodiannSpace.s2, 0.01));
          expect(_decoration(tester).borderRadius, ZodiannRadius.tag);
        },
      );
    }

    for (final v in _marked) {
      testWidgets('gap between the mark and the label is 6: $v', (
        tester,
      ) async {
        await pumpInApp(tester, ZodiannTag(variant: v, label: _label));
        final mark = tester.getRect(_text(v.mark!));
        final label = tester.getRect(_text(_label));
        expect(label.left - mark.right, closeTo(ZodiannSize.tagGap, 0.01));
      });
    }
  });

  group('the NFR-X4 marks', () {
    testWidgets(
      'axis renders + and diagonal renders ×, in front of the label',
      (tester) async {
        for (final (v, mark) in [
          (ZodiannTagVariant.axis, _plus),
          (ZodiannTagVariant.diagonal, _times),
        ]) {
          await pumpInApp(tester, ZodiannTag(variant: v, label: _label));
          expect(_text(mark), findsOneWidget, reason: '$v');
          expect(
            tester.getRect(_text(mark)).right,
            lessThan(tester.getRect(_text(_label)).left),
            reason: '$v: the mark precedes the label',
          );
        }
      },
    );

    testWidgets('eighth, noHighlight, center, today, neutral and accent '
        'render no mark', (tester) async {
      for (final v in ZodiannTagVariant.values.where(
        (v) => !_marked.contains(v),
      )) {
        await pumpInApp(tester, ZodiannTag(variant: v, label: _label));
        expect(
          find.descendant(of: _tag(), matching: find.byType(Text)),
          findsOneWidget,
          reason: '$v has only its label',
        );
        expect(_text(_plus), findsNothing, reason: '$v');
        expect(_text(_times), findsNothing, reason: '$v');
      }
    });
  });

  group('styles', () {
    for (final MapEntry(key: name, value: theme) in _themes.entries) {
      testWidgets("$name: label is 12 / 600 in the variant's ink; neutral is "
          '500', (tester) async {
        for (final v in ZodiannTagVariant.values) {
          await pumpInApp(
            tester,
            ZodiannTag(variant: v, label: _label),
            theme: theme,
          );
          final style = tester.widget<Text>(_text(_label)).style!;
          final expected = _style(theme, v);
          final label = theme.extension<ZodiannTextStyles>()!.label;
          expect(style.fontSize, 12, reason: '$v');
          expect(
            style.fontWeight,
            v == ZodiannTagVariant.neutral ? FontWeight.w500 : FontWeight.w600,
            reason: '$v',
          );
          expect(style.color, expected.ink, reason: '$v');
          expect(style.fontFamily, label.fontFamily, reason: '$v');
          expect(style.height, label.height, reason: '$v');
        }
      });

      testWidgets('$name: mark style is 13 / 500 at 0.9 alpha', (tester) async {
        for (final v in _marked) {
          await pumpInApp(
            tester,
            ZodiannTag(variant: v, label: _label),
            theme: theme,
          );
          final style = tester.widget<Text>(_text(v.mark!)).style!;
          final ink = _style(theme, v).ink;
          expect(style.fontSize, 13, reason: '$v');
          expect(style.fontWeight, FontWeight.w500, reason: '$v');
          expect(
            style.color,
            ink.withValues(alpha: ZodiannStates.tagMarkOpacity),
            reason: '$v',
          );
          expect(
            find.descendant(of: _tag(), matching: find.byType(Opacity)),
            findsNothing,
            reason: 'the opacity is in the colour, not an Opacity widget',
          );
        }
      });

      testWidgets('$name: fills are the variant fills', (tester) async {
        for (final v in ZodiannTagVariant.values) {
          await pumpInApp(
            tester,
            ZodiannTag(variant: v, label: _label),
            theme: theme,
          );
          expect(
            _decoration(tester).color,
            _style(theme, v).fill,
            reason: '$v',
          );
        }
      });
    }
  });

  group('the inside outline', () {
    testWidgets('center and today draw a 1.5 px inside outline in their ink; '
        'the others draw none', (tester) async {
      for (final v in ZodiannTagVariant.values) {
        await pumpInApp(tester, ZodiannTag(variant: v, label: _label));
        final border = _decoration(tester).border;
        final outlined =
            v == ZodiannTagVariant.center || v == ZodiannTagVariant.today;
        if (!outlined) {
          expect(border, isNull, reason: '$v');
          continue;
        }
        final ink = _style(ZodiannTheme.graphite, v).ink;
        expect(border, isA<Border>(), reason: '$v');
        final b = border! as Border;
        for (final side in [b.top, b.right, b.bottom, b.left]) {
          expect(side.width, ZodiannSize.tagOutline, reason: '$v');
          expect(side.color, ink, reason: '$v');
          expect(side.strokeAlign, BorderSide.strokeAlignInside, reason: '$v');
        }
        // A Container would add the border to the padding (9.5, not 8).
        final box = tester.getRect(_box());
        expect(
          tester.getRect(_text(_label)).left - box.left,
          closeTo(ZodiannSpace.s2, 0.01),
          reason: '$v keeps its content in place',
        );
        expect(box.height, ZodiannSize.tag, reason: '$v');
      }
    });
  });

  group('RTL and Hebrew', () {
    for (final v in _marked) {
      testWidgets('the mark leads at the start side, the box mirrors exactly, '
          'no Transform: $v', (tester) async {
        await pumpInApp(tester, ZodiannTag(variant: v, label: _label));
        final ltrBox = tester.getRect(_box());
        final ltrMark = tester.getRect(_text(v.mark!));
        final ltrLabel = tester.getRect(_text(_label));

        await pumpInApp(
          tester,
          ZodiannTag(variant: v, label: _label),
          hebrew: true,
        );
        final rtlBox = tester.getRect(_box());
        final rtlMark = tester.getRect(_text(v.mark!));
        final rtlLabel = tester.getRect(_text(_label));

        expect(rtlBox.size, ltrBox.size);
        expect(rtlMark.right, greaterThan(rtlLabel.right));
        expect(
          rtlBox.right - rtlMark.right,
          closeTo(ltrMark.left - ltrBox.left, 0.01),
          reason: 'the mark is 8 from the start edge',
        );
        expect(
          rtlLabel.left - rtlBox.left,
          closeTo(ltrBox.right - ltrLabel.right, 0.01),
          reason: 'the label is 8 from the end edge',
        );
        expect(
          find.descendant(of: _tag(), matching: find.byType(Transform)),
          findsNothing,
        );
      });
    }

    testWidgets('Hebrew label renders in IBM Plex Sans Hebrew', (tester) async {
      await pumpInApp(
        tester,
        const ZodiannTag(variant: ZodiannTagVariant.axis, label: 'ציר'),
        hebrew: true,
      );
      expect(
        tester.widget<Text>(_text('ציר')).style!.fontFamily,
        contains(ZodiannFonts.plexSansHebrew),
      );
      expect(_text(_plus), findsOneWidget);
    });
  });

  group('text scale and squeeze', () {
    testWidgets('textScaler 2.0 grows the tag (height > 24, no overflow)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ZodiannTheme.graphite,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const Material(
              child: Center(
                child: ZodiannTag(
                  variant: ZodiannTagVariant.axis,
                  label: _label,
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(_box()).height, greaterThan(ZodiannSize.tag));
    });

    for (final v in [ZodiannTagVariant.axis, ZodiannTagVariant.neutral]) {
      testWidgets('narrow parent ellipsizes without overflow: $v', (
        tester,
      ) async {
        const label = 'A rather long tag label';
        await pumpInApp(tester, ZodiannTag(variant: v, label: label));
        final wideLabel = tester.getSize(_text(label)).width;
        final wideMark = _marked.contains(v)
            ? tester.getSize(_text(v.mark!)).width
            : null;

        await pumpInApp(
          tester,
          SizedBox(
            width: 60,
            child: ZodiannTag(variant: v, label: label),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(tester.getSize(_box()).width, 60);
        expect(tester.getSize(_text(label)).width, lessThan(wideLabel));
        final t = tester.widget<Text>(_text(label));
        expect(t.overflow, TextOverflow.ellipsis);
        expect(t.maxLines, 1);
        if (wideMark != null) {
          expect(
            tester.getSize(_text(v.mark!)).width,
            wideMark,
            reason: 'NFR-X4: the mark keeps its full width under squeeze',
          );
        }
      });
    }
  });

  group('semantics', () {
    testWidgets('one semantics node named by the label; the mark is excluded', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpInApp(
        tester,
        const ZodiannTag(variant: ZodiannTagVariant.axis, label: 'Axis'),
      );
      final node = tester.getSemantics(_tag());
      expect(node.label, 'Axis');
      final texts = <String>[];
      void visit(SemanticsNode n) {
        texts.add(n.label);
        n.visitChildren((c) {
          visit(c);
          return true;
        });
      }

      visit(node);
      expect(texts.where((t) => t.isNotEmpty), ['Axis']);
      handle.dispose();
    });
  });

  testWidgets('switches live with the theme', (tester) async {
    Future<void> pump(ThemeData theme) => tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: Center(
            child: ZodiannTag(variant: ZodiannTagVariant.axis, label: _label),
          ),
        ),
      ),
    );
    await pump(ZodiannTheme.graphite);
    final dark = _decoration(tester).color;
    expect(dark, graphiteTokens.square.axisFill);
    await pump(ZodiannTheme.porcelain);
    await tester.pumpAndSettle();
    expect(_decoration(tester).color, porcelainTokens.square.axisFill);
    expect(_decoration(tester).color, isNot(dark));
  });
}
