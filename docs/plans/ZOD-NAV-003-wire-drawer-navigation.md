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
3. A **malformed or unknown deep link** (`zodiann://nope`, `zodiann://square/extra`, `zodiann:///Square`, `zodiann://`) shows the wheel, never an error page (Task 1).
4. A route change **while the drawer is open** (warm deep link) moves the drawer's active mark; the NAV-002 "captured at open" minor is closed (Task 2).
5. Hebrew (RTL) drawer navigation behaves identically, and a locale change mid-session keeps the route (Task 2).

## File Structure

| File | Responsibility |
|---|---|
| `apps/astro_mobile/lib/src/navigation/app_route.dart` (modify) | add `AppRoute.fromUri(Uri) → AppRoute?` (path or `zodiann://name` host form; tolerant of trailing slash and query) |
| `apps/astro_mobile/lib/src/navigation/active_route.dart` (create) | `activeRouteProvider`: the router's current screen as an `AppRoute` |
| `apps/astro_mobile/lib/src/navigation/app_router.dart` (modify) | `screenBuilder` parameter; redirect rewrites the deep-link host form |
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
- Produces: `static AppRoute? AppRoute.fromUri(Uri uri)`; `final NotifierProvider<ActiveRoute, AppRoute> activeRouteProvider` (state = current screen, initial = the router's initial screen); `GoRouter buildAppRouter({String? initialLocation, Widget Function(AppRoute route)? screenBuilder})`.
- Consumes: `appRouterProvider`, `AppRoute`.

- [ ] **Step 1: Spike (no commit).** In a scratch test, build `buildAppRouter(initialLocation: 'zodiann://square')` and `'zodiann:///square'`, pump a `MaterialApp.router`, and print `router.state.uri` and `router.state.topRoute?.path` for both, for `zodiann://square/extra`, and for `/square/?x=1`. Record the findings in the plan's Decisions section. They decide the exact redirect rule below; the host form is only added if go_router does not already resolve it.
- [ ] **Step 2: Write failing tests** (`active_route_test.dart`, `app_router_test.dart`):
  - `fromUri`: `/square`, `/square/`, `/square?x=1`, `zodiann:///square`, `zodiann://square` → `AppRoute.square`; `/Square`, `/nope`, `/wheel/extra`, `zodiann://nope`, `zodiann://square/extra`, `zodiann://`, empty → `null`.
  - Router: `initialLocation` of each of the five `zodiann://<name>` and `zodiann:///<name>` forms opens that screen; every malformed form in Review Focus 3 lands on `/wheel`.
  - `activeRouteProvider`: equals the initial screen (cold start at `/saved` → `saved`); follows `router.go` for each route; follows a redirect (`go('/nope')` → `wheel`); emits once per switch (a `ProviderContainer` listener records the sequence `wheel → square → settings`); a `go` to the current route emits nothing; survives a theme and a locale rebuild without resetting.
  - `screenBuilder`: when given, each route shows `screenBuilder(route)`; default still shows `ScreenStub` (existing test unedited).
- [ ] **Step 3: Run `fvm flutter test test/navigation` in `apps/astro_mobile`.** Expected: the new tests fail (undefined symbols / wrong location), existing ones pass.
- [ ] **Step 4: Implement** `AppRoute.fromUri`; `ActiveRoute extends Notifier<AppRoute>` whose `build()` reads `appRouterProvider`, derives the screen from the delegate's current configuration with `fromUri` (falling back to the wheel), subscribes with `router.routerDelegate.addListener` and removes it in `ref.onDispose`, updating `state` only when the screen changes; `buildAppRouter` gains `screenBuilder` and its redirect maps a deep-link host form to `route.path` using `fromUri` (only if Step 1 shows it is needed). If the delegate configuration is not available at `build()`, resolve the initial screen from `initialLocation` instead, so the first value is correct before the first frame.
- [ ] **Step 5: Run the same tests.** Expected: all pass. Run `fvm dart run melos run lint` → exit 0.
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
  - Review Focus 2: tap Settings then About 50 ms later → location `/settings`, exactly one location change recorded;
  - Review Focus 4: with the drawer open, `router.go('/square')` → the Square item becomes selected without closing the drawer;
  - Review Focus 5: the same navigation in Hebrew (RTL), and a locale switch en → he after navigating keeps the route;
  - the hamburger still opens the drawer on every screen at 1440, 800 and 390 widths; Back still closes without navigating (existing tests unchanged).
- [ ] **Step 2: Run** `fvm flutter test test/navigation/drawer_navigation_test.dart test/navigation/drawer_shell_test.dart`. Expected: navigation tests fail; the old "inert" test is the one being replaced.
- [ ] **Step 3: Implement.** In `_openDrawer`, capture `GoRouter.of(context)` once. Replace the captured `route` with a small `ConsumerWidget` inside the builder that watches `activeRouteProvider` for `selected`. `onTap`: if `ModalRoute.of(drawerContext)?.isActive != true` return; pop the drawer route; if the item's route differs from the active one, `router.go(r.path)`. Order (pop first or go first) is decided by a short experiment confirming the overlay on the root navigator is not removed by `go`; record the result in Decisions.
- [ ] **Step 4: Run** the same tests plus the whole `astro_mobile` suite. Expected: all pass.
- [ ] **Step 5: Commit** `feat(ZOD-NAV-003): drawer items navigate and close the drawer`.

---

### Task 3: Leave-screen seam and scroll reset (criteria 2 and 3)

**Files:**
- Test: `apps/astro_mobile/test/navigation/screen_switch_test.dart` (create); production change only if a test proves one is needed
- Doc: document the seam in `active_route.dart`'s class doc ("a screen that must stop on leaving subscribes with `ref.listen(activeRouteProvider, …)`")

**Interfaces:**
- Consumes: `activeRouteProvider`, `buildAppRouter(screenBuilder:)`.
- Produces: the contract WHL-017 uses (no code beyond Task 1).

- [ ] **Step 1: Write the tests.**
  - *Scroll reset:* a test screen per route is a long `ListView`; scroll Wheel, Square and Settings by 800, switch away by drawer and by `router.go`, and return → each starts at offset 0; the switch from a scrolled Settings to Wheel shows the Wheel at 0. Also at phone width, where the body inherits the bar's top padding.
  - *Playback seam (fake):* an app-level fake `PlaybackController` provider that ticks every 110 ms (fake time) while "playing" and stops when `activeRouteProvider` leaves `wheel` (the exact subscription WHL-017 will use). Start it, switch to Settings by the drawer after 3 ticks → tick count stops advancing; return to the wheel → still not advancing and not playing. Repeat navigating by `router.go` and by a deep link arriving while it plays.
  - *Mutant proof:* removing the subscription makes the ticks keep advancing (the test fails for the right reason).
- [ ] **Step 2: Run.** Expected: pass without production changes if go_router disposes departed pages. If scroll position survives anywhere (state kept alive), the failing test drives a fix in `app_router.dart` (a distinct page key per route).
- [ ] **Step 3: Commit** `test(ZOD-NAV-003): scroll reset and the leave-screen seam`.

---

### Task 4: OS deep-link registration, T-UI-1, verification and docs

**Files:**
- Modify: `AndroidManifest.xml` (a second `intent-filter` on `MainActivity`: `VIEW`, `DEFAULT`, `BROWSABLE`, `<data android:scheme="zodiann"/>`); `ios/Runner/Info.plist` (`CFBundleURLTypes` with scheme `zodiann`)
- Create: `apps/astro_mobile/test/navigation/t_ui_1_test.dart`, `apps/astro_mobile/test/platform_links_test.dart`
- Modify: task file status, `docs/development/TASKS.md`, `docs/PROGRESS.md`

**Interfaces:** none new.

- [ ] **Step 1: Write failing tests.**
  - `platform_links_test.dart` (reads the files from disk): the manifest has exactly one `BROWSABLE` filter with scheme `zodiann` and no `INTERNET` permission; the plist declares the `zodiann` URL scheme; `FlutterDeepLinkingEnabled` is not set to false.
  - `t_ui_1_test.dart`, a group named `T-UI-1`: (a) drawer navigation reaches each screen (one test per screen); (b) a deep link opens `square` directly on cold start (`initialLocation: 'zodiann:///square'`, and `zodiann://square` if Task 1 supports it); (c) the relaunch clause: a router started at an injected location (the DAT-007 seam) opens that screen; its comment states the full restore is ZOD-DAT-007's (P3).
- [ ] **Step 2: Run** `fvm flutter test`. Expected: platform tests fail, T-UI-1 passes.
- [ ] **Step 3: Edit the manifest and plist.** Re-run: all pass.
- [ ] **Step 4: Emulator check** (emulator-5554, debug APK per the PROGRESS conventions): `adb shell am start -a android.intent.action.VIEW -d "zodiann:///square" com.zodiann.app` from a cold start shows the Square title; repeat while the app is open on Settings (warm); `zodiann://nope` shows the wheel; tapping a drawer item navigates and closes. Record the outcome; screenshots stay out of the repo. If `zodiann://square` (host form) does not reach `square`, the redirect from Task 1 must be proven on the device too.
- [ ] **Step 5: Whole-repo verification** (record real results): `fvm dart run melos run lint` exit 0; `fvm dart run melos run test` exit 0; `fvm flutter build apk --debug` in `apps/astro_mobile`.
- [ ] **Step 6: Mutation proofs** (each caught by a named test): item tap does not close; closes but does not navigate; navigates on the active item; navigates twice on a rapid second tap; drawer selection captured at open; redirect removed (host form → wheel); scroll key shared across routes; seam subscription removed; manifest scheme removed.
- [ ] **Step 7: Code review** (`requesting-code-review`), fix Important findings test-first.
- [ ] **Step 8: Docs.** Task file: tick criteria 1 (drawer + deep link parts), 2 (seam part), 3, and state in `PROGRESS.md` what stays open: the relaunch clause (DAT-007), the real playback proof (WHL-017), and iOS link verification (Mac). Update the NAV-002 deferred minor "highlighted item captured at open" as fixed. Do not rewrite acceptance criteria text. Update `TASKS.md` status and `PROGRESS.md` (completed row, current task, next task NAV-004, git state).
- [ ] **Step 9: Commit and push** (`docs`/`feat` commits as above), `git push -u origin task/ZOD-NAV-003-drawer-navigation`, open the PR into `main`, record the PR link in a follow-up commit.

## Acceptance mapping

| Criterion | Where proven |
|---|---|
| 1. T-UI-1: drawer navigation, deep link (relaunch clause: DAT-007) | Tasks 2 and 4 (`t_ui_1_test.dart`, emulator) |
| 2. Navigating away stops playback | Task 3 with a fake consumer; real timer in WHL-017 |
| 3. Every screen switch resets scroll | Task 3 |

## Risks and open items

- go_router's handling of `zodiann://square` (host form) is unknown until the Task 1 spike; the redirect rule depends on it.
- The delegate's configuration may not be available when the provider first builds; Task 1 has the `initialLocation` fallback.
- Whether `go` while the root-navigator overlay is open leaves the overlay intact is settled by the Task 2 experiment.
- iOS URL-scheme behaviour cannot be verified on this machine (outstanding, as for earlier iOS items).
- Android Back from a non-wheel screen still exits the app (FND-014's `go` decision); not changed here.
- NAV-004 owns focus, announcements and the hamburger's expanded state.

## Plan review

_Pending: the `plan-reviewer` cycle runs after this commit._
