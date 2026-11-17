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
- **Active item colour (plan review D1): `accent-strong`** for the active icon and name, as kit.css, every designer PNG and NAV-3 ("marked with the accent colour") draw it. MASTER §5 and the task text say `text`; MASTER is not edited and the deviation is recorded here and in PROGRESS (as the UI-009 neutral-tag weight was).
- **Screen reader (plan review D2).** Try a real TalkBack session. If the emulator cannot run one, the task is still closed, with acceptance criterion 4 left **unticked** and the check recorded as outstanding (the FND-005 iOS precedent).

## Facts established while planning (2026-11-17)

- **Geometry (kit.css, border-box; reference measurements by plan review round 1 on `00-navigation-drawer_desktop_en_dark.png`):**
  - Panel: width `min(320, 0.86 × screen width)`: 320 from 372.093… up (372.1 → 320; 372.09 → 319.9974; 360 → 309.6; 320 → 275.2); full height; `surface`; `border-inline-end` 1 px `line`; shadow `var(--shadow-float)`. **The 1 px border is inside the width**: the content box is `width − 1`. At 320 the border column is x 319 and the outline column (under the shadow) x 320.
  - Header: 76 high including a 1 px `line-soft` bottom rule (rule at row 75); padding start 20 (`s5`), end 12 (`s3`), top and bottom 12; gap 12; logo 40 (x 20–60); wordmark starts at x 72, 20/600 −0.01 em (`drawerWordmark`); close button 46 × 46 ending 12 from the inner border (x 261–307 at 320), its X ink x 278–289.
  - Nav: padding 12; **every nav child (group labels and items) is 2 apart** (`.drawer nav { gap: 2px }`). Group label: padding 16 / 12 / 8, the first 8 on top; 12, `text-3`, weight 400.
  - Item: padding 12, radius 8; a 24 px icon column (the 20 px icon at its start, not centred, 1 px down: `margin-top: 1px`), 12 gap, text column 235 wide at 320; name 14/500 (`text`); description 12 `text-2`, weight 400; row gap 2. **The en Wheel description wraps to two lines** (fill ≈ 81 px high), so a width error of a few pixels shifts every row below it. Inactive icon `text-2`, inactive name `text`.
  - Active: `accent-soft` fill, 3 px `accent` bar on the start edge (10 px from top and bottom, radius 3), icon and name `accent-strong` (decided, D1).
  - Footer: pinned to the bottom; padding 16 / 20, 1 px `line-soft` top rule, 12 `text-3`, two lines 2 apart.
- **At 390 × 844 @2 the panel is 640 device px (320 logical).** Border columns 638–639 and outline 640–641; header rule rows 150–151.
- **`ZodiannPressable` has one semantics node and no `selected` or `hint`** (`zodiann_pressable.dart:95-100`). In Flutter 3.50 the selected flag has three states, so the node must carry *no* selected state unless the item is active (Task 1).
- **Flutter's close curve does not flip.** A `CurvedAnimation` applies the same curve on the way back, so `reverseCurve: easeOutCubic` would close slowly then fast (97.6 % open after 25 % of the close). The close uses `Curves.easeOutCubic.flipped`: open fraction 0.400 / 0.125 / 0.024 at 45 / 90 / 135 ms of closing; opening is 0.600 / 0.875 / 0.976 at 60 / 120 / 180 ms (±0.01). `Curves.easeOutCubic` is `Cubic(0.215, 0.61, 0.355, 1.0)` (the CSS curve MASTER §12 names), **not** `1 − (1 − t)³`; the tests keep these literal values and never compute them with `Curves.easeOutCubic.transform`.
- **Route default barrier fades with `Curves.ease` on raw progress**, not in step with the panel; the route supplies its own barrier (Task 3).
- **Existing assertion that must change:** `apps/astro_mobile/test/navigation/top_bar_shell_test.dart:150-167` ("hamburger is disabled and labelled …": `onPressed` null and `isEnabled: false`) and the file header's mention of the hamburger (lines 1-4). Nothing else in that file.
- **Tokens that exist:** `ZodiannSurfaces.scrim / accentSoft / accentStrong / lineSoft / line / text2 / text3`, `ZodiannElevation.floating / floatingOutline`, `ZodiannTextStyles.drawerWordmark`, `ZodiannSize.logoDrawer (40) / iconButton (46) / icon (20)`, `ZodiannIcons.wheel / grid / folder / sliders / info / x`, and the ARB key `appTitle` ("Zodiann", used for the wordmark).
- **Device sizes of the reference renderer:** desktop 1440 × 900 @1, mobile 390 × 844 @2 (`_source/render/render.js:6`). That renderer launches Chrome with web fonts reachable from `file://`, hinting off, sRGB, and waits for fonts (`render.js:13-23`).
- **Root architecture guards** (all of `test/architecture`, notably `no_magic_dimensions`, `no_color_literals`, `no_text_literals`, `logo_size_guard`, `l10n_key_parity`, `sentence_case`) run from the repository root, so every task runs them explicitly.
- **Go_router back** stops at a route pushed on the root navigator (`delegate.dart:116-135`), so the drawer closes on back before the router acts.

## Global Constraints

