import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tells the app that the platform delivered a link while it was running (a
/// "warm" deep link: the user tapped a Zodiann link in another app).
///
/// It exists because go_router's route-information provider cannot say where
/// a notification came from: a platform push is wrapped like `router.go`, and
/// `GoRouter.refresh()` / `refreshListenable` only call `notifyListeners()`.
/// This observer sees platform pushes and nothing else, so the open drawer
/// can close on every incoming link (valid, same-screen or malformed) and on
/// nothing internal (ZOD-NAV-003, P4).
///
/// It never consumes the link: it returns `false`, so go_router still
/// handles it. Flutter notifies observers in registration order until one
/// returns true, and go_router's provider returns true, so this observer must
/// be registered **before** the router mounts. `ZodiannApp` watches
/// [warmLinkProvider] ahead of `MaterialApp.router` for that reason; creating
/// it lazily (for example when the drawer opens) would miss every link.
final class WarmLinkEvents extends ChangeNotifier with WidgetsBindingObserver {
  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    notifyListeners();
    return SynchronousFuture<bool>(false);
  }
}

/// The app's [WarmLinkEvents], registered for the lifetime of the scope.
final Provider<WarmLinkEvents> warmLinkProvider = Provider<WarmLinkEvents>((
  ref,
) {
  final events = WarmLinkEvents();
  WidgetsBinding.instance.addObserver(events);
  ref.onDispose(() {
    WidgetsBinding.instance.removeObserver(events);
    events.dispose();
  });
  return events;
});
