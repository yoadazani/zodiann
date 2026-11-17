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
- Open for the product owner (optional): a warm deep link while the drawer is open leaves it open with the active mark moved; the alternative is closing it.

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
3. A **malformed or unknown deep link** (`zodiann://nope`, `zodiann://square/extra`, `zodiann:///Square`, `zodiann://`, `zodiann://nope/square`, `zodiann://wheel/square`, `https://example.com/square`) shows the wheel, never an error page (Task 1).
4. A route change **while the drawer is open** (warm deep link) moves the drawer's active mark; the NAV-002 "captured at open" minor is closed (Task 2).
5. Hebrew (RTL) drawer navigation behaves identically, and a locale change mid-session keeps the route (Task 2).

## File Structure

| File | Responsibility |
|---|---|
| `apps/astro_mobile/lib/src/navigation/app_route.dart` (modify) | add `AppRoute.fromUri(Uri) → AppRoute?`: scheme `zodiann` or none (any other scheme → null); a host form (`zodiann://name`) requires path `''` or `/`; the path form (`/name`, `zodiann:///name`) tolerates one trailing slash and any query; names are case-sensitive, except that Dart lowercases a URI host so `zodiann://Square` resolves (documented). Add `AppRoute.fromPath(String) → AppRoute` (exact path equality, fallback wheel) |
| `apps/astro_mobile/lib/src/navigation/active_route.dart` (create) | `activeRouteProvider`: the router's current screen as an `AppRoute` |
| `apps/astro_mobile/lib/src/navigation/app_router.dart` (modify) | `screenBuilder` parameter (real screens replace `ScreenStub` in their own tasks; NAV-003 keeps it as the default); scheme-canonicalising redirect; the shell builder uses `AppRoute.fromPath` |
| `apps/astro_mobile/lib/src/navigation/app_shell.dart` (modify) | drawer taps close and navigate; drawer panel follows `activeRouteProvider` |
| `apps/astro_mobile/android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist` (modify) | register the `zodiann` scheme |
| `apps/astro_mobile/test/navigation/…` (create/modify) | tests per task |

---

### Task 1: Route parsing, active-route provider, deep-link normalisation

**Files:**
- Modify: `app_route.dart`, `app_router.dart`
- Create: `active_route.dart`
- Test: `apps/astro_mobile/test/navigation/active_route_test.dart` (create); `app_router_test.dart` (extend)

