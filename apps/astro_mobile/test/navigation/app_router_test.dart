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

import 'deep_link_cases.dart';

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

  deepLinkTests();
}

// ZOD-NAV-003: deep links (NAV-5, T-UI-1) and the router seams.
Future<ProviderContainer> _pumpWith(
  WidgetTester tester,
  GoRouter Function() build,
) async {
  final container = ProviderContainer(
    overrides: [
      appRouterProvider.overrideWith((ref) {
        final router = build();
        ref.onDispose(router.dispose);
        return router;
      }),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const ZodiannApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

void deepLinkTests() {
  group('AppRoute.fromUri', () {
    test('resolves every accepted spelling', () {
      for (final link in squareLinks) {
        expect(
          AppRoute.fromUri(Uri.parse(link)),
          AppRoute.square,
          reason: link,
        );
      }
      for (final MapEntry(key: link, value: route) in schemeLinks.entries) {
        expect(AppRoute.fromUri(Uri.parse(link)), route, reason: link);
      }
    });

    test('rejects everything that names no screen', () {
      for (final link in malformedLinks) {
        expect(AppRoute.fromUri(Uri.parse(link)), isNull, reason: link);
      }
    });
  });

  test('AppRoute.fromPath is exact equality with a wheel fallback', () {
    for (final route in AppRoute.values) {
      expect(AppRoute.fromPath(route.path), route);
    }
    for (final path in ['', '/', '/Square', '/square/', '/nope', 'square']) {
      expect(AppRoute.fromPath(path), AppRoute.wheel, reason: path);
    }
  });

  group('cold start through initialLocation', () {
    for (final MapEntry(key: link, value: route) in schemeLinks.entries) {
      testWidgets('$link opens ${route.name}, no scheme left', (tester) async {
        await _pumpApp(tester, initialLocation: link);
        expect(_stubRoute(tester), route);
        expect(_router(tester).state.uri.toString(), route.path);
        expect(tester.takeException(), isNull);
      });
    }

    for (final link in malformedLinks.where((l) => l.isNotEmpty)) {
      testWidgets('malformed "$link" lands on the wheel', (tester) async {
        await _pumpApp(tester, initialLocation: link);
        expect(_stubRoute(tester), AppRoute.wheel);
        expect(_router(tester).state.uri.toString(), '/wheel');
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('cold start through the platform default route', () {
    for (final link in ['zodiann://square', 'zodiann:///square']) {
      testWidgets('$link opens the square', (tester) async {
        addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
        tester.platformDispatcher.defaultRouteNameTestValue = link;
        await _pumpApp(tester);
        expect(_stubRoute(tester), AppRoute.square);
        expect(_router(tester).state.uri.toString(), '/square');
      });
    }

    testWidgets('the platform link wins over an injected initialLocation', (
      tester,
    ) async {
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
      tester.platformDispatcher.defaultRouteNameTestValue = 'zodiann://square';
      await _pumpApp(tester, initialLocation: '/saved');
      expect(_stubRoute(tester), AppRoute.square);
    });
  });

  group('warm links (handlePushRoute)', () {
    testWidgets('open the screen and leave no scheme in router state', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _go(tester, AppRoute.settings.path);
      for (final MapEntry(key: link, value: route) in schemeLinks.entries) {
        await tester.binding.handlePushRoute(link);
        await tester.pumpAndSettle();
        expect(_stubRoute(tester), route, reason: link);
        expect(_router(tester).state.uri.toString(), route.path, reason: link);
      }
    });

    testWidgets('a malformed link lands on the wheel', (tester) async {
      await _pumpApp(tester);
      for (final link in malformedLinks.where((l) => l.isNotEmpty)) {
        await _go(tester, AppRoute.square.path);
        await tester.binding.handlePushRoute(link);
        await tester.pumpAndSettle();
        expect(_stubRoute(tester), AppRoute.wheel, reason: link);
        expect(tester.takeException(), isNull, reason: link);
      }
    });
  });

  group('router seams', () {
    testWidgets('screenBuilder replaces the stub on every route', (
      tester,
    ) async {
      final container = await _pumpWith(
        tester,
        () => buildAppRouter(
          screenBuilder: (route) => Text('screen-${route.name}'),
        ),
      );
      for (final route in AppRoute.values) {
        container.read(appRouterProvider).go(route.path);
        await tester.pumpAndSettle();
        expect(find.text('screen-${route.name}'), findsOneWidget);
        expect(find.byType(ScreenStub), findsNothing);
      }
    });

    testWidgets('a refreshListenable notifies the router', (tester) async {
      final refresh = ValueNotifier<int>(0);
      addTearDown(refresh.dispose);
      await _pumpWith(tester, () => buildAppRouter(refreshListenable: refresh));
      var notified = 0;
      final provider = _router(tester).routeInformationProvider;
      void count() => notified++;
      provider.addListener(count);
      addTearDown(() => provider.removeListener(count));
      refresh.value++;
      expect(notified, 1);
      expect(_stubRoute(tester), AppRoute.wheel);
    });
  });
}
