# ZOD-NAV-001 Sticky Top Bar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every screen sits under one sticky, translucent top bar (MASTER §5, NAV-1). It holds a 46 × 46 hamburger, the screen's title over its subtitle, and the screen's actions, and it mirrors in Hebrew. On the Square screen the actions are Save and Export to Excel, which collapse to two icon buttons on a phone. The hamburger and both actions are visible but disabled until their owning tasks wire them.

**Architecture:**
- **`ZodiannPressable` (`shared_ui`, internal).** `ZodiannButton`'s state machinery is extracted unchanged into it: semantics, focus, hover filter, press, focus ring, disabled opacity and the ≥ 44 touch target. `ZodiannButton` keeps its behaviour, and the UI-004 suites are the regression gate.
- **`ZodiannIconButton` (`shared_ui`).** A 46 × 46 `plain` / `boxed` icon button on `ZodiannPressable`.
- **`ZodiannTopBar` (`shared_ui`).** A route-independent bar. It takes a title, a subtitle, the hamburger's label and callback, and a list of `ZodiannTopBarAction`s.
- **`AppShell` (app).** A go_router `ShellRoute` wraps the five routes in an `AppShell`, which maps the active `AppRoute` to its copy and actions. The body extends behind the bar, so content scrolls under the blur.

**Tech Stack:** Flutter 3.50.0 / Dart 3.14.0 (FVM), material_ui 1.11, go_router ^18.1.4 (`ShellRoute`), `gen-l10n`, `flutter_test`. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-11-15-zod-nav-001-top-bar-design.md` (product-owner decisions, 2026-11-15). Task: `docs/development/navigation/ZOD-NAV-001-implement-the-sticky-top-bar.md`. Design references:
- `design-reference/zodiann/MASTER.md` §5 (top bar), §4 (sizes), §10 (button states), §3 (screen title);
- `_source/kit.css:127-145` (`.topbar`, `.icon-btn`);
- `_source/square.html:40-45` (phone: `--topbar-h: 60px`, `padding-inline: s1 s2`, buttons → icon buttons) and `wheel.html:47-49` / `saved.html` / `settings.html` / `about.html` (phone `padding-inline: s1 s4`);
- `_source/kit.js:18-25, 40, 85-92, 107` (copy) and `:269-277` (`shell()`);
- `screens/02-square-of-nine_dates_desktop_{en,he}_dark.png` and `responsive/mobile/square-of-nine_datetime_mobile_{en,he}_dark.png`.

## Product-owner decisions (2026-11-15)

- **`ZodiannTopBar` in `shared_ui`, independent of the router.** The app shell owns the route → title / subtitle / actions mapping. All five routes are wrapped in one shell now, so NAV-002 and NAV-003 can add the drawer without restructuring navigation. The route-contract question stays open, because the bar never sees a route.
- **`ZodiannIconButton` in `shared_ui`, 46 × 46.** It follows UI-004's hover, press, focus and disabled behaviour exactly, draws through `ZodiannIcon`, and is built for reuse by the drawer close button and the wheel steppers.
- **Copy:** all titles, subtitles, labels and action labels in en and he, from `kit.js` only.
- **Subtitle weight 400**, as kit.css (`.topbar .sub` sets no weight) and the mockups draw it. MASTER §3's Label role says 500 for "subtitles". The discrepancy is recorded in the task Notes and PROGRESS, and MASTER is not edited.
- **Option B:** the hamburger, Save and Export are visible and **disabled** (UI-004's disabled state: 42 %, not focusable, `forbidden` cursor, semantics `enabled: false`) until NAV-002, the saved-squares task and the Excel task wire them. The phone Square screen still shows its two icon buttons.
- **Out of scope:** the drawer, saving and export.

## Facts established while planning (2026-11-15)

- **Design geometry** (kit.css; the top-bar border is part of its height, `box-sizing: border-box`):

  | | Regular (≥ 700) | Phone (< 700) |
  |---|---|---|
  | Height (incl. 1 px `line-soft` bottom rule) | 64 | 60 |
  | `padding-inline` start / end | 12 / 24 | 4 / 16, or 4 / 8 on Square (actions present) |
  | Hamburger box | 46 × 46, radius 8 | same |
  | Gap hamburger → titles | 12 | 12 |
  | Gap between actions | 8 | 8 |

  - **Desktop (1440):** the hamburger box is x 12–58, the titles start at x 70, and Export's right edge is x 1416.
  - **Phone (390):** the hamburger box is x 4–50, the titles start at x 62. On Square, download's box is x 336–382 and bookmark's is x 282–328.
  - Hebrew mirrors all of these. The PNGs agree by eye: desktop en title at ~70, Export ending at ~1416; mobile en bookmark centred near 305 and download near 359.
- **Phone breakpoint:** `ZodiannBreakpoint.forWidth` (< 700 is phone, MASTER §6). The HTML uses `max-width: 700px` (≤ 700); MASTER and the existing token win, as in UI-003.
- **Phone actions:** the icon buttons are plain `.icon-btn` (46 × 46, transparent, no border), in the same order as the regular buttons: Save (`save.svg`, the bookmark), then Export (`download.svg`). Regular Save is a secondary `ZodiannButton` with the `save` icon, and Export is primary with `download`.
- **Only Square has actions** (`kit.js` `shell({ end })` is empty on the other four screens).
- **Hover:** UI-004 ruled that MASTER §10 and the component sheet win over kit.css `:hover` colours, so hover is `brightness(1.12)`. kit.css's `.icon-btn:hover { background: surface-2 }` loses the same way. On a transparent icon button the filter only lifts the icon, which is barely visible on dark `text`. This follows "UI-004's behaviour exactly" and is recorded as a known consequence.
- **Blur:** CSS `backdrop-filter: blur(10px)` is a Gaussian with σ = 10 px, so `ImageFilter.blur(sigmaX: 10, sigmaY: 10)`. Background: `color-mix(bg 88%, transparent)` is `bg` at alpha 0.88.
- **Existing app tests:**
  - `find.byType(ScreenStub)` and `app_shell_test`'s first `Material` under `find.byType(Scaffold)` stay valid with an outer shell `Scaffold` (the shell's own `Material` is found first).
  - **Three "blank screen" assertions break once the bar draws text:** `app_shell_test.dart` "boots with no overrides to a blank themed screen", and `app_router_test.dart` "boots to the wheel" and "every route resolves to its blank stub", each `expect(find.byType(Text), findsNothing)`. Task 4 narrows exactly those three to `find.descendant(of: find.byType(ScreenStub), matching: find.byType(Text))`. Their intent, a blank stub, is unchanged, and no other line is edited.
- **Reference measurements** (review round 1, decoded PNGs; the executor's sanity check):
  - desktop en: rule at row 63, hamburger ink x 27–42, title ink from x 70, Save 1164–1251, Export 1260–1415 (rows 12–51); desktop he hamburger ink 1397–1412;
  - mobile en (device px, DPR 2): rule at rows 118–119, hamburger ink 39–68, title from 125, bookmark ink 600–619, download ink 705–730.
- **go_router 18.1.4:** in a `ShellRoute` builder, `state.topRoute` is the leaf `GoRoute` (`match.dart:325–336`), and the shell page persists across child `go`s.
- **Scaffold:** the app bar gets at most its preferred height + `padding.top` and is laid out at its actual height. With `extendBodyBehindAppBar`, the body's `MediaQuery.padding.top` equals the bar's height.

## Global Constraints

- **Tokens only** in `lib/`: sizes from `ZodiannSize` / `ZodiannSpace` / `ZodiannRadius`, colours from `ZodiannSurfaces`, text from `ZodiannTextStyles` roles. The UI-003 dimension guard and the colour guard stay green.
- **Logical layout only:** `EdgeInsetsDirectional`, `AlignmentDirectional`, `Row` order. No `left` / `right` and no manual RTL swapping.
- **No user-visible literal text in `lib/`** (L10-001 guard). Every string comes from `ZodiannLocalizations`.
- **Copy:** ARB values verbatim from `kit.js`. Keys are camelCase with a `description` in `app_en.arb`; `app_he.arb` has no metadata.
- **No new dependency.** `test/architecture/no_network_test.dart` and the other guards are unchanged.
- **Commands:** `fvm dart …` / `fvm flutter …` from PowerShell. Melos as `fvm dart run melos run <script>`. Regenerate l10n with `fvm flutter gen-l10n` in `packages/shared_ui`.

## Out of scope

- The drawer, its open / close, and the hamburger's expanded / collapsed state (NAV-002, NAV-004).
- Save (the saved-squares task) and Export (the Excel task) behaviour.
- The real screens. Their content uses the shell's top inset when they are built.
- The small (36) icon-button size, until a screen needs it.

## Review Focus

1. **Longest copy on the narrowest phone.** Hebrew Settings' subtitle "שפה, ערכת נושא, אורבים וברירות מחדל", or Square with both actions at 320 px wide, ellipsizes the title and subtitle. No overflow. *Test: Task 3 "narrow phone ellipsizes, no overflow".*
2. **Large text scale.** At `textScaler` 2.0 the bar keeps its 64 / 60 height and nothing overflows. Bar text clamps at a 1.5 text scale ((21.6 + 17.4) × 1.5 = 58.5 ≤ 59 px of phone content). *Test: Task 3.*
3. **A status-bar / notch inset.** The bar's content sits below `MediaQuery.padding.top`, and its translucent background covers the inset. *Test: Task 3.*
4. **The breakpoint boundary.** 699.9 is phone (60, icon buttons) and 700 is regular (64, labelled buttons). *Test: Task 3.*
5. **Navigation.** Switching routes keeps the same bar element, so nothing flickers or resets, and the title updates. The body extends behind the bar with a top inset equal to the bar's height. *Test: Task 4.*

---

**Before Task 1:** the reviewed plan and the design doc are committed on `task/ZOD-NAV-001-sticky-top-bar` (`docs(ZOD-NAV-001): plan and design`).

### Task 1: Extract `ZodiannPressable` from `ZodiannButton` (behaviour unchanged)

**Files:**
- Create: `packages/shared_ui/lib/src/widgets/zodiann_pressable.dart`
- Modify: `packages/shared_ui/lib/src/widgets/zodiann_button.dart`
  - Lines 75–234 (`_ZodiannButtonState.build`'s interaction stack) become a `ZodiannPressable`.
  - Lines 236–349 (`_TouchTarget`, `_brightness`, `ZodiannFocusRingPainter`) move to the new file.
  - `zodiann_button.dart` re-exports `ZodiannFocusRingPainter` (`export 'zodiann_pressable.dart' show ZodiannFocusRingPainter;`), so `button_behavior_test.dart:13`'s import still works.
- Test: the existing UI-004 suites, **unchanged** (`button_test`, `button_behavior_test`, `button_colors_test`, `button_sheet_test`), plus `packages/shared_ui/test/widgets/pressable_test.dart`.

**Interfaces:**
- Produces, in `zodiann_pressable.dart` (not exported from the barrel; `ZodiannFocusRingPainter` stays `@visibleForTesting` and barrel-hidden):
  - `class ZodiannPressable extends StatefulWidget { const ZodiannPressable({super.key, required this.onPressed, required this.semanticLabel, required this.child, this.focusNode, this.autofocus = false}); final VoidCallback? onPressed; final String semanticLabel; final Widget child; final FocusNode? focusNode; final bool autofocus; }`
  - It owns everything `_ZodiannButtonState.build` does today around the drawn box: `Semantics(container, button, enabled, label, onTap)`, `FocusableActionDetector` (`ActivateIntent`, the cursor), `MouseRegion`, `GestureDetector`, `_TouchTarget`, `ExcludeSemantics`, `Opacity`, `Transform.translate`, the focus-ring `CustomPaint`, and the brightness `TweenAnimationBuilder`. `child` is the drawn box.

- [ ] **Step 1: Write `pressable_test.dart`.** It drives `ZodiannPressable` directly with a 40 × 40 coloured box as `child`:
  - `'disabled: 42 % opacity, not focusable, forbidden cursor, enabled: false'`
  - `'tap and Enter / Space call onPressed once each'`
  - `'pressed moves the child 1 px down and applies 0.94 brightness'`
  - `'hover eases to 1.12 over 150 ms; instant under disableAnimations'`
  - `'keyboard focus shows the ring; a pointer tap does not'`
  - `'a 40 × 40 child gets a 44 × 44 hit box, centred'`

  Expected values come from `ZodiannStates` and `ZodiannSize.minTouchTarget`.
- [ ] **Step 2: Run and verify it fails.** In `packages/shared_ui`, run `fvm flutter test test/widgets/pressable_test.dart`. Expected: compile failure, `zodiann_pressable.dart` not found.
- [ ] **Step 3: Implement.** Move the code verbatim. `ZodiannButton` keeps building its `drawn` box and returns `ZodiannPressable(onPressed: widget.onPressed, semanticLabel: widget.label, focusNode: widget.focusNode, autofocus: widget.autofocus, child: drawn)`. Its `didUpdateWidget` pressed reset moves into the pressable's state. No behaviour change.
- [ ] **Step 4: Run and verify.**
  - `fvm flutter test test/widgets` → all pass: the pressable suite and every UI-004 suite **with no test edited**.
  - `git diff --stat -- ':/packages/shared_ui/test/widgets/button_*' ':/packages/shared_ui/test/support/button_*'` must print nothing. The `:/` prefix makes the paths root-relative from any directory.
- [ ] **Step 5: Gate, then commit.** From the workspace root, `fvm dart run melos run lint` → exit 0 and `fvm dart test test/architecture` → all pass. Then commit: `refactor(ZOD-NAV-001): extract ZodiannPressable from ZodiannButton`.

---

### Task 2: `ZodiannIconButton`

**Files:**
- Create: `packages/shared_ui/lib/src/widgets/zodiann_icon_button.dart`
- Modify: `packages/shared_ui/lib/shared_ui.dart` (export it, alphabetical)
- Test: `packages/shared_ui/test/widgets/icon_button_test.dart`

**Interfaces:**
- Consumes: `ZodiannPressable` (Task 1), `ZodiannIcon` / `ZodiannIcons` / `iconBack` (FND-009).
- Produces:
  - `enum ZodiannIconButtonVariant { plain, boxed }`
  - `class ZodiannIconButton extends StatelessWidget { const ZodiannIconButton({super.key, required this.icon, required this.semanticLabel, required this.onPressed, this.variant = ZodiannIconButtonVariant.plain, this.focusNode, this.autofocus = false}); final Widget icon; … }`
  - `icon` is a `Widget`, so `iconBack()` works for the wheel steppers.
- **Drawn box:**
  - `ZodiannSize.iconButton` square (46), radius `ZodiannRadius.md` (8);
  - `plain`: no fill (decoration colour null, or `ZodiannStates.transparent`; never `Colors.transparent`, which the colour guard rejects) and no border (kit.css `.icon-btn`);
  - `boxed`: `surface` fill, 1 px `line` border (`.icon-btn.boxed`);
  - the icon is centred in `IconTheme(size: ZodiannSize.icon, color: surfaces.text)`;
  - everything else comes from `ZodiannPressable`, with `semanticLabel` as the label.

- [ ] **Step 1: Write `icon_button_test.dart`**, in both themes unless stated:
  - `'46 × 46 box, hit box 46 × 46 (already ≥ 44)'`
  - `'icon is 20 px, centred, text colour'`: read the `ZodiannIconPainter` and check `size == 20` and `color == text`. The icon's centre equals the box's centre.
  - `'plain is transparent with no border; boxed is surface with a 1 px line border, radius 8'`
  - `'labelled for screen readers; disabled when onPressed is null'`: `matchesSemantics(label:, isButton: true, isEnabled: …, hasEnabledState: true)`.
  - `'states are UI-004's'`: brightness 1.12 on hover (eased 150 ms), 0.94 and +1 px when pressed, the keyboard focus ring with radius 8 + outset, 0.42 opacity disabled.
  - `'iconBack() inside flips with Directionality'`: it resolves to chevR under RTL.
