// T-UI-1 (spec): "Opening the drawer through the hamburger leads to the right
// screen, reopening the app returns to the last screen, and a deep link shows
// the requested screen."
//
// ZOD-TST-014 consolidates the T-UI suite; this group is NAV-003's share.
// The relaunch clause is split out (product-owner decision P3): restoring the
// last screen is ZOD-DAT-007's. Its case pins only the seam DAT-007 will use,
// a router started at an injected location through `appRouterProvider`.
import 'package:astro_mobile/src/app.dart';
import 'package:astro_mobile/src/navigation/app_route.dart';
import 'package:astro_mobile/src/navigation/app_router.dart';
import 'package:astro_mobile/src/navigation/app_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

final _en = lookupZodiannLocalizations(const Locale('en'));

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  String? initialLocation,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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
    UncontrolledProviderScope(container: container, child: const ZodiannApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

String _location(ProviderContainer c) =>
    c.read(appRouterProvider).routerDelegate.currentConfiguration.uri.path;

String _title(WidgetTester tester) =>
    tester.widget<ZodiannTopBar>(find.byType(ZodiannTopBar)).title;

void main() {
  group('T-UI-1', () {
    group('drawer navigation reaches the right screen', () {
      for (final target in AppRoute.values) {
        testWidgets(target.name, (tester) async {
          final start = target == AppRoute.wheel
              ? AppRoute.settings
              : AppRoute.wheel;
          final c = await _pump(tester, initialLocation: start.path);
          await tester.tap(
            find
                .descendant(
                  of: find.byType(ZodiannTopBar),
                  matching: find.byType(ZodiannIconButton),
                )
                .first,
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.descendant(
              of: find.byType(ZodiannDrawer),
              matching: find.text(target.title(_en)),
            ),
          );
          await tester.pumpAndSettle();
          expect(_location(c), target.path);
          expect(_title(tester), target.title(_en));
          expect(find.byType(ZodiannDrawer), findsNothing);
        });
      }
    });

    group('a deep link opens the requested screen directly on cold start', () {
      for (final link in ['zodiann://square', 'zodiann:///square']) {
        testWidgets(link, (tester) async {
          addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
          tester.platformDispatcher.defaultRouteNameTestValue = link;
          final c = await _pump(tester);
          expect(_location(c), '/square');
          expect(_title(tester), AppRoute.square.title(_en));
        });
      }

      testWidgets('and wins over a restored location (the DAT-007 seam)', (
        tester,
      ) async {
        addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
        tester.platformDispatcher.defaultRouteNameTestValue =
            'zodiann://square';
        final c = await _pump(tester, initialLocation: '/saved');
        expect(_location(c), '/square');
      });
    });

    group('relaunch (the seam only; the restore is ZOD-DAT-007)', () {
      testWidgets(
        'a router started at an injected location opens that screen',
        (tester) async {
          final c = await _pump(tester, initialLocation: '/settings');
          expect(_location(c), '/settings');
          expect(_title(tester), AppRoute.settings.title(_en));
          expect(
            GoRouter.of(tester.element(find.byType(ZodiannTopBar))).canPop(),
            isFalse,
          );
        },
      );
    });
  });
}
