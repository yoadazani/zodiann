# ZOD-UI-003 Spacing, Radius, Elevation and Sizing Tokens Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Define MASTER.md §4's spacing scale, per-breakpoint layout values, radius scale, floating-layer elevation and control/icon sizes once, in `shared_ui`, with a guard against layout magic numbers. Prove the panel spacing with a measured render, and cross-check it against the reference screenshots.

**Architecture:**
- **Theme-independent constants** live in one new file, `packages/shared_ui/lib/src/theme/tokens/zodiann_dimensions.dart`:
  - `ZodiannSpace`: the 4-based scale;
  - `ZodiannRadius`: the scale plus the semantic `BorderRadius` values;
  - `ZodiannSize`: control heights and icons;
  - `ZodiannBreakpoints`.

  The `tokens/` directory is already the one place literals are allowed (ARCH-7), and the new guard uses the same exemption.
- **Breakpoint-dependent values:** `ZodiannLayout` (gutter, panel gap, panel padding, panel head height), resolved by `ZodiannLayout.forWidth(double)` / `ZodiannLayout.of(context)`.
- **Theme-dependent elevation:** a new `ThemeExtension`, `ZodiannElevation` (the floating-layer shadow and its outline), joins `ZodiannTokens` and the themes. Its values sit in `graphite_tokens.dart` / `porcelain_tokens.dart`.
- **Guard:** `test/architecture/no_magic_dimensions_test.dart` flags numeric layout literals in `apps/*/lib` and `packages/*/lib` outside `tokens/`.
- **Criterion 2:** a test-only `TokenPanelHarness` is measured pixel-by-pixel at desktop and phone widths, and a reference test measures the same distances in the design PNGs.

**Tech Stack:** Flutter 3.50.0 / Dart 3.14.0 (FVM), material_ui 1.11.0, flutter_test (`dart:ui` image decoding as in UI-001). No new dependencies.

**Spec:** `assets/zodiann-specification.md` ARCH-8 (pixels are logical pixels). Design: `design-reference/zodiann/MASTER.md` §4, §6 (breakpoints), and `_source/kit.css:24,72,103–106,177–182`. References: `screens/04-settings_desktop_en_dark.png`, `responsive/tablet/settings_tablet_en_dark.png`, `responsive/mobile/settings_mobile_he_dark.png`. Task: `docs/development/shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md`.

## Facts established while planning (2026-11-13)