- [ ] **Step 2: Run and verify it fails.** `fvm flutter test test/widgets/icon_button_test.dart` → compile failure.
- [ ] **Step 3: Implement** `ZodiannIconButton`.
- [ ] **Step 4: Run and verify** that `fvm flutter test test/widgets` passes.
- [ ] **Step 5: Mutation proofs.** Each must fail the named test; then revert.
  - I1: box 44 instead of `iconButton` (size test).
  - I2: icon `iconSmall` (icon test).
  - I3: boxed border `lineSoft` (variant test).
  - I4: bypass `ZodiannPressable` and use a bare `GestureDetector` (states test).
- [ ] **Step 6: Gate, then commit.** `fvm dart run melos run lint` → exit 0 and `fvm dart test test/architecture` → all pass (from the root). Then commit: `feat(ZOD-NAV-001): ZodiannIconButton (plain / boxed, 46 × 46, UI-004 states)`.

---

### Task 3: `ZodiannTopBar`

**Files:**
- Create: `packages/shared_ui/lib/src/widgets/zodiann_top_bar.dart`
- Modify:
  - `packages/shared_ui/lib/src/theme/tokens/zodiann_dimensions.dart`: add `ZodiannSize.topBar = 64.0` and `ZodiannSize.topBarPhone = 60.0`, with MASTER §5 doc comments.
  - `dimensions_test.dart`: extend the typed MASTER table with both, and add `'topbar-h': ZodiannSize.topBar` to the kit.css `:root` cross-check map (~line 141).
  - `packages/shared_ui/lib/shared_ui.dart`: export the top bar.
