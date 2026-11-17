// ZOD-NAV-001: the app shell puts the top bar over every route (NAV-1): the
// route's title and subtitle, the Square actions (disabled until their tasks
// wire them: product-owner decision, Option B), the hamburger (enabled since
// ZOD-NAV-002: it opens the drawer), one bar for the app's lifetime, and
// content scrolling beneath it.
import 'package:astro_mobile/src/app.dart';
import 'package:astro_mobile/src/navigation/app_route.dart';
import 'package:astro_mobile/src/navigation/app_router.dart';
import 'package:astro_mobile/src/navigation/app_shell.dart';
import 'package:astro_mobile/src/navigation/screen_stub.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

const _en = {
  AppRoute.wheel: ('Zodiac wheel', 'Tropical geocentric positions'),
  AppRoute.square: ('Gann Square of Nine', 'Spiral, angles and highlights'),
  AppRoute.saved: ('Saved squares', 'Stored on this device'),
  AppRoute.settings: ('Settings', 'Language, theme, orbs and defaults'),
  AppRoute.about: ('About and sources', 'Version, sources and method'),
};

const _he = {
  AppRoute.wheel: ('גלגל המזלות', 'מיקומים גאוצנטריים טרופיים'),
  AppRoute.square: ('ריבוע התשע של גאן', 'ספירלה, זוויות והדגשות'),
  AppRoute.saved: ('ריבועים שמורים', 'שמורים במכשיר הזה'),
  AppRoute.settings: ('הגדרות', 'שפה, ערכת נושא, אורבים וברירות מחדל'),
  AppRoute.about: ('אודות ומקורות', 'גרסה, מקורות ושיטה'),
};