- Sentence case; no `toUpperCase(`; every user-visible string is localized (ARB), none is a literal in `lib/` (`no_text_literals_test`). Copy comes from `kit.js`, except the close label (decision above).
- Layout values come from `ZodiannSpace / ZodiannRadius / ZodiannSize` (`no_magic_dimensions_test`); directional geometry only (`EdgeInsetsDirectional`, `AlignmentDirectional`), no mirroring transform, no icon is mirrored.
- `shared_ui` imports no route, no app code and no version source; `AppRoute` stays in the app.
- The logo is `ZodiannLogo(size: ZodiannSize.logoDrawer)`; icons come from `ZodiannIcon(ZodiannIcons.…)`; text styles derive from `ZodiannTextStyles` roles.
- The drawer is never docked or permanent, at any width (NAV-7). NAV-005 keeps its own criteria and dedicated suite; Task 4's widths are this task's smoke test.
- No new dependency; keep `no_network_test` green.
- Commands run as `fvm flutter …` / `fvm dart …` / `fvm dart run melos …`, sequentially. A root `fvm flutter pub get` deletes the tracked l10n output: restore with `git checkout -- packages/shared_ui/lib/l10n` (never commit the deletion). Regenerate l10n with the command `tool/check_l10n.dart` uses.
- **Every task's final run** includes the root guards: from the repository root, `fvm dart test test/architecture` (all pass), plus `fvm dart run melos run lint`.

## Review Focus

Failure modes the spec implies and no acceptance criterion exercises. Each has a test in the owning task.

1. **Narrow phone, large text:** at 320 px wide with `textScaler` 2.0 and long Hebrew descriptions, items grow and wrap, the header (clamped at 1.5×) does not overflow, nothing overflows, and the list scrolls (Task 2).
2. **Short screen (landscape phone, 360 px high):** header + nav + footer exceed the height; the nav area scrolls, the footer stays at the bottom, no overflow (Task 2).
3. **Double tap on the hamburger:** two quick taps open one drawer, not two stacked (Tasks 3 and 4).
4. **Locale or theme change while open:** the drawer re-lays out in the new direction, theme and scrim colour, the app's copy follows the new locale, and the swipe direction follows (Tasks 3 and 4).
5. **Interrupted gestures:** release mid-drag, drag toward the open side (must not move past open), a fling while opening, a drag to the closed edge, and back pressed during the opening animation all end in a consistent open or closed state with no leftover route (Task 3).

---

## File Structure