- Test: `packages/shared_ui/test/widgets/top_bar_test.dart`, `packages/shared_ui/test/widgets/top_bar_reference_test.dart`

**Interfaces:**
- Consumes: `ZodiannIconButton` (Task 2), `ZodiannButton` (UI-004), `ZodiannIcons` (FND-009).
- Produces:
  - `final class ZodiannTopBarAction { const ZodiannTopBarAction({required this.icon, required this.label, required this.onPressed, this.variant = ZodiannButtonVariant.secondary}); final ZodiannIconData icon; final String label; final VoidCallback? onPressed; final ZodiannButtonVariant variant; }`
  - `class ZodiannTopBar extends StatelessWidget implements PreferredSizeWidget { const ZodiannTopBar({super.key, required this.title, required this.subtitle, required this.menuLabel, required this.onMenuPressed, this.actions = const []}); … }`
  - `preferredSize` (64) is nominal. The shell sizes the bar per breakpoint through `ZodiannTopBar.heightFor`, and the Scaffold lays the app bar out at its actual height.
  - `static double heightFor(double width)`: `ZodiannSize.topBarPhone` when `ZodiannBreakpoint.forWidth(width) == ZodiannBreakpoint.phone`, else `ZodiannSize.topBar`, so the breakpoint rule exists once.