Future<void> _pumpApp(
  WidgetTester tester, {
  String? initialLocation,
  double width = 1440,
  bool hebrew = false,
  GoRouter? router,
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
        if (router != null)
          appRouterProvider.overrideWith((ref) => router)
        else if (initialLocation != null)
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

Future<void> _go(WidgetTester tester, AppRoute route) async {
  GoRouter.of(tester.element(find.byType(ScreenStub))).go(route.path);
  await tester.pumpAndSettle();
}

Finder _inBar(Finder f) =>
    find.descendant(of: find.byType(ZodiannTopBar), matching: f);

void main() {
  for (final (lang, copy, hebrew) in [('en', _en, false), ('he', _he, true)]) {
    testWidgets('every route shows its title and subtitle ($lang)', (
      tester,
    ) async {
      await _pumpApp(tester, hebrew: hebrew);
      for (final route in AppRoute.values) {
        await _go(tester, route);
        final (title, subtitle) = copy[route]!;
        expect(_inBar(find.text(title)), findsOneWidget, reason: '$route');
        expect(_inBar(find.text(subtitle)), findsOneWidget, reason: '$route');
      }
    });
  }

  testWidgets('the bar is the same element across navigation', (tester) async {
    await _pumpApp(tester);
    final bar = tester.element(find.byType(ZodiannTopBar));
    await _go(tester, AppRoute.saved);
    expect(tester.element(find.byType(ZodiannTopBar)), same(bar));
    expect(_inBar(find.text('Saved squares')), findsOneWidget);
    await _go(tester, AppRoute.square);
    expect(tester.element(find.byType(ZodiannTopBar)), same(bar));
    expect(_inBar(find.text('Gann Square of Nine')), findsOneWidget);
  });

  testWidgets(
    'Square has Save and Export, disabled; other screens have no actions',
    (tester) async {
      await _pumpApp(tester);
      for (final route in AppRoute.values) {
        await _go(tester, route);
        final buttons = tester
            .widgetList<ZodiannButton>(_inBar(find.byType(ZodiannButton)))
            .toList();
        if (route == AppRoute.square) {
          expect(
            [for (final b in buttons) b.label],
            ['Save', 'Export to Excel'],
          );
          expect(
            [for (final b in buttons) b.variant],
            [ZodiannButtonVariant.secondary, ZodiannButtonVariant.primary],
          );
          expect([for (final b in buttons) b.onPressed], [null, null]);
        } else {
          expect(buttons, isEmpty, reason: '$route');
        }
      }
    },
  );

  testWidgets(
    'phone Square shows two disabled icon buttons labelled Save / Export',
    (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpApp(tester, width: 390, initialLocation: '/square');
      expect(_inBar(find.byType(ZodiannButton)), findsNothing);
      final icons = tester
          .widgetList<ZodiannIconButton>(_inBar(find.byType(ZodiannIconButton)))
          .toList();
      expect(icons, hasLength(3));
      expect(
        [for (final b in icons.skip(1)) b.semanticLabel],
        ['Save', 'Export to Excel'],
      );
      // The hamburger opens the drawer (ZOD-NAV-002); Save and Export stay
      // disabled until their tasks wire them.
      expect(icons.first.onPressed, isNotNull);
      expect([for (final b in icons.skip(1)) b.onPressed], [null, null]);
      for (final label in ['Save', 'Export to Excel']) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(label)),
          isSemantics(label: label, isButton: true, isEnabled: false),
        );
      }
      handle.dispose();
    },
  );

  for (final (lang, label, hebrew) in [
    ('en', 'Open menu', false),
    ('he', 'פתיחת תפריט', true),
  ]) {
    testWidgets('hamburger is enabled and labelled $label ($lang)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpApp(tester, hebrew: hebrew);
      final hamburger = tester.widget<ZodiannIconButton>(
        _inBar(find.byType(ZodiannIconButton)).first,
      );
      expect(hamburger.semanticLabel, label);
      expect(hamburger.onPressed, isNotNull);
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        isSemantics(label: label, isButton: true, isEnabled: true),
      );
      handle.dispose();
    });
  }

  // Separate tests: each cold start needs a fresh ProviderScope (a re-pump
  // keeps the router it already built).
  testWidgets('deep link /square cold-starts with the Square bar', (
    tester,
  ) async {
    await _pumpApp(tester, initialLocation: '/square');
    expect(_inBar(find.text('Gann Square of Nine')), findsOneWidget);
  });

  testWidgets('an unknown route cold-starts with the wheel bar', (
    tester,
  ) async {
    await _pumpApp(tester, initialLocation: '/nope');
    expect(_inBar(find.text('Zodiac wheel')), findsOneWidget);
  });

  testWidgets(
    "the body extends behind the bar: the screen's MediaQuery top padding "
    'equals the bar height',
    (tester) async {
      for (final (width, height) in [(1440.0, 64.0), (390.0, 60.0)]) {
        await _pumpApp(tester, width: width);
        expect(
          MediaQuery.paddingOf(tester.element(find.byType(ScreenStub))).top,
          height,
          reason: '$width',
        );
        expect(tester.getTopLeft(find.byType(ScreenStub)).dy, 0);
        expect(tester.getSize(find.byType(ZodiannTopBar)).height, height);
      }
    },
  );

  testWidgets('content scrolls under a fixed bar', (tester) async {
    final router = GoRouter(
      routes: [
        ShellRoute(
          builder: (_, _, child) =>
              AppShell(route: AppRoute.wheel, child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => Scaffold(
                body: ListView.builder(
                  itemExtent: 48,
                  itemCount: 100,
                  itemBuilder: (_, i) => ColoredBox(
                    key: ValueKey(i),
                    color: const Color(0xFF808080),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await _pumpApp(tester, width: 800, router: router);
    final bar = tester.getRect(find.byType(ZodiannTopBar));
    expect(bar.bottom, 64);
    expect(tester.getRect(find.byKey(const ValueKey(0))).top, bar.bottom);

    await tester.drag(find.byType(ListView), const Offset(0, -30));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(ZodiannTopBar)), bar);
    final item = tester.getRect(find.byKey(const ValueKey(0)));
    expect(item.top, lessThan(bar.bottom));
    expect(item.bottom, greaterThan(bar.top));
  });
}
