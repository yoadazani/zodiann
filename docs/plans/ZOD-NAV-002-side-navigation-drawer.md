# ZOD-NAV-002 Side Navigation Drawer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The hamburger opens a drawer from the start side: a 76 px header (logo, wordmark, close button), two groups of five screens with the active one marked, and a footer. It closes by backdrop tap, close button, swipe aside or Android back. It is never permanent. Item taps are inert (product-owner decision A); ZOD-NAV-003 wires them.

**Architecture:**
- **`ZodiannDrawer` (`shared_ui`).** A route-independent panel. It takes data (`ZodiannDrawerGroup` / `ZodiannDrawerItem`) and finished strings; it imports no route, no localizations and no version.
- **`showZodiannDrawer` (`shared_ui`).** A custom `PopupRoute` pushed on the root navigator, so it covers the top bar. It owns the 240 / 180 ms motion, the scrim, reduced motion and the swipe-aside gesture. Back, backdrop tap and the close button all pop it.
- **`AppShell` (app).** Enables the hamburger, maps `AppRoute.values` to the two groups, and supplies localized copy, the temporary `1.0.0` version and a no-op item tap.

**Tech Stack:** Flutter 3.50.0 / Dart 3.14.0 (FVM), material_ui 1.11, go_router ^18.1.4, `gen-l10n`, `flutter_test`, headless Chrome for the references. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-11-17-zod-nav-002-drawer-design.md` (approved 2026-11-17, with clarifications). Task: `docs/development/navigation/ZOD-NAV-002-implement-the-side-navigation-drawer.md`. Design: `MASTER.md` §5 "Drawer", §12 "Motion", §13; `DESIGN_DECISIONS.md` D17; `_source/kit.css:149-174`; `_source/kit.js:255-267` and the copy at `:18-23`, `:85-92`; the four `navigation-drawer` PNGs. Spec rows: NAV-2, NAV-3, NAV-7.

## Product-owner decisions (2026-11-17)

- **A.** A drawer item reports a tap; the app passes a no-op. No navigation and no closing on item tap in this task.
- **Mechanism 2.** A custom `PopupRoute`, not `Scaffold.drawer`.
- **Close label.** "Close menu" / "סגירת תפריט": an intentional, documented exception to NAV-001's "`kit.js`-only copy" rule, localized and consistent with `openMenu`.
- **Light references.** Chrome-generated from `kit.css`, labelled as generated visual references, not designer assets; `kit.css` and the design specification stay authoritative and the images never override them.
- **Motion and version.** `easeOutCubic` for open (240 ms) and close (180 ms), instant under reduced motion. Version ownership stays outside `shared_ui`: the drawer receives the finished version line. `1.0.0` is a temporary app-provided value with its fallback documented.

## Facts established while planning (2026-11-17)

- **Geometry (kit.css, border-box):**
  - Panel: width `min(320, 86 % × screen width)` (so 320 from 372.09 up; 309.6 at 360); full height; `surface`; `border-inline-end` 1 px `line`; `box-shadow: var(--shadow-float)`.
  - Header: height 76 including a 1 px `line-soft` bottom rule; padding start 20 (`s5`), end 12 (`s3`), top and bottom 12; gap 12; logo 40, wordmark 20/600 −0.01 em (`ZodiannTextStyles.drawerWordmark` exists), close button 46 × 46 at the end.
  - Nav: padding 12, items 2 apart. Group label: padding 16 / 12 / 8 (top / sides / bottom), the first one 8 on top; 12, `text-3`, weight 400.
  - Item: padding 12, radius 8; a 24 px icon column, 12 gap, icon 1 px down; name 14/500; description 12 `text-2`, weight 400; row gap 2. Active: `accent-soft` fill, 3 px `accent` bar on the start edge (10 px from the top and bottom, radius 3), icon and name in `accent-strong`.
  - Footer: pinned to the bottom; padding 16 / 20, 1 px `line-soft` top rule, 12 `text-3`, two lines 2 apart.
- **Reference measurements (the executor re-checks them in Task 5).** At 390 × 844 @2 the panel is 640 device px wide (320 logical), which agrees with `min(320, 86 %)`. Desktop (1440 × 900 @1): the logo spans x 20–60 and the panel's inner edge is at x ≈ 320.
- **Discrepancy, decided by the reference:** MASTER §5 and the task text say the active icon and name are `text`; `kit.css` draws `accent-strong` (white on dark, black on light). The PNGs are the pixel authority, so Task 5 measures the active-name ink colour and the plan follows the PNG. **Open item for the product owner (see Review record).**
- **`ZodiannPressable` has one semantics node and no `selected` or `hint`** (`zodiann_pressable.dart:95-100`). The selected state needs two additive optional parameters (Task 1); the UI-004 / NAV-001 suites are the regression gate.
- **Existing assertion that must change:** `apps/astro_mobile/test/navigation/top_bar_shell_test.dart:153-162` ("hamburger is disabled and labelled …") asserts `onPressed` is null; Task 4 changes exactly that assertion and its description. Nothing else in that file.
- **Tokens that exist:** `ZodiannSurfaces.scrim / accentSoft / accentStrong / lineSoft / line / text3`, `ZodiannElevation.floating / floatingOutline`, `ZodiannTextStyles.drawerWordmark`, `ZodiannSize.logoDrawer (40) / iconButton (46) / icon (20)`, `ZodiannIcons.wheel / grid / folder / sliders / info / x`.
- **Device sizes of the reference renderer:** desktop 1440 × 900 @1, mobile 390 × 844 @2 (`_source/render/render.js:6`).

## Global Constraints

- Sentence case; no `toUpperCase(`; every user-visible string is localized (ARB), none is a literal in `lib/` (`no_text_literals_test`). Copy comes from `kit.js`, except the close label (decision above).
- Layout values come from `ZodiannSpace / ZodiannRadius / ZodiannSize` (`no_magic_dimensions_test`); directional geometry only (`EdgeInsetsDirectional`, `AlignmentDirectional`), no mirroring transform, no icon is mirrored.
- `shared_ui` imports no route, no app code and no version source; `AppRoute` stays in the app.
- The logo is `ZodiannLogo(size: ZodiannSize.logoDrawer)`; icons come from `ZodiannIcon(ZodiannIcons.…)`; text styles derive from `ZodiannTextStyles` roles.
- The drawer is never docked or permanent, at any width (NAV-7).
- No new dependency; keep `no_network_test` green.
- Commands run as `fvm flutter …` / `fvm dart …` / `fvm dart run melos …`, sequentially. A root `fvm flutter pub get` deletes the tracked l10n output: restore with `git checkout -- packages/shared_ui/lib/l10n` (never commit the deletion). Regenerate l10n with the command `tool/check_l10n.dart` uses.

## Review Focus

Failure modes the spec implies and no acceptance criterion exercises. Each has a test in the owning task.

1. **Narrow phone, large text:** at 320 px wide with `textScaler` 2.0 and long Hebrew descriptions, items grow and wrap, nothing overflows, and the list scrolls (Task 2).
2. **Short screen (landscape phone, 360 px high):** header + nav + footer exceed the height; the nav area scrolls, the footer stays at the bottom, no overflow (Task 2).
3. **Double tap on the hamburger:** two quick taps open one drawer, not two stacked (Task 4).
4. **Locale or theme change while open:** the drawer re-lays out in the new direction and theme, and the swipe direction follows (Task 3).
5. **Interrupted gestures:** release mid-drag, drag toward the open side (must not move past open), a fling while opening, and back pressed during the opening animation all end in a consistent open or closed state with no leftover route (Task 3).

---

## File Structure

| File | Responsibility |
|---|---|
| `packages/shared_ui/lib/src/theme/tokens/zodiann_dimensions.dart` (modify) | Drawer and nav sizes in `ZodiannSize` |
| `packages/shared_ui/lib/src/theme/tokens/zodiann_states.dart` (modify) | `drawerOpenDuration`, `drawerCloseDuration` |
| `packages/shared_ui/lib/src/widgets/zodiann_pressable.dart` (modify) | Optional `selected`, `semanticHint` |
| `packages/shared_ui/lib/src/widgets/zodiann_drawer.dart` (create) | `ZodiannDrawer`, `ZodiannDrawerGroup`, `ZodiannDrawerItem` (the panel) |
| `packages/shared_ui/lib/src/widgets/zodiann_drawer_route.dart` (create) | `showZodiannDrawer`, the route, scrim, motion and swipe |
| `packages/shared_ui/lib/shared_ui.dart` (modify) | Exports (the route class hidden) |
| `packages/shared_ui/lib/l10n/app_{en,he}.arb` (modify) + generated output | New strings |
| `apps/astro_mobile/lib/src/navigation/app_shell.dart` (modify) | Enable the hamburger, build the groups |
| `tool/drawer/render_drawer_references.dart` (create) | Headless-Chrome reference renderer |
| `packages/shared_ui/test/fixtures/drawer/` (create) | Generated PNGs, `manifest.json`, `README.md` |
| `packages/shared_ui/test/support/drawer_features.dart` (create) | The feature extractor for the references |
| Tests: `test/widgets/drawer_test.dart`, `drawer_route_test.dart`, `drawer_reference_test.dart`, `test/l10n/drawer_copy_test.dart` (shared_ui); `test/navigation/drawer_shell_test.dart` (app) | |

---

### Task 1: Tokens, copy and the pressable's selected state

**Files:** modify `zodiann_dimensions.dart`, `zodiann_states.dart`, `zodiann_pressable.dart`, both ARBs; test `packages/shared_ui/test/theme/dimensions_test.dart` (extend), `packages/shared_ui/test/widgets/pressable_test.dart` (extend), create `packages/shared_ui/test/l10n/drawer_copy_test.dart`.

**Interfaces:**
- Produces: `ZodiannSize.drawerMaxWidth = 320`, `drawerWidthFactor = 0.86`, `drawerHead = 76`, `navIconColumn = 24`, `navItemGap = 2`, `navActiveBar = 3`, `navActiveBarInset = 10`; `ZodiannStates.drawerOpenDuration = 240 ms`, `drawerCloseDuration = 180 ms`; `ZodiannPressable({…, bool selected = false, String? semanticHint})`.
- ARB keys (en / he): `closeMenu` "Close menu" / "סגירת תפריט"; `drawerGroupAnalysis` "Analysis" / "ניתוח"; `drawerGroupLibrary` "Library and app" / "ספרייה ואפליקציה"; `drawerDescWheel`, `drawerDescSquare`, `drawerDescSaved`, `drawerDescSettings`, `drawerDescAbout` (kit.js `wheelDesc` … `aboutDesc`, verbatim); `drawerVersion` (placeholder `{version}`: "Version {version}" / "גרסה {version}"); `drawerOffline` "All data stays on this device" / "כל הנתונים נשארים במכשיר". Item names reuse `screen{Wheel,Square,Saved,Settings,About}Title`.

- [ ] **Step 1: Write the failing tests.** `dimensions_test`: each new token equals the value above and appears in the kit.css cross-check (`.drawer` width 320, `.drawer-head` 76, `.nav-item` grid 24 / gap 2, `.nav-item.on::before` width 3, top 10). `pressable_test`: `selected: true` gives a semantics node with `isSelected` and `semanticHint` becomes its hint; the default node is unchanged (flags and actions equal the current ones). `drawer_copy_test`: every new key equals the `kit.js` value in en and he (`wheelDesc` …, `tools`, `library`, `version` with `1.0.0`, `offline`), the close label is the literal pair above and is the only key that has no `kit.js` source (assert that exemption explicitly, with the reason in a comment), and the key sets of the two ARBs are equal.
- [ ] **Step 2: Run them; expect FAIL** (undefined tokens and getters). `cd packages/shared_ui; fvm flutter test test/theme/dimensions_test.dart test/widgets/pressable_test.dart test/l10n/drawer_copy_test.dart`.
- [ ] **Step 3: Implement** the tokens (with doc comments citing MASTER §5 / kit.css), the two durations, the ARB entries with `@key` descriptions (state the exception on `closeMenu`), regenerate l10n, and add `selected` / `semanticHint` to `ZodiannPressable` (passed to the existing `Semantics`; defaults leave the node unchanged).
- [ ] **Step 4: Run them; expect PASS**, then `fvm dart run melos run l10n:check` and the whole `shared_ui` suite (UI-004 and NAV-001 suites unedited; `git diff --stat` shows no edits to their files).
- [ ] **Step 5: Commit** `feat(ZOD-NAV-002): add drawer tokens, copy and the pressable's selected state`.

### Task 2: `ZodiannDrawer` (the panel)

**Files:** create `zodiann_drawer.dart`; modify `shared_ui.dart`; test `packages/shared_ui/test/widgets/drawer_test.dart`.

**Interfaces:**
- Consumes: Task 1 tokens and `ZodiannPressable(selected:, semanticHint:)`; `ZodiannIconButton`, `ZodiannLogo`, `ZodiannIcon`, `ZodiannElevation`.
- Produces:
  - `final class ZodiannDrawerItem { const ZodiannDrawerItem({required ZodiannIconData icon, required String name, required String description, required bool selected, required VoidCallback onTap}); }`
  - `final class ZodiannDrawerGroup { const ZodiannDrawerGroup({required String label, required List<ZodiannDrawerItem> items}); }`
  - `class ZodiannDrawer extends StatelessWidget { const ZodiannDrawer({super.key, required List<ZodiannDrawerGroup> groups, required String closeLabel, required VoidCallback onClose, required String versionLabel, required String offlineLabel}); }`: width `min(drawerMaxWidth, drawerWidthFactor × MediaQuery width)`, full height.

- [ ] **Step 1: Write the failing tests** (`drawer_test.dart`, pumped in graphite and porcelain, en and he, at 1440 and 390; every geometry assertion measured with `tester.getRect` / `getTopLeft`):
  - width 320 at 1440, 390 and 372.09; 309.6 at 360; 275.2 at 320;
  - header 76 high with the rule at its last row, logo 40 × 40 at the start inset 20 (LTR x 20, RTL mirrored), wordmark style equals `drawerWordmark`, close button 46 × 46 at 12 from the end edge, labelled `closeLabel`;
  - group labels 12 / `text3` / weight 400 with paddings 16 / 12 / 8 and the first group 8 on top; items 2 apart; item padding 12, radius 8, icon column 24 + gap 12, name 14/500, description 12 / `text2` / 400;
  - the active item: `accentSoft` fill, a 3 × (height − 20) `accent` bar on the start edge (LTR left, RTL right), name and icon colours per the Task 5 measurement (default `accentStrong`), and a semantics node `isSelected` with label = name and hint = description; the others are not selected; item semantics have one node each;
  - footer pinned to the bottom, 16 / 20 padding, `lineSoft` top rule, `text3`, the two lines in order; the inner-edge line and the `floating` shadow plus outside `floatingOutline`;
  - `ZodiannLogo` variant follows `Theme.brightness` (dark → on-dark asset, porcelain → on-light) with the OS brightness set the other way;
  - **Review Focus 1 and 2:** 320 px wide with `textScaler` 2.0 and Hebrew descriptions: no overflow, list scrolls; 360 px high: no overflow, footer at the bottom, nav scrolls;
  - safe areas: with a 24 top inset, 34 bottom inset and a 20 side inset the background still covers the insets while the content stays inside them;
  - tapping an item calls its `onTap` once; the close button calls `onClose` once; items have the UI-004 hover / press / focus-ring behaviour (one representative check) and a ≥ 44 target.
- [ ] **Step 2: Run; expect FAIL** (`ZodiannDrawer` undefined).
- [ ] **Step 3: Implement** the three classes in `zodiann_drawer.dart` and export them. Build from `Column` (header, `Expanded` scrollable nav, footer), with `EdgeInsetsDirectional` throughout, the active bar as a `PositionedDirectional` in a `Stack`, the elevation via `DecoratedBox` (`floating` shadows followed by a `BoxShadow(color: floatingOutline.color, spreadRadius: floatingOutline.width)`), and `MediaQuery.withClampedTextScaling` only if a measured overflow requires it (record it).
- [ ] **Step 4: Run; expect PASS**, then the whole `shared_ui` suite and `melos run lint`.
- [ ] **Step 5: Commit** `feat(ZOD-NAV-002): add ZodiannDrawer`.

### Task 3: `showZodiannDrawer` (route, motion, swipe)

**Files:** create `zodiann_drawer_route.dart`; modify `shared_ui.dart`; test `packages/shared_ui/test/widgets/drawer_route_test.dart`.

**Interfaces:**
- Consumes: `ZodiannDrawer`, `ZodiannStates.drawer*Duration`.
- Produces: `Future<void> showZodiannDrawer(BuildContext context, {required WidgetBuilder builder})`. Pushes on the root navigator; `builder` returns the `ZodiannDrawer` (it calls `Navigator.of(context).maybePop()` for `onClose`). The duration is read from `MediaQuery.disableAnimationsOf(context)` at push time (zero when reduced).

- [ ] **Step 1: Write the failing tests** (a harness `MaterialApp` with a button that calls `showZodiannDrawer`; en and he):
  - opens in 240 ms (a frame at 120 ms is part-way, at 240 ms fully open) and closes in 180 ms with `easeOutCubic` (sample the panel's offset against the curve at 25 / 50 / 75 %); the scrim opacity follows the same animation; the scrim colour is `scrim` in both themes;
  - **the four closes:** backdrop tap (outside the panel) closes; the close button closes; swipe toward the start edge closes (LTR leftward, RTL rightward, mirrored exactly); `tester.binding.handlePopRoute()` closes; after each, no route is left;
  - a tap on the panel does not close it; a drag toward the open side never moves past fully open; a release before halfway settles open, after halfway or with fling velocity ≥ 365 px/s settles closed; the panel follows the finger 1:1 during the drag;
  - reduced motion (`disableAnimations: true`): open and close are immediate;
  - the route is on the root navigator and the top bar is behind the scrim (a tap on the hamburger's position hits the scrim and closes);
  - the scrim has no semantics node of its own; the panel is the only accessible content;
  - **Review Focus 3 and 4:** a locale change (en → he) and a theme change while open re-lay out the panel and flip the swipe direction; **Review Focus 5:** back pressed at 100 ms into opening reaches closed with no leftover route; a fling while opening ends in a consistent state; two quick `showZodiannDrawer` calls from the same context leave one route (document the chosen guard, e.g. the route rejects a second push while one is current).
- [ ] **Step 2: Run; expect FAIL.**
- [ ] **Step 3: Implement** `_ZodiannDrawerRoute extends PopupRoute<void>`: `transitionDuration` / `reverseTransitionDuration` from the captured values; `barrierDismissible: true`; `barrierColor` the theme's `scrim` (fading in step through `ModalRoute`'s barrier animation); `buildModalBarrier` wrapped to exclude the scrim from semantics; `buildTransitions` slides the child from the start edge with `CurvedAnimation(curve: Curves.easeOutCubic, reverseCurve: Curves.easeOutCubic)` using `AlignmentDirectional`/`Directionality`; a horizontal drag layer drives `controller.value` by `−delta × directionSign / panelWidth`, and on release calls `forward()` or pops (the controller scales the remaining reverse time).
- [ ] **Step 4: Run; expect PASS**, whole `shared_ui` suite, `melos run lint`.
- [ ] **Step 5: Commit** `feat(ZOD-NAV-002): add showZodiannDrawer`.

### Task 4: Wire the drawer into the app shell

**Files:** modify `app_shell.dart` and its doc comment, `top_bar_shell_test.dart:150-162` (only that test), `apps/astro_mobile/lib/src/app.dart` doc comment; create `apps/astro_mobile/test/navigation/drawer_shell_test.dart`.

**Interfaces:**
- Consumes: `showZodiannDrawer`, `ZodiannDrawer*`, the new ARB getters.
- Produces: an `AppShell` whose hamburger (`onMenuPressed`) opens the drawer; an app-level constant `appVersion = '1.0.0'` with a doc comment ("temporary app-provided value; replace with the authoritative version source (About task); the drawer never owns it"), passed to `l.drawerVersion(appVersion)`.

- [ ] **Step 1: Write the failing tests** (`drawer_shell_test.dart`, en and he, with the shell's `_pumpApp` pattern): the hamburger is enabled and labelled; tapping it opens one drawer whose groups are "Analysis" (wheel, square) and "Library and app" (saved, settings, about) in `AppRoute.values` order with the literal en / he names and descriptions; the active item follows the route (`/square` → Square selected, then Settings); the footer reads "Version 1.0.0" / "גרסה 1.0.0" and the offline line; tapping an item changes nothing (route unchanged, drawer still open: decision A); back closes the drawer and leaves the route unchanged; the close button and the backdrop close it; **Review Focus 3:** two quick hamburger taps → one drawer; **never docked:** at widths 390, 700, 1099, 1100 and 1440 no `ZodiannDrawer` exists while closed, exactly one exists while open and it sits in a route above the shell (the shell's `Scaffold` has no `drawer` / `endDrawer`), and the content behind is covered. Change `top_bar_shell_test`'s hamburger test to "hamburger is enabled and labelled …" (`onPressed` is non-null); nothing else in that file.
- [ ] **Step 2: Run; expect FAIL.** `cd apps/astro_mobile; fvm flutter test test/navigation`.
- [ ] **Step 3: Implement** the shell wiring: the hamburger calls `showZodiannDrawer(context, builder: …)` building a `ZodiannDrawer` from the two groups (icons `wheel`, `grid`, `folder`, `sliders`, `info`), `selected: route == r`, item `onTap` a documented no-op ("ZOD-NAV-003 wires navigation and closing"), copy from `ZodiannLocalizations`.
- [ ] **Step 4: Run; expect PASS**, the whole app suite (NAV-001 / FND-014 suites green), `melos run lint`.
- [ ] **Step 5: Commit** `feat(ZOD-NAV-002): open the drawer from the app shell`.

### Task 5: References, fidelity and the active-colour measurement

**Files:** create `tool/drawer/render_drawer_references.dart`, `packages/shared_ui/test/support/drawer_features.dart`, `packages/shared_ui/test/widgets/drawer_reference_test.dart`, `packages/shared_ui/test/fixtures/drawer/{README.md,manifest.json,*.png}`.

**Interfaces:**
- Produces: `fvm dart run tool/drawer/render_drawer_references.dart` (Chrome from `CHROME` or the default path, as `tool/logo`), writing `packages/shared_ui/test/fixtures/drawer/generated_{dark,light}_{en,he}_{desktop,mobile}.png` (desktop 1440 × 900 @1, mobile 390 × 844 @2) from `_source/wheel.html?lang=…&theme=…&drawer=1`; `manifest.json` records the Chrome version and the SHA-256 of `kit.css`, `kit.js` and `wheel.html` (LF-normalised). The tool exits non-zero if a PNG has the wrong size. `README.md` states first: **generated visual references, not designer-provided assets; `kit.css` and `MASTER.md` remain authoritative and these images never override them**, and lists how to regenerate.
- `drawer_features.dart`: one extractor for both PNGs and rendered widgets: the panel's inner-edge column, the header-rule and footer-rule rows, the active fill's rectangle, the active bar's columns and rows, and the ink extents of each text line.

- [ ] **Step 1: Write the failing tests.** (a) Extractor self-check: on the four designer dark PNGs the extractor finds the header rule at row 75, the panel edge at x 320 (desktop) and the active bar 3 px wide. (b) Pipeline check: each generated dark PNG matches its designer PNG over the panel region within the same ceilings (proves the renderer reproduces the designer's images). (c) Widget vs reference: `ZodiannDrawer` rendered at the same size with the real fonts and the Wheel active matches the designer dark PNGs and the generated light PNGs (en and he, desktop and mobile): panel edge, rules, fill rectangle and bar within 1 logical px, text ink extents within 3, and a per-pixel mean-difference ceiling over the panel. (d) The manifest hashes still match the three source files. (e) The active name's ink colour in the dark PNG is the `accentStrong` white or the `text` colour: assert whichever the measurement shows and record it in the README (Task 2's active colours follow it).
- [ ] **Step 2: Run; expect FAIL** (no fixtures, no extractor).
- [ ] **Step 3: Implement** the renderer and the extractor, generate the eight PNGs, then run the test with `ZODIANN_DRAWER_CALIBRATE=1` to print the measured differences. Pin the ceilings just above the measured worst and record the calibration (values, Chrome version) in this plan's Verification record.
- [ ] **Step 4: Run; expect PASS**, plus `melos run lint` and the whole `shared_ui` suite.
- [ ] **Step 5: Commit** `test(ZOD-NAV-002): match the drawer against the references in both themes`.

### Task 6: Mutation proofs, device check and close-out

**Files:** modify `docs/PROGRESS.md`, the task file's Status, `docs/development/TASKS.md`, this plan's Verification record.

- [ ] **Step 1: Mutation proofs.** Apply each mutant, confirm a named test fails, revert: M1 header 75 / 77; M2 item padding 10; M3 bar 2 px or on the end edge; M4 fixed 320 width (no 86 %); M5 close duration 240; M6 swipe direction not mirrored in RTL; M7 backdrop tap ignored; M8 `selected` semantics dropped; M9 `EdgeInsets` instead of directional (he fails); M10 outline omitted; M11 reduced motion ignored; M12 the drawer docked inline at ≥ 1100; M13 scrim left in semantics; M14 active colour `text` vs `accentStrong` (the reference test fails whichever is wrong).
- [ ] **Step 2: Device check (emulator-5554, debug APK).** Open the drawer, run `adb shell uiautomator dump` and confirm the active item has `selected="true"` and the others do not; confirm the Android back button closes it. Note: this checks the accessibility node information, not a TalkBack session. Run TalkBack if the emulator image has it; if not, record the limit (**open item**).
- [ ] **Step 3: Final verification** (sequential): `fvm dart run melos run lint`, `fvm dart run melos run test`, `fvm flutter build apk --debug`; record exit codes and counts.
- [ ] **Step 4: Code review** with `requesting-code-review` on the whole branch; fix Critical and Important findings test-first.
- [ ] **Step 5: Docs.** Task file Status → Done (acceptance boxes ticked only for what is verified), `TASKS.md` row, `PROGRESS.md` (completed row, conventions: "Drawer" paragraph — use `showZodiannDrawer`, the version is app-owned, items are inert until NAV-003, the references are generated; deferred minors; Next Recommended Task). Commit `docs(ZOD-NAV-002): close out the drawer`, push, open the PR, record the link.

## Acceptance criteria → proof

| Criterion | Proof |
|---|---|
| Matches `00-navigation-drawer_*` in both languages and both themes | Task 5 (designer dark PNGs; generated light PNGs, labelled as such) |
| All four close interactions | Task 3 tests; Task 6 device back check |
| Never permanent at any breakpoint | Task 4 "never docked" test; M12 |
| Active item "selected" with a screen reader | Task 2 and Task 4 semantics tests; Task 6 device node check (TalkBack itself is an open item) |

## Risks

- The "pixel-for-pixel" criterion is met as calibrated ceilings, as in earlier tasks, not as byte equality.
- The route's drag layer is the one piece of new gesture code; Task 3 has the most tests for that reason.
- Android 14+ predictive-back animation is not designed in the references and is out of scope; back still closes the drawer.
- A root `pub get` deletes the tracked l10n output (see Global Constraints).

## Verification record

_(filled during implementation)_

## Plan review

_(filled by the plan-review cycle)_