- **Layout** (MediaQuery width → phone or regular), top to bottom:
  - `AnnotatedRegion<SystemUiOverlayStyle>`: `SystemUiOverlayStyle.dark` (dark icons) when `Theme.of(context).brightness == Brightness.light`, else `.light`, both with `statusBarColor: ZodiannStates.transparent`. The bar covers the status bar, and no `AppBar` sets this for us.
  - `ClipRect` → `BackdropFilter(ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma))`;
  - `Container(height: MediaQuery.paddingOf(context).top + heightFor(width), decoration: BoxDecoration(color: surfaces.bg.withValues(alpha: _backdropAlpha), border: Border(bottom: BorderSide(color: surfaces.lineSoft))), padding: EdgeInsetsDirectional.only(top: MediaQuery.paddingOf(context).top, start: s3 | s1, end: s6 | (actions.isEmpty ? s4 : s2)), child: Row(…))`.
    - `Container` adds the 1 px border to its padding (border-box, as kit.css), so the row gets `heightFor(width) − 1` with no literal.
    - `Container(height:)` is a documented gap of the dimension guard. A `SizedBox(height: … − 1)` would trip the guard, and a `DecoratedBox` border would overlap the content, giving a 63 / 59 bar.
  - The row holds:
    - `ZodiannIconButton(icon: ZodiannIcon(ZodiannIcons.menu), semanticLabel: menuLabel, onPressed: onMenuPressed)`;
    - a `s3` gap;
    - `Expanded` titles: a `Column` with the title (`screenTitle`, 1 line, ellipsis, `Semantics(header: true)`) over the subtitle (`label.copyWith(fontWeight: FontWeight.w400, color: text2)`, 1 line, ellipsis);
    - when `actions` is non-empty, a `SizedBox(width: ZodiannSpace.s3)` before the first action (kit.css flex `gap: s3`);
    - the actions with an `s2` gap. Regular: `ZodiannButton(label:, variant:, icon: ZodiannIcon(icon), onPressed:)`. Phone: `ZodiannIconButton(icon: ZodiannIcon(icon), semanticLabel: label, onPressed:)`.
  - The bar's text clamps at `MediaQuery.withClampedTextScaling(maxScaleFactor: _maxTextScale)`.
  - Named constants in the file, with references:
    - `_backdropAlpha = 0.88` and `_blurSigma = 10.0` (kit.css);
    - `_maxTextScale = 1.5` ("(21.6 + 17.4) × 1.5 = 58.5 ≤ 59, the phone row").

