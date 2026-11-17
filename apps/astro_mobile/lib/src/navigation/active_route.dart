import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_route.dart';
import 'app_router.dart';

/// The router's current screen (ZOD-NAV-003), for everything outside the
/// shell: the drawer's active mark, and consumers that must act when the user
/// leaves a screen.
///
/// Feature packages never import this. To stop work when the user leaves a
/// screen, the app layer listens (`ref.listen(activeRouteProvider, …)`) and
/// calls a stop method the feature exposes (ZOD-WHL-017 adds that wiring for
/// the wheel's playback, WH-12). A screen's `State`, and `autoDispose`
/// providers watched only by that screen, are disposed on leave, because each
/// route has its own page.
///
/// It resolves the screen from the matched leaf route, the same source the
/// shell uses ([AppRoute.fromPath]), and changes state only when the screen
/// changes: a `go` to the current screen, a refresh and a query change emit
/// nothing. Before the first frame the router's configuration is empty, so
/// the first value comes from `routeInformationProvider`, which already holds
/// a cold-start platform link ([AppRoute.fromUri]).
final NotifierProvider<ActiveRoute, AppRoute> activeRouteProvider =
    NotifierProvider<ActiveRoute, AppRoute>(ActiveRoute.new);

/// See [activeRouteProvider].
class ActiveRoute extends Notifier<AppRoute> {
  @override
  AppRoute build() {
    final router = ref.watch(appRouterProvider);
    final delegate = router.routerDelegate;
    void sync() {
      final next = _screenOf(router);
      if (next != state) state = next;
    }

    delegate.addListener(sync);
    ref.onDispose(() => delegate.removeListener(sync));
    return _screenOf(router);
  }

  static AppRoute _screenOf(GoRouter router) {
    final configuration = router.routerDelegate.currentConfiguration;
    if (configuration.isEmpty) {
      return AppRoute.fromUri(router.routeInformationProvider.value.uri) ??
          AppRoute.wheel;
    }
    return AppRoute.fromPath(configuration.last.route.path);
  }
}
