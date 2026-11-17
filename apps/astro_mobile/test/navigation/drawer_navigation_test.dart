// ZOD-NAV-003: the drawer's items navigate and close it (NAV-3, NAV-5,
// T-UI-1), its active mark follows the route, and an incoming warm platform
// link closes it while internal refreshes, theme and locale changes do not
// (product-owner decision P4).
import 'package:astro_mobile/src/app.dart';
import 'package:astro_mobile/src/navigation/active_route.dart';
import 'package:astro_mobile/src/navigation/app_route.dart';
import 'package:astro_mobile/src/navigation/app_router.dart';
import 'package:astro_mobile/src/navigation/app_shell.dart';
import 'package:astro_mobile/src/theme/theme_mode_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

final _en = lookupZodiannLocalizations(const Locale('en'));

class _Harness {
  _Harness(this.tester, this.container);

  final WidgetTester tester;
  final ProviderContainer container;

  GoRouter get router => container.read(appRouterProvider);

  String get location => router.routerDelegate.currentConfiguration.uri.path;

  AppRoute get screen => container.read(activeRouteProvider);

  String get title =>
      tester.widget<ZodiannTopBar>(find.byType(ZodiannTopBar)).title;

  bool get drawerOpen => find.byType(ZodiannDrawer).evaluate().isNotEmpty;

  /// The drawer's items in [AppRoute] (table) order, as the panel built them.
  List<ZodiannDrawerItem> get items => [
    for (final group
        in tester.widget<ZodiannDrawer>(find.byType(ZodiannDrawer)).groups)
      ...group.items,
  ];

  /// The routes the drawer currently marks selected.
  List<AppRoute> get marked => [
    for (final (i, item) in items.indexed)
      if (item.selected) AppRoute.values[i],
  ];