- [ ] **Step 1: Write `top_bar_test.dart`.** Pump it under the Zodiann themes, at widths 1440 / 699.9 / 700 / 390 / 320 via `tester.view`.
  - **Harness:** pump the bar as `Scaffold(appBar: PreferredSize(preferredSize: Size.fromHeight(ZodiannTopBar.heightFor(width)), child: bar))`, as `AppShell` does.
  - **Background:** the test reads `find.descendant(of: find.byType(ZodiannTopBar), matching: find.byType(DecoratedBox)).first`.
  - The tests:
  - `'height 64 regular, 60 phone; 699.9 is phone, 700 is regular'`
  - `'hamburger is 46 × 46 at the start: LTR left 12 (phone 4), RTL right 12 (phone 4)'`
  - `'order from the start: hamburger, titles (start at 70 / 62), actions at the end'`, in LTR and mirrored in RTL (positions via `getTopLeft` / `getTopRight`).
  - `'end padding: 24 regular; phone 16 without actions, 8 with'`
  - `'title is screenTitle 18/600; subtitle is 12/400 text2'`
  - `'regular actions are ZodiannButtons with icon + label + variant; phone actions are ZodiannIconButtons labelled with the action label, same order'`
  - `'null callbacks render disabled: hamburger and actions enabled: false, 42 % opacity'`
  - `'background: bg at 0.88 behind a σ 10 blur, 1 px lineSoft bottom rule'`: inspect the `BackdropFilter` and `DecoratedBox`.
  - `'title is a header; hamburger is labelled menuLabel'`
  - `'status-bar inset: content below padding.top; background covers it'`: with `MediaQuery.padding.top` 24, the bar is 24 + 64.
  - `'textScaler 2.0: height unchanged, no overflow'` at 700 (labelled Save and Export, en and he) and at 320 (phone icon buttons, Hebrew Settings copy) (Review Focus 2).
  - `'narrow phone ellipsizes, no overflow'`: 320 px wide, Hebrew Settings strings plus two actions. The titles' end edge keeps ≥ 12 px to the first action (Review Focus 1).
  - `'only logical layout: no mirroring transform, positions mirror exactly'`:
    - every `Transform` under the bar (each pressable has a press `Transform.translate`) has x-translation 0 and no negative scale;
    - for each child, RTL left = width − LTR right.
  - `'status-bar icons contrast with the bar'`: the `AnnotatedRegion<SystemUiOverlayStyle>` value has dark icons on Porcelain and light icons on Graphite, with a transparent status bar.
  - `'the clip keeps the keyboard focus ring'` (optional): Tab to the phone hamburger and to the last action; the ring's painted bounds lie inside the bar.
- [ ] **Step 2: Write `top_bar_reference_test.dart`.** Load the real fonts (`test/support/load_bundled_fonts.dart`).
  - Render `ColoredBox(color: surfaces.bg, child: ZodiannTopBar(…))` in a `RepaintBoundary`, so the 88 % fill composites over `bg` as in the PNGs.
    - `title` / `subtitle` come from the ARB copy ("Gann Square of Nine" / "Spiral, angles and highlights", and the he equivalents).
    - The hamburger and both actions are **enabled** no-ops, so the comparison is like for like.
  - The ink threshold is relative to the bar's own background pixel, sampled the same way in both images.
  - Tolerance: 1 logical px = 1 device px at DPR 1 and 2 device px at DPR 2.
  - Compare only the PNG's top 64 / 120 device rows.
  - Render and compare at these sizes:
    - at 1440 × 64, DPR 1, against `screens/02-square-of-nine_dates_desktop_{en,he}_dark.png`;
    - at 390 × 60, DPR 2, against `responsive/mobile/square-of-nine_datetime_mobile_{en,he}_dark.png`.
  - Measure the same features on the PNG and on our render with one extractor, in the style of `reference_layout_test.dart`'s scan lines. Each must be within 1 logical px:
    - (a) the bottom rule's row;
    - (b) the hamburger icon's ink bounding box;
    - (c) the title ink's start edge;
    - (d) each action's box edges (regular: the button box; phone: the icon ink box).
