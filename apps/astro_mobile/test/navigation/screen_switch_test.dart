// ZOD-NAV-003 (NAV-4, WH-12): switching screens lands the new screen at the
// top, and every switch is announced through `activeRouteProvider`, so the
// wheel's playback can stop when the user leaves it (ZOD-WHL-017 wires the real
// timer; this file proves the seam with a fake one).
import 'dart:async';

import 'package:astro_mobile/src/app.dart';
import 'package:astro_mobile/src/navigation/active_route.dart';
import 'package:astro_mobile/src/navigation/app_route.dart';
import 'package:astro_mobile/src/navigation/app_router.dart';
import 'package:astro_mobile/src/navigation/app_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

final _en = lookupZodiannLocalizations(const Locale('en'));

/// A stand-in for the wheel's playback: ticks every 110 ms (MASTER §12) until
/// stopped. It knows nothing about routes.
class _Playback extends Notifier<int> {
  Timer? _timer;

  bool get playing => _timer != null;

  @override
  int build() {
    ref.onDispose(() => _timer?.cancel());
    return 0;
  }

  void play() {
    _timer ??= Timer.periodic(
      const Duration(milliseconds: 110),
      (_) => state++,
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

final _playbackProvider = NotifierProvider<_Playback, int>(_Playback.new);

/// The app-layer wiring WHL-017 will add: stop playback when the screen leaves
/// the wheel.
class _WithPlaybackStop extends ConsumerWidget {
  const _WithPlaybackStop();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(activeRouteProvider, (_, next) {
      if (next != AppRoute.wheel) ref.read(_playbackProvider.notifier).stop();
    });
    return const ZodiannApp();
  }
}

/// Every screen is the same widget type with no per-route key, so scroll state
/// could only survive a switch through a shared page.
Widget _longScreen(AppRoute route) => ListView(
  children: [
    for (var i = 0; i < 60; i++) SizedBox(height: 80, child: Text('row $i')),
  ],
);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Size size = const Size(1440, 900),
  bool withPlayback = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      appRouterProvider.overrideWith((ref) {
        final router = buildAppRouter(screenBuilder: _longScreen);
        ref.onDispose(router.dispose);
        return router;
      }),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: withPlayback ? const _WithPlaybackStop() : const ZodiannApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

GoRouter _router(ProviderContainer c) => c.read(appRouterProvider);

double _offset(WidgetTester tester) {
  expect(find.byType(Scrollable), findsOneWidget, reason: 'drawer closed');
  return tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
}

Future<void> _scroll(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable), const Offset(0, -800));
  await tester.pumpAndSettle();
  expect(_offset(tester), greaterThan(0));
}

Future<void> _viaDrawer(WidgetTester tester, AppRoute route) async {
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
      matching: find.text(route.title(_en)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _viaGo(
  WidgetTester tester,
  ProviderContainer c,
  AppRoute route,
) async {
  _router(c).go(route.path);
  await tester.pumpAndSettle();
}

void main() {
  group('every screen switch lands at the top', () {
    for (final (label, size) in [
      ('desktop', const Size(1440, 900)),
      ('phone', const Size(390, 844)),
    ]) {
      for (final scrolled in [
        AppRoute.wheel,
        AppRoute.square,
        AppRoute.settings,
      ]) {
        testWidgets('$label: leaving a scrolled ${scrolled.name} by the drawer '
            'and by go, then returning', (tester) async {
          final c = await _pump(tester, size: size);
          final other = scrolled == AppRoute.about
              ? AppRoute.wheel
              : AppRoute.about;

          await _viaGo(tester, c, scrolled);
          await _scroll(tester);
          await _viaDrawer(tester, other);
          await _viaDrawer(tester, scrolled);
          expect(_offset(tester), 0, reason: 'back via the drawer');

          await _scroll(tester);
          await _viaGo(tester, c, other);
          await _viaGo(tester, c, scrolled);
          expect(_offset(tester), 0, reason: 'back via go');
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('$label: a scrolled settings → wheel shows the wheel at 0', (
        tester,
      ) async {
        final c = await _pump(tester, size: size);
        await _viaGo(tester, c, AppRoute.settings);
        await _scroll(tester);
        await _viaDrawer(tester, AppRoute.wheel);
        expect(_offset(tester), 0);
      });
    }
  });

  group('leaving the wheel stops playback (WH-12)', () {
    Future<void> ticks(WidgetTester tester, int n) async {
      for (var i = 0; i < n; i++) {
        await tester.pump(const Duration(milliseconds: 110));
      }
    }

    Future<void> expectStoppedAfterLeaving(
      WidgetTester tester,
      Future<void> Function(ProviderContainer) leave,
    ) async {
      final c = await _pump(tester, withPlayback: true);
      final playback = c.read(_playbackProvider.notifier);
      playback.play();
      await ticks(tester, 3);
      expect(c.read(_playbackProvider), greaterThanOrEqualTo(3));
      expect(playback.playing, isTrue);

      await leave(c);
      final atLeave = c.read(_playbackProvider);
      expect(playback.playing, isFalse);
      await ticks(tester, 3);
      expect(
        c.read(_playbackProvider),
        atLeave,
        reason: 'no tick after leaving',
      );

      await _viaGo(tester, c, AppRoute.wheel);
      await ticks(tester, 3);
      expect(playback.playing, isFalse, reason: 'back on the wheel: idle');
      expect(c.read(_playbackProvider), atLeave, reason: 'not advancing');
    }

    testWidgets('by the drawer', (tester) async {
      await expectStoppedAfterLeaving(
        tester,
        (_) => _viaDrawer(tester, AppRoute.settings),
      );
    });

    testWidgets('by router.go', (tester) async {
      await expectStoppedAfterLeaving(
        tester,
        (c) => _viaGo(tester, c, AppRoute.settings),
      );
    });

    testWidgets('by a warm deep link', (tester) async {
      await expectStoppedAfterLeaving(tester, (_) async {
        await tester.binding.handlePushRoute('zodiann://settings');
        await tester.pumpAndSettle();
      });
    });

    testWidgets('staying on the wheel keeps it playing', (tester) async {
      final c = await _pump(tester, withPlayback: true);
      final playback = c.read(_playbackProvider.notifier);
      playback.play();
      await ticks(tester, 2);
      // A refresh and a go to the same screen are not a switch.
      _router(c).refresh();
      await _viaGo(tester, c, AppRoute.wheel);
      final before = c.read(_playbackProvider);
      await ticks(tester, 2);
      expect(playback.playing, isTrue);
      expect(c.read(_playbackProvider), greaterThan(before));
      playback.stop();
    });
  });
}
