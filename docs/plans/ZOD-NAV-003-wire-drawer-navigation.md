# ZOD-NAV-003 Wire Drawer Navigation to `go_router` Routes: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Drawer item taps navigate to their screen, close the drawer and move the active mark; OS deep links (`zodiann://…`) open a screen on cold start; every screen switch lands at the top and is announced through a seam that WHL-017 uses to stop playback.

**Architecture:** All changes are in `apps/astro_mobile` (app layer; `shared_ui` is untouched, the drawer stays route-independent). A new `activeRouteProvider` mirrors the router's current screen and is the single source for the drawer's active mark and for "left a screen" consumers. The router gains a `screenBuilder` seam (default `ScreenStub`) and a deep-link normalisation in its existing top-level redirect. Platform link registration is a custom scheme in the Android manifest and iOS plist.

**Tech Stack:** Flutter 3.50 / Dart 3.14 (FVM), `go_router ^18.1.4`, `flutter_riverpod ^3.5.0`, `flutter_test`.

**Spec:** NAV-4, NAV-5, WH-12, T-UI-1 in `assets/zodiann-specification.md`; task file `docs/development/navigation/ZOD-NAV-003-wire-drawer-navigation-to-go-router-routes.md`; NAV-002 design `docs/superpowers/specs/2026-11-17-zod-nav-002-drawer-design.md`.

## Product-owner decisions (2026-11-17)

- **P1, playback stop:** NAV-003 provides a leave-screen seam (`activeRouteProvider`) proven with a fake playback consumer; the real timer arrives in ZOD-WHL-017, which closes acceptance criterion 2 jointly.
- **P2, deep links:** custom scheme `zodiann://` in the Android manifest and iOS plist; Android verified on the emulator, iOS recorded as outstanding (no Mac).
- **P3, relaunch:** "app relaunch returns to the last screen" (T-UI-1 clause, criterion 1) belongs to ZOD-DAT-007. NAV-003 pins only the seam it will use (`appRouterProvider` started at an injected location). The task file's wording is not edited; the split is recorded in `docs/PROGRESS.md`.

## Decisions (plan review, 2026-11-17)

Settled by a go_router 18.1.4 spike (Flutter 3.50.0) during plan review:

- `zodiann:///name` resolves natively; `zodiann://name` goes to the wheel (it parses as `zodiann://name/`, path `/`). go_router ignores the host, so `zodiann://nope/square` would show Square. Hence a redirect that canonicalises **every** scheme URI to a bare `/name` or `/wheel` (also leaves no scheme in router state).
- Android hands the cold-start link over as `PlatformDispatcher.defaultRouteName`; go_router lets it override `initialLocation`. A warm link arrives through `handlePushRoute`.
- Popping the drawer and calling `go` is safe in either order (the `ShellRoute` page key is stable). Use pop, then `go`. Never give the `ShellRoute` a per-location key: it would drop an open drawer.
- Each `GoRoute` has its own page key, so departed screens are disposed and scroll resets with no production change.
- Before the first frame the delegate configuration is empty, while `routeInformationProvider.value` already holds the platform link.
- **P4 (product owner, 2026-11-17, with a same-day follow-up):** when the app is running and an external deep link (WhatsApp, a browser, another app) arrives while the drawer is open, the app navigates to the destination **and closes the drawer**. **Every incoming warm platform link closes it, including a link to the screen already shown and a malformed link while on the wheel. An internal router refresh (`GoRouter.refresh()`, `refreshListenable`) must not close it, nor may theme or locale changes.** Finding (go_router 18.1.4 source): the router's information provider cannot tell these apart reliably. A platform push is wrapped in `RouteInformationState.go()` exactly like `router.go`; `refresh()` and `refreshListenable` only call `notifyListeners()`; and the router silently swaps the provider's `value` after its own navigations, so neither a notification nor the value's identity proves an external link. **Smallest architectural adjustment (proposed, needs approval):** a tiny app-level `WarmLinkEvents` (a `WidgetsBindingObserver` + `ChangeNotifier`, `navigation/warm_link.dart`) whose `didPushRouteInformation` notifies and returns `SynchronousFuture(false)`, so go_router still handles the link. `warmLinkProvider` provides it and `ZodiannApp` watches it **before** `MaterialApp.router` mounts, because Flutter notifies observers in registration order until one returns true and go_router's provider returns true. The drawer panel listens to it and pops its own route while the route is active. No timing is involved. An internal `go` to another screen while the drawer is open does not close it (the mark follows `activeRouteProvider`).

## Global Constraints

