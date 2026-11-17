// ZOD-NAV-002: the app shell opens the navigation drawer from the hamburger
// (NAV-2, NAV-3, NAV-7): the two groups in AppRoute order with the kit's copy
// in en and he, the active item following the route, the temporary app-owned
// version, inert item taps (product-owner decision A; ZOD-NAV-003 wires them),
// every close path, never docked at any width, and the review-focus cases.
import 'package:astro_mobile/src/app.dart';
import 'package:astro_mobile/src/navigation/app_route.dart';
import 'package:astro_mobile/src/navigation/app_router.dart';
import 'package:astro_mobile/src/navigation/screen_stub.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

const _enNames = [
  'Zodiac wheel',
  'Gann Square of Nine',
  'Saved squares',
  'Settings',
  'About and sources',
];
const _enDescs = [
  'Planet positions, aspects and degree crossings',
  'Numbers, days or 4-hour blocks on the spiral',
  'Return to squares you named',
  'Language, theme, orbs, defaults',
  'Computation sources and method',
];
const _heNames = [
  'גלגל המזלות',
  'ריבוע התשע של גאן',
  'ריבועים שמורים',
  'הגדרות',
  'אודות ומקורות',
];
const _heDescs = [
  'מיקומי כוכבים, היבטים ומעברי מעלות',
  'מספרים, ימים או בלוקים של 4 שעות בספירלה',
  'חזרה לריבועים ששמרת בשם',
  'שפה, ערכת נושא, אורבים',
  'מקורות החישוב והשיטה',
];