**Interfaces:**
- Produces: `static AppRoute? AppRoute.fromUri(Uri uri)`; `static AppRoute AppRoute.fromPath(String path)`; `final NotifierProvider<ActiveRoute, AppRoute> activeRouteProvider` (state = current screen, initial = the router's initial screen); `GoRouter buildAppRouter({String? initialLocation, Widget Function(AppRoute route)? screenBuilder})`.
- Consumes: `appRouterProvider`, `AppRoute`.

Working directories: `fvm flutter test` / `fvm flutter build` run from `apps/astro_mobile`; `fvm dart run melos …` from the repo root.

- [ ] **Step 1: (settled by plan review, see Decisions).** No spike is needed.
- [ ] **Step 2: Write failing tests** (`active_route_test.dart`, `app_router_test.dart`):
  - `fromUri` positives → the route: `/square`, `/square/`, `/square?x=1`, `zodiann:///square`, `zodiann://square`, `zodiann://square/`, `zodiann://square?x=1`, `zodiann://Square` (lowercased by `Uri`, pinned). Negatives → `null`: `/Square`, `/nope`, `/wheel/extra`, `zodiann://nope`, `zodiann://square/extra`, `zodiann://`, `zodiann://nope/square`, `https://example.com/square`, empty. `fromPath` is exact equality with a wheel fallback.
  - Router, via `initialLocation`: each of the five `zodiann://<name>` and `zodiann:///<name>` forms opens that screen; every malformed form in Review Focus 3 lands on `/wheel`. After every valid deep link, cold and warm, `router.state.uri.toString() == '/<name>'` (no scheme left).
  - Router, via the real platform path: with the default `appRouterProvider` and `tester.platformDispatcher.defaultRouteNameTestValue` set to `zodiann://square` and to `zodiann:///square` (cleared in `addTearDown`) the Square opens; one more case overrides `initialLocation: '/saved'` as DAT-007 will and shows the platform link still wins.
  - Warm: `await tester.binding.handlePushRoute('zodiann://about')` while on Settings opens About.
  - `activeRouteProvider`: equals the initial screen (cold start at `/saved` → `saved`); follows `router.go` for each route; follows a redirect (`go('/nope')` → `wheel`); emits once per switch (a `ProviderContainer` listener records `wheel → square → settings`); a `go` to the current route emits nothing; survives a theme and a locale rebuild without resetting. With `defaultRouteNameTestValue = 'zodiann://square'` and the default router, reading `activeRouteProvider` through an `UncontrolledProviderScope` container before `pumpWidget` gives `square`, it stays `square` after `pumpAndSettle`, and `tester.takeException()` is null.
  - `screenBuilder`: when given, each route shows `screenBuilder(route)`; the default still shows `ScreenStub` (existing test unedited).
- [ ] **Step 3: Run `fvm flutter test test/navigation`.** Expected: `active_route_test.dart` and `app_router_test.dart` fail to compile (`fromUri`, `fromPath`, `activeRouteProvider` undefined; no named parameter `screenBuilder`); `drawer_shell_test.dart` and `top_bar_shell_test.dart` pass.
- [ ] **Step 4: Implement.**
  - `AppRoute.fromUri` and `fromPath` as specified in the File Structure.
  - `buildAppRouter`'s redirect becomes: `if (state.uri.hasScheme) return AppRoute.fromUri(state.uri)?.path ?? AppRoute.wheel.path; return state.topRoute == null ? AppRoute.wheel.path : null;` so every scheme URI is rewritten to a bare `/name`, or to `/wheel`, before matching. The `ShellRoute` builder resolves its route with `AppRoute.fromPath` (closes the NAV-001 deferred minor).
  - `ActiveRoute extends Notifier<AppRoute>`: `build()` does `ref.watch(appRouterProvider)` and derives the screen from the matched leaf, the same source the shell uses: `config.isEmpty ? (AppRoute.fromUri(router.routeInformationProvider.value.uri) ?? AppRoute.wheel) : AppRoute.fromPath(config.last.route.path)`, where `config = router.routerDelegate.currentConfiguration`. It subscribes with `routerDelegate.addListener`, removes the listener in `ref.onDispose`, and assigns `state` only on change.
- [ ] **Step 5: Run the same tests** from `apps/astro_mobile`. Expected: all pass. Run `fvm dart run melos run lint` from the root → exit 0.
- [ ] **Step 6: Commit** `feat(ZOD-NAV-003): route parsing and the active-route provider`.

---

### Task 2: Drawer taps navigate and close; the active mark follows the route

**Files:**
- Modify: `app_shell.dart` (`_openDrawer`)
- Test: `apps/astro_mobile/test/navigation/drawer_navigation_test.dart` (create); `drawer_shell_test.dart` (replace the test `item taps are inert in this task (decision A)`; update the file's header comment and the class doc in `app_shell.dart`)

**Interfaces:**
- Consumes: `activeRouteProvider`, `showZodiannDrawer`, `ZodiannDrawerItem.onTap`, `GoRouter`.
- Produces: tapping an item pops the drawer route and calls `router.go(route.path)` unless it is the active screen; items ignore taps once the drawer route is no longer active (`ModalRoute.of(drawerContext)!.isActive`).

- [ ] **Step 1: Write failing tests** (`drawer_navigation_test.dart`, helpers copied from `drawer_shell_test.dart`'s `_pumpApp` / `_open`):
  - for each of the five screens, from each other screen: open drawer, tap its item, `pumpAndSettle` → location is the route's path, no `ZodiannDrawer` in the tree, the top bar title is that screen's title (en);
  - reopen: the tapped item is the only `selected` node (semantics) and carries the accent style;
  - Review Focus 1: tap the active item → drawer closed, location unchanged, a scrolled test screen (via `screenBuilder`) keeps its offset;
  - Review Focus 2: tap Settings, `pump()`, `pump(50 ms)`, then invoke About's callback directly (`tester.widget<ZodiannDrawer>(find.byType(ZodiannDrawer)).groups[1].items[2].onTap()`, as NAV-002's `onPressed(); onPressed();` test does; a pointer tap is already blocked by the reversing route's `IgnorePointer`) → after `pumpAndSettle` the location is `/settings` and exactly one delegate notification was recorded. Also invoke the active item's `onTap` twice → no navigation, one pop;
  - Review Focus 4: with the drawer open, `router.go('/square')` → the Square item becomes selected without closing the drawer; repeat with `await tester.binding.handlePushRoute('zodiann://square')`;
  - Review Focus 5: the same navigation in Hebrew (RTL), and a locale switch en → he after navigating keeps the route;
  - the hamburger still opens the drawer on every screen at 1440, 800 and 390 widths; Back still closes without navigating (existing tests unchanged).
- [ ] **Step 2: Run** `fvm flutter test test/navigation/drawer_navigation_test.dart test/navigation/drawer_shell_test.dart` from `apps/astro_mobile`. Expected: navigation tests fail with location `/wheel`, expected `/settings`, and `ZodiannDrawer` still found; the old "inert" test is the one being replaced.
- [ ] **Step 3: Implement.** In `_openDrawer`, capture `GoRouter.of(context)` once. Replace the captured `route` with a small `ConsumerWidget` inside the builder that watches `activeRouteProvider` for `selected`. `onTap`: if `ModalRoute.of(drawerContext)?.isActive != true` return; pop the drawer route; then, if the item's route differs from the active one, `router.go(r.path)` (pop first, then `go`; see Decisions).
- [ ] **Step 4: Run** the same tests plus the whole `astro_mobile` suite from `apps/astro_mobile`. Expected: all pass.
- [ ] **Step 5: Commit** `feat(ZOD-NAV-003): drawer items navigate and close the drawer`.

---

### Task 3: Leave-screen seam and scroll reset (criteria 2 and 3)

**Files:**
- Test: `apps/astro_mobile/test/navigation/screen_switch_test.dart` (create); production change only if a test proves one is needed
- Doc: document the seam in `active_route.dart`'s class doc: "Feature packages never import this. To stop work when the user leaves a screen, the app layer listens (`ref.listen(activeRouteProvider, …)`) and calls a stop method the feature exposes (WHL-017 adds that wiring for playback). A screen's own `State` / `autoDispose` providers are also disposed on leave, because each route has its own page."

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
  - `adb shell am force-stop com.zodiann.app`, then `adb shell am start -a android.intent.action.VIEW -d "zodiann://square" com.zodiann.app` → Square title;
  - repeat with `zodiann:///square`;
  - with the app open on Settings, send `zodiann://about` → About (warm, `singleTop`);
  - `zodiann://nope` and `zodiann://nope/square` → Wheel;
  - a drawer tap navigates and closes.

  Record each outcome; screenshots stay out of the repo.
- [ ] **Step 5: Whole-repo verification** (record real results): `fvm dart run melos run lint` and `fvm dart run melos run test` from the root, both exit 0; `fvm flutter build apk --debug` from `apps/astro_mobile`.
- [ ] **Step 6: Mutation proofs** (each caught by a named test): item tap does not close; closes but does not navigate; navigates on the active item; navigates twice on a second `onTap` after the pop (`isActive` guard removed); drawer selection captured at open; scheme redirect removed (host form → wheel, and `zodiann://nope/square` → Square); shared page key across routes; seam subscription removed; manifest scheme removed.
- [ ] **Step 7: Code review** (`requesting-code-review`), fix Important findings test-first.
- [ ] **Step 8: Docs.** Task file: tick criterion 3 only. Leave criteria 1 and 2 unticked and add a Notes entry: "NAV-003 verified the drawer and deep-link parts of criterion 1 and the leave-screen seam for criterion 2; the relaunch clause closes in ZOD-DAT-007 (P3), the real playback proof in ZOD-WHL-017 (P1)." State in `PROGRESS.md` what stays open (relaunch, real playback, iOS link verification). Mark the NAV-002 deferred minor "highlighted item captured at open" and the NAV-001 minor on the silent wheel fallback as fixed. Do not rewrite acceptance criteria text. Update `TASKS.md` status and `PROGRESS.md` (completed row, current task, next task NAV-004, git state). In `PROGRESS.md` → Architecture Conventions: replace the drawer bullet "Item taps are inert until ZOD-NAV-003…" with "Item taps pop the drawer, then `go(route.path)` unless the item is active; taps after the drawer starts closing are ignored"; add Navigation bullets: deep links use the `zodiann://` scheme and the top-level redirect canonicalises them to `/name`; `activeRouteProvider` is the single source of the current screen (feature packages never import it); the cold-start link (`defaultRouteName`) overrides an injected `initialLocation`.
- [ ] **Step 9: Commit and push** (`docs`/`feat` commits as above), `git push -u origin task/ZOD-NAV-003-drawer-navigation`, open the PR into `main`, record the PR link in a follow-up commit.

## Acceptance mapping

| Criterion | Where proven |
|---|---|
| 1. T-UI-1: drawer navigation, deep link (relaunch clause: DAT-007) | Tasks 2 and 4 (`t_ui_1_test.dart`, emulator) |
| 2. Navigating away stops playback | Task 3 with a fake consumer; real timer in WHL-017 |
| 3. Every screen switch resets scroll | Task 3 |

## Risks and open items

- The delegate configuration is empty before the first frame; the provider seeds from `routeInformationProvider.value`, which already holds the platform deep link (Task 1 test).
- A warm deep link while the drawer is open leaves it open with the mark moved (optional product-owner question in Decisions).
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
- **M1–M6, M8:** applied. **M7** (warm link while the drawer is open): kept as designed and listed as an optional product-owner question in Decisions.

Open items: none needing a decision.