| File | Responsibility |
|---|---|
| `packages/shared_ui/lib/src/theme/tokens/zodiann_dimensions.dart` (modify) | Drawer and nav sizes in `ZodiannSize` |
| `packages/shared_ui/lib/src/theme/tokens/zodiann_states.dart` (modify) | Drawer durations and fling velocity |
| `packages/shared_ui/lib/src/widgets/zodiann_pressable.dart` (modify) | Optional `selected`, `semanticHint` |
| `packages/shared_ui/lib/src/widgets/zodiann_drawer.dart` (create) | `ZodiannDrawer`, `ZodiannDrawerGroup`, `ZodiannDrawerItem` (the panel) |
| `packages/shared_ui/lib/src/widgets/zodiann_drawer_route.dart` (create) | `showZodiannDrawer`, the private route, barrier, motion and swipe |
| `packages/shared_ui/lib/shared_ui.dart` (modify) | Exports |
| `packages/shared_ui/lib/l10n/app_{en,he}.arb` (modify) + generated output | New strings |
| `apps/astro_mobile/lib/src/app_version.dart` (create) | The temporary `appVersion` constant |
| `apps/astro_mobile/lib/src/navigation/app_shell.dart` (modify) | Enable the hamburger, build the groups |
| `apps/astro_mobile/lib/src/navigation/app_route.dart` (modify, doc only) | Route-contract comment |
| `tool/drawer/render_drawer_references.dart` (create) | Headless-Chrome reference renderer |
| `packages/shared_ui/test/fixtures/drawer/` (create) | Generated PNGs, `manifest.json`, `README.md` |
| `packages/shared_ui/test/support/drawer_features.dart` (create) | The feature extractor for the references |
| Tests (new files only): shared_ui `test/widgets/pressable_selected_test.dart`, `drawer_test.dart`, `drawer_route_test.dart`, `drawer_reference_test.dart`, `test/l10n/drawer_copy_test.dart`, `test/theme/dimensions_test.dart` (extended: UI-003's own file); app `test/navigation/drawer_shell_test.dart` | |

---

### Task 1: Tokens, copy and the pressable's selected state

**Files:** modify `zodiann_dimensions.dart`, `zodiann_states.dart`, `zodiann_pressable.dart`, both ARBs; extend `packages/shared_ui/test/theme/dimensions_test.dart`; create `packages/shared_ui/test/widgets/pressable_selected_test.dart` and `packages/shared_ui/test/l10n/drawer_copy_test.dart`. (`pressable_test.dart` is NAV-001's and stays unedited.)

**Interfaces:**
- Produces: `ZodiannSize.drawerMaxWidth = 320`, `drawerWidthFactor = 0.86`, `drawerHead = 76`, `navIconColumn = 24`, `navIconNudge = 1`, `navItemGap = 2`, `navActiveBar = 3`, `navActiveBarInset = 10`; `ZodiannStates.drawerOpenDuration = 240 ms`, `drawerCloseDuration = 180 ms`, `drawerFlingVelocity = 365` (px/s, Material's drawer constant); `ZodiannPressable({…, bool selected = false, String? semanticHint})`.
- ARB keys (en / he): `closeMenu` "Close menu" / "סגירת תפריט"; `drawerGroupAnalysis` "Analysis" / "ניתוח"; `drawerGroupLibrary` "Library and app" / "ספרייה ואפליקציה"; `drawerDescWheel`, `drawerDescSquare`, `drawerDescSaved`, `drawerDescSettings`, `drawerDescAbout` (kit.js `wheelDesc` … `aboutDesc`, verbatim); `drawerVersion` (placeholder `{version}`: "Version {version}" / "גרסה {version}"); `drawerOffline` "All data stays on this device" / "כל הנתונים נשארים במכשיר". Item names reuse `screen{Wheel,Square,Saved,Settings,About}Title`; the wordmark reuses `appTitle`.

- [ ] **Step 1: Write the failing tests.** `dimensions_test`: each new token equals the value above and appears in the kit.css cross-check (`.drawer` width 320, `.drawer-head` 76, `.nav-item` grid 24 / gap 2, `svg` margin-top 1, `.nav-item.on::before` width 3, top 10). `pressable_selected_test`: `selected: true` gives a node with `isSelected` and the `semanticHint` as its hint; with the default, the node has **no selected state at all** (`hasSelectedState` false) and its flags and actions equal a plain pressable's. `drawer_copy_test`: every new key equals the `kit.js` value in en and he (`wheelDesc` …, `tools`, `library`, `version` with `1.0.0`, `offline`); `closeMenu` is the literal pair above and is the only **drawer** key with no `kit.js` source (assert that exemption explicitly, with the reason in a comment); the key sets of the two ARBs are equal.
- [ ] **Step 2: Run; expect FAIL.** `cd packages/shared_ui; fvm flutter test test/theme/dimensions_test.dart test/widgets/pressable_selected_test.dart test/l10n/drawer_copy_test.dart` → compilation errors: undefined `ZodiannSize.drawerMaxWidth`, `selected`, `closeMenu`.
- [ ] **Step 3: Implement** the tokens (doc comments citing MASTER §5 / kit.css), the ARB entries with `@key` descriptions (state the exception on `closeMenu`), regenerate l10n, and add `selected` / `semanticHint` to `ZodiannPressable`, passing `selected: widget.selected ? true : null` and `hint: widget.semanticHint` to the existing `Semantics`.
- [ ] **Step 4: Run; expect PASS:** the three files, `fvm dart run melos run l10n:check`, the whole `shared_ui` suite (UI-004 and NAV-001 suites unedited: `git diff --stat main -- packages/shared_ui/test/widgets/pressable_test.dart packages/shared_ui/test/widgets/button_*.dart packages/shared_ui/test/widgets/top_bar_test.dart` is empty), and the root guards.
- [ ] **Step 5: Commit** `feat(ZOD-NAV-002): add drawer tokens, copy and the pressable's selected state`.

### Task 2: `ZodiannDrawer` (the panel)

**Files:** create `zodiann_drawer.dart`; modify `shared_ui.dart`; test `packages/shared_ui/test/widgets/drawer_test.dart`.

**Interfaces:**
- Consumes: Task 1 tokens and `ZodiannPressable(selected:, semanticHint:)`; `ZodiannIconButton`, `ZodiannLogo`, `ZodiannIcon`, `ZodiannElevation`.
- Produces:
  - `final class ZodiannDrawerItem { const ZodiannDrawerItem({required ZodiannIconData icon, required String name, required String description, required bool selected, required VoidCallback onTap}); }`
  - `final class ZodiannDrawerGroup { const ZodiannDrawerGroup({required String label, required List<ZodiannDrawerItem> items}); }`
  - `class ZodiannDrawer extends StatelessWidget { const ZodiannDrawer({super.key, required String wordmark, required List<ZodiannDrawerGroup> groups, required String closeLabel, required VoidCallback onClose, required String versionLabel, required String offlineLabel}); static double widthFor(double screenWidth); }` where `widthFor` is `min(drawerMaxWidth, drawerWidthFactor × screenWidth)` (the panel's width, mirroring `ZodiannTopBar.heightFor`).

- [ ] **Step 1: Write the failing tests** (`drawer_test.dart`, graphite and porcelain, en and he, at 1440 and 390; geometry measured with `tester.getRect` / `getTopLeft`):
  - `widthFor` and the panel's width: 320 at 1440, 390 and 372.1; 319.9974 at 372.09 (compared within 1e-6); 309.6 at 360; 275.2 at 320;
  - header 76 high with the rule at its last row; the content box is `width − 1` (the 1 px inner border); logo 40 × 40 at the start inset 20 (LTR x 20, RTL mirrored); wordmark text equals `wordmark` with the `drawerWordmark` style, starting 12 after the logo; the close button 46 × 46 ending 12 from the inner border, labelled `closeLabel`;
  - group labels 12 / `text3` / weight 400 with paddings 16 / 12 / 8, the first 8 on top; every nav child (labels and items) 2 apart; item padding 12, radius 8; the 20 px icon at the **start** of the 24 px column (LTR and RTL), 1 px down; name 14/500 in `text`; description 12 / `text2` / 400; inactive icon `text2`;
  - the active item: `accentSoft` fill; a `navActiveBar` × (height − 2 × `navActiveBarInset`) `accent` bar on the start edge (LTR left, RTL right) with radius 3; name and icon `accentStrong` (decision D1); a semantics node `isSelected` with label = name and hint = description; the others have no selected state; one semantics node per item;
  - footer pinned to the bottom, padding 16 / 20, `lineSoft` top rule, `text3`, the two lines in order; the `floating` shadow with the `floatingOutline` ring outside; the inner-edge line;
  - `ZodiannLogo` variant follows `Theme.brightness` (graphite → on-dark asset, porcelain → on-light) with the OS brightness set the other way;
  - **Review Focus 1 and 2:** 320 px wide with `textScaler` 2.0 and Hebrew descriptions: no overflow, the header's text is clamped at 1.5×, the list scrolls; 360 px high: no overflow, footer at the bottom, nav scrolls;
  - safe areas: with a 24 top inset, 34 bottom inset and a 20 side inset the background still covers the insets while the content stays inside them;
  - an item tap calls its `onTap` once; the close button calls `onClose` once; items have the UI-004 hover / press / focus-ring behaviour (one representative check) and a ≥ 44 target; the first and last items' focus rings are not clipped by the nav padding (the 2 px item gap leaves rings of neighbouring items overlapping; accepted, noted in the doc comment).
- [ ] **Step 2: Run; expect FAIL.** `cd packages/shared_ui; fvm flutter test test/widgets/drawer_test.dart` → compilation error: undefined name `ZodiannDrawer`.
- [ ] **Step 3: Implement** the three classes and `widthFor` in `zodiann_drawer.dart`, exported from `shared_ui.dart`. Build from `Column` (header, `Expanded` scrollable nav, footer) with `EdgeInsetsDirectional` throughout; the content is inset by the border width (`floatingOutline.width`, no literal); the active bar is a `PositionedDirectional` in a `Stack`; the header wraps its text in `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.5)` (the top bar's rule: 20 × 1.45 × 1.5 = 43.5 ≤ 51, which is 76 − 24 padding − 1 rule; nav and footer scale freely); elevation is a `DecoratedBox` whose shadows list `floatingOutline` ring first, then `floating` (Flutter paints later shadows on top, and the reference's outline column sits under the shadow; a 1 px deviation outside the compared region is recorded if the order has to differ). This deviates from the task Notes' example ordering (an "e.g."), which would paint the ring over the shadow. Use the existing tokens and invent no constants: `ZodiannRadius.xs` (bar, 3), `ZodiannRadius.md` / `control` (items, 8), `ZodiannSpace.s4 / s3 / s2` (group-label padding) and `s4 / s5` (footer padding).
- [ ] **Step 4: Run; expect PASS:** `drawer_test.dart`, the whole `shared_ui` suite, the root guards, `fvm dart run melos run lint`.
- [ ] **Step 5: Commit** `feat(ZOD-NAV-002): add ZodiannDrawer`.

### Task 3: `showZodiannDrawer` (route, motion, swipe)

**Files:** create `zodiann_drawer_route.dart`; modify `shared_ui.dart`; test `packages/shared_ui/test/widgets/drawer_route_test.dart`.

**Interfaces:**
- Consumes: `ZodiannDrawer.widthFor`, `ZodiannStates.drawer*`.
- Produces: `Future<void> showZodiannDrawer(BuildContext context, {required WidgetBuilder builder})`. Pushes a private `_ZodiannDrawerRoute` on the root navigator; `builder` returns the `ZodiannDrawer` (its `onClose` calls `Navigator.of(context).maybePop()`). **Guard:** an `Expando` keyed by the root `NavigatorState` holds the open drawer route; `showZodiannDrawer` returns without pushing while it holds a route that is not yet disposed (this also covers a route that is still popping, which `isCurrent` would miss). Documented on the function; always the root navigator, never the nearest. The durations are read from `MediaQuery.disableAnimationsOf(context)` at push time (zero when reduced).

- [ ] **Step 1: Write the failing tests** (a harness `MaterialApp` whose home is a `Scaffold` with a `ZodiannTopBar` (`onMenuPressed` calls `showZodiannDrawer`) and a body button; en and he; graphite and porcelain):
  - **Open:** the open fraction at 60 / 120 / 180 ms is 0.600 / 0.875 / 0.976 (±0.01) and 1.0 at 240 ms. **Close:** the open fraction at 45 / 90 / 135 ms is 0.400 / 0.125 / 0.024 (±0.01) and the route is gone at 180 ms. (The curve is `easeOutCubic` opening and `easeOutCubic.flipped` closing, so both ease out.)
  - **Scrim in step:** at every sample, opening and closing, **and at every frame during a drag and during the settle after release**, the scrim's opacity equals the panel's open fraction × the theme's `scrim` alpha, and its RGB equals the theme's `scrim` RGB (porcelain included, so the fade is the scrim colour at reduced alpha, not a blend from black). The scrim colour is read live: after a theme switch while open, `pumpAndSettle` past the theme animation and assert the new `scrim`.
  - **The four closes:** a backdrop tap (outside the panel) closes; the close button closes; a swipe toward the start edge closes (LTR leftward, RTL rightward, mirrored exactly); `tester.binding.handlePopRoute()` closes; after each, no route is left. A tap on the panel does not close it.
  - **Gesture:** the panel follows the finger 1:1 (the drag and the settle use linear progress, not the curve); no jump on release (the panel moves < 1 px between the last drag frame and the first settle frame); a drag toward the open side never moves past fully open; a fling of at least `drawerFlingVelocity` decides by its direction (a release at 30 % open with a fling toward the end side settles open; a release at 70 % with a fling toward the start closes); without a fling, a release at ≤ 50 % closes, otherwise it settles open; a drag to the closed edge and release leaves no route; drags start on the panel and on the scrim.
  - Reduced motion (`disableAnimations: true`): open and close are immediate.
  - **Top bar and hit testing:** the route is on the root navigator and the top bar is behind it; a tap on the top bar's title area (outside the panel) hits the scrim and closes the drawer; a tap at the hamburger's position hits the panel and the drawer stays open; the top bar's controls get no taps while the drawer is open.
  - **Semantics:** the scrim has no semantics node of its own (`semanticsDismissible => false`) while a backdrop tap still closes the drawer; the panel is the only accessible content and the screen behind is blocked (the focus trap and focus movement are ZOD-NAV-004's).
  - **Review Focus 3:** two quick `showZodiannDrawer` calls from the same context leave one route; a call during the 180 ms close animation also ends with exactly one drawer route; called from inside a nested `Navigator`, the route lands on the root navigator. **Focus 4:** a locale change (en → he) and a theme change while open re-lay out the panel, update the scrim colour and flip the swipe direction. **Focus 5:** back pressed 100 ms into opening reaches closed with no leftover route; a fling while opening ends in a consistent state.
- [ ] **Step 2: Run; expect FAIL.** `cd packages/shared_ui; fvm flutter test test/widgets/drawer_route_test.dart` → compilation error: undefined name `showZodiannDrawer`.
- [ ] **Step 3: Implement** `_ZodiannDrawerRoute extends PopupRoute<void>`: `transitionDuration` / `reverseTransitionDuration` from the captured values; `barrierDismissible: true`; `semanticsDismissible => false`. **One progress for both layers:** the route owns a single `Animation<double> _progress` (created once, disposed in `dispose()`) whose value is the linear `controller.value` while a private `_gestureActive` flag is set, and otherwise the value of one `CurvedAnimation(parent: controller, curve: Curves.easeOutCubic, reverseCurve: Curves.easeOutCubic.flipped)`. The `SlideTransition(textDirection: Directionality.of(context))` and the barrier both use `_progress`. **Override `buildModalBarrier()`** to return `Builder(builder: (context) { final scrim = Theme.of(context).extension<ZodiannSurfaces>()!.scrim; return AnimatedModalBarrier(color: _progress.drive(ColorTween(begin: scrim.withValues(alpha: 0), end: scrim)), dismissible: true, barrierSemanticsDismissible: false); })`. The `Builder` registers the theme dependency on the barrier's own overlay entry (so a theme change updates it live), and `begin` is the scrim at alpha 0 (not `Colors.transparent`, which `no_color_literals_test` flags, and not `ZodiannStates.transparent`, which blends up from black). **Drag layer:** put the detector in `buildTransitions` around the slide (as Cupertino does), and a detector inside the barrier `Builder` for drags that start on the scrim; ignore drag starts while the route is not current (popping). When a drag starts, set `_gestureActive`, stop the controller and call `navigator.didStartUserGesture()`; set `controller.value` by `−delta × directionSign / ZodiannDrawer.widthFor(screenWidth)`, clamped to ≤ 1. On release: if the fling speed is at least `drawerFlingVelocity` its direction decides (toward the start pops, toward the end `forward()`s); otherwise pop if the value ≤ 0.5, else `forward()`; reaching 0 always pops. Clear `_gestureActive` and call `navigator.didStopUserGesture()` only when the settle animation reaches `completed` or `dismissed` (as `TransitionRoute._handleDragEnd` does), **not on pointer-up**, so the slide and scrim stay linear through the whole settle and never jump.
- [ ] **Step 4: Run; expect PASS:** `drawer_route_test.dart`, the whole `shared_ui` suite, the root guards, `fvm dart run melos run lint`.
- [ ] **Step 5: Commit** `feat(ZOD-NAV-002): add showZodiannDrawer`.

### Task 4: Wire the drawer into the app shell

**Files:** create `apps/astro_mobile/lib/src/app_version.dart`, `apps/astro_mobile/test/navigation/drawer_shell_test.dart`; modify `app_shell.dart` (and its doc comment), `app_route.dart` (doc comment only), `app.dart` (doc comment), `top_bar_shell_test.dart:150-167` and its header (lines 1-4).

**Interfaces:**
- Consumes: `showZodiannDrawer`, `ZodiannDrawer*`, the new ARB getters.
- Produces: `const String appVersion = '1.0.0';` in `app_version.dart`, documented as a temporary app-provided value to be replaced by the authoritative version source (the About task); the drawer never owns it. An `AppShell` whose hamburger opens the drawer; the builder resolves `ZodiannLocalizations.of(drawerContext)` **inside** the builder and builds the groups there (only `route` is captured), passing `wordmark: l.appTitle`, `versionLabel: l.drawerVersion(appVersion)`, `offlineLabel: l.drawerOffline`, `closeLabel: l.closeMenu`.

- [ ] **Step 1: Write the failing tests** (`drawer_shell_test.dart`, en and he, with the shell's `_pumpApp` pattern): the hamburger is enabled and labelled; tapping it opens one drawer whose groups are "Analysis" (wheel, square) and "Library and app" (saved, settings, about) in `AppRoute.values` order with the literal en / he names and descriptions and the wordmark "Zodiann"; the active item follows the route (`/square` → Square selected, then Settings); the footer reads "Version 1.0.0" / "גרסה 1.0.0" and the offline line; tapping an item changes nothing (route unchanged, drawer still open: decision A); back closes the drawer and leaves the route unchanged; the close button and the backdrop close it; **Focus 3:** two quick hamburger taps → one drawer, and a hamburger tap during the close animation ends with exactly one drawer route; **Focus 4:** switching the device locale en → he while open shows the Hebrew copy and the mirrored layout; **never docked:** at widths 390, 700, 1099, 1100 and 1440 no `ZodiannDrawer` exists while closed, exactly one exists while open and it sits in a route above the shell (the shell's `Scaffold` has no `drawer` / `endDrawer`), and the content behind is covered. Change `top_bar_shell_test`: the hamburger test becomes "hamburger is enabled and labelled …" (`onPressed` non-null and `isEnabled: true`) and the header comment no longer says the hamburger is disabled; no other test in that file changes.
- [ ] **Step 2: Run; expect FAIL.** `cd apps/astro_mobile; fvm flutter test test/navigation` → the new tests fail (hamburger disabled, no drawer) and the amended hamburger test fails.
- [ ] **Step 3: Implement** the wiring: groups with icons `wheel`, `grid`, `folder`, `sliders`, `info`, `selected: route == r`, item `onTap` a documented no-op ("ZOD-NAV-003 wires navigation and closing"). Update `app_route.dart`'s doc comment: the drawer is route-independent too, so the feature-accessible route-contract decision passes to ZOD-DAT-005.
- [ ] **Step 4: Run; expect PASS:** `fvm flutter test test/navigation`, the whole app suite (NAV-001 / FND-014 suites green), the root guards, `fvm dart run melos run lint`.
- [ ] **Step 5: Commit** `feat(ZOD-NAV-002): open the drawer from the app shell`.

### Task 5: References, fidelity and the active-colour confirmation

**Files:** create `tool/drawer/render_drawer_references.dart`, `packages/shared_ui/test/support/drawer_features.dart`, `packages/shared_ui/test/widgets/drawer_reference_test.dart`, `packages/shared_ui/test/fixtures/drawer/{README.md,manifest.json,*.png}`.

**Interfaces:**
- Produces: `fvm dart run tool/drawer/render_drawer_references.dart` (Chrome from `CHROME` or the default path), writing `packages/shared_ui/test/fixtures/drawer/generated_{dark,light}_{en,he}_{desktop,mobile}.png` from `_source/wheel.html?lang=…&theme=…&drawer=1` (desktop 1440 × 900 @1, mobile 390 × 844 @2). Chrome arguments: `--headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files --force-color-profile=srgb --font-render-hinting=none --force-device-scale-factor=<1|2> --window-size=<1440,900|390,844> --virtual-time-budget=5000 --screenshot=…` (the logo tool's flags are not enough: web fonts would not load from `file://` and the screenshot would not wait for them). The tool exits non-zero on a wrong PNG size. `manifest.json` records the Chrome version and the SHA-256 (LF-normalised) of `kit.css`, `kit.js`, `wheel.html`, `assets/fonts/fonts.css` and both logo SVGs. `README.md` states first: **generated visual references, not designer-provided assets; `kit.css` and `MASTER.md` remain authoritative and these images never override them**, and how to regenerate.
- `drawer_features.dart`: one extractor for PNGs and rendered widgets: the border and outline columns, the header-rule and footer-rule rows, the active fill's rectangle, the active bar's columns and rows, each text line's ink extents, and the brightest (dark) or darkest (light) pixel of a name.

- [ ] **Step 1: Write the failing tests.** (a) Extractor self-check on the four designer dark PNGs: border column 319 and outline column 320 (desktop @1; 638–639 and 640–641 @2), header rule at row 75 (150–151 @2), the active bar 3 px wide. (b) Pipeline check: each generated dark PNG matches its designer PNG over the panel region within the same ceilings. (c) Widget vs reference: `ZodiannDrawer` rendered at the same size with the real fonts and Wheel active matches the designer dark PNGs and the generated light PNGs (en and he, desktop and mobile): border, rules, fill rectangle and bar within 1 logical px, text ink extents within 3, and a per-pixel mean-difference ceiling over the panel. (d) The manifest hashes still match the source files. (e) **Active colour:** in the designer dark PNGs, the brightest pixel of the active name equals `accentStrong` and that of each inactive name equals `text`, within ±1 per channel (measured: `ffffff` and `f4f5f7` in the desktop and mobile en dark PNGs). In the generated light PNGs and in the rendered widget, the extreme pixel (brightest in dark, darkest in light) of the active name is closer to `accentStrong` than to `text`, and each inactive name's is closer to `text` than to `accentStrong` (the two light tokens are only 11 levels apart, and hinting-off text may not reach a fully inked pixel).
- [ ] **Step 2: Run; expect FAIL.** `cd packages/shared_ui; fvm flutter test test/widgets/drawer_reference_test.dart` → fixtures and extractor missing.
- [ ] **Step 3: Implement** the renderer and extractor and generate the eight PNGs. The fixed 1 px (position) and 3 px (text ink) ceilings stand; only the mean-difference ceiling is calibrated: run with `ZODIANN_DRAWER_CALIBRATE=1`, then pin it by the recorded rule `max(round_up(worst × 1.5, 3), floor)` (PROGRESS, 2026-11-15) and record the calibration (values, Chrome version) in the Verification record.
- [ ] **Step 4: Run; expect PASS:** the test, the whole `shared_ui` suite, the root guards, `fvm dart run melos run lint`.
- [ ] **Step 5: Commit** `test(ZOD-NAV-002): match the drawer against the references in both themes`.

### Task 6: Mutation proofs, device check and close-out

**Files:** modify `docs/PROGRESS.md`, the task file's Status, `docs/development/TASKS.md`, this plan's Verification record.

- [ ] **Step 1: Mutation proofs.** Apply each mutant, confirm a named test fails, revert: M1 header 75 / 77; M2 item padding 10; M3 bar 2 px or on the end edge; M4 fixed 320 width (no 86 %); M5 close duration 240; M6 swipe direction not mirrored in RTL; M7 backdrop tap ignored; M8 `selected` semantics dropped; M9 `EdgeInsets` instead of directional (he fails); M10 outline omitted; M11 reduced motion ignored; M12 the drawer docked inline at ≥ 1100; M13 scrim left in semantics; M14 active colour `text` (named failures: Task 2's colour assertion and Task 5(e)); M15 `reverseCurve` not flipped (the close sample test); M16 scrim on the default barrier curve (the in-step test); M17 `selected: false` always passed (the no-selected-state test); M18 the barrier driven by the curved animation during a drag (the scrim-during-drag test).
- [ ] **Step 2: Device check (emulator-5554, debug APK).** `adb` is at `"$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"` (not on the shell PATH; Git Bash syntax); confirm a device is attached with `… devices` first. Open the drawer with `adb shell input tap` at the hamburger; confirm the Android back button closes it. For the selected state: try TalkBack (`… shell pm list packages | grep -i talkback`; if present, enable it with `… shell settings put secure enabled_accessibility_services com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService` and `… shell settings put secure accessibility_enabled 1`; ideally on a Google Play image) and listen for / dump the active item's "selected" state. Flutter exposes its accessibility tree only while an accessibility service is active, so a plain `uiautomator dump` may show no Flutter nodes; if neither TalkBack nor a service-backed dump is possible, record that and leave **acceptance criterion 4 unticked** (decision D2).
- [ ] **Step 3: Final verification** (sequential): `fvm dart run melos run lint`, `fvm dart run melos run test`, `fvm flutter build apk --debug` (from `apps/astro_mobile`); record exit codes and counts.
- [ ] **Step 4: Code review** with `requesting-code-review` on the whole branch; fix Critical and Important findings test-first.
- [ ] **Step 5: Docs.** Task file Status → Done (acceptance boxes ticked only for what is verified), `TASKS.md` row, `PROGRESS.md`: the completed row; conventions "Drawer" paragraph (use `showZodiannDrawer`; the version is app-owned and temporary; items are inert until NAV-003; the references are generated; the active colour deviation from MASTER §5); **Navigation → Contract** updated to say the route-contract decision passes to ZOD-DAT-005; deferred minors; Next Recommended Task. Commit `docs(ZOD-NAV-002): close out the drawer`, push, open the PR, record the link.

## Acceptance criteria → proof

| Criterion | Proof |
|---|---|
| Matches `00-navigation-drawer_*` in both languages and both themes | Task 5 (designer dark PNGs; generated light PNGs, labelled as such) |
| All four close interactions | Task 3 tests; Task 6 device back check |
| Never permanent at any breakpoint | Task 4 "never docked" test; M12 |
| Active item "selected" with a screen reader | Task 2 and Task 4 semantics tests; Task 6 device check (a real screen-reader run if possible, else criterion left unticked, D2) |

## Risks

- The "pixel-for-pixel" criterion is met as calibrated ceilings, as in earlier tasks, not as byte equality.
- The route's drag layer is the one piece of new gesture code; Task 3 has the most tests for that reason.
- Android 14+ predictive-back animation is not designed in the references and is out of scope; back still closes the drawer.
- A root `pub get` deletes the tracked l10n output (see Global Constraints).
- The screen-reader criterion may stay unticked (D2).

## Verification record

Recorded 2026-11-17, from the real runs.

**Commands (final, sequential, Windows, Flutter 3.50.0 via FVM)**
- `fvm dart run melos run lint`: exit 0 (analyze clean with `--fatal-infos`, format check 0 changed, l10n and icons up to date).
- `fvm dart run melos run test`: exit 0. astro_core 60, gann_core 196, workspace 296 (includes the architecture guards), astro_mobile 63, shared_ui 634.
- `fvm flutter build apk --debug` (from `apps/astro_mobile`): built `app-debug.apk`.

**Fidelity calibration (Chrome 157.0.8103.78, `ZODIANN_DRAWER_CALIBRATE=1`)**
- Widget against the references: positions within 1 logical px, text-height-driven bottoms 1.5, text x extents 2, text rows 5.0 by the last list item, mean per-pixel difference 4.07. Pinned ceilings: position 1, bottom 2, textX 3, textY 6, mean 9.
- The generator against the designer's own dark renders: positions 0.5, mean 1.2. Pinned ceilings: position 1, bottom 1, textX 2, textY 2, mean 3.
- The text-row drift is Flutter rounding each text line height to whole pixels (a name 20 for 20.3, a description line 17 for 17.4), accumulating over 5 names and 7 description lines. A forced strut did not help. Accepted.

**Mutation proofs (19 mutants, each run against the focused test files)**
- Caught by named tests: M1 header 77, M2 item padding 10, M3a bar 2 px, M3b bar on the end edge, M4 fixed 320 width, M5 close duration 240, M6 swipe not mirrored in RTL (7 RTL swipe tests), M7 backdrop tap ignored, M8 and M17 selected semantics dropped or always passed, M9 non-directional header padding (reference tests), M10 outline ring omitted, M11 reduced motion ignored, M12 a `Scaffold.drawer` wired (never-docked tests), M14 active colour `text`, M15 close curve not flipped, M16 scrim on the default curve, M18 scrim curved during a drag.
- M13 (`semanticsDismissible => true`) survives and is an equivalent mutant: `ModalBarrier` builds a tap or dismiss node only when it has a label, and the route's barrier has none, so the flag changes nothing observable (checked by dumping the semantics tree under the mutant, also with a label added). The test 'the scrim exposes no unlabelled tap target' pins the invariant but does not kill the mutant.
- Finding from the run: M6 hung the runner for 1.5 hours because four swipe tests looped `while (fraction > x)` with no bound. Replaced by `_dragUntil` (at most 200 steps, then a failing `expect`); M6 now fails in 13 s.

**Device check (emulator-5554, Pixel 9 Pro API 35, debug APK)**
- The hamburger opens the drawer; Android Back closes it and the app stays open.
- TalkBack enabled through settings: the accessibility node tree contains only the panel (no "Open menu" from behind the scrim); "Zodiac wheel, Planet positions, aspects and degree crossings" has `selected=true`, the other four items `selected=false`; "Close menu" is labelled; the version and offline lines are present.
- TalkBack's speech could not be captured: the log reports "TTS is not ready". Acceptance criterion 4 therefore stays unticked (decision D2).

**Whole-branch review (opus; a first dispatch on fable stopped on a usage-credit limit before reporting)**
- 0 Critical, 2 Important, 1 Minor. Important 1: grabbing the panel while it opens made it jump from about 80 % to about 51 % open (the gesture ran on the raw controller value while the panel showed the eased one); fixed test-first (`grabbing the panel while it opens does not move it`, LTR and RTL, RED then GREEN) by taking the shown position over at drag start. Important 2: the fling-while-opening test accepted either end state; it now asserts the drawer closes. Minor (deferred, since fixed, see the physical-device audit below): a tap right after a swipe release can fall through to the scrim.
- After the fix: lint exit 0 and the suites above.

**Physical-device audit and the tap-after-release fix (2026-11-17; Samsung SM-S908E, Android 16, 1080 × 2316 at 450 dpi, debug APK from the task branch)**
- On the device (Hebrew, dark; light and English spot-checked): the hamburger opens the drawer; the close button, a backdrop tap and Android Back close it; a slow 33 % drag springs back, a drag past halfway closes, a short fast fling closes, a drag toward the open side does not move the panel, and the panel follows the finger 1:1; an edge swipe while closed opens nothing (by design); the logo renders in light and dark; the Hebrew layout mirrors the designer's `he` reference.
- **Defect found:** a swipe released above halfway followed by an immediate tap on the panel (within about 0.25 s) closed the drawer 5 of 5 times. Cause: the navigator's user gesture stayed open for the whole settle, so the page ignored pointers and the tap reached the scrim.
- **Fix** (`5a8ed15`): the route releases the navigator's user gesture as soon as the panel settles open and keeps its own `_gestureActive` flag until the settle ends, so the motion stays linear. Four new tests (an item tap during the settle reaches the item and the drawer stays open; a tap on the scrim during the settle still closes it; LTR and RTL), RED then GREEN. Mutant M19 (the release removed) is caught by exactly the two "reaches the panel" tests; M6, M7, M11, M15, M16, M18 are still caught and M13 is still the equivalent mutant. Suites after the fix: lint exit 0; astro_core 60, gann_core 196, workspace 296, astro_mobile 63, shared_ui 638; architecture guards 166.
- **Re-check on the device after the fix:** 8 of 8 swipe-then-immediate-taps leave the drawer open; the same swipe then an immediate tap on the scrim still closes it; all the interactions above pass again.
- **Not verified:** acceptance criterion 4 (TalkBack announcing "selected"). On the device TalkBack's speech locale follows the Hebrew system language and the default TTS engine (Samsung SMT) has no Hebrew voice (`Failed to set locale to he_IL`); the spoken text could not be captured. The real accessibility tree under TalkBack shows `selected=true` on the active item only, a labelled "Close menu" button, and no unlabelled or background nodes. Device-level animation timing and reduced motion were also not measured on the device (the widget tests cover both frame by frame).

## Plan review

### Round 1 (2026-11-17)

**Verdict:** Needs user decision (2 items). 3 Critical, 16 Important, 13 Minor.

- **Product-owner decisions taken:** D1 active colour → `accent-strong`; D2 screen reader → try real TalkBack, else leave criterion 4 unticked and record it.
- **Critical (all applied):** C1 the close curve does not flip → `easeOutCubic.flipped` with literal sample values in Facts and Task 3; C2 the default barrier fades on its own curve → own `AnimatedModalBarrier` driven by the panel's animation, plus an in-step test; C3 the hamburger-tap test could not pass (the panel covers it) → replaced with the title-area / hamburger-position / no-controls tests.
- **Important (all applied):** I1 drag drawn linear, gesture start/stop, release rules, `widthFor`, drag regions, no-jump and drag-to-zero tests (Task 3); I2 `wordmark` parameter, app passes `appTitle` (Tasks 2, 4); I3 `navIconNudge`, `drawerFlingVelocity`, border inset via `floatingOutline.width` (Tasks 1, 2); I4 inactive colours and icon start alignment (Facts, Task 2); I5 `selected: widget.selected ? true : null` and a no-selected-state test (Task 1); I6 the double-push guard specified (Task 3); I7 header text clamped at 1.5× (Task 2); I8 the border inside the width, measured columns and rows (Facts, Tasks 2, 5); I9 renderer Chrome flags, extra manifest hashes (Task 5); I10 active-colour assertions on pixels in the PNG and the widget, M14 names (Tasks 5, 6); I11 the whole hamburger assertion and header comment (Task 4); I12 copy resolved inside the builder plus a locale-switch test (Task 4); I13 new `pressable_selected_test.dart` instead of editing NAV-001's file (Task 1); I14 root architecture guards in every task's final run (Global Constraints, Step 4s); I15 route-contract comment and PROGRESS follow-through (Tasks 4, 6); I16 device-check limits and the `adb` path (Task 6).
- **Minor:** M1 (372.1 / 372.09 values), M2 (run commands and expected failures), M3 (`fvm dart run melos run lint`), M4 (shadow order, Task 2), M5 (calibration rule, Task 5), M6 (`SlideTransition(textDirection:)`, live scrim colour), M7 (`semanticsDismissible => false`, no outer exclusion), M8 (drawer-scoped exemption), M9 (`app_version.dart`), M10 (private route), M11 (NAV-005 line), M12 (ring overlap noted), M13 (the pointer fixed): all applied.
- **Open items:** none.

### Round 2 (2026-11-17)

**Verdict:** Needs changes (1 Critical, 4 Important, 10 Minor, no user decisions). Round 1's findings were confirmed resolved except as noted below. All corrections were applied; the plan was **not re-reviewed** (two-round cap), so the applied corrections are unverified by a third reader.

- **C1 (applied):** the sampled fractions came from the polynomial `1 − (1 − t)³`; Flutter's `Curves.easeOutCubic` is `Cubic(0.215, 0.61, 0.355, 1.0)`. Corrected to open 0.600 / 0.875 / 0.976 and close 0.400 / 0.125 / 0.024, with the curve stated in Facts and the literal values kept in the tests.
- **I1 (applied):** one route-owned `_progress` (linear while a gesture is active, otherwise the curved animation) drives both the slide and the barrier; the barrier is a `Builder` (live theme dependency) around an `AnimatedModalBarrier`; `didStopUserGesture()` fires when the settle completes, not on pointer-up; a test and mutant M18 cover the scrim during drag and settle.
- **I2 (applied):** the scrim fades from `scrim.withValues(alpha: 0)`, not `Colors.transparent` (guard) or `ZodiannStates.transparent` (blends from black); an RGB assertion added.
- **I3 (applied):** a fling decides by direction first, then the halfway point; opening-fling tests added.
- **I4 (applied):** Task 5(e) is exact on the designer dark PNGs (`ffffff` / `f4f5f7`, measured) and nearest-token on the generated light PNGs and the widget.
- **Minor (applied):** M1 clamp arithmetic (≤ 51); M2 the 2 px gap applies to every nav child; M3 existing tokens named; M4 root-navigator `Expando` guard covering a popping route, nested-navigator and close-animation tests; M5 harness has a `ZodiannTopBar`; M6 drag-layer placement and ignoring drags while popping; M7 Git Bash `adb` and TalkBack commands, build directory; M8 guard list; M9 shadow-order deviation stated; M10 NAV-004 boundary on the semantics bullet.
- **Open items:** none.