Future<void> _pumpApp(
  WidgetTester tester, {
  double width = 1440,
  bool hebrew = false,
  String? initialLocation,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (hebrew) {
    tester.platformDispatcher.localesTestValue = const [Locale('he')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (initialLocation != null)
          appRouterProvider.overrideWith((ref) {
            final r = buildAppRouter(initialLocation: initialLocation);
            ref.onDispose(r.dispose);
            return r;
          }),
      ],
      child: const ZodiannApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _hamburger() => find
    .descendant(
      of: find.byType(ZodiannTopBar),
      matching: find.byType(ZodiannIconButton),
    )
    .first;

Finder _closeButton() => find.descendant(
  of: find.byType(ZodiannDrawer),
  matching: find.byType(ZodiannIconButton),
);

/// Text inside the drawer (the top bar behind the scrim repeats the title).
Finder _t(String text) =>
    find.descendant(of: find.byType(ZodiannDrawer), matching: find.text(text));

Future<void> _open(WidgetTester tester) async {
  await tester.tap(_hamburger());
  await tester.pumpAndSettle();
}

String _location(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(ScreenStub)))
        .routerDelegate
        .currentConfiguration
        .uri
        .path;

Future<void> _go(WidgetTester tester, AppRoute route) async {
  GoRouter.of(tester.element(find.byType(ScreenStub))).go(route.path);
  await tester.pumpAndSettle();
}

NavigatorState _root(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator).first);

void main() {
  for (final (lang, names, descs, hebrew) in [
    ('en', _enNames, _enDescs, false),
    ('he', _heNames, _heDescs, true),
  ]) {
    testWidgets('the hamburger opens the drawer with the kit copy ($lang)', (
      tester,
    ) async {
      await _pumpApp(tester, hebrew: hebrew);
      expect(find.byType(ZodiannDrawer), findsNothing);
      expect(
        tester.widget<ZodiannIconButton>(_hamburger()).onPressed,
        isNotNull,
      );
      await _open(tester);
      expect(find.byType(ZodiannDrawer), findsOneWidget);

      final l = lookupZodiannLocalizations(Locale(lang));
      expect(_t('Zodiann'), findsOneWidget);
      expect(_t(l.drawerGroupAnalysis), findsOneWidget);
      expect(_t(l.drawerGroupLibrary), findsOneWidget);
      for (var i = 0; i < 5; i++) {
        expect(_t(names[i]), findsOneWidget, reason: names[i]);
        expect(_t(descs[i]), findsOneWidget, reason: descs[i]);
      }
      // Group labels and items in AppRoute (table) order, top to bottom.
      final tops = <double>[
        tester.getTopLeft(_t(l.drawerGroupAnalysis)).dy,
        tester.getTopLeft(_t(names[0])).dy,
        tester.getTopLeft(_t(names[1])).dy,
        tester.getTopLeft(_t(l.drawerGroupLibrary)).dy,
        tester.getTopLeft(_t(names[2])).dy,
        tester.getTopLeft(_t(names[3])).dy,
        tester.getTopLeft(_t(names[4])).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(AppRoute.values.map((r) => r.name), [
        'wheel',
        'square',
        'saved',
        'settings',
        'about',
      ]);
      // The footer: the temporary app-provided version, and the privacy line.
      expect(_t(hebrew ? 'גרסה 1.0.0' : 'Version 1.0.0'), findsOneWidget);
      expect(_t(l.drawerOffline), findsOneWidget);
    });
  }

  testWidgets('the active item follows the route', (tester) async {
    final handle = tester.ensureSemantics();
    await _pumpApp(tester);
    Future<void> expectSelected(int selected) async {
      await _open(tester);
      for (var i = 0; i < 5; i++) {
        final node = tester.getSemantics(
          find.descendant(
            of: find.byType(ZodiannDrawer),
            matching: find.bySemanticsLabel(_enNames[i]),
          ),
        );
        if (i == selected) {
          expect(
            node,
            isSemantics(
              label: _enNames[i],
              hint: _enDescs[i],
              hasSelectedState: true,
              isSelected: true,
            ),
            reason: _enNames[i],
          );
        } else {
          expect(
            node,
            isNot(isSemantics(hasSelectedState: true)),
            reason: _enNames[i],
          );
        }
      }
      await tester.tapAt(const Offset(1000, 450));
      await tester.pumpAndSettle();
    }

    await expectSelected(0);
    await _go(tester, AppRoute.square);
    await expectSelected(1);
    await _go(tester, AppRoute.settings);
    await expectSelected(3);
    handle.dispose();
  });

  testWidgets('item taps are inert in this task (decision A)', (tester) async {
    await _pumpApp(tester);
    await _open(tester);
    await tester.tap(_t('Settings'));
    await tester.pumpAndSettle();
    expect(_location(tester), '/wheel');
    expect(find.byType(ZodiannDrawer), findsOneWidget);
  });

  group('closing', () {
    testWidgets('back closes it and leaves the route unchanged', (
      tester,
    ) async {
      await _pumpApp(tester, initialLocation: '/square');
      await _open(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ZodiannDrawer), findsNothing);
      expect(_location(tester), '/square');
    });

    testWidgets('the close button closes it', (tester) async {
      await _pumpApp(tester);
      await _open(tester);
      await tester.tap(_closeButton());
      await tester.pumpAndSettle();
      expect(find.byType(ZodiannDrawer), findsNothing);
      expect(_location(tester), '/wheel');
    });

    testWidgets('a tap on the backdrop closes it', (tester) async {
      await _pumpApp(tester);
      await _open(tester);
      await tester.tapAt(const Offset(1000, 450));
      await tester.pumpAndSettle();
      expect(find.byType(ZodiannDrawer), findsNothing);
    });
  });

  group('review focus', () {
    testWidgets('two quick activations open one drawer', (tester) async {
      await _pumpApp(tester);
      final onPressed = tester
          .widget<ZodiannIconButton>(_hamburger())
          .onPressed!;
      onPressed();
      onPressed();
      await tester.pumpAndSettle();
      expect(find.byType(ZodiannDrawer), findsOneWidget);
      _root(tester).pop();
      await tester.pumpAndSettle();
      expect(find.byType(ZodiannDrawer), findsNothing);
      expect(_root(tester).canPop(), isFalse);
    });

    testWidgets('an activation during the close animation ends with one', (
      tester,
    ) async {
      await _pumpApp(tester);
      final onPressed = tester
          .widget<ZodiannIconButton>(_hamburger())
          .onPressed!;
      await _open(tester);
      await tester.tap(_closeButton());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      onPressed();
      await tester.pumpAndSettle();
      expect(find.byType(ZodiannDrawer), findsOneWidget);
      _root(tester).pop();
      await tester.pumpAndSettle();
      expect(find.byType(ZodiannDrawer), findsNothing);
      expect(_root(tester).canPop(), isFalse);
    });

    testWidgets('switching the locale while open shows the new copy', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _open(tester);
      expect(_t(_enNames[0]), findsOneWidget);
      expect(tester.getRect(find.byType(ZodiannDrawer)).left, 0);

      tester.platformDispatcher.localesTestValue = const [Locale('he')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpAndSettle();
      expect(find.byType(ZodiannDrawer), findsOneWidget);
      expect(_t(_enNames[0]), findsNothing);
      expect(_t(_heNames[0]), findsOneWidget);
      expect(_t('גרסה 1.0.0'), findsOneWidget);
      // Mirrored: the panel is on the right now.
      expect(tester.getRect(find.byType(ZodiannDrawer)).right, 1440);
    });
  });

  group('never docked (NAV-7)', () {
    for (final width in [390.0, 700.0, 1099.0, 1100.0, 1440.0]) {
      testWidgets('width $width: an overlay route, never in the layout', (
        tester,
      ) async {
        await _pumpApp(tester, width: width);
        expect(find.byType(ZodiannDrawer), findsNothing);
        final scaffold = tester.widget<Scaffold>(
          find
              .descendant(
                of: find.byType(MaterialApp),
                matching: find.byType(Scaffold),
              )
              .first,
        );
        expect(scaffold.drawer, isNull);
        expect(scaffold.endDrawer, isNull);

        await _open(tester);
        expect(find.byType(ZodiannDrawer), findsOneWidget);
        final drawerRoute = ModalRoute.of(
          tester.element(find.byType(ZodiannDrawer)),
        );
        final shellRoute = ModalRoute.of(
          tester.element(find.byType(ScreenStub)),
        );
        expect(drawerRoute, isNot(same(shellRoute)));
        expect(_root(tester).canPop(), isTrue);
        // The content behind is covered: a tap beside the panel hits the
        // scrim and closes the drawer instead of reaching the screen.
        await tester.tapAt(Offset(width - 5, 450));
        await tester.pumpAndSettle();
        expect(find.byType(ZodiannDrawer), findsNothing);
        expect(find.byType(ScreenStub), findsOneWidget);
      });
    }
  });
}