  Future<void> open() async {
    await tester.tap(
      find
          .descendant(
            of: find.byType(ZodiannTopBar),
            matching: find.byType(ZodiannIconButton),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  Finder item(AppRoute route) => find.descendant(
    of: find.byType(ZodiannDrawer),
    matching: find.text(route.title(_en)),
  );

  Future<void> tapItem(AppRoute route) async {
    await tester.tap(item(route));
  }

  Future<void> warm(String link, {bool settle = true}) async {
    await tester.binding.handlePushRoute(link);
    if (settle) await tester.pumpAndSettle();
  }

  Future<void> go(AppRoute route) async {
    router.go(route.path);
    await tester.pumpAndSettle();
  }
}

Future<_Harness> _pump(
  WidgetTester tester, {
  String? initialLocation,
  bool hebrew = false,
  Widget Function(AppRoute route)? screenBuilder,
  Listenable? refreshListenable,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (hebrew) {
    tester.platformDispatcher.localesTestValue = const [Locale('he')];
  }
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  final container = ProviderContainer(
    overrides: [
      appRouterProvider.overrideWith((ref) {
        final router = buildAppRouter(
          initialLocation: initialLocation,
          screenBuilder: screenBuilder,
          refreshListenable: refreshListenable,
        );
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
  return _Harness(tester, container);
}

void main() {
  group('item taps', () {
    for (final from in AppRoute.values) {
      for (final to in AppRoute.values.where((r) => r != from)) {
        testWidgets('${from.name} → ${to.name}: navigates, closes, marks', (
          tester,
        ) async {
          final h = await _pump(tester, initialLocation: from.path);
          await h.open();
          expect(h.marked, [from]);
          await h.tapItem(to);
          await tester.pumpAndSettle();

          expect(h.location, to.path);
          expect(h.drawerOpen, isFalse);
          expect(h.title, to.title(_en));
          expect(h.screen, to);
          expect(tester.takeException(), isNull);

          await h.open();
          expect(h.marked, [to], reason: 'the tapped item is the only mark');
        });
      }
    }

    testWidgets('Hebrew (RTL) navigates identically', (tester) async {
      final h = await _pump(tester, hebrew: true);
      final he = lookupZodiannLocalizations(const Locale('he'));
      await h.open();
      await tester.tap(
        find.descendant(
          of: find.byType(ZodiannDrawer),
          matching: find.text(AppRoute.settings.title(he)),
        ),
      );
      await tester.pumpAndSettle();
      expect(h.location, '/settings');
      expect(h.drawerOpen, isFalse);
      expect(h.title, AppRoute.settings.title(he));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a locale switch after navigating keeps the route', (
      tester,
    ) async {
      final h = await _pump(tester);
      await h.open();
      await h.tapItem(AppRoute.saved);
      await tester.pumpAndSettle();
      tester.platformDispatcher.localesTestValue = const [Locale('he', 'IL')];
      await tester.pumpAndSettle();
      expect(h.location, '/saved');
      expect(h.screen, AppRoute.saved);
    });

    testWidgets('the active item closes the drawer without navigating or '
        'resetting scroll', (tester) async {
      final h = await _pump(
        tester,
        screenBuilder: (_) => ListView(
          key: const ValueKey('screen-list'),
          children: [
            for (var i = 0; i < 60; i++)
              SizedBox(height: 80, child: Text('row $i')),
          ],
        ),
      );
      await tester.drag(
        find.byKey(const ValueKey('screen-list')),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      double offset() => tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byKey(const ValueKey('screen-list')),
              matching: find.byType(Scrollable),
            ),
          )
          .position
          .pixels;
      final scrolled = offset();
      expect(scrolled, greaterThan(0));

      var notes = 0;
      h.router.routerDelegate.addListener(() => notes++);
      var infoNotes = 0;
      h.router.routeInformationProvider.addListener(() => infoNotes++);
      await h.open();
      await h.tapItem(AppRoute.wheel);
      await tester.pumpAndSettle();

      expect(h.drawerOpen, isFalse);
      expect(h.location, '/wheel');
      expect(notes, 0);
      expect(infoNotes, 0, reason: "no navigation request at all");
      expect(offset(), scrolled);
    });

    testWidgets('a second onTap after the pop navigates nowhere and pops '
        'nothing more', (tester) async {
      final h = await _pump(tester);
      var notes = 0;
      h.router.routerDelegate.addListener(() => notes++);
      await h.open();
      await h.tapItem(AppRoute.settings);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      // The route is leaving: a pointer tap cannot arrive, but a keyboard
      // activation or a programmatic call can.
      h.items[AppRoute.about.index].onTap();
      await tester.pumpAndSettle();

      expect(h.location, '/settings');
      expect(notes, 1, reason: 'one navigation for the first tap');
      expect(find.byType(ZodiannTopBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the active item activated twice closes once', (tester) async {
      final h = await _pump(tester);
      await h.open();
      final onTap = h.items[AppRoute.wheel.index].onTap;
      onTap();
      onTap();
      await tester.pumpAndSettle();
      expect(h.drawerOpen, isFalse);
      expect(h.location, '/wheel');
      expect(find.byType(ZodiannTopBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a tap counts exactly one router notification', (tester) async {
      final h = await _pump(tester);
      await h.open();
      var notes = 0;
      h.router.routerDelegate.addListener(() => notes++);
      await h.tapItem(AppRoute.square);
      await tester.pumpAndSettle();
      expect(h.location, '/square');
      expect(h.drawerOpen, isFalse);
      expect(notes, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('the active mark follows the route (it is not captured at open)', () {
    testWidgets('router.go with the drawer open moves the mark and keeps it '
        'open', (tester) async {
      final h = await _pump(tester);
      await h.open();
      expect(h.marked, [AppRoute.wheel]);
      await h.go(AppRoute.square);
      expect(h.drawerOpen, isTrue);
      expect(h.marked, [AppRoute.square]);
    });
  });

  group('warm deep links with the drawer open (P4)', () {
    testWidgets('a link to another screen closes the drawer and the mark '
        'moves first', (tester) async {
      final h = await _pump(tester);
      await h.open();
      await h.warm('zodiann://square', settle: false);
      await tester.pump(); // one frame: the drawer is still closing
      expect(h.drawerOpen, isTrue);
      expect(h.items[AppRoute.square.index].selected, isTrue);
      expect(h.items[AppRoute.wheel.index].selected, isFalse);
      await tester.pumpAndSettle();

      expect(h.location, '/square');
      expect(h.router.state.uri.toString(), '/square', reason: 'no scheme');
      expect(h.drawerOpen, isFalse);
      expect(h.title, AppRoute.square.title(_en));
      expect(h.screen, AppRoute.square);
      expect(tester.takeException(), isNull);

      await h.open();
      expect(h.marked, [AppRoute.square]);
    });

    testWidgets('the path form of a link closes it too', (tester) async {
      final h = await _pump(tester);
      await h.open();
      await h.warm('zodiann:///settings');
      expect(h.location, '/settings');
      expect(h.drawerOpen, isFalse);
    });

    testWidgets('Hebrew (RTL)', (tester) async {
      final h = await _pump(tester, hebrew: true);
      await h.open();
      await h.warm('zodiann://about');
      expect(h.location, '/about');
      expect(h.drawerOpen, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a link to the screen already shown closes it', (tester) async {
      final h = await _pump(tester);
      await h.open();
      await h.warm('zodiann://wheel');
      expect(h.location, '/wheel');
      expect(h.drawerOpen, isFalse);
    });

    for (final link in [
      'zodiann://nope',
      'zodiann:square',
      'https://example.com/square',
    ]) {
      for (final start in [AppRoute.wheel, AppRoute.square]) {
        testWidgets('malformed "$link" from ${start.name} lands on the wheel '
            'and closes', (tester) async {
          final h = await _pump(tester, initialLocation: start.path);
          await h.open();
          await h.warm(link);
          expect(h.location, '/wheel');
          expect(h.drawerOpen, isFalse);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('leaving-route guard: a link while a tap is closing the '
        'drawer', (tester) async {
      final h = await _pump(tester);
      await h.open();
      await h.tapItem(AppRoute.settings);
      await tester.pump();
      await h.warm('zodiann://about');
      expect(h.location, '/about');
      expect(find.byType(ZodiannTopBar), findsOneWidget);
      expect(h.drawerOpen, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('leaving-route guard: two links back to back', (tester) async {
      final h = await _pump(tester);
      await h.open();
      await h.warm('zodiann://square', settle: false);
      await h.warm('zodiann://about', settle: false);
      await tester.pumpAndSettle();
      expect(h.location, '/about');
      expect(find.byType(ZodiannTopBar), findsOneWidget);
      expect(h.drawerOpen, isFalse);
      expect(tester.takeException(), isNull);
    });
  });

  group('must not close the drawer', () {
    testWidgets('router.refresh()', (tester) async {
      final h = await _pump(tester);
      await h.open();
      h.router.refresh();
      await tester.pumpAndSettle();
      expect(h.drawerOpen, isTrue);
      expect(h.location, '/wheel');
    });

    testWidgets('a refreshListenable notification', (tester) async {
      final refresh = ValueNotifier<int>(0);
      addTearDown(refresh.dispose);
      final h = await _pump(tester, refreshListenable: refresh);
      await h.open();
      refresh.value++;
      await tester.pumpAndSettle();
      expect(h.drawerOpen, isTrue);
      expect(h.location, '/wheel');
    });

    testWidgets('a theme change', (tester) async {
      final h = await _pump(tester);
      await h.open();
      h.container.read(themeModeProvider.notifier).set(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(h.drawerOpen, isTrue);
    });

    testWidgets('a locale change (and the panel turns RTL)', (tester) async {
      final h = await _pump(tester);
      await h.open();
      tester.platformDispatcher.localesTestValue = const [Locale('he', 'IL')];
      await tester.pumpAndSettle();
      expect(h.drawerOpen, isTrue);
      expect(
        Directionality.of(tester.element(find.byType(ZodiannDrawer))),
        TextDirection.rtl,
      );
    });

    testWidgets('opening it does not close it', (tester) async {
      final h = await _pump(tester);
      await h.open();
      await tester.pump(const Duration(seconds: 1));
      expect(h.drawerOpen, isTrue);
    });
  });
}
