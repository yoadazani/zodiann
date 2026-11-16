// ZOD-FND-014 (NAV-5): the go_router scaffold. Five route stubs in the
// Navigation table's order, the wheel as default and as the fallback for any
// unrecognized route, and one router that survives app rebuilds.
import 'package:astro_mobile/src/app.dart';
import 'package:astro_mobile/src/navigation/app_route.dart';
import 'package:astro_mobile/src/navigation/app_router.dart';
import 'package:astro_mobile/src/navigation/screen_stub.dart';
import 'package:astro_mobile/src/theme/theme_mode_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _pumpApp(WidgetTester tester, {String? initialLocation}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (initialLocation != null)
          appRouterProvider.overrideWith((ref) {
            final router = buildAppRouter(initialLocation: initialLocation);
            ref.onDispose(router.dispose);
            return router;
          }),
      ],
      child: const ZodiannApp(),
    ),
  );
  await tester.pumpAndSettle();
}

ProviderContainer _container(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(ScreenStub)),
  listen: false,
);

GoRouter _router(WidgetTester tester) =>
    _container(tester).read(appRouterProvider);

AppRoute _stubRoute(WidgetTester tester) {
  expect(find.byType(ScreenStub), findsOneWidget);
  return tester.widget<ScreenStub>(find.byType(ScreenStub)).route;
}

Future<void> _go(WidgetTester tester, String location) async {
  _router(tester).go(location);
  await tester.pumpAndSettle();
}

void main() {
  test('route identifiers match the spec table', () {
    expect(AppRoute.values.map((r) => '#${r.name}'), [
      '#wheel',
      '#square',
      '#saved',
      '#settings',
      '#about',
    ]);
    expect(AppRoute.values.map((r) => r.path), [
      '/wheel',
      '/square',
      '/saved',
      '/settings',
      '/about',
    ]);
  });

  testWidgets('boots to the wheel', (tester) async {
    await _pumpApp(tester);
    expect(_stubRoute(tester), AppRoute.wheel);
    expect(
      find.descendant(of: find.byType(ScreenStub), matching: find.byType(Text)),
      findsNothing,
    );
  });

  testWidgets('every route resolves to its blank stub', (tester) async {
    await _pumpApp(tester);
    for (final route in AppRoute.values) {
      await _go(tester, route.path);
      expect(_stubRoute(tester), route, reason: route.path);
      expect(
        find.descendant(
          of: find.byType(ScreenStub),
          matching: find.byType(Text),
        ),
        findsNothing,
        reason: route.path,
      );
    }
  });

  testWidgets('unknown routes redirect to the wheel', (tester) async {
    await _pumpApp(tester);
    for (final location in ['/nope', '/', '/wheel/extra', '/Square']) {
      await _go(tester, AppRoute.square.path);
      expect(_stubRoute(tester), AppRoute.square);
      await _go(tester, location);
      expect(_stubRoute(tester), AppRoute.wheel, reason: location);
      expect(_router(tester).state.uri.path, '/wheel', reason: location);
      expect(tester.takeException(), isNull, reason: location);
    }
  });

  testWidgets('known routes tolerate a query and a trailing slash', (
    tester,
  ) async {
    await _pumpApp(tester);
    for (final location in ['/square?x=1', '/square/']) {
      await _go(tester, AppRoute.wheel.path);
      await _go(tester, location);
      expect(_stubRoute(tester), AppRoute.square, reason: location);
    }
  });

  testWidgets('cold start at a route opens it directly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appRouterProvider.overrideWith((ref) {
            final router = buildAppRouter(initialLocation: '/square');
            ref.onDispose(router.dispose);
            return router;
          }),
        ],
        child: const ZodiannApp(),
      ),
    );
    // NAV-5: a deep link to the square opens it directly, with no wheel first.
    expect(find.byType(ScreenStub), findsOneWidget);
    expect(_stubRoute(tester), AppRoute.square);
    await tester.pumpAndSettle();
    expect(_stubRoute(tester), AppRoute.square);
  });

  testWidgets('cold start at an unknown route lands on the wheel', (
    tester,
  ) async {
    await _pumpApp(tester, initialLocation: '/nope');
    expect(_stubRoute(tester), AppRoute.wheel);
    expect(_router(tester).state.uri.path, '/wheel');
    expect(tester.takeException(), isNull);
  });

  testWidgets('route survives theme and locale changes', (tester) async {
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    await _pumpApp(tester);
    // The router on screen, not the provider's: if the app built its own
    // router, a rebuild would reset the route and this test would see it.
    GoRouter.of(tester.element(find.byType(ScreenStub))).go('/saved');
    await tester.pumpAndSettle();
    expect(_stubRoute(tester), AppRoute.saved);

    // A theme-mode change rebuilds ZodiannApp.
    _container(tester).read(themeModeProvider.notifier).set(ThemeMode.dark);
    await tester.pumpAndSettle();
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    tester.platformDispatcher.localesTestValue = const [Locale('he', 'IL')];
    await tester.pumpAndSettle();

    expect(_stubRoute(tester), AppRoute.saved);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig,
      same(_router(tester)),
    );
  });

  testWidgets('go replaces the screen', (tester) async {
    await _pumpApp(tester);
    await _go(tester, AppRoute.square.path);
    await _go(tester, AppRoute.about.path);
    expect(_router(tester).canPop(), isFalse);
    expect(_stubRoute(tester), AppRoute.about);
  });
}
