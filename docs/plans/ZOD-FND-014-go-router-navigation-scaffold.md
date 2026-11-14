# ZOD-FND-014 `go_router` Navigation Scaffold Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The app routes between five blank screen stubs (`#wheel` (the default), `#square`, `#saved`, `#settings`, `#about`) through `go_router`. Any unrecognized route lands on the wheel.

**Architecture:**
- **Route identifiers.** An `AppRoute` enum in `apps/astro_mobile/lib/src/navigation/` lists the five screens in the spec's table order. The spec's `#wheel` identifier is the value's `name`. Its `go_router` location is `path` = `'/' + name`, because `go_router` locations must start with `/`.
  - The hash values are identifiers only (NAV-5). No URL strategy or web address is configured, and a test checks the values and their order against the spec's table.
- **One router per app.** `buildAppRouter({String? initialLocation})` builds a `GoRouter` with one `GoRoute` per `AppRoute`. Each route builds `ScreenStub(route: r)`.
  - The router lives in a Riverpod `Provider<GoRouter>` (`appRouterProvider`, disposed with its container). Rebuilding `ZodiannApp` (today on a theme-mode change; later on a locale setting) therefore never recreates it or resets the route.
  - Later tasks override the provider: DAT-007 restores the last route as `initialLocation`, and tests use it for cold-start deep links.
- **Unknown routes.** A top-level `redirect` returns `AppRoute.wheel.path` when no route matched (`state.topRoute == null`) and `null` otherwise. `go_router` 18 applies the top-level redirect to unmatched locations too (`RouteConfiguration.redirect`, configuration.dart:380), so there is no error page and no loop.
- **Stubs.** `ScreenStub` replaces today's `ShellHome`. It is a blank `Scaffold` that carries its `AppRoute`. `ZodiannApp` switches from `MaterialApp(home:)` to `MaterialApp.router(routerConfig:)` and keeps its theme, localization and `builder` unchanged.

**Tech Stack:**
- Flutter 3.50.0 / Dart 3.14.0 (FVM), with `flutter_test` in `apps/astro_mobile`.
- **New dependency:** `go_router ^18.1.4`, the latest release (2026-11-09).
  - Its SDK floor is `sdk ^3.12.0, flutter >=3.44.0`.
  - It depends on `material_ui ^1.0.0`, which the app already uses, and on `cupertino_ui ^1.0.0` (already in the lock).
  - A `pub add --dry-run` on this branch resolved it, adding only `go_router` and `flutter_web_plugins` (SDK), with no conflict against Flutter's exact pins.
  - It is not a network package (`no_network_test.dart`).
  - ABT-007's licenses list already names go_router.

**Spec:** `assets/zodiann-specification.md`: NAV-5, the Navigation table (lines 86–96), and ARCH-3 (Riverpod). Task: `docs/development/foundations-architecture/ZOD-FND-014-set-up-go-router-navigation-scaffold.md`.

## Facts established while planning (2026-11-14)

- **Today's app has no navigation.**
  - `apps/astro_mobile/lib/src/app.dart` builds `MaterialApp(home: const ShellHome())`. `ShellHome` is a blank `Scaffold`.
  - Tests in `app_shell_test.dart`, `l10n_test.dart` and `theme_switch_test.dart` find the screen with `find.byType(ShellHome)`. That is 23 of the 26 app tests (the other 3 are in `test/di/ephemeris_providers_test.dart`).
- **Downstream tasks:**
  - NAV-003 wires drawer taps to these routes. It owns scroll-to-top and playback stop (NAV-4), and the cold-start platform deep link (T-UI-1).
  - DAT-007 restores the last route on relaunch.
  - NAV-001 / NAV-002 show the active screen's title and the drawer items.
- **`go_router` 18.1.4 details:**
  - `GoRoute.caseSensitive` defaults to `true`, so `/Square` is unknown.
  - `RouteConfiguration.normalizeUri` strips a trailing slash, so `/square/` is `/square`.

## Global Constraints

- **Route identifiers:** `#wheel`, `#square`, `#saved`, `#settings`, `#about`, in that order, with `#wheel` the default. They are identifiers only, never web addresses, and no URL strategy is configured (NAV-5).
- **No navigation logic beyond routing.** There is no drawer, no top bar, no transitions and no persistence. Stubs show no text, so the `no_text_literals` guard holds.
- **Dependencies:** use the latest compatible stable release (PROGRESS dependency policy). The delegates follow the L10-001 convention (unchanged).
- **Git hygiene:**
  - Never stage `.fvmrc`.
  - Never run `git checkout .`, `git restore .` or `git stash`. Restore mutations by explicit path.
  - Stage the root `pubspec.lock` (`pub get` changes it).