- **MASTER §4, verbatim:**
  - **Spacing:** 4, 8, 12, 16, 20, 24, 32, 40, 48. Gutter 24 (phone 16). Panel gap 20 (phone 16). Panel padding 20 (phone 16). Panel head 56 (phone 52).
  - **Radius:** 3 (square cells' outer frame, legend swatches), 6 (tags, segment thumbs), 8 (buttons, inputs), 12 (panels), 16 (dialogs), pill (chips). Square cells themselves have none.
  - **Elevation:**
    - Dark: surfaces get lighter instead of casting shadows.
    - Floating layers (drawer, dialog, toast) use `0 24 64 rgba(0,0,0,.55)` plus a 1 px `line` outline.
    - Light uses `0 24 56 rgba(21,25,31,.18)`.
  - **Controls:**
    - buttons/inputs 40 (small 32); segment thumbs 32 in a 3 px track;
    - table rows 44; hamburger/icon buttons 46 × 46, small 36;
    - play 48 circle; switch 40 × 24; orb stepper 36.
  - **Icons:** 20 in controls, 16 in small buttons and fields.
- **`kit.css` agrees on spacing, radius and controls** (`--s1…--s12`, `--r-xs 3 … --r-xl 16`, `--r-pill 999px`, `--control-h 40`, `--control-h-sm 32`, `--tap 46`; `.seg` padding 3, thumb 32; `.stepper` 36). **It differs on elevation:** dark `rgba(0,0,0,.6)`, light `rgba(11,12,14,.16)`, outline in both. MASTER wins, as in UI-001 and UI-002, so the shadow values are MASTER's.
- **Light outline — product-owner decision (2026-11-13): both themes.** MASTER's sentence gives the 1 px `line` outline to "floating layers" as a class, then replaces only the shadow for light, and `kit.css:72` draws the ring in light too. So `ZodiannElevation` carries the outline in both themes. The task file's "(dark)" reading gets a Note recording the decision.
- **The outline is a ring outside the box:** `kit.css` writes it as `0 0 0 1px var(--line)`. A `BorderSide` painted as a border sits inside. The consuming component (UI-011, UI-013, NAV-002) paints it outside, e.g. with `BoxShadow(color: side.color, spreadRadius: side.width)` after `floating`, or accounts for the 1 px inset. The `floatingOutline` doc comment says so.
- **The mobile PNG differs from MASTER at phone width:**
  - The settings mobile PNG shows a phone panel gap of 20 (column x 50: `bg` 966–1005 = 40 device px) and a head of 56 logical (1008–1119). That's because `_source/settings.html:28–34` doesn't override `.col { gap: s5 }` or `kit.css:178`'s `min-height: 56px` at phone.
  - MASTER §4 and the task file agree on 16 / 52, and win. So the reference test checks only the phone gutter and padding, which the PNG does change.
  - The phone breakpoint follows MASTER (< 700), not `settings.html`'s `max-width: 700px`, which includes 700.
- **Resting elevation:** panels have no shadow in either theme (`kit.css:177` `.panel` has a border only). Elevation below floating layers is the surface ladder `surface` → `surface2` → `surface3`, which FND-013 already mapped to `surfaceContainer` / `High` / `Highest`.
  - **Material 3 surface tint:** component defaults in material_ui 1.11 set `surfaceTintColor` to `Colors.transparent` (e.g. the dialog, app-bar and banner M3 defaults). **The exception is `AppBar`**, which falls back to `colorScheme.surfaceTint` (`app_bar.dart:1238–1245`). Zodiann's tint is `primary`, the accent, so a scrolled-under `AppBar` would get an accent tint.
  - No current code uses `AppBar`, so UI-003 changes nothing. ZOD-NAV-001 must set `surfaceTintColor: Colors.transparent` (or an `appBarTheme`) if it builds on `AppBar`. This is recorded in the `buildZodiannTheme` doc comment and in a NAV-001 Note.
- **CSS blur → Flutter:** CSS blur radius = 2σ, and Flutter's `BoxShadow.blurRadius` maps to σ via `convertRadiusToSigma(r) = r × 0.57735 + 0.5`. So `blurRadius = (cssBlur / 2 − 0.5) / 0.57735`: 54.5596 for 64, and 47.6314 for 56. The test pins `shadow.blurSigma ≈ cssBlur / 2`, using the instance getter inherited from `dart:ui` `Shadow`. Offset is (0, 24) and spread 0.
- **The CSS box model is `border-box`** (`kit.css`: `* { box-sizing: border-box }`):
  - a panel's 1 px border sits outside its padding;
  - the panel head's 56 includes its 1 px bottom rule.
- **Reference measurements** (pixel scans, `GetPixel`):

  | PNG | Width (DPR) | Measured |
  |---|---|---|
  | settings desktop en dark | 1440 (1×) | Two panel columns: right border of panel A at x 709, left border of panel B at 730, so the **gap is 20** (x 710–729). Stacked panels: border at y 418, next at 439, so the **gap is 20**. Panel top border at y 88, head rule at y 144, so the **head is 56** including the rule. |
  | settings tablet en dark | 834 (1×) | First panel border at x 24, so the **gutter is 24**. |
  | settings mobile he dark | 780 (2×) | First panel border at x 32–33, so the **gutter is 16 logical**. The first field starts at x 66 (panel inner edge at 34), so the **panel padding is 16 logical**. |

  Background `bg` is `#08080A`, the border `line-soft` is `#1B1B20`, and the panel `surface` is `#111114`.

  **Scan lines for the reference test** (re-verified by the reviewer; colours exact):
  - **Desktop:**
    - row y = 100: border at 154, surface to 708, border at 709, `bg` 710–729, border at 730;
    - row y = 176: border at 154, surface 155–174, first content pixel at 175 (**padding 20**);
    - column x = 400: top bar rule at 63, panel border at 88, head 89–144 (rule at 144), panel bottom border at 418, `bg` 419–438, next border at 439.
  - **Tablet:**
    - row y = 150: `bg` 0–23, border at 24;
    - row y = 176: border at 24, surface 25–44, first content pixel at 45 (**padding 20**).
  - **Mobile (2×):** row y = 400: `bg` 0–31, border 32–33, surface 34–65, field border at 66.
- **Breakpoints (MASTER §6):** phone is < 700, tablet is 700–1099, desktop is ≥ 1100. Content max width is 1440. MASTER gives a range of 1080–1180 for secondary screens; the screens pick within it, so it's not a token here. UI-002 left the breakpoint to this task.
- **ARCH-8:** every value is in logical pixels (Flutter's units), so there's no conversion.
- **Current `lib/` code:** none of the guard's patterns match with a numeric literal anywhere outside `tokens/` (reviewer grep over `EdgeInsets|SizedBox|Radius\.|BorderRadius|BoxShadow|Size\(|Size\.|BorderSide|BoxConstraints|Icon\(|iconSize|spacing:|runSpacing:`). So the guard starts green.

## Global Constraints

- Values are MASTER §4's exactly. Literals appear only in `packages/shared_ui/lib/src/theme/tokens/`.
- The elevation colours are colour literals, so they live in the token files (ARCH-7). The outline colour is the theme's `line` token, referenced rather than repeated.
- Material types come from `package:material_ui/material_ui.dart`. No new dependencies.
- Before every commit: `cmd //c "fvm dart run melos run lint && fvm dart run melos run test"` exits 0.
- Toolchain:
  - `export PATH="$PATH:$LOCALAPPDATA/Pub/Cache/bin"`;
  - `cmd //c "…"` with no `^`;
  - never stage `.idea/` or `.qodo/`.

## Out of scope

- **ZOD-UI-004…014:** components (buttons, fields, segmented control, panel, dialog, toast) that apply these tokens. In particular, ZOD-UI-014 builds the real hairline panel; the harness here is test-only.
- **ZOD-NAV-*:** the top bar (64/60) and drawer (320 / 86 %, 76 head). MASTER §5 lists them under navigation, not §4.
- **Screen tasks:** secondary-screen widths (1080–1180), and which layout values a screen uses.

## Review Focus

1. **A breakpoint boundary off by one,** where 699.x vs 700 or 1099.x vs 1100 picks the wrong layout. Covered by Task 2's boundary tests at 699.9, 700, 1099.9 and 1100.
2. **A Flutter `BoxShadow` blur that doesn't match the CSS blur,** giving a visibly harder or softer shadow. Covered by Task 3's σ test.
3. **Measuring the panel padding from the wrong edge.** The CSS box is border-box, so padding is counted inside the 1 px border. Covered by Task 4's harness measurement definitions, which mirror the reference scan.
4. **Magic numbers creeping into feature code.** Covered by Task 5's guard, with mutants for each pattern.
5. **The theme-switch animation choking on the new extension,** if `ZodiannElevation.lerp` is wrong. Covered by Task 3's lerp tests and FND-013's existing mid-animation test, which now includes the new token group (the seventh `ThemeData` extension).

---

### Task 1: Dimension constants

**Files:**
- Create: `packages/shared_ui/lib/src/theme/tokens/zodiann_dimensions.dart` (exported from `lib/shared_ui.dart`)
- Test: `packages/shared_ui/test/theme/dimensions_test.dart`

**Interfaces:**
- Produces (all `abstract final class` with `static const`):
  ```dart
  ZodiannSpace   { s1 = 4.0, s2 = 8.0, s3 = 12.0, s4 = 16.0, s5 = 20.0, s6 = 24.0, s8 = 32.0, s10 = 40.0, s12 = 48.0;
                   List<double> scale = [s1, …, s12]; }
  ZodiannRadius  { xs = 3.0, sm = 6.0, md = 8.0, lg = 12.0, xl = 16.0, pill = 999.0;
                   BorderRadius cellFrame = BorderRadius.all(Radius.circular(xs)), legendSwatch (xs), tag (sm), segmentThumb (sm),
                   control (md; buttons, inputs), panel (lg), dialog (xl), chip (pill);
                   // square cells: none (BorderRadius.zero) — documented, not a constant }
  ZodiannSize    { control = 40.0, controlSmall = 32.0, segmentThumb = 32.0, segmentTrackInset = 3.0, tableRow = 44.0,
                   iconButton = 46.0, iconButtonSmall = 36.0, playButton = 48.0, switchWidth = 40.0, switchHeight = 24.0,
                   stepper = 36.0, panelHead = 56.0, panelHeadPhone = 52.0, icon = 20.0, iconSmall = 16.0; }
  ZodiannBreakpoints { tablet = 700.0 /* phone is < tablet */, desktop = 1100.0, contentMaxWidth = 1440.0; }
  // Doc comments distinguish ZodiannBreakpoints (the width constants) from
  // Task 2's ZodiannBreakpoint enum (the resolved class).
  ```

- [ ] **Step 1: Write the failing tests.** In `dimensions_test.dart`, type MASTER §4 in as literals:
  - `the spacing scale is MASTER's 4-based scale`: `ZodiannSpace.scale == [4, 8, 12, 16, 20, 24, 32, 40, 48]`, and each named constant equals its position.
  - `radii follow MASTER's hierarchy`: the scale values; each semantic `BorderRadius` equals `BorderRadius.circular(n)` for its MASTER value; the scale strictly increases (the hierarchy is deliberate).
  - `control and icon sizes are MASTER's`: a literal table over every `ZodiannSize` constant.
  - `breakpoints are MASTER §6's`: 700, 1100, 1440.
  - `kit.css agrees on spacing, radius and controls`: parse `--s1…--s12`, `--r-xs…--r-pill`, `--control-h`, `--control-h-sm` and `--tap` from `../../design-reference/zodiann/_source/kit.css` (as UI-001's `master_values_test.dart` does) and compare them with the constants. `--r-pill` is 999. Also check these rules by regex on their selectors:
    - `.seg` padding 3 and thumb height 32 (`kit.css:212–214`);
    - `.stepper` height 36 (237);
    - `.switch` 40 × 24 (242);
    - `.tbl td` row 44 (267).

- [ ] **Step 2: Run it and see it fail.** Run `cmd //c "cd packages\\shared_ui && fvm flutter test test/theme/dimensions_test.dart"`. Expected: compile failure.

- [ ] **Step 3: Implement.** Write the constants with a doc line naming MASTER's use for each, e.g. `/// Buttons and inputs (MASTER §4).`

- [ ] **Step 4: Run it and see it pass.** Same command.

- [ ] **Step 5: Mutation proofs.**
  - **D1:** `s5 = 24.0`. Fails the scale and kit.css tests.
  - **D2:** `panel` radius `md`. Fails the radius test.
  - **D3:** `iconButton = 44.0`. Fails the sizes and kit.css (`--tap`) tests.

- [ ] **Step 6: Gates, then commit.** Commit as `feat(ZOD-UI-003): MASTER §4 spacing, radius, size and breakpoint constants`.

### Task 2: Breakpoints and per-breakpoint layout

**Files:**
- Create: `packages/shared_ui/lib/src/theme/zodiann_layout.dart` (export it)
- Test: `packages/shared_ui/test/theme/layout_test.dart`

**Interfaces:**
- Consumes: the Task 1 constants.
- Produces:
  ```dart
  enum ZodiannBreakpoint { phone, tablet, desktop;
    static ZodiannBreakpoint forWidth(double logicalWidth); } // < 700 phone, < 1100 tablet, else desktop
  @immutable final class ZodiannLayout {
    const ZodiannLayout({required gutter, required panelGap, required panelPadding, required panelHeadHeight});
    final double gutter, panelGap, panelPadding, panelHeadHeight;
    static const ZodiannLayout phone   = ZodiannLayout(gutter: ZodiannSpace.s4, panelGap: ZodiannSpace.s4, panelPadding: ZodiannSpace.s4, panelHeadHeight: ZodiannSize.panelHeadPhone);
    static const ZodiannLayout regular = ZodiannLayout(gutter: ZodiannSpace.s6, panelGap: ZodiannSpace.s5, panelPadding: ZodiannSpace.s5, panelHeadHeight: ZodiannSize.panelHead);
    static ZodiannLayout forWidth(double logicalWidth); // phone below 700, else regular
    static ZodiannLayout of(BuildContext context);      // forWidth(MediaQuery.sizeOf(context).width)
    // == / hashCode by value
  }
  ```
  MASTER gives tablet and desktop the same values ("desktop/tablet"), so there are two layouts and three breakpoints.

- [ ] **Step 1: Write the failing tests.**
  - `phone values are 16/16/16/52 and tablet/desktop values are 24/20/20/56`, as literals.
  - `breakpoint boundaries`:
    - `forWidth` at 0, 699.9 gives phone;
    - at 700, 1099.9 gives tablet;
    - at 1100, 1440 and 2560 gives desktop.
    - `ZodiannLayout.forWidth(699.9) == phone` and `forWidth(700) == regular`.
  - `of(context) follows MediaQuery`: a `testWidgets` with a `MediaQuery(data: MediaQueryData(size: Size(390, 844)))` → phone, and 1440 × 900 → regular. The `Size` literals are in test code, which the guard doesn't scan.

- [ ] **Step 2: Run and see it fail.** Run `cmd //c "cd packages\\shared_ui && fvm flutter test test/theme/layout_test.dart"`. Expected: compile failure.

- [ ] **Step 3: Implement.**

- [ ] **Step 4: Run and see it pass.** Same command.

- [ ] **Step 5: Mutation proofs.**
  - **L1:** phone test `<=` instead of `<` at 700. Fails the boundaries test.
  - **L2:** `regular.panelGap = s4`. Fails the values test.

- [ ] **Step 6: Gates, then commit.** Commit as `feat(ZOD-UI-003): breakpoints and per-breakpoint layout values`.

### Task 3: `ZodiannElevation`

**Files:**
- Create: `packages/shared_ui/lib/src/theme/zodiann_elevation.dart` (export it)
- Modify:
  - `packages/shared_ui/lib/src/theme/zodiann_tokens.dart`: add a `required ZodiannElevation elevation` field, included in `extensions`.
  - `tokens/graphite_tokens.dart`, `tokens/porcelain_tokens.dart`: hoist each `ZodiannSurfaces` into a private top-level `const _surfaces` so the outline can reference `_surfaces.line`.
  - `zodiann_theme.dart`: doc comment only. Record that M3 defaults set no surface tint except `AppBar`'s scrolled-under fallback to `colorScheme.surfaceTint` (handed to ZOD-NAV-001), and change line 10's "the five groups" to "the six token groups". Also record that elevation is the surface ladder plus `ZodiannElevation`.
- Test: `packages/shared_ui/test/theme/elevation_test.dart`.
- Update the FND-013 tests:
  - `zodiann_theme_test.dart`: rename "both themes carry all five extensions" to "both themes carry all token extensions" and add `ZodiannElevation`. In "buildZodiannTheme uses only the given tokens", add `expect(theme.extension<ZodiannElevation>(), same(tokens.elevation))`.
  - `test/theme/samples.dart`: add `ZodiannElevation sampleElevation(int seed)` (one `BoxShadow` with `sampleColor(seed, 0)`, offset (0, seed), blurRadius seed; outline `BorderSide(color: sampleColor(seed, 1))`), and pass `elevation: sampleElevation(seed)` in `sampleTokens`.
  - Update `ZodiannTokens`' doc lines ("the five MASTER.md §2 groups") to name elevation. It's the sixth token group and the seventh `ThemeData` extension, after `ZodiannTextStyles`.

**Interfaces:**
- Produces:
  ```dart
  @immutable final class ZodiannElevation extends ThemeExtension<ZodiannElevation> {
    const ZodiannElevation({required List<BoxShadow> floating, required BorderSide floatingOutline});
    final List<BoxShadow> floating;     // drawer, dialog, toast
    final BorderSide floatingOutline;   // 1 px `line`; doc: paint it OUTSIDE the box (kit's 0 0 0 1px ring), the consumer owns how
    /// The CSS blur radius → Flutter blurRadius with the same σ.
    static double blurFromCss(double cssBlur) => (cssBlur / 2 - 0.5) / 0.57735;
    copyWith, lerp (BoxShadow.lerpList(a, b, t)!, BorderSide.lerp; other == null → this), == (via `listEquals(floating, other.floating)` and `floatingOutline`) and hashCode (`Object.hash(Object.hashAll(floating), floatingOutline)`). The == test builds its two equal instances from separately created lists.
  }
  ```
- Values:
  - **Graphite:** `floating: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.55), offset: Offset(0, 24), blurRadius: ZodiannElevation.blurFromCss(64))]`, `floatingOutline: BorderSide(color: _surfaces.line)` (width 1).
  - **Porcelain:** `Color.fromRGBO(21, 25, 31, 0.18)`, `Offset(0, 24)`, `blurFromCss(56)`, and the outline from its `line`.

- [ ] **Step 1: Write the failing tests.**
  - `the floating shadow is MASTER's, per theme`:
    - one shadow each;
    - colours are `Color.fromRGBO(0,0,0,.55)` and `Color.fromRGBO(21,25,31,.18)`;
    - offset is (0, 24) and spread 0;
    - `shadow.blurSigma` (the inherited `Shadow` getter, `blurRadius × 0.57735 + 0.5`) is `closeTo(32, 1e-9)` (dark) and `closeTo(28, 1e-9)` (light).
  - `the outline is 1 px of the theme's line colour`: `floatingOutline == BorderSide(color: tokens.surfaces.line, width: 1)`, in both themes.
  - `the themes carry ZodiannElevation`: `ZodiannTheme.graphite.extension<ZodiannElevation>()` is `same(graphiteTokens.elevation)`, and likewise for porcelain. `withZodiannScript` keeps it (`same`).
  - `lerp, copyWith, ==`:
    - lerp at 0 and 1 gives the endpoints;
    - at 0.5 the shadow colour is `Color.lerp` of the two;
    - `lerp(null, t)` returns this;
    - equal values are `==` with equal hashCodes.
  - `resting panels have no shadow`: a doc-level assertion that `ZodiannElevation` exposes only `floating` and `floatingOutline` (no `resting` field) is a non-test, so skip it. The surface ladder is FND-013's existing `ColorScheme` test.

- [ ] **Step 2: Run and see it fail.** Run `cmd //c "cd packages\\shared_ui && fvm flutter test test/theme/elevation_test.dart"`. Expected: compile failure.

- [ ] **Step 3: Implement.** Then run the whole package, `cmd //c "cd packages\\shared_ui && fvm flutter test"`, and update FND-013's per-type extension tests (add `ZodiannElevation`). Also run the app tests, `cmd //c "cd apps\\astro_mobile && fvm flutter test"`: FND-013's mid-animation test now lerps seven extensions (six token groups plus `ZodiannTextStyles`) and must stay green.

- [ ] **Step 4: Mutation proofs.**
  - **E1:** dark alpha .6 (`kit.css`'s). Fails the shadow test.
  - **E2:** `blurRadius: 64` (a naive CSS copy). Fails the σ test.
  - **E3:** `lerp` returns `this`. Fails the lerp test.
  - **E4:** porcelain outline omitted (a transparent `BorderSide.none`). Fails the outline test.

- [ ] **Step 5: Gates, then commit.** Commit as `feat(ZOD-UI-003): floating-layer elevation per theme`.

### Task 4: Measured panel harness and reference cross-check (criterion 2)

**Files:**
- Create: `packages/shared_ui/test/support/token_panel_harness.dart`: a test-only `TokenPanelHarness` that uses tokens for every measured value and mirrors the CSS border-box. The 1 px border inset and the 40 px content block are test-only literals. It derives `layout` with `ZodiannLayout.of(context)` from the test view (1440 × 900 or 390 × 1200, DPR 1), so the measured render also exercises `of`. The harness draws boxes only, no text, so no fonts are loaded. On a `bg` page with `Padding(EdgeInsets.all(layout.gutter))`, it draws two panels, side by side (`Row`) when `layout == regular` and stacked (`Column`) on phone, separated by `layout.panelGap`. Each panel is:
  - a `DecoratedBox(color: surface, border: Border.all(color: lineSoft), borderRadius: ZodiannRadius.panel)` containing `Padding(EdgeInsets.all(1))`, so the content sits inside the 1 px border as in CSS;
  - a head of height `layout.panelHeadHeight − 1` followed by a 1 px `lineSoft` rule, so the head is 56/52 including the rule, as in CSS;
  - a body with `Padding(EdgeInsets.all(layout.panelPadding))` around a content block of height 40 in `accent` (a colour that appears nowhere else).
- Create: `packages/shared_ui/test/theme/panel_spacing_test.dart`.
- Create: `packages/shared_ui/test/theme/reference_layout_test.dart`.

**Interfaces:**
- Consumes: `ZodiannLayout`, `ZodiannRadius`, `ZodiannSpace`, the colour extensions.

- [ ] **Step 1: Write the failing tests.**
  - `panel_spacing_test.dart`, for `(1440 × 900, regular)` and `(390 × 1200, phone)` at DPR 1 under `ZodiannTheme.graphite`:
    - Render the harness's `RepaintBoundary` to raw RGBA inside `tester.runAsync`, as UI-001's harness does.
    - Scan the pixels, comparing each colour exactly with the token values. Define the scan lines so they avoid the 12 px corner radius: the row through the first panel's body at the content block's vertical centre, and the column at x = gutter + 40.
    - Measure:
      - **gutter:** the first non-`bg` x on the row. Expected 24 (regular) or 16 (phone).
      - **panel padding:** the content block's first `accent` x, minus (gutter + 1 border). Expected 20 or 16.
      - **panel gap:**
        - regular: on the same row, the run of `bg` between panel A's right border and panel B's left border. Expected 20.
        - phone: on the column, the `bg` run between the stacked panels. Expected 16.
      - **head height:** on the column, from the first pixel inside panel A's top border to the head rule, inclusive. Expected 56 or 52.
    - Assert each harness measurement **exactly** (`equals(v)`). The render is pixel-aligned at DPR 1, so exact equality is the strongest form of the criterion's "within 1 px". The ±1 tolerance applies only to the reference PNG measurements (antialiasing, DPR 2).
  - `reference_layout_test.dart`, decoding the PNGs with `dart:ui` `instantiateImageCodec` inside a plain `test`, as UI-001's `reference_swatches_test.dart` does. Using the Facts' scan lines:
    - **desktop:**
      - horizontal gap = `ZodiannLayout.regular.panelGap` (20), on row y = 100;
      - vertical gap = 20 and head height = `ZodiannSize.panelHead` (56), on column x = 400;
      - panel padding = `regular.panelPadding` (20): on row y = 176, the first non-`surface` x minus the first `surface` x after the left border.
    - **tablet:** gutter = `regular.gutter` (24) on row y = 150, and padding 20 on row y = 176.
    - **mobile (DPR 2):** on row y = 400, gutter = `phone.gutter` × 2 (32 device px) and padding = `phone.panelPadding` × 2.
    - The phone gap and head aren't checked: the PNG disagrees with MASTER there (Facts).
    - Compare pixels with `graphiteTokens.surfaces.{bg, lineSoft, surface}`. First assert the image sizes: 1440 × 1241, 834 × 2147 and 780 × 4918, as `reference_swatches_test.dart` does.
    - Each measurement equals its token within 1 px (device px / DPR).
    - This ties the tokens to the design images, as UI-001 did for colours.

- [ ] **Step 2: Run them and see them fail.** Run `cmd //c "cd packages\\shared_ui && fvm flutter test test/theme/panel_spacing_test.dart test/theme/reference_layout_test.dart"`. Expected:
  - `panel_spacing_test`: compile failure, because there's no harness yet.
  - `reference_layout_test`: passes immediately, because the tokens already exist. It's proven by mutants P1 and P2.

- [ ] **Step 3: Write the harness, then run and see it pass.** Optionally write a PNG with `ZODIANN_PANEL_DIR` set, for review.

- [ ] **Step 4: Mutation proofs.**
  - **P1:** `regular.panelPadding = s4`. Fails the regular padding measurement, and the reference desktop/tablet checks that compare with `regular`.
  - **P2:** `phone.gutter = s6`. Fails the phone gutter measurement and the mobile reference check.
  - **P3:** remove the harness's 1 px inner padding. Fails padding (19 ≠ 20) and head (55 ≠ 56).

- [ ] **Step 5: Gates, then commit.** Commit as `test(ZOD-UI-003): measured panel spacing and reference cross-check`.

### Task 5: Magic-number guard, close-out

**Files:**
- Create: `test/architecture/dimension_literals.dart` (scanner) and `test/architecture/no_magic_dimensions_test.dart`. Mirror `color_literals.dart` / `no_color_literals_test.dart`, including the exemption helper over `packages/shared_ui/lib/src/theme/tokens/`.
- Modify: the UI-003 task file, `docs/development/TASKS.md` and `docs/PROGRESS.md`, plus Notes in these task files:
  - **UI-014:** the panel uses `ZodiannLayout`, `ZodiannRadius.panel`, and the border-box measurement in the harness.
  - **ZOD-NAV-001:** if the top bar builds on `AppBar`, set `surfaceTintColor: Colors.transparent`, because `AppBar` falls back to `colorScheme.surfaceTint` (the accent).
  - **UI-011, UI-013 and ZOD-NAV-002:** "Floating layer: `ZodiannElevation.floating`, plus `floatingOutline` painted outside the box (both themes, PO 2026-11-13)."

**Interfaces:**
- Produces: `List<DimensionLiteral> findDimensionLiterals(String source)` and `bool isDimensionLiteralAllowed(String repoRelativePath)`.

- [ ] **Step 1: Write the failing tests.**
  - **Scanner unit tests**, using samples flagged vs allowed:
    - **Flagged:**
      - `EdgeInsets.all(8)`
      - `EdgeInsets.symmetric(horizontal: 12)`
      - `EdgeInsetsDirectional.only(start: 4.5)`
      - `EdgeInsets.fromLTRB(0, 8, 0, 0)`
      - `SizedBox(height: 40)`
      - `SizedBox.square(dimension: 24)`
      - `SizedBox.fromSize(size: Size(4, 4))`
      - `Radius.circular(12)`
      - `Radius.elliptical(4, 2)`
      - `BorderRadius.circular(8)`
      - `BoxShadow(blurRadius: 4)`
      - `Size(46, 46)`
      - `Size.square(46)`
      - `Size.fromHeight(40)`
      - `BorderSide(width: 2)`
      - `BoxConstraints(minHeight: 40)`
      - `BoxConstraints.tightFor(height: 44)`
      - `Icon(Icons.add, size: 20)`
      - `IconButton(iconSize: 20, …)`
      - `Row(spacing: 8, …)`
      - `Wrap(runSpacing: 4, …)`
      - the multi-line forms `const EdgeInsets.symmetric(\n  horizontal: 12,\n  vertical: 8,\n)` and `SizedBox(\n  height: 40,\n  child: x,\n)`
    - **Allowed:**
      - `EdgeInsets.all(ZodiannSpace.s2)`
      - `EdgeInsets.zero`
      - `EdgeInsets.fromLTRB(0, 0, 0, 0)` (0 is not a magic number)
      - `SizedBox(height: ZodiannSize.control)`
      - `SizedBox(height: ZodiannSize.control, child: Text('Step 1'))`
      - `Icon(Icons.filter_1)`
      - `Row(flex: 2)`: only `spacing:` / `runSpacing:` are checked on `Row`, `Column`, `Wrap` and `Flex`
      - a multi-line `SizedBox(child: Column(children: [...]))` with no numbers
      - text after `//`
    - **Behaviour:**
      - The scanner strips `//` comments and blanks string-literal contents.
      - Patterns are anchored with `\b`, as in `color_literals.dart`, so `fromSize(`, `BorderRadius.` and `ImageIcon(` don't match the `Size(`, `Radius.` and `Icon(` patterns.
      - For each pattern match it reads the call's argument list across lines, tracking depth over `()`, `[]` and `{}` together, so closure bodies and collection literals count as nested.
      - **Unrestricted patterns** (`EdgeInsets*`, `SizedBox*`, `Radius.*`, `BorderRadius.circular`, `BoxShadow`, `Size*`, `BorderSide`, `BoxConstraints*`) flag any numeric literal other than `0`/`0.0` at depth 0.
      - **Named-argument patterns** flag a literal only in the value of the named argument, at depth 0: `Icon(` → `size:`; `IconButton(` → `iconSize:`; `Row(` / `Column(` / `Wrap(` / `Flex(` → `spacing:`, `runSpacing:`.
      - Extra samples: allowed `IconButton(onPressed: () { _page = 2; }, iconSize: ZodiannSize.icon)`; flagged `BorderRadius.circular(8)`, asserted as exactly one finding.
      - It flags a numeric literal (`(?<![\w.$])\d+(\.\d+)?`) other than `0`/`0.0` only at nesting depth 0 of that list. Nested constructors are found by their own pattern.
      - The finding reports the line of the literal.
    - **Documented gaps:**
      - `Container(width:/height:)`, `Divider` and flex factors aren't scanned;
      - nor are `Offset(...)` (`BoxShadow` offsets, transforms) or numeric default parameter values;
      - arithmetic on tokens (`ZodiannSpace.s2 * 1.5`) flags the `1.5`, a deliberate fail-loud case.
  - `no workspace lib/ source has a layout magic number outside tokens/` (DATA scan like ARCH-7: `apps/*/lib`, `packages/*/lib`, pure-Dart members included harmlessly). Expect none. Exemption: `isDimensionLiteralAllowed` is true only under `packages/shared_ui/lib/src/theme/tokens/`, with `\` normalised.

- [ ] **Step 2: Run and see it fail.** Run `cmd //c "fvm dart test test/architecture"`. Expected: compile failure, because the scanner doesn't exist. After implementing, the workspace test passes immediately, since current `lib/` is clean (Facts). It's proven by mutant M1.

- [ ] **Step 3: Implement the scanner.** Then run the same command. Expected: 29 existing tests plus the new ones pass.

- [ ] **Step 4: Mutation proofs.**
  - **M1:** add `const _ = EdgeInsets.all(8);` to `packages/shared_ui/lib/src/theme/zodiann_layout.dart`. Fails the workspace scan.
  - **M2:** drop the `Radius.circular` pattern. Fails its scanner sample.
  - **M3:** revert to same-line scanning. The multi-line samples fail.

- [ ] **Step 5: Gates, then commit.** Commit as `test(ZOD-UI-003): magic-number guard for layout dimensions`.

- [ ] **Step 6: Whole-branch code review** (opus). Fix Critical and Important findings test-first, and defer minors.

- [ ] **Step 7: Close out.**
  - **UI-003 task file:** Done, both criteria ticked. Notes:
    - the product-owner decision on the light outline (both themes), plus the outside-ring painting note;
    - the mobile PNG's phone gap and head (20 / 56) disagree with MASTER (16 / 52), and MASTER wins;
    - MASTER over `kit.css` for the shadow values;
    - the CSS-blur conversion;
    - border-box measurement;
    - criterion 1's mechanism (`tokens/` + the guard, with its documented gaps);
    - `surfaceTint`: no change in UI-003. `AppBar` is the one M3 consumer, and it's handed to NAV-001.
  - **UI-014 Note:**
    - the panel uses `ZodiannLayout` and `ZodiannRadius.panel`, with border-box measurement as in the harness;
    - the mobile PNG's 20 / 56 phone gap and head are mockup leftovers, and MASTER's 16 / 52 apply.
  - **PROGRESS:**
    - Technical Decisions: the dimension constants live in `tokens/`; `ZodiannLayout` has two layouts and three breakpoints; `ZodiannElevation` is the sixth token group (seventh `ThemeData` extension); the light outline (PO); blur σ.
    - Architecture Conventions: "spacing, radius and sizes come from `ZodiannSpace` / `ZodiannRadius` / `ZodiannSize` / `ZodiannLayout`, never numeric literals (guard)"; breakpoints via `ZodiannBreakpoint.forWidth` / `ZodiannLayout.of`.
    - Verification, Git State, next task.
  - **TASKS.md:** UI-003 Done.
  - Commit as `docs(ZOD-UI-003): close out spacing, radius, elevation and sizing tokens`, then push, open the PR, and record the PR link.

## Plan review

### Round 1: Needs user decision (1 Critical, 7 Important, 9 Minor, 1 Needs user decision)

The reviewer re-derived every MASTER §4/§6 value and the `kit.css` primitives. It re-scanned the reference PNGs with a Node decoder, and all of the plan's measurements matched. It also found desktop/tablet padding 20 and the mobile PNG's gap/head discrepancy.

**Critical (applied):**
- **C1:** `BoxShadow.convertRadiusToSigma` doesn't exist (it's a static on `dart:ui` `Shadow`, and statics aren't inherited). The σ test now uses the inherited `blurSigma` getter.

**Important (applied):**
- **I1:** `samples.dart` builds `ZodiannTokens`, so the new required field would break compilation. It now gets `sampleElevation`, plus a `same(tokens.elevation)` assertion.
- **I2:** harness measurements are exact (`equals`), because the render is pixel-aligned, so P3 (a 1 px border-inset error) now fails. ±1 stays for the reference PNGs.
- **I3:** desktop/tablet panel padding (20) is now checked in the reference PNGs, so P1's claim holds.
- **I4:** the exact scan rows and columns are in Facts.
- **I5:** the mobile PNG's phone gap and head (20 / 56) contradict MASTER (16 / 52) because `settings.html` doesn't override them. This is recorded in Facts and the Notes. The reference test checks only the phone gutter and padding, and the breakpoint follows MASTER's < 700.
- **I6:** the scanner now reads balanced argument lists across lines, with strings blanked and depth-0 numerics only. Added the multi-line and false-positive samples and mutant M3.
- **I7:** added `BoxConstraints*`, `Size.square/fromHeight/fromWidth/fromRadius`, `SizedBox.fromSize`, `Radius.elliptical`, `Icon(size:)`, `IconButton(iconSize:)` and `Row/Column/Wrap/Flex(spacing:, runSpacing:)`.

**Minor (applied):**
- **M1:** blur radii corrected (54.5596 / 47.6314).
- **M2:** "sixth token group, seventh `ThemeData` extension" wording; the doc lines and the test renamed.
- **M3:** `lerpList(...)!`.
- **M4:** Task 4 RED expectations corrected.
- **M5:** harness wording.
- **M6:** the outline is a ring outside the box; the consumer paints it.
- **M7:** the harness uses `ZodiannLayout.of`.
- **M8:** the `ZodiannBreakpoints` / `ZodiannBreakpoint` names are distinguished in the doc comments.
- **M9:** more `kit.css` control checks.

**Needs user decision (resolved):**
- **U1:** the 1 px outline applies in **both themes**. Product-owner decision, 2026-11-13.

### Round 2: Approve after corrections (0 Critical, 2 Important, 6 Minor)

The reviewer confirmed all round-1 corrections and U1 are applied, and re-ran every scan coordinate (all exact). It also confirmed the `blurSigma` getter and that every mutant fails as planned once the scanner rules are tightened.

**Important (applied):**
- **I1:** the `surfaceTint` fact was wrong for `AppBar`. M3 defaults set a transparent tint, except `AppBar`, which falls back to `colorScheme.surfaceTint` (the accent). UI-003 changes nothing; a ZOD-NAV-001 Note hands it over, and the doc comment and close-out are corrected.
- **I2:** the scanner rules are now specified:
  - patterns anchored with `\b`;
  - depth tracked over `()`, `[]` and `{}`;
  - unrestricted vs named-argument patterns (`Icon(size:)`, `IconButton(iconSize:)`, `Row/Column/Wrap/Flex(spacing:, runSpacing:)`);
  - the closure false-positive sample, plus a single-finding `BorderRadius.circular` sample.

**Minor (all applied):**
- **M1:** extension counts corrected (six token groups, seven `ThemeData` extensions; per-type tests); the theme doc line updated.
- **M2:** `ZodiannElevation.==` compares the list by value, and the test uses separate lists.
- **M3:** more documented scanner gaps, and the full pattern set is confirmed clean.
- **M4:** the reference test names its colour source and asserts the image sizes.
- **M5:** Notes for UI-011, UI-013 and NAV-002 about the floating layer.
- **M6:** harness wording.

No open items remain after two rounds.