- [ ] **Step 3: Run and verify both fail.** `fvm flutter test test/widgets/top_bar_test.dart test/widgets/top_bar_reference_test.dart` → compile failure.
- [ ] **Step 4: Implement** the tokens, `ZodiannTopBarAction`, `ZodiannTopBar` and the exports.
- [ ] **Step 5: Run and verify.**
  - `fvm flutter test` in `packages/shared_ui` passes.
  - If a reference measurement misses by more than 1 px, debug first (superpowers:systematic-debugging). Never widen the tolerance without recording why.
- [ ] **Step 6: Mutation proofs.** Each must fail; then revert.
  - T1: `EdgeInsets.only(left:)` instead of directional padding (RTL mirror test).
  - T2: phone height 64 (height test).
  - T3: subtitle w500 (style test).
  - T4: phone end padding always s4 (padding test).
  - T5: no text clamp (text-scale test).
  - T6: actions shown as buttons on phone (phone actions test, reference d).
  - T7: hamburger box 44 (hamburger test, reference b).
  - T8: drop the `AnnotatedRegion` (status-bar test).
  - T9: a `DecoratedBox` border with a `SizedBox(height: h − 1)` row (height test: the bar measures 63; and the dimension guard).
- [ ] **Step 7: Gate, then commit.** `fvm dart run melos run lint` → exit 0 and `fvm dart test test/architecture` → all pass (from the root). Then commit: `feat(ZOD-NAV-001): ZodiannTopBar (sticky translucent bar, responsive actions, RTL)`.

---

### Task 4: App shell, route copy and the translations

**Files:**
- Modify:
  - `packages/shared_ui/lib/l10n/app_en.arb` and `app_he.arb`: 13 keys, values verbatim from `kit.js`.
  - The generated `zodiann_localizations*.dart`, regenerated with `fvm flutter gen-l10n`.
- Create: `apps/astro_mobile/lib/src/navigation/app_shell.dart`
- Modify:
  - `apps/astro_mobile/lib/src/navigation/app_router.dart`: one `ShellRoute` around the five `GoRoute`s, unchanged otherwise (redirect, initial location).
  - `apps/astro_mobile/lib/src/navigation/app_route.dart`: no new public members. Its contract doc becomes: "NAV-001's bar is route-independent; the contract decision passes to the first feature-side navigation (DAT-005) or NAV-002."
  - `apps/astro_mobile/lib/src/app.dart`: the doc comment says the shell (with the top bar) is in place, and the drawer comes in NAV-002.
  - `apps/astro_mobile/test/app_shell_test.dart` and `apps/astro_mobile/test/navigation/app_router_test.dart`: **only** the three `find.byType(Text)` → `findsNothing` assertions are narrowed to `find.descendant(of: find.byType(ScreenStub), matching: find.byType(Text))`.
- Test: `apps/astro_mobile/test/navigation/top_bar_shell_test.dart` (new) and `packages/shared_ui/test/l10n/screen_copy_test.dart` (new). `l10n_test.dart` and `theme_switch_test.dart` are unchanged.

**Keys** (en / he):

| Key | en | he |
|---|---|---|
| `screenWheelTitle` | Zodiac wheel | גלגל המזלות |
| `screenWheelSubtitle` | Tropical geocentric positions | מיקומים גאוצנטריים טרופיים |
| `screenSquareTitle` | Gann Square of Nine | ריבוע התשע של גאן |
| `screenSquareSubtitle` | Spiral, angles and highlights | ספירלה, זוויות והדגשות |
| `screenSavedTitle` | Saved squares | ריבועים שמורים |
| `screenSavedSubtitle` | Stored on this device | שמורים במכשיר הזה |
| `screenSettingsTitle` | Settings | הגדרות |
| `screenSettingsSubtitle` | Language, theme, orbs and defaults | שפה, ערכת נושא, אורבים וברירות מחדל |
| `screenAboutTitle` | About and sources | אודות ומקורות |
| `screenAboutSubtitle` | Version, sources and method | גרסה, מקורות ושיטה |
| `openMenu` | Open menu | פתיחת תפריט |
| `actionSave` | Save | שמירה |
| `actionExportXlsx` | Export to Excel | ייצוא לאקסל |

**Interfaces:**
- Consumes: `ZodiannTopBar`, `ZodiannTopBarAction` (Task 3), `AppRoute`, `buildAppRouter` (FND-014).
- Produces, in `app_shell.dart`:
  - `class AppShell extends StatelessWidget { const AppShell({super.key, required this.route, required this.child}); final AppRoute route; final Widget child; }` → `Scaffold(extendBodyBehindAppBar: true, appBar: PreferredSize(preferredSize: Size.fromHeight(ZodiannTopBar.heightFor(width)), child: ZodiannTopBar(…)), body: child)`.
  - The hamburger is `onMenuPressed: null` (NAV-002), with the label `openMenu`.
  - Square's actions: `ZodiannTopBarAction(icon: ZodiannIcons.save, label: actionSave, onPressed: null)` (secondary) and `ZodiannTopBarAction(icon: ZodiannIcons.download, label: actionExportXlsx, variant: ZodiannButtonVariant.primary, onPressed: null)`. The other routes have none.
  - `extension AppRouteCopy on AppRoute { String title(ZodiannLocalizations l); String subtitle(ZodiannLocalizations l); }`: exhaustive `switch`.
  - The router: `ShellRoute(builder: (context, state, child) => AppShell(route: <state.topRoute?.path → AppRoute, wheel if none>, child: child), routes: [ …the five GoRoutes… ])`.