- **Commands:**
  - First: `export PATH="$PATH:$LOCALAPPDATA/Pub/Cache/bin"`.
  - App tests: `cmd //c "cd apps\\astro_mobile && fvm flutter test"`.
  - Gates: `cmd //c "fvm dart run melos run lint && fvm dart run melos run test"`.

## Out of scope

- The top bar, the drawer and its taps (NAV-001..003), and the screen titles.
- Scroll-to-top and stopping playback (NAV-4), platform deep-link configuration and T-UI-1 (NAV-003), and last-route persistence (DAT-007).
- Real screens (the `feature_*` packages) and page transitions.

## Review Focus

1. **A theme or locale change mid-session** must leave the user on the screen they were on. Creating the router inside `build` would silently reset it to the wheel. Task 1, test `route survives theme and locale changes`.
2. **Odd locations** (`/`, `/nope`, `/wheel/extra`, the wrong-case `/Square`) must land on the wheel, never on `go_router`'s error page or an exception, including as the initial location (a stale route restored by DAT-007). Task 1, tests `unknown routes redirect to the wheel` and `cold start at an unknown route lands on the wheel`.
3. **A known route with a query string or a trailing slash** (`/square?x=1`, `/square/`) must stay on that screen, not bounce to the wheel. Task 1, test `known routes tolerate a query and a trailing slash`.
4. **A cold start at a non-default route** (the deep-link foundation) opens that screen directly, without passing through the wheel. Task 1, test `cold start at a route opens it directly`.
5. **Switching screens replaces the screen rather than stacking it** (NAV-4: one screen at any moment), so back doesn't walk through a history of screens. Task 1, test `go replaces the screen`. NAV-003 may revisit how back behaves. (This test documents `go_router` semantics and guards the flat route table; NAV-003 owns the tap wiring.)

---

### Task 1: Routes, router and screen stubs

**Files:**
- Modify: `apps/astro_mobile/pubspec.yaml` (add `go_router: ^18.1.4`) and the root `pubspec.lock`.
- Create:
  - `apps/astro_mobile/lib/src/navigation/app_route.dart`;
  - `apps/astro_mobile/lib/src/navigation/app_router.dart`;
  - `apps/astro_mobile/lib/src/navigation/screen_stub.dart`.
- Modify: `apps/astro_mobile/lib/src/app.dart` (`MaterialApp.router`; delete `ShellHome`).
- Test:
  - create `apps/astro_mobile/test/navigation/app_router_test.dart`;
  - modify `apps/astro_mobile/test/app_shell_test.dart`, `test/l10n_test.dart` and `test/theme_switch_test.dart` (`ShellHome` → `ScreenStub`).
  - In `l10n_test.dart` 'the window title is the localized app title', replace `expect(_app(tester).title, '')` with `expect(_app(tester).title, isNull)`: material_ui 1.11.0's `MaterialApp.router` has no `''` default (`app.dart:256, 367`), and the title comes only from `onGenerateTitle`.

**Interfaces:**
- Produces:
  - `enum AppRoute { wheel, square, saved, settings, about; String get path; }`. `path` is `'/$name'`. The doc comment says `#<name>` is the spec identifier and `path` is the `go_router` location. It also says: **app-level placeholder, not a public contract.** Feature packages must never import the app layer; the first task that needs a route from a feature package (e.g. ZOD-DAT-005, or NAV-001/002 if built in `shared_ui`) decides where the feature-accessible route contract lives.
  - `GoRouter buildAppRouter({String? initialLocation})`. The default is `AppRoute.wheel.path`.
  - `final appRouterProvider = Provider<GoRouter>(...)`. It calls `buildAppRouter()` and `ref.onDispose(router.dispose)`.
  - `class ScreenStub extends StatelessWidget { const ScreenStub({super.key, required this.route}); final AppRoute route; }`. It builds `const Scaffold()`. Its doc carries over `ShellHome`'s rule: it must not read `ephemerisPortProvider`.

- [ ] **Step 1: Add the dependency.** Run `cmd //c "cd apps\\astro_mobile && fvm flutter pub add go_router:^18.1.4"`. Expected: `+ go_router 18.1.4` (and `+ flutter_web_plugins` from the SDK).

