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
GoRouter buildAppRouter({String? initialLocation}) => GoRouter(
  initialLocation: initialLocation ?? AppRoute.wheel.path,
  redirect: (_, state) => state.topRoute == null ? AppRoute.wheel.path : null,
  routes: [
    ShellRoute(
      builder: (_, state, child) => AppShell(
        route: AppRoute.values.firstWhere(
          (route) => route.path == state.topRoute?.path,
          orElse: () => AppRoute.wheel,
        ),
        child: child,
      ),
      routes: [
        for (final route in AppRoute.values)
          GoRoute(
            path: route.path,
            builder: (_, _) => ScreenStub(route: route),
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