- All user-visible copy comes from `ZodiannLocalizations`; this task adds none.
- No new dependency; `test/architecture/no_network_test.dart` stays green (a `BROWSABLE` intent filter must not add `INTERNET`).
- Route identifiers are `#name` as `go_router` path `/name` (`AppRoute.path`); unknown locations land on the wheel (NAV-5).
- Feature packages never import `AppRoute`; `shared_ui` stays route-independent.
- `go` replaces, never stacks (FND-014 decision); Android Back from a non-wheel screen is unchanged.
- Run SDK commands through FVM (`fvm flutter …`, `fvm dart run melos …`).
- Commit format `type(ZOD-NAV-003): …` with the environment's attribution trailer.

## Review Focus

Behaviours the spec implies and no acceptance criterion names (each is pinned by a test in the task shown):

1. Tapping the **already active** item closes the drawer, does not navigate and does not reset scroll (Task 2).
2. **Two rapid taps** on different items during the close animation navigate once, to the first (Task 2).
3. A **malformed or unknown deep link** (`zodiann://nope`, `zodiann://square/extra`, `zodiann:///Square`, `zodiann://`, `zodiann://nope/square`, `zodiann://wheel/square`, `https://example.com/square`, `zodiann:square`) shows the wheel, never an error page (Task 1).
4. A **warm deep link while the drawer is open** (P4) navigates to the destination and closes the drawer, whether it names another screen, the screen already shown, or nothing valid; the next open marks the destination active. An internal router refresh (`refresh()`, `refreshListenable`), a theme change and a locale change do not close it; `router.go` does not close it either and the mark follows. The NAV-002 "captured at open" minor is closed (Task 2).
5. Hebrew (RTL) drawer navigation behaves identically, and a locale change mid-session keeps the route (Task 2).

## File Structure

| File | Responsibility |
|---|---|
| `apps/astro_mobile/lib/src/navigation/app_route.dart` (modify) | add `AppRoute.fromUri(Uri) → AppRoute?`: scheme `zodiann` or none (any other scheme → null); a scheme URI must have an authority (`uri.hasAuthority`), so `zodiann:name` and `zodiann:/name` → null; query and fragment are ignored; a host form (`zodiann://name`) requires path `''` or `/`; the path form (`/name`, `zodiann:///name`) tolerates one trailing slash and any query; names are case-sensitive, except that Dart lowercases a URI scheme and host, so `zodiann://Square` and `ZODIANN://square` resolve (documented). Invariant: for every input, `fromUri(raw) ?? wheel` must equal the screen the router settles on after go_router's `normalizeUri` and the redirect; otherwise the `ActiveRoute` seed differs from the first configuration and the delegate listener modifies the provider during build (Riverpod assertion). Add `AppRoute.fromPath(String) → AppRoute` (exact path equality, fallback wheel) |
| `apps/astro_mobile/lib/src/navigation/active_route.dart` (create) | `activeRouteProvider`: the router's current screen as an `AppRoute`, for everything outside the shell |
| `apps/astro_mobile/lib/src/navigation/app_router.dart` (modify) | `screenBuilder` parameter (real screens replace `ScreenStub` in their own tasks; NAV-003 keeps it as the default); scheme-canonicalising redirect; `refreshListenable` test seam; the shell builder uses `AppRoute.fromPath` |
| `apps/astro_mobile/lib/src/navigation/app_shell.dart` (modify) | drawer taps close and navigate; the drawer panel's selection follows `activeRouteProvider` and the panel closes itself on a warm platform link (P4) |
| `apps/astro_mobile/lib/src/navigation/warm_link.dart` (create) | `WarmLinkEvents` (observer + `ChangeNotifier`) and `warmLinkProvider`: the only place that knows an incoming platform link arrived, distinct from internal router refreshes |
| `apps/astro_mobile/lib/src/app.dart` (modify) | `ref.watch(warmLinkProvider)` before `MaterialApp.router`, so the observer registers ahead of go_router's |
| `apps/astro_mobile/android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist` (modify) | register the `zodiann` scheme |
| `apps/astro_mobile/test/navigation/…` (create/modify) | tests per task |

---

### Task 1: Route parsing, active-route provider, deep-link normalisation

**Files:**
- Modify: `app_route.dart`, `app_router.dart`
- Create: `active_route.dart`
- Test: `apps/astro_mobile/test/navigation/active_route_test.dart` (create); `app_router_test.dart` (extend)