- [ ] **Step 2: Write the failing tests** in `test/navigation/app_router_test.dart`.
  - Pump `ProviderScope(child: ZodiannApp())` (or with `overrides`) and `pumpAndSettle`.
  - Read the router with `ProviderScope.containerOf(tester.element(find.byType(ScreenStub))).read(appRouterProvider)`, passing `listen: false` to `containerOf` as the existing tests do.
  - `stubRoute()` = `tester.widget<ScreenStub>(find.byType(ScreenStub)).route`, after asserting `findsOneWidget`.

  ```dart
  test('route identifiers match the spec table', () {
    expect(AppRoute.values.map((r) => '#${r.name}'),
        ['#wheel', '#square', '#saved', '#settings', '#about']);
    expect(AppRoute.values.map((r) => r.path),
        ['/wheel', '/square', '/saved', '/settings', '/about']);
  });
  // testWidgets:
  // 'boots to the wheel': stubRoute() == AppRoute.wheel; find.byType(Text) findsNothing.
  // 'every route resolves to its blank stub': for each r in AppRoute.values:
  //     router.go(r.path); pumpAndSettle; stubRoute() == r; Text findsNothing.
  // 'unknown routes redirect to the wheel': start at /square, then for each of
  //     ['/nope', '/', '/wheel/extra', '/Square']: router.go(loc);
  //     pumpAndSettle; stubRoute() == AppRoute.wheel;
  //     router.state.uri.path == '/wheel'; tester.takeException() isNull.
  //     Go back to /square between cases, so each one proves a redirect.
  // 'known routes tolerate a query and a trailing slash': '/square?x=1' and
  //     '/square/' → stubRoute() == AppRoute.square.
  // 'cold start at a route opens it directly': override appRouterProvider with
  //     (ref) => buildAppRouter(initialLocation: '/square') (dispose via
  //     ref.onDispose); after the first pump, find.byType(ScreenStub)
  //     findsOneWidget and stubRoute() == AppRoute.square (NAV-5: a deep link
  //     to the square opens it directly).
  // 'cold start at an unknown route lands on the wheel': override with
  //     buildAppRouter(initialLocation: '/nope'); after pumpAndSettle
  //     stubRoute() == AppRoute.wheel, router.state.uri.path == '/wheel',
  //     takeException() isNull.
  // 'route survives theme and locale changes': navigate with
  //     GoRouter.of(tester.element(find.byType(ScreenStub))).go('/saved')
  //     (the router on screen, so mutation (b) fails by the rebuild resetting
  //     the route); pumpAndSettle;
  //     container.read(themeModeProvider.notifier).set(ThemeMode.dark)
  //     (this rebuilds ZodiannApp; device brightness/locale alone do not);
  //     pumpAndSettle; then flip platformBrightnessTestValue and
  //     localesTestValue (en → he); pumpAndSettle; stubRoute() ==
  //     AppRoute.saved, and tester.widget<MaterialApp>(find.byType(MaterialApp))
  //     .routerConfig is same(container.read(appRouterProvider)).
  //     Clear the test values in addTearDown.
  // 'go replaces the screen': go('/square') then go('/about');
  //     router.canPop() isFalse; one ScreenStub in the tree.
  ```

  Also switch the three existing test files to `ScreenStub`. In `app_shell_test`, `boots with no overrides to a blank themed screen` additionally asserts `route == AppRoute.wheel`.

- [ ] **Step 3: Run the tests and watch them fail.** Run the app tests. Expected: four of the five app test files fail to load: `test/navigation/app_router_test.dart` on the missing `lib/src/navigation/` imports, and the three edited files on `ScreenStub` / `AppRoute` undefined. `test/di/ephemeris_providers_test.dart` (3 tests) still passes.

- [ ] **Step 4: Implement** `app_route.dart`, `screen_stub.dart` and `app_router.dart` per the Interfaces block.
  - Use one `GoRoute(path: r.path, builder: (_, _) => ScreenStub(route: r))` per value.
  - The top-level `redirect: (_, state) => state.topRoute == null ? AppRoute.wheel.path : null`.
  - In `app.dart`, use `MaterialApp.router(routerConfig: ref.watch(appRouterProvider), …)` and keep every other argument as is. Do not pass `title:`. Update the class doc, which today points at FND-014.

- [ ] **Step 5: Run the app tests.** Expected: all pass (26 existing, one assertion updated, + 9 new).

- [ ] **Step 6: Mutation proofs.** Revert each mutation by explicit path, then record each result in the Step 7 commit body.
  - (a) Remove the `redirect`. Expected: `unknown routes redirect to the wheel` fails.
  - (b) Build the router inside `ZodiannApp.build` instead of the provider. Expected: `route survives theme and locale changes` fails.
  - (c) Swap two enum values. Expected: `route identifiers match the spec table` fails.

