// ZOD-NAV-003: `activeRouteProvider` mirrors the router's current screen. It
// is the source for everything outside the shell (the drawer's active mark,
// leave-screen consumers such as ZOD-WHL-017's playback stop).
import 'package:astro_mobile/src/app.dart';
import 'package:astro_mobile/src/navigation/active_route.dart';
import 'package:astro_mobile/src/navigation/app_route.dart';
import 'package:astro_mobile/src/navigation/app_router.dart';
import 'package:astro_mobile/src/theme/theme_mode_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'deep_link_cases.dart';

/// Watches the provider above `MaterialApp.router`, as the WHL-017 wiring
/// will.
class _WatchedApp extends ConsumerWidget {
  const _WatchedApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(activeRouteProvider);
    return const ZodiannApp();
  }
}

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  String? initialLocation,
}) async {
  final container = ProviderContainer(
    overrides: [
      if (initialLocation != null)
        appRouterProvider.overrideWith((ref) {
          final router = buildAppRouter(initialLocation: initialLocation);
          ref.onDispose(router.dispose);
          return router;
        }),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const _WatchedApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _go(
  WidgetTester tester,
  ProviderContainer container,
  String location,
) async {
  container.read(appRouterProvider).go(location);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts on the wheel', (tester) async {
    final container = await _pumpApp(tester);
    expect(container.read(activeRouteProvider), AppRoute.wheel);
  });

  testWidgets('starts on the screen a cold start opens (/saved)', (
    tester,
  ) async {
    final container = await _pumpApp(tester, initialLocation: '/saved');
    expect(container.read(activeRouteProvider), AppRoute.saved);
  });

  testWidgets('follows router.go to every screen', (tester) async {
    final container = await _pumpApp(tester);
    for (final route in AppRoute.values.reversed) {
      await _go(tester, container, route.path);
      expect(container.read(activeRouteProvider), route, reason: route.name);
    }
  });

  testWidgets('follows a redirect: an unknown location is the wheel', (
    tester,
  ) async {
    final container = await _pumpApp(tester);
    await _go(tester, container, AppRoute.square.path);
    expect(container.read(activeRouteProvider), AppRoute.square);
    await _go(tester, container, '/nope');
    expect(container.read(activeRouteProvider), AppRoute.wheel);
  });

  testWidgets('emits once per screen switch and nothing on the same screen', (
    tester,
  ) async {
    final container = await _pumpApp(tester);
    final seen = <AppRoute>[];
    container.listen(activeRouteProvider, (_, next) => seen.add(next));
    await _go(tester, container, AppRoute.square.path);
    await _go(tester, container, AppRoute.square.path);
    await _go(tester, container, '/square?x=1');
    await _go(tester, container, AppRoute.settings.path);
    expect(seen, [AppRoute.square, AppRoute.settings]);
  });

  testWidgets('survives a theme and a locale change without resetting', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    final container = await _pumpApp(tester);
    await _go(tester, container, AppRoute.saved.path);
    final seen = <AppRoute>[];
    container.listen(activeRouteProvider, (_, next) => seen.add(next));

    container.read(themeModeProvider.notifier).set(ThemeMode.dark);
    await tester.pumpAndSettle();
    tester.platformDispatcher.localesTestValue = const [Locale('he', 'IL')];
    await tester.pumpAndSettle();

    expect(container.read(activeRouteProvider), AppRoute.saved);
    expect(seen, isEmpty);
  });

  testWidgets('a warm link moves it (handlePushRoute)', (tester) async {
    final container = await _pumpApp(tester);
    await _go(tester, container, AppRoute.settings.path);
    await tester.binding.handlePushRoute('zodiann://about');
    await tester.pumpAndSettle();
    expect(container.read(activeRouteProvider), AppRoute.about);
  });

  group('cold-start link through the platform default route', () {
    // The seed (read before the first frame, from the raw link) must equal
    // what the router settles on after go_router normalises the link and the
    // redirect runs, or the delegate listener would modify the provider
    // during build (a Riverpod assertion).
    final cases = <String, AppRoute>{
      for (final link in squareLinks) link: AppRoute.square,
      ...schemeLinks,
      for (final link in malformedLinks) link: AppRoute.wheel,
    };
    for (final MapEntry(key: link, value: expected) in cases.entries) {
      testWidgets('"$link" → ${expected.name}', (tester) async {
        addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
        tester.platformDispatcher.defaultRouteNameTestValue = link;
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final seed = container.read(activeRouteProvider);
        final changes = <AppRoute>[];
        container.listen(activeRouteProvider, (_, next) => changes.add(next));
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const _WatchedApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(seed, expected, reason: 'the seed');
        expect(container.read(activeRouteProvider), expected);
        expect(changes, isEmpty, reason: 'no change while pumping');
        expect(tester.takeException(), isNull);
        final settled = GoRouter.of(tester.element(find.byType(Scaffold).first))
            .state
            .uri;
        expect(settled.path, expected.path, reason: 'the router settled here');
        expect(settled.hasScheme, isFalse, reason: 'no scheme left');
      });
    }
  });
}
