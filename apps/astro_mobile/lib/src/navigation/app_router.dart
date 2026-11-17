import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_route.dart';
import 'app_shell.dart';
import 'screen_stub.dart';

/// Builds the app's router: one route per [AppRoute], all inside one
/// [AppShell] (the top bar, ZOD-NAV-001), opening at [initialLocation] (the
/// wheel by default).
///
/// The shell persists across navigation; it shows the active route, which
/// is the matched leaf route (`state.topRoute`). Any location no route
/// matches redirects to the wheel (NAV-5), both at startup and at runtime,
/// so there is no error page.
///
/// Deep links (ZOD-NAV-003) use the `zodiann` scheme. The redirect rewrites
/// every scheme URI to the bare `/name` it names, or to `/wheel` when it
/// names none, before matching: go_router ignores a URI's host, so without
/// this `zodiann://nope/square` would show the square, and `zodiann://square`
/// would not resolve at all. No scheme is left in the router's state.
///
/// [screenBuilder] builds each route's screen (the blank [ScreenStub] by
/// default; real screens replace it in their own tasks). [refreshListenable]
/// is go_router's refresh seam, passed through for tests (nothing in the app
/// refreshes the router today).
GoRouter buildAppRouter({
  String? initialLocation,
  Widget Function(AppRoute route)? screenBuilder,
  Listenable? refreshListenable,
}) => GoRouter(
  initialLocation: initialLocation ?? AppRoute.wheel.path,
  refreshListenable: refreshListenable,
  redirect: (_, state) {
    if (state.uri.hasScheme) {
      return (AppRoute.fromUri(state.uri) ?? AppRoute.wheel).path;
    }
    return state.topRoute == null ? AppRoute.wheel.path : null;
  },
  routes: [
    ShellRoute(
      builder: (_, state, child) => AppShell(
        route: AppRoute.fromPath(state.topRoute?.path ?? ''),
        child: child,
      ),
      routes: [
        for (final route in AppRoute.values)
          GoRoute(
            path: route.path,
            builder: (_, _) =>
                screenBuilder?.call(route) ?? ScreenStub(route: route),
          ),
      ],
    ),
  ],
);

/// The one router for the app's lifetime, so rebuilding `ZodiannApp` (on a
/// theme or locale change) never resets the screen. Override it to start
/// elsewhere, for example to restore the last screen (ZOD-DAT-007).
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  final router = buildAppRouter();
  ref.onDispose(router.dispose);
  return router;
});