- [ ] **Step 7: Commit.**
  ```bash
  git add apps/astro_mobile/pubspec.yaml pubspec.lock apps/astro_mobile/lib apps/astro_mobile/test
  git commit -m "feat(ZOD-FND-014): go_router scaffold with five route stubs and wheel fallback" \
    -m "Mutants: redirect removed, router built in build(), two enum values swapped; each caught by its named test." \
    -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01324yHX893k8iR98bp7889Q"
  ```

### Task 2: Review and close-out

**Files:**
- Modify:
  - the FND-014 task file (Status Done, both criteria checked, a Note on the `#name` ↔ `/name` mapping);
  - `docs/development/TASKS.md` (the row);
  - `docs/PROGRESS.md` (the row, verification, git state, and the Technical Decisions below);
  - hand-off Notes in these task files:
    - **NAV-003:** replace `ScreenStub` with the real screens in `buildAppRouter`, and navigate with `context.go(route.path)`. The cold-start platform deep link is still NAV-003's: Flutter's deep linking is on by default, and the Android/iOS link configuration plus T-UI-1 belong there. Back behaviour is currently "replace, not stack". `AppRoute` is an app-level placeholder, not a public contract: feature packages must never import the app layer.
    - **DAT-007:** restore the last route by overriding `appRouterProvider` with `buildAppRouter(initialLocation: saved.path)`. Recommended storage: `AppRoute.name`, never a path or a translated title (the format is DAT-007's decision). A platform deep link (non-`/` `defaultRouteName`) takes precedence over the restored `initialLocation` (go_router `_effectiveInitialLocation`).
    - **NAV-001 / NAV-002:** the active screen comes from the router's location → `AppRoute`. The drawer items iterate `AppRoute.values` (table order). If the bar or drawer is built in `shared_ui`, that task decides where the feature-accessible route contract lives (feature packages and `shared_ui` never import the app layer).
    - **DAT-005:** navigating to the Square screen from a feature package needs a feature-accessible route contract, since `AppRoute` lives in the app layer; this task decides where it lives.
- **Technical Decisions:**
  - the spec's `#name` maps to the `go_router` path `/name`;
  - the router lives in `appRouterProvider` (one instance; overridable);
  - unknown routes go through the top-level redirect on `topRoute == null`;
  - `go_router` 18.1.4 was added under the dependency policy.

- [ ] **Step 1: Run the whole-branch review** (`requesting-code-review`, most capable model) with this plan's Review Focus. Fix Critical and Important findings test-first, and record Minor ones as deferred.
- [ ] **Step 2: Run the full gates:** `cmd //c "fvm dart run melos run lint && fvm dart run melos run test"`. Expected: exit 0.
- [ ] **Step 3: Write the docs** listed above.
- [ ] **Step 4: Commit, push and open the PR** (`docs(ZOD-FND-014): close out the go_router scaffold`, with the session's attribution trailers). Then add the PR link to PROGRESS and push a follow-up commit.

## Open items for approval

None beyond approving the plan.

## Plan review

### Round 1: Approve after corrections (2 Critical, 3 Important, 7 Minor, 0 Needs user decision)

- **C1 (Critical), applied:** `MaterialApp.router` has no `''` title default (material_ui 1.11.0 `app.dart:256, 367`). The existing l10n assertion becomes `isNull`, and Step 4 says not to pass `title:`.
- **C2 (Critical), applied:** device brightness and locale changes don't rebuild `ZodiannApp`, so mutation (b) would have survived. The test now rebuilds the app through `themeModeProvider` and checks that `MaterialApp.routerConfig` is the provider's router.
- **I1 (Important), applied:** added a cold start at an unknown location (`/nope`) → wheel. This is the stale-route case for DAT-007.
- **I2 (Important), applied:** `AppRoute` is documented as an app-level placeholder, not a public contract. Hand-offs go to NAV-001/002/003 and DAT-005.
- **I3 (Important), applied:** Step 3's expected failure is corrected.
- **M1–M7 (Minor), applied:**
  - `listen: false`;
  - the cold start uses `/square` (NAV-5);
  - a scope note on Review Focus 5;
  - DAT-007's deep-link precedence, with storage as a recommendation;
  - `flutter_web_plugins`;
  - `cupertino_ui`;
  - attribution trailers.

### Round 2: Approve (0 Critical, 0 Important, 3 Minor, 0 Needs user decision)

- **M1, applied:** `ephemeris_providers_test.dart` still loads at Step 3.
- **M2, applied:** the 23 / 26 test count is corrected.
- **M3, applied:** the route-survives test navigates through the on-screen router, so mutation (b) fails for the real reason. Mutation results go in the commit body (the project convention), not a ledger.

**Open items:** none.