- [ ] **Step 1a: Write `packages/shared_ui/test/l10n/screen_copy_test.dart`** (`'kit.js agrees'`).
  - The 13 `ZodiannLocalizations` getters for en / he equal kit.js `wheel`, `wheelSub`, …, `openMenu`, `save`, `exportXlsx`, parsed as `entity_names_test.dart:153` does.
  - In `packages/shared_ui`, run `fvm flutter test test/l10n/screen_copy_test.dart`. Expected: compile failure, getters such as `screenWheelTitle` are undefined.
- [ ] **Step 1: Add the 13 ARB keys** (with `description`s in `app_en.arb`), then run `fvm flutter gen-l10n` in `packages/shared_ui` and re-run `screen_copy_test.dart` (passes). Then, from the workspace root:
  - `fvm dart run melos run l10n:check` → exit 0;
  - `fvm dart test test/architecture/l10n_key_parity_test.dart test/architecture/no_text_literals_test.dart` → all pass.
- [ ] **Step 2: Write `test/navigation/top_bar_shell_test.dart`**, with the router pumped as in `app_router_test.dart`'s `_pumpApp`:
  - `'every route shows its title and subtitle (en)'` and `'(he)'`: all five, literal strings from the table.
  - `'the bar is the same element across navigation'`: `go('/saved')` then `go('/square')`; `tester.element(find.byType(ZodiannTopBar))` is identical, and the title updates.
  - `'Square has Save and Export, disabled; other screens have no actions'`
  - `'phone Square shows two disabled icon buttons labelled Save / Export'`: width 390; semantics labels from the ARB.
  - `'hamburger is disabled and labelled Open menu (פתיחת תפריט in he)'`
  - `'deep link /square cold-starts with the Square bar; an unknown route shows the wheel bar'`
  - `'the body extends behind the bar: the screen's MediaQuery top padding equals the bar height'` (64 at 1440, 60 at 390).
  - `'content scrolls under a fixed bar'`:
    - Pump `ZodiannApp` with `appRouterProvider` overridden by `GoRouter(routes: [ShellRoute(builder: (_, _, child) => AppShell(route: AppRoute.wheel, child: child), routes: [GoRoute(path: '/', builder: (_, _) => Scaffold(body: ListView.builder(itemExtent: 48, itemCount: 100, itemBuilder: (_, i) => ColoredBox(key: ValueKey(i), color: const Color(0xFF808080)))))])])`. Test code is outside the colour guard.
    - Before dragging, item 0's top equals the bar's bottom (64 at the default 800-wide view).
    - After `tester.drag(find.byType(ListView), const Offset(0, -30))` and `pumpAndSettle`, the bar's rect is unchanged, and item 0's rect overlaps the bar's rect (top < bar bottom, bottom > bar top).
- [ ] **Step 3: Run and verify it fails.** In `apps/astro_mobile`, run `fvm flutter test test/navigation/top_bar_shell_test.dart` → compile failure (`AppShell`).
- [ ] **Step 4: Implement** `AppShell`, `AppRouteCopy` and the `ShellRoute`.
- [ ] **Step 5: Run and verify.**
  - `fvm flutter test` in `apps/astro_mobile`: all pass.
  - `git status --short -- :/apps/astro_mobile/test` lists exactly `M test/app_shell_test.dart`, `M test/navigation/app_router_test.dart` and `?? test/navigation/top_bar_shell_test.dart` (paths relative to the cwd).
  - `git diff -- :/apps/astro_mobile/test` shows only the three `find.byType(Text)` → `find.descendant(of: find.byType(ScreenStub), matching: find.byType(Text))` line changes.
  - `fvm dart run melos run test`: workspace green, including the text-literal, dimension and network guards.
- [ ] **Step 6: Mutation proofs.** Each must fail; then revert.
  - S1: `GoRoute`s not inside the `ShellRoute`, with the bar built per screen (same-element test).
  - S2: Square actions with no-op callbacks instead of null (disabled test).
  - S3: `extendBodyBehindAppBar: false` (body-inset test).
  - S4: swap two Hebrew values (`top_bar_shell_test` he copy test and `screen_copy_test`).
- [ ] **Step 7: Gate, then commit.** `fvm dart run melos run lint` → exit 0 (the full `melos run test` already ran in Step 5). Then commit: `feat(ZOD-NAV-001): app shell with the top bar on every route; screen copy en/he`.

---

### Task 5: Review and close-out