**Interfaces:**
- Produces: `static AppRoute? AppRoute.fromUri(Uri uri)`; `static AppRoute AppRoute.fromPath(String path)`; `final NotifierProvider<ActiveRoute, AppRoute> activeRouteProvider` (state = current screen, initial = the router's initial screen); `GoRouter buildAppRouter({String? initialLocation, Widget Function(AppRoute route)? screenBuilder, Listenable? refreshListenable})`.
- Consumes: `appRouterProvider`, `AppRoute`.

Working directories: `fvm flutter test` / `fvm flutter build` run from `apps/astro_mobile`; `fvm dart run melos …` from the repo root.

- [ ] **Step 1: (settled by plan review, see Decisions).** No spike is needed.
- [ ] **Step 2: Write failing tests** (`active_route_test.dart`, `app_router_test.dart`):
  - `fromUri` positives → the route: `/square`, `/square/`, `/square?x=1`, `zodiann:///square`, `zodiann://square`, `zodiann://square/`, `zodiann://square?x=1`, `zodiann://Square` and `ZODIANN://square` (lowercased by `Uri`, pinned), `/square#f`. Negatives → `null`: `zodiann:square`, `zodiann:/square`, `/Square`, `/nope`, `/wheel/extra`, `zodiann://nope`, `zodiann://square/extra`, `zodiann://`, `zodiann://nope/square`, `https://example.com/square`, empty. `fromPath` is exact equality with a wheel fallback.
  - Router, via `initialLocation`: each of the five `zodiann://<name>` and `zodiann:///<name>` forms opens that screen; every malformed form in Review Focus 3 lands on `/wheel`. After every valid deep link, cold and warm, `router.state.uri.toString() == '/<name>'` (no scheme left).
  - Router, via the real platform path: with the default `appRouterProvider` and `tester.platformDispatcher.defaultRouteNameTestValue` set to `zodiann://square` and to `zodiann:///square` (cleared in `addTearDown`) the Square opens; one more case overrides `initialLocation: '/saved'` as DAT-007 will and shows the platform link still wins.
  - Warm: `await tester.binding.handlePushRoute('zodiann://about')` while on Settings opens About.
  - `activeRouteProvider`: equals the initial screen (cold start at `/saved` → `saved`); follows `router.go` for each route; follows a redirect (`go('/nope')` → `wheel`); emits once per switch (a `ProviderContainer` listener records `wheel → square → settings`); a `go` to the current route emits nothing; survives a theme and a locale rebuild without resetting. For every positive and every malformed input in the `fromUri` lists and Review Focus 3, with `defaultRouteNameTestValue` set to it and the default router: reading `activeRouteProvider` through an `UncontrolledProviderScope` container (disposed in `addTearDown`) before `pumpWidget` gives the screen the router settles on; a listener records no change during `pumpWidget` and `pumpAndSettle`, and `tester.takeException()` is null. The pumped app must `ref.watch(activeRouteProvider)` above `MaterialApp.router`, as the WHL-017 wiring will.
  - `screenBuilder`: when given, each route shows `screenBuilder(route)`; the default still shows `ScreenStub` (existing test unedited).
- [ ] **Step 3: Run `fvm flutter test test/navigation`.** Expected: `active_route_test.dart` and `app_router_test.dart` fail to compile (`fromUri`, `fromPath`, `activeRouteProvider` undefined; no named parameter `screenBuilder`); `drawer_shell_test.dart` and `top_bar_shell_test.dart` pass.
- [ ] **Step 4: Implement.**
  - `AppRoute.fromUri` and `fromPath` as specified in the File Structure.
  - `buildAppRouter` also takes `Listenable? refreshListenable` (test seam, default null) and passes it to `GoRouter`.
  - `buildAppRouter`'s redirect becomes: `if (state.uri.hasScheme) return AppRoute.fromUri(state.uri)?.path ?? AppRoute.wheel.path; return state.topRoute == null ? AppRoute.wheel.path : null;` so every scheme URI is rewritten to a bare `/name`, or to `/wheel`, before matching. The `ShellRoute` builder resolves its route with `AppRoute.fromPath(state.topRoute?.path ?? '')` (closes the NAV-001 deferred minor).
  - `ActiveRoute extends Notifier<AppRoute>`: `build()` does `ref.watch(appRouterProvider)` and derives the screen from the matched leaf, the same source the shell uses: `config.isEmpty ? (AppRoute.fromUri(router.routeInformationProvider.value.uri) ?? AppRoute.wheel) : AppRoute.fromPath(config.last.route.path)`, where `config = router.routerDelegate.currentConfiguration`. It subscribes with `routerDelegate.addListener`, removes the listener in `ref.onDispose`, and assigns `state` only on change.
- [ ] **Step 5: Run the same tests** from `apps/astro_mobile`. Expected: all pass. Run `fvm dart run melos run lint` from the root → exit 0.
- [ ] **Step 6: Commit** `feat(ZOD-NAV-003): route parsing and the active-route provider`.

---

### Task 2: Drawer taps navigate and close; the active mark follows the route

**Files:**
- Create: `navigation/warm_link.dart`
- Modify: `app_shell.dart` (`_openDrawer`), `app.dart`
- Test: `apps/astro_mobile/test/navigation/drawer_navigation_test.dart` (create); `drawer_shell_test.dart` (replace the test `item taps are inert in this task (decision A)`; update the file's header comment and the class doc in `app_shell.dart`)

**Interfaces:**
- Consumes: `activeRouteProvider`, `showZodiannDrawer`, `ZodiannDrawerItem.onTap`, `GoRouter`.
- Produces: tapping an item pops the drawer route and calls `router.go(route.path)` unless it is the active screen; items ignore taps once the drawer route is no longer active (`ModalRoute.of(drawerContext)?.isActive != true`); the panel pops its own route when `warmLinkProvider` notifies (an incoming platform link) while the route is active (P4); `final Provider<WarmLinkEvents> warmLinkProvider`.

- [ ] **Step 1: Write failing tests** (`drawer_navigation_test.dart`, helpers copied from `drawer_shell_test.dart`'s `_pumpApp` / `_open`):
  - for each of the five screens, from each other screen: open drawer, tap its item, `pumpAndSettle` → location is the route's path, no `ZodiannDrawer` in the tree, the top bar title is that screen's title (en);
  - reopen: the tapped item is the only `selected` node (semantics) and carries the accent style;
  - Review Focus 1: tap the active item → drawer closed, location unchanged, a scrolled test screen (via `screenBuilder`) keeps its offset;
  - Review Focus 2: tap Settings, `pump()`, `pump(50 ms)`, then invoke About's callback directly (`tester.widget<ZodiannDrawer>(find.byType(ZodiannDrawer)).groups[1].items[2].onTap()`, as NAV-002's `onPressed(); onPressed();` test does; a pointer tap is already blocked by the reversing route's `IgnorePointer`) → after `pumpAndSettle` the location is `/settings` and exactly one delegate notification was recorded. Also invoke the active item's `onTap` twice → the drawer closes, the location is unchanged, the top bar is still present, and `tester.takeException()` is null (a second pop would remove the shell page);
  - **Regression, P4 (warm deep link with the drawer open):** drive warm links with `await tester.binding.handlePushRoute(uri)`. On the wheel, open the drawer, push `zodiann://square`, then a single `await tester.pump()` (animations on, not reduced motion; the drawer is still closing) → `tester.widget<ZodiannDrawer>(find.byType(ZodiannDrawer)).groups[0].items[1].selected` is true and `items[0].selected` is false (the mark moves before the panel leaves; catches a selection captured at open); then `pumpAndSettle` → location `/square` (no scheme left), no `ZodiannDrawer`, top bar title Square's, `activeRouteProvider` is `square`, `tester.takeException()` is null; reopening shows Square as the only `selected` node. Further cases, each from an open drawer: `zodiann:///settings`; Hebrew (RTL); **same screen** (`zodiann://wheel` from the wheel) → closes, location `/wheel`; **malformed** (`zodiann://nope`, `zodiann:square`, `https://example.com/square`) from the wheel and from Square → closes, location `/wheel`. **Must not close:** `router.refresh()`; a `refreshListenable` (a `ChangeNotifier` passed to `buildAppRouter(refreshListenable:)`) notified; a theme change (`themeModeProvider`); an en → he locale switch (the drawer stays, RTL after the switch); `router.go('/square')` (the drawer stays open and the Square mark follows). Tap variant: from the wheel with the drawer open, tap Square with a delegate-notification counter attached before the tap → after `pumpAndSettle` the location is `/square`, no `ZodiannDrawer`, `tester.takeException()` is null, and exactly one delegate notification was recorded (a regression check for the tap path; a tap never reaches the warm-link listener). Opening the drawer must not close it; **Leaving-route guard:** (a) with the drawer open on the wheel, tap Settings, `await tester.pump()`, then `await tester.binding.handlePushRoute('zodiann://about')`; (b) with the drawer open, `await tester.binding.handlePushRoute('zodiann://square'); await tester.binding.handlePushRoute('zodiann://about');` with no pump between. After `pumpAndSettle`, each case has location `/about`, one `ZodiannTopBar`, no `ZodiannDrawer`, and `tester.takeException()` null. Without the guard, (a) fails go_router's `currentConfiguration.isNotEmpty` assertion and (b) reports a duplicate navigator GlobalKey;
  - Review Focus 5: the same navigation in Hebrew (RTL), and a locale switch en → he after navigating keeps the route;
  - the hamburger still opens the drawer on every screen at 1440, 800 and 390 widths; Back still closes without navigating (existing tests unchanged).
- [ ] **Step 2: Run** `fvm flutter test test/navigation/drawer_navigation_test.dart test/navigation/drawer_shell_test.dart` from `apps/astro_mobile`. Expected: navigation tests fail with location `/wheel`, expected `/settings`, and `ZodiannDrawer` still found; the old `item taps are inert…` test was deleted in Step 1; no other existing test fails. The P4 link cases fail first on the mid-close mark (`selected` Expected true, Actual false: the selection is captured at open); the same-screen and malformed cases fail on `ZodiannDrawer` still found; the `router.go('/square')` case fails on the Square mark; the tap variant fails with location `/wheel` and the drawer still found; the refresh, `refreshListenable`, theme and locale "must not close" cases already pass (nothing closes yet; they guard against the listener-on-provider mutant).
- [ ] **Step 3: Implement.** Create `navigation/warm_link.dart`: `final class WarmLinkEvents extends ChangeNotifier with WidgetsBindingObserver` whose `didPushRouteInformation(RouteInformation _)` calls `notifyListeners()` and returns `SynchronousFuture<bool>(false)` (it never consumes the link); `final warmLinkProvider = Provider<WarmLinkEvents>(…)` that adds it with `WidgetsBinding.instance.addObserver` and, in `ref.onDispose`, removes and disposes it. `ZodiannApp.build` calls `ref.watch(warmLinkProvider)` **before** returning `MaterialApp.router` (document why in both places: observers run in registration order and go_router's provider returns true). In `_openDrawer`, capture `GoRouter.of(context)` once. Replace the captured `route` with a small `ConsumerStatefulWidget` inside the builder that watches `activeRouteProvider` for `selected` and, in `initState`, adds a listener to `ref.read(warmLinkProvider)` (removed in `dispose`) that pops the drawer route when `ModalRoute.of(context)?.isActive == true`. `onTap`: if `ModalRoute.of(drawerContext)?.isActive != true` return; pop the drawer route; then, if the item's route differs from the active one, `router.go(r.path)` (pop first, then `go`; see Decisions).
- [ ] **Step 4: Run** the same tests plus the whole `astro_mobile` suite from `apps/astro_mobile`. Expected: all pass.
- [ ] **Step 5: Commit** `feat(ZOD-NAV-003): drawer items navigate and close the drawer`.

---

### Task 3: Leave-screen seam and scroll reset (criteria 2 and 3)

**Files:**
- Test: `apps/astro_mobile/test/navigation/screen_switch_test.dart` (create); production change only if a test proves one is needed
- Doc: document the seam in `active_route.dart`'s class doc: "Feature packages never import this. To stop work when the user leaves a screen, the app layer listens (`ref.listen(activeRouteProvider, …)`) and calls a stop method the feature exposes (WHL-017 adds that wiring for playback). A screen's `State`, and `autoDispose` providers watched only by that screen, are disposed on leave, because each route has its own page."

**Interfaces:**
- Consumes: `activeRouteProvider`, `buildAppRouter(screenBuilder:)`.
- Produces: the contract WHL-017 uses (no code beyond Task 1).

- [ ] **Step 1: Write the tests.**
  - *Scroll reset:* a test screen per route is a long `ListView`, the same widget type with no per-route key (otherwise the mutant below is not caught); scroll Wheel, Square and Settings by 800, switch away by drawer and by `router.go`, and return → each starts at offset 0; the switch from a scrolled Settings to Wheel shows the Wheel at 0. Also at phone width, where the body inherits the bar's top padding.
  - *Playback seam (fake):* a fake `PlaybackController` provider (test-only; it does not import `AppRoute`) with `Timer.periodic(110 ms)`, cancelled in `ref.onDispose` and in `stop()`. The test adds an app-level `ref.listen(activeRouteProvider, …)` that calls `controller.stop()` when the screen leaves the wheel. While playing, advance with `tester.pump(const Duration(milliseconds: 110))` steps, not `pumpAndSettle`; end each test stopped so no timer is pending. Start it, switch to Settings by the drawer after 3 ticks → tick count stops advancing; return to the wheel → still not advancing and not playing. Repeat navigating by `router.go` and by `tester.binding.handlePushRoute('zodiann://settings')` while it plays.
  - *Mutant proofs:* removing the subscription makes the ticks keep advancing; every `GoRoute` given a `pageBuilder` returning `MaterialPage(key: const ValueKey('screen'), …)` (one shared page key) makes the scroll-reset test fail.
- [ ] **Step 2: Run.** Expected: pass with no production change; each `GoRoute` has its own page key, so departed screens are disposed (verified in plan review).
- [ ] **Step 3: Commit** `test(ZOD-NAV-003): scroll reset and the leave-screen seam`.

---

### Task 4: OS deep-link registration, T-UI-1, verification and docs

**Files:**
- Modify: `AndroidManifest.xml` (a second `intent-filter` on `MainActivity`: `VIEW`, `DEFAULT`, `BROWSABLE`, `<data android:scheme="zodiann"/>`); `ios/Runner/Info.plist` (`CFBundleURLTypes` with scheme `zodiann`)
- Create: `apps/astro_mobile/test/navigation/t_ui_1_test.dart`, `apps/astro_mobile/test/platform_links_test.dart`
- Modify: task file status, `docs/development/TASKS.md`, `docs/PROGRESS.md`

**Interfaces:** none new.

- [ ] **Step 1: Write failing tests.**
  - `platform_links_test.dart` (reads the files from disk): the manifest has exactly one `BROWSABLE` filter with scheme `zodiann`, no `INTERNET` permission (repeats the root `no_network_test.dart`; keep or drop) and no `flutter_deeplinking_enabled` meta-data set to false; the plist `CFBundleURLTypes` entry carries `CFBundleURLName` (`com.zodiann.app`) and `CFBundleURLSchemes` `[zodiann]`, and `FlutterDeepLinkingEnabled` is not false.
  - `t_ui_1_test.dart`, a group named `T-UI-1`: (a) drawer navigation reaches each screen (one test per screen); (b) a deep link opens `square` directly on cold start (the default `appRouterProvider` with `tester.platformDispatcher.defaultRouteNameTestValue` set to `zodiann://square` and to `zodiann:///square`, cleared in `addTearDown`; plus one case with `initialLocation: '/saved'` overridden as DAT-007 will, showing the platform link still wins); (c) the relaunch clause: a router started at an injected location (the DAT-007 seam) opens that screen; its comment states the full restore is ZOD-DAT-007's (P3).
- [ ] **Step 2: Run** `fvm flutter test` from `apps/astro_mobile`. Expected: platform tests fail, T-UI-1 passes.
- [ ] **Step 3: Edit the manifest and plist.** Re-run: all pass.
- [ ] **Step 4: Emulator check** (emulator-5554), first on the debug APK and then on `fvm flutter build apk --release` (from `apps/astro_mobile`) installed with `adb install -r build/app/outputs/flutter-apk/app-release.apk` (release signs with the debug key; only a release build exercises Flutter's manifest-based intent validation):
  - run the `adb` commands from PowerShell, or prefix them with `MSYS_NO_PATHCONV=1` in Git Bash (path conversion can rewrite `:/`);
  - `adb shell am force-stop com.zodiann.app`, then `adb shell am start -a android.intent.action.VIEW -d "zodiann://square" com.zodiann.app` → Square title;
  - repeat with `zodiann:///square`;
  - with the app open on Settings, send `zodiann://about` → About (warm, `singleTop`);
  - with the app open on Settings and the drawer open, send `zodiann://about` → About is shown and the drawer closes (P4);
  - `zodiann://nope` and `zodiann://nope/square` → Wheel;
  - a drawer tap navigates and closes.

  Record each outcome; screenshots stay out of the repo.
- [ ] **Step 5: Whole-repo verification** (record real results): `fvm dart run melos run lint` and `fvm dart run melos run test` from the root, both exit 0; `fvm flutter build apk --debug` from `apps/astro_mobile`.
- [ ] **Step 6: Mutation proofs** (each caught by a named test): item tap does not close; closes but does not navigate; navigates on the active item; navigates twice on a second `onTap` after the pop (`isActive` guard removed); drawer selection captured at open (caught by the mid-close assertion of the P4 regression); the P4 listener removed (warm link leaves the drawer open); the P4 listener without the `isActive` guard (a link arriving while the drawer is already closing pops the shell page; caught by the two leaving-route guard cases of the P4 regression); the P4 listener on `activeRouteProvider` (same-screen and malformed links fail to close); the P4 listener on `router.routeInformationProvider` (`refresh()` and `refreshListenable` close the drawer); `warmLinkProvider` created lazily at drawer open instead of by `ZodiannApp` (every warm link is missed: registration order); the observer returning true (go_router never sees the link); scheme redirect removed (host form → wheel, and `zodiann://nope/square` → Square); shared page key across routes; the `routerDelegate.addListener` subscription removed from `ActiveRoute.build` (production code, not the test's `ref.listen`); manifest scheme removed.
- [ ] **Step 7: Code review** (`requesting-code-review`), fix Important findings test-first.
- [ ] **Step 8: Docs.** Task file: tick criterion 3 only. Leave criteria 1 and 2 unticked and add a Notes entry: "NAV-003 verified the drawer and deep-link parts of criterion 1 and the leave-screen seam for criterion 2; the relaunch clause closes in ZOD-DAT-007 (P3), the real playback proof in ZOD-WHL-017 (P1)." State in `PROGRESS.md` what stays open (relaunch, real playback, iOS link verification). Mark the NAV-002 deferred minor "highlighted item captured at open" and the NAV-001 minor on the silent wheel fallback as fixed. Add a **From ZOD-NAV-003** note to ZOD-WHL-017 (stop playback by `ref.listen(activeRouteProvider, …)` in the app layer and call the feature's stop method; the fake-consumer test is `test/navigation/screen_switch_test.dart`), to ZOD-DAT-007 (inject the saved screen with `buildAppRouter(initialLocation:)` via `appRouterProvider`; a cold-start platform link overrides it) and to ZOD-TST-014 (T-UI-1 lives in `apps/astro_mobile/test/navigation/t_ui_1_test.dart`; the relaunch case is DAT-007's). Do not rewrite acceptance criteria text. Update `TASKS.md` status and `PROGRESS.md` (completed row, current task, next task NAV-004, git state). In `PROGRESS.md` → Architecture Conventions: replace the drawer bullet "Item taps are inert until ZOD-NAV-003…" with "Item taps pop the drawer, then `go(route.path)` unless the item is active; taps after the drawer starts closing are ignored"; add Navigation bullets: deep links use the `zodiann://` scheme and the top-level redirect canonicalises them to `/name`; `activeRouteProvider` and the shell both resolve the current screen from the matched leaf with `AppRoute.fromPath`, and `activeRouteProvider` is the source for anything outside the shell (drawer mark, leave-screen consumers; feature packages never import it); the cold-start link (`defaultRouteName`) overrides an injected `initialLocation`; the open drawer closes itself on any incoming platform link (`warmLinkProvider`, registered by `ZodiannApp` before the router mounts; P4), never on a refresh, theme or locale change.
- [ ] **Step 9: Commit and push** (`docs`/`feat` commits as above), `git push -u origin task/ZOD-NAV-003-drawer-navigation`, open the PR into `main`, record the PR link in a follow-up commit.

## Acceptance mapping

| Criterion | Where proven |
|---|---|
| 1. T-UI-1: drawer navigation, deep link (relaunch clause: DAT-007) | Tasks 2 and 4 (`t_ui_1_test.dart`, emulator) |
| 2. Navigating away stops playback | Task 3 with a fake consumer; real timer in WHL-017 |
| 3. Every screen switch resets scroll | Task 3 |

## Risks and open items

- The delegate configuration is empty before the first frame; the provider seeds from `routeInformationProvider.value`, which already holds the platform deep link (Task 1 test).
- P4: `WarmLinkEvents` depends on Flutter notifying observers in registration order (documented on `WidgetsBindingObserver.didPushRouteInformation` and `WidgetsBinding.handlePushRoute`: observers are notified in registration order until one returns true) and on go_router's provider consuming the event; the regression tests fail if either changes. The pop runs outside build for warm links (verified in review).
- Deferred minor for the drawer owner: `_ZodiannDrawerRoute._dragEnd` pops without checking `isActive`; a P4 pop in the middle of a swipe (realistically only a warm platform link arriving mid-swipe) followed by the release would pop the shell page. No NAV-003 change.
- iOS URL-scheme behaviour cannot be verified on this machine (outstanding, as for earlier iOS items).
- Android Back from a non-wheel screen still exits the app (FND-014's `go` decision); not changed here.
- NAV-004 owns focus, announcements and the hamburger's expanded state.

## Plan review

### Round 1: Approve after corrections (3 Critical, 8 Important, 8 Minor)

The reviewer checked go_router 18.1.4 behaviour in a scratch harness (results in Decisions). All applied:

- **C1** (a malformed host-form link such as `zodiann://nope/square` would open Square; the redirect was conditional): applied; the redirect canonicalises every scheme URI.
- **C2** (`fromUri` rejected the commonest real link `zodiann://square`, seen as `zodiann://square/`): applied; the rule and the test cases are spelled out.
- **C3** (the active-route fallback read a source that is unavailable and wrong on a real cold start): applied; seed from `routeInformationProvider.value`, resolve from the matched leaf, add `AppRoute.fromPath` shared with the shell.
- **I1** (cold-start tests bypassed `defaultRouteName`): applied. **I2** (the rapid-tap pointer test could not catch its mutant): applied, the callback is invoked directly. **I3** (scheme URIs lingering in router state): applied. **I4** (the seam told a feature package to import the app layer): applied, the app layer listens and calls a stop method. **I5** (warm links only simulated with `go`): applied, `handlePushRoute`. **I6** (scroll mutant had no target): applied, a shared page-key mutant. **I7** (Step 8 would tick partly open criteria): applied, criterion 3 only. **I8** (emulator check under-specified, no release run): applied.
- **M1–M6, M8:** applied. **M7** (warm link while the drawer is open): kept as designed and listed as an optional product-owner question in Decisions (superseded by P4, 2026-11-17).

Open items: one optional product-owner question (M7, Decisions); the plan proceeds as designed if unanswered. (Superseded by P4, 2026-11-17.)

### Round 2: Approve after corrections (0 Critical, 2 Important, 9 Minor)

All round-1 corrections verified present and correct against go_router 18.1.4 and Riverpod 3.5.0; existing router tests and the redirect do not loop. All applied:

- **I1** (the cold-start seed read the raw URI while the redirect read go_router's normalised one, so an opaque link such as `zodiann:square` reached a screen and tripped a Riverpod "modified during build" assertion): applied; scheme URIs must have an authority, the `fromUri(raw) ?? wheel == settled screen` invariant is stated, `zodiann:square` and `zodiann:/square` are negatives.
- **I2** (the seed check ran on one input and could not catch I1): applied; it runs over the whole positive and malformed corpus with a watching app.
- **M1–M9:** applied (nullable shell path, observable for the active-item double tap, mutant target, hand-off notes for WHL-017 / DAT-007 / TST-014, "single source" wording, disposal wording, open-items wording, `MSYS_NO_PATHCONV`, RED expectation).

Open items: the same optional question (M7). Two rounds are done, so no further review is scheduled. (Superseded by P4, 2026-11-17.)

### Revision P4 (warm deep link closes the drawer), review cycle 2, round 1: needs user decision (0 Critical, 2 Important, 4 Minor)

Triggered by the product owner's P4 decision. The reviewer spiked the listener approach on Flutter 3.50.0, go_router 18.1.4 and flutter_riverpod 3.5.0; the pop runs outside build, the guard works, theme and locale rebuilds keep the drawer open. All applied:

- **I1** (the "captured at open" mutant was no longer caught, because the drawer is gone before it can show a stale mark): applied; a mid-close `pump()` assertion on the drawer's `selected` flags.
- **I2** (the unguarded-listener mutant fails as a second delegate notification and a rebuilt shell, not as an exception, and the active-item tap never reaches it): applied; the tap variant taps a non-active item with a notification counter.
- **M1** (the same-screen limit was wider: a malformed link on the wheel also gave no reaction) and **Q1** (needs user decision): the product owner chose option B, so the panel closes on any route-information change and the limit disappears. The consequences (a programmatic `go` to the current screen closes the drawer; a future `refresh()` would too) are recorded in Decisions and Risks.
- **M2** (RED expectation), **M3** (stale text in Interfaces, File Structure and conventions; `fireImmediately` stays false): applied. **M4** (`_dragEnd` pops without an `isActive` check): recorded as a deferred minor for the drawer owner.

Open items: none. The revision touched one decision and its tests; the reviewer's corrections were mechanical, so no further round is scheduled.

### Revision P4 follow-up (refreshes must not close the drawer): replaces option B of the previous revision

The product owner asked that every warm platform link close the drawer but that an internal `GoRouter.refresh()` or `refreshListenable` notification, and theme and locale changes, must not, without timing workarounds. Option B (listening to `routeInformationProvider`) cannot do that, so the plan uses `WarmLinkEvents` (Decisions, P4). The previous revision's Q1 text and its "Open items: none" are superseded.

#### Review cycle 3, round 1: Approve after corrections (0 Critical, 2 Important, 3 Minor)

The reviewer implemented Tasks 1 and 2 as specified in a scratch clone (Flutter 3.50.0, go_router 18.1.4, flutter_riverpod 3.5.0): 35 spike tests pass. Verified: the observer sees valid, same-screen and malformed warm links (legacy `pushRoute` too) and go_router still navigates; the observer registers before go_router's even with a pre-built router override; `refresh()`, `refreshListenable`, theme and locale changes never notify it; a tap does not double-pop; the pop runs outside build and before go_router navigates; cold start does not notify it; no engine path bypasses `didPushRouteInformation`; the lazy-at-open mutant is caught. All applied:

- **I1** (the unguarded-listener mutant is no longer caught: a tap never reaches the warm-link listener): applied; two leaving-route guard cases (a link while the drawer is closing; two back-to-back links) replace the tap-based argument.
- **I2** (the Task 2 RED expectation was wrong: `refreshListenable` was used before it exists, and the mark assertions fail at RED): applied; the seam moved into Task 1 and the expected failures are spelled out.
- **M1** (stale "programmatic `go`" wording), **M2** (guard spelled two ways), **M3** (non-public method named in a doc reference): applied.

Open items: none. Two rounds of the original cycle plus this revision are done.
