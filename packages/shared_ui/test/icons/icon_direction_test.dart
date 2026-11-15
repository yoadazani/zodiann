// ZOD-FND-009: back / forward follow the reading direction (MASTER §11:
// chevL / chevR swap in Hebrew), and no icon is ever mirrored.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/icon_capture.dart';

const _black = Color(0xFF000000);

ZodiannIconData _resolved(WidgetTester tester) =>
    tester.widget<ZodiannIcon>(find.byType(ZodiannIcon)).icon;

Future<void> _pumpDirectional(
  WidgetTester tester,
  TextDirection direction,
  Widget child,
) => tester.pumpWidget(
  Directionality(
    textDirection: direction,
    child: Center(child: child),
  ),
);

void main() {
  testWidgets(
    'iconBack is chevL in LTR and chevR in RTL; iconFwd the reverse',
    (tester) async {
      await _pumpDirectional(tester, TextDirection.ltr, iconBack());
      expect(_resolved(tester), ZodiannIcons.chevL);
      await _pumpDirectional(tester, TextDirection.rtl, iconBack());
      expect(_resolved(tester), ZodiannIcons.chevR);
      await _pumpDirectional(tester, TextDirection.ltr, iconFwd());
      expect(_resolved(tester), ZodiannIcons.chevR);
      await _pumpDirectional(tester, TextDirection.rtl, iconFwd());
      expect(_resolved(tester), ZodiannIcons.chevL);
    },
  );

  testWidgets('iconBack passes size, colour and label through', (tester) async {
    await _pumpDirectional(
      tester,
      TextDirection.ltr,
      iconBack(
        size: ZodiannSize.iconSmall,
        color: _black,
        semanticLabel: 'Back',
      ),
    );
    final icon = tester.widget<ZodiannIcon>(find.byType(ZodiannIcon));
    expect(icon.size, ZodiannSize.iconSmall);
    expect(icon.color, _black);
    expect(icon.semanticLabel, 'Back');
  });

  for (final (locale, back, forward) in [
    (const Locale('he'), ZodiannIcons.chevR, ZodiannIcons.chevL),
    (const Locale('en'), ZodiannIcons.chevL, ZodiannIcons.chevR),
  ]) {
    testWidgets(
      'switching the app to ${locale.languageCode} picks the chevrons',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: const [
              ZodiannLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: ZodiannLocalizations.supportedLocales,
            theme: ZodiannTheme.graphite,
            home: Row(
              mainAxisSize: MainAxisSize.min,
              children: [iconBack(), iconFwd()],
            ),
          ),
        );
        await tester.pumpAndSettle();
        final icons = tester
            .widgetList<ZodiannIcon>(find.byType(ZodiannIcon))
            .map((i) => i.icon)
            .toList();
        expect(icons, [back, forward]);
      },
    );
  }

  testWidgets('live switch updates the same element', (tester) async {
    await _pumpDirectional(tester, TextDirection.ltr, iconBack());
    final before = tester.element(find.byType(ZodiannIcon));
    expect(_resolved(tester), ZodiannIcons.chevL);
    await _pumpDirectional(tester, TextDirection.rtl, iconBack());
    expect(tester.element(find.byType(ZodiannIcon)), same(before));
    expect(_resolved(tester), ZodiannIcons.chevR);
  });

  testWidgets('nested Directionality: iconBack follows the nearest ancestor', (
    tester,
  ) async {
    await _pumpDirectional(
      tester,
      TextDirection.rtl,
      Directionality(textDirection: TextDirection.ltr, child: iconBack()),
    );
    expect(_resolved(tester), ZodiannIcons.chevL);
  });

  Future<List<int>> render(
    WidgetTester tester,
    ZodiannIconData icon,
    TextDirection direction,
  ) async => (await captureWidget(
    tester,
    ZodiannIcon(icon, color: _black),
    width: 20,
    height: 20,
    direction: direction,
  )).bytes.toList();

  group(
    'no icon is mirrored: every icon paints identically in LTR and RTL',
    () {
      for (final icon in ZodiannIcons.values) {
        testWidgets(icon.name, (tester) async {
          final ltr = await render(tester, icon, TextDirection.ltr);
          final rtl = await render(tester, icon, TextDirection.rtl);
          expect(rtl, ltr);
        });
      }
    },
  );

  group('MASTER §11: these never mirror', () {
    for (final icon in [
      ZodiannIcons.wheel,
      ZodiannIcons.grid,
      ZodiannIcons.rotate,
      ZodiannIcons.datewheel,
      ZodiannIcons.target,
      ZodiannIcons.anchor,
    ]) {
      testWidgets(icon.name, (tester) async {
        final ltr = await render(tester, icon, TextDirection.ltr);
        final rtl = await render(tester, icon, TextDirection.rtl);
        expect(rtl, ltr);
      });
    }
  });

  testWidgets('chevL and chevR differ (the pixel test can see a flip)', (
    tester,
  ) async {
    final left = await render(tester, ZodiannIcons.chevL, TextDirection.ltr);
    final right = await render(tester, ZodiannIcons.chevR, TextDirection.ltr);
    expect(left, isNot(right));
  });

  for (final direction in TextDirection.values) {
    testWidgets('no Transform around or inside the icon ($direction)', (
      tester,
    ) async {
      await _pumpDirectional(
        tester,
        direction,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [iconBack(), const ZodiannIcon(ZodiannIcons.rotate)],
        ),
      );
      for (final type in [ZodiannIcon, ZodiannDirectionalIcon]) {
        expect(
          find.descendant(
            of: find.byType(type),
            matching: find.byType(Transform),
          ),
          findsNothing,
        );
        expect(
          find.ancestor(
            of: find.byType(type),
            matching: find.byType(Transform),
          ),
          findsNothing,
        );
      }
    });
  }
}