**Files:**
- Modify: the task file (status; Notes recording the subtitle-weight deviation, Option B, and the hover consequence on a transparent icon button), `docs/development/TASKS.md`, `docs/PROGRESS.md`. In PROGRESS:
  - Completed Tasks, Verification, Git State, Technical Decisions;
  - an **App shell** block under Architecture Conventions:
    - screens render inside `AppShell`;
    - the body extends behind the bar, so scroll views use the inherited top padding, and a scroll view with its own `padding` must add `MediaQuery.paddingOf(context).top` itself;
    - actions go through `ZodiannTopBarAction`, disabled until wired;
  - the Navigation "Contract" bullet updated: NAV-001's bar is route-independent, and the decision passes to DAT-005 or NAV-002;
  - the PR #25 merge recorded in Git State.

- [ ] **Step 1: Whole-branch code review** (superpowers:requesting-code-review). Fix Critical / Important findings test-first. Record deferred minors.
- [ ] **Step 2: Verification** (superpowers:verification-before-completion). Run sequentially in the foreground, with no background runs: `fvm dart run melos run lint`, then `fvm dart run melos run test`. Record the exit codes and counts.
- [ ] **Step 3: Docs, commit, push, PR, record the PR link** (zodiann-development Step 8). Never stage `.fvmrc`.

---

## Open items for approval

None. Calls made while planning, for you to check:
- `ZodiannPressable` is extracted from `ZodiannButton` rather than duplicated, so "exactly UI-004's behaviour" is one implementation. UI-004's tests are the unchanged gate.
- The icon button has `plain` + `boxed` variants now; small (36) is deferred.
- Phone end padding is 8 when actions are present and 16 otherwise, as the HTML sources draw it.
- Bar text clamps at a 1.5 text scale, so the fixed 64 / 60 bar never overflows.
- The breakpoint is < 700 (MASTER / token), not the HTML's ≤ 700.

## Plan review

### Round 1: Approve after corrections (2 Critical, 5 Important, 9 Minor, 0 Needs user decision)

| ID | Severity | Finding | Action |
|---|---|---|---|
| C1 | Critical | Three existing app tests assert no `Text` anywhere and break once the bar has text | Applied: only those three assertions are narrowed to `ScreenStub`, with a diff check; Facts corrected |
| C2 | Critical | A `DecoratedBox` border with a `SizedBox(h − 1)` row gives a 63 / 59 bar and trips the dimension guard | Applied: `Container(height: top + h)` with a bottom border (border-box); mutation T9 |
| I1 | Important | "No Transform" fails on correct code (the pressable's press translate) | Applied: no *mirroring* transform (x-translation 0, no negative scale) plus position mirroring |
| I2 | Important | `tool/check_l10n.dart` was run from the package directory | Applied: `melos run l10n:check` and the root guard tests, from the root |
| I3 | Important | Commits skipped lint and the root guards | Applied: a lint + `test/architecture` gate before every task commit |
| I4 | Important | The status-bar icon style is unset once the bar covers the inset (light theme unreadable) | Applied: `AnnotatedRegion<SystemUiOverlayStyle>` per brightness, a test, mutation T8 |
| I5 | Important | The reference check wasn't like for like (no `bg` underneath, disabled hamburger, tolerance in device px) | Applied: `ColoredBox(bg)`, enabled hamburger, a relative ink threshold, DPR-aware tolerance, top rows only; measured values added to Facts |
| M1–M9 | Minor | `ZodiannStates.transparent`; wider diff check; kit.css `topbar-h` pin; named widths for the text-scale test; scroll-under test; kit.js copy test; stale docs; `heightFor` via `ZodiannBreakpoint`; focus ring inside the clip | All applied |

### Round 2: Approve after corrections (0 Critical, 2 Important, 5 Minor, 0 Needs user decision)

All round-1 corrections were verified as applied, with no contradictions.

| ID | Severity | Finding | Action |
|---|---|---|---|
| I1 | Important | The "no test edited" diff checks were vacuous when run from a package directory, and `git diff` never lists untracked files | Applied: `:/` root-relative pathspecs, plus a `git status --short` expectation |
| I2 | Important | The scroll-under test left its harness to the executor and its assertion passed even when the item had scrolled off-screen | Applied: an explicit `appRouterProvider` override with a `ListView`; asserts the initial offset at the bar's bottom and an overlap after the drag |
| M1 | Minor | `screen_copy_test` was not in Files and not written first | Applied: in Files, as Step 1a before the ARB keys (RED: undefined getters), and named in S4 |
| M2 | Minor | No titles → actions gap (kit.css flex `gap: s3`) | Applied: an `s3` gap before the first action; the narrow test checks ≥ 12 px |
| M3 | Minor | The 1.5 clamp was an inline literal | Applied: `_maxTextScale` |
| M4 | Minor | The `top_bar_test` harness and `DecoratedBox` finder were under-specified | Applied: a `Scaffold` + `PreferredSize` harness; `.first` under the bar |
| M5 | Minor | Two test files named `app_shell_test.dart` | Applied: the new one is `top_bar_shell_test.dart` |

Two rounds done (the cap). No open items. The plan awaits the product owner's approval.
