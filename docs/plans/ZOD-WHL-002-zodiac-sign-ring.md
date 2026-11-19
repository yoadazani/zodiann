# ZOD-WHL-002 Render the zodiac sign ring: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (default, sequential) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. No work here is independent enough for subagents (every task edits the same layer, context and proportion files).

**Goal:** Draw the wheel's outer ring of 12 equal 30° sectors, Aries to Pisces, each with its element tint, its 30° separator, its element-coloured glyph, and the sign band's two rims, as one new `WheelLayer`.

**Architecture:** A new `SignRingLayer` (one `WheelLayer`, ARCH-5: no widget per sign) runs first in the painter's list and draws sectors, glyphs, separators, then the two band rims, in the kit's order. `WheelPaintContext` gains the two theme inputs the layer needs (`ZodiacColors`, the glyph `TextStyle`), so layers still read no provider and no `Theme`. `SignRingLayer` also owns the two band rims and the halo (T2 option b), so `ProportionGridLayer` leaves the default layer list and stays an opt-in debug / test layer.

**Tech Stack:** Flutter 3.50 / Dart 3.14, `feature_wheel`, `shared_ui` (`ZodiacColors`, `ZodiannGlyphs`, `ZodiannTextStyles`, `ZodiannSurfaces`), `astro_core` (`ZodiacSign`), headless Chrome for references (the NAV-002 pattern).

**Spec:** `assets/zodiann-specification.md` WH-1, L-6; `design-reference/zodiann/MASTER.md` §7.2 ("Sign band", "Sign glyphs"), §2.3; task file `docs/development/zodiac-wheel/ZOD-WHL-002-render-the-zodiac-sign-ring.md`; the kit `design-reference/zodiann/_source/kit.js` `wheelSVG` (lines 296-348) and `kit.css` (lines 300-315), which render the PNGs and so win over MASTER's prose (PROGRESS D1 / D7 precedent).

## Product-owner decisions needed (open at plan time)

- **T1: tint opacity.** Three sources disagree. MASTER §7.2 and the task's Implementation Details say 11 % (desktop). MASTER §2.3, `kit.css` (`--sign-tint: .10` dark / `.09` light), `ZodiacColors.signTintOpacity` (0.10 / 0.09, shipped in UI-001) and therefore the reference PNGs say 10 % / 9 %. The task's criterion 2 says "11 % dark / 9 % light per §2.3", which no source states. **Recommendation:** use `ZodiacColors.signTintOpacity` (10 % dark / 9 % light), because it is the value the PNGs are rendered with and the token already exists; record that MASTER §7.2's 11 % and the task's 11 % are not edited (NAV-002 / UI-009 precedent), and add a note to the task file. **Cost of the alternative:** 11 % needs a second token, and the ring would no longer match the PNGs.
- **T2: who draws the band rims and the halo, and does the scaffolding grid ship?** The kit draws the `accent-line` outer circle, the `line` inner circle and the 50 % halo in one statement (`kit.js:315`), after the sectors. Today `ProportionGridLayer` draws all three, plus two body rings (0.64 R, 0.547 R) that have **no counterpart in the kit** and the inner-disc fill (kit `.inner`, `kit.js:324`); PROGRESS hands the grid's future to this task. Options: (a) `SignRingLayer` draws the two rims; the grid stays in the default layers with the halo, the two body rings and the inner disc (two non-design circles stay on the wheel with no owner); (b) **recommended:** `SignRingLayer` draws both rims **and the halo**; `ProportionGridLayer` leaves the default layer list and stays an opt-in debug / test layer; the inner-disc fill is assigned to WHL-007 (or WHL-004) by a Note on that task file; until WHL-003+ the (unrouted) wheel shows only the ring; (c) as (b), but the grid keeps only the inner disc in the default layers until its owner takes it. **The rest of this plan is written for (b); a different answer changes Task 3 only (which circles the grid keeps, the default layer list, the tests that count circles).**
- **T4: criterion 3's tolerance against the designer PNGs.** The criterion says "pixel-identical between the English and Hebrew screenshots"; the plan reviewer measured the designer's own pairs (integer shift dx = 490, ring about 1.06× the kit at the PNG scale): in the 255–318 px annulus dark has 75 differing pixels and light 102, maximum difference 1 per channel; inside the sign band proper (≥ 265 px) dark 2 and light 10, all on the Libra separator at screen angle about 43°; the rest lies in the tick / degree-number zone (WHL-003's). Options: (a) **recommended:** the designer comparison is "equal within 1 per channel", masked to the band (rim to `signBandInner`) plus the separator rays; the Flutter en / he comparison stays byte-identical; (b) tolerance 0 (fails on the designer's files, so criterion 3 cannot be ticked); (c) restate criterion 3 as about the app's render only.
- **T3 (informational, kit-driven):** the separator is not band-only. The kit draws each from the outer rim to `signBandInner − 18` units, so it runs 18 units past the inner edge across the tick zone (PNG evidence). The plan follows the kit. The kit also skips ticks at multiples of 30° (`kit.js:318`) because the separator is the 30° mark: Task 5 adds a Note to ZOD-WHL-003.
- **The tint values in Tasks 3 and 4 (0.10 / 0.09) assume T1 option (a).** If T1 chooses 11 %, a new token is added, those expectations become 0.11 / 0.09, and the PNG fill sampling gets a larger, measured tolerance.
- **Gate 1:** the layer reads `ZodiacSign` (an enum) and no ephemeris or crossing output, so the WHL-001 ruling stands (Gate 1 applies from ZOD-WHL-004).

## Global Constraints

- **ARCH-5:** one `CustomPainter`, one `RepaintBoundary`; no widget per sign, glyph or separator.
- **ARCH-3:** the screen's one provider is untouched; the layer is a pure function of its context.
- **L-6:** signs run Aries to Pisces counter-clockwise from 0° at the same place in every language; the layer never branches on text direction, and glyph text gets `TextDirection.ltr` from the context.
- **ARCH-7:** no colour literal in `lib/`; element colours from `ZodiacColors`, rims and separators from `ZodiannSurfaces` (`accentLine`, `line`).
- **UI-003 dimension guard** (`test/architecture/no_magic_dimensions_test.dart`) stays green: sizes come from `WheelProportions` fractions, never literals in the layer.
- **Typography:** glyph strings come only from `ZodiannGlyphs.signs` (U+FE0E included); the style derives from the `ZodiannTextStyles.glyph` role with `copyWith` for size and colour; never build a `TextStyle` from scratch.
- **L10-001 guard:** no string literal in a `Text`; the layer draws glyph strings through `TextPainter`, not `Text`.
- **Logical pixels (ARCH-8).**
- **Commands:** `fvm flutter …`, `fvm dart …`, `fvm dart run melos <cmd>`; import `material_ui`, never `material.dart`.
- **Scope:** no ticks, degree numbers, bodies, pointer, interaction, router wiring (WHL-003…025). Compact sizes are applied here only through the existing compact table (WHL-024 owns per-layer responsive polish).

## Review Focus

- **Zero / tiny / non-finite size:** the painter already returns for `radius <= 0`; a tiny radius (R = 1) must paint without throwing or producing NaN offsets. Test in Task 3.
- **Pointer longitude ≠ 0 (rotation):** the ring must rotate with the wheel (`offsetOf(..., pointerLongitude:)`), glyphs stay upright (never rotated). Test in Task 3 with `pointerLongitude` 123.4, plus the wrap case 359.9.
- **Theme switch with the layer on screen:** tint opacity and element colours change (10 % → 9 %, graphite → porcelain palette) with no stale cache. Test in Task 3.
- **Hebrew locale / RTL app:** the ring's pixels equal the English render's (the whole of L-6 for this task). Test in Task 4.
- **Text scale 2.0 and a Hebrew script swap (`withZodiannScript`):** the glyphs do not change size or fallback to an emoji face; the layer draws sizes from the proportion table, not from `MediaQuery.textScaler`. Test in Task 3 (textScaler 2.0 gives identical pixels) and the glyph font check in Task 4.

## File Structure

| File | Responsibility |
|---|---|
| `packages/feature_wheel/lib/src/canvas/wheel_layer.dart` (modify) | `WheelPaintContext` gains `zodiac` (`ZodiacColors`) and `glyphStyle` (`TextStyle`) |
| `packages/feature_wheel/lib/src/canvas/wheel_painter.dart` (modify) | new fields, passed to the context, compared in `shouldRepaint` |
| `packages/feature_wheel/lib/src/canvas/wheel_canvas.dart` (modify) | reads both from `Theme`; default layers `[SignRingLayer()]` (T2 b) |
| `packages/feature_wheel/lib/src/geometry/wheel_proportions.dart` (modify) | new field `signSeparatorInner` (`(250 - 18) / referenceRadius` desktop, `(240 - 18) / referenceRadius` compact), in `==` / `hashCode` |
| `packages/feature_wheel/lib/src/canvas/proportion_grid_layer.dart` (modify) | stops drawing the two band rims and the halo (T2 b); doc comment updated |
| `packages/feature_wheel/test/support/repo_root.dart` (create) | `repoRoot()`: walks up from `Directory.current` to the directory holding `packages/`, so file-reading tests pass from the repo root and under `melos run test` |
| `packages/feature_wheel/lib/src/canvas/sign_element.dart` (create) | `enum ZodiacElement { fire, earth, air, water }`, `ZodiacElement elementOf(ZodiacSign)` |
| `packages/feature_wheel/lib/src/canvas/sign_ring_layer.dart` (create) | `SignRingLayer` |
| `packages/feature_wheel/lib/feature_wheel.dart` (modify) | exports |
| `packages/feature_wheel/test/canvas/sign_element_test.dart`, `sign_ring_layer_test.dart` (create) | unit and canvas tests |
| `packages/feature_wheel/test/support/wheel_harness.dart` (modify) | default layers, a ring-only capture helper |
| `tool/wheel/render_sign_ring_references.dart` (create) | Chrome references (hides everything but the ring) |
| `packages/feature_wheel/test/fixtures/sign_ring/` (create) | reference PNGs, manifest with SHA-256 of the kit files |
| `test/design/wheel_ring_png_test.dart` (create, root) | en vs he designer PNG ring equality (criterion 3) |

---

### Task 1: the sign-to-element table and the proportion field

**Files:** Create `lib/src/canvas/sign_element.dart`, `test/canvas/sign_element_test.dart`; modify `wheel_proportions.dart` and `test/geometry/wheel_proportions_test.dart`.

**Interfaces:**
- Produces: `enum ZodiacElement { fire, earth, air, water }`; `ZodiacElement elementOf(ZodiacSign sign)`; `WheelProportions.signSeparatorInner` (fraction of `R`).

- [ ] **Step 1: Failing tests.** `sign_element_test.dart`: a literal table of the 12 `(ZodiacSign, element)` pairs copied from `kit.js` `SIGNS` (fire: aries, leo, sagittarius; earth: taurus, virgo, capricorn; air: gemini, libra, aquarius; water: cancer, scorpio, pisces); `ZodiacSign.values` has length 12 and `elementOf` covers every value; each element appears exactly 3 times, and signs `i` and `i + 4` share an element. A second test reads `kit.js` text and checks each `k: '<sign>'` line's `el:` against `elementOf` (second source, as UI-001 did for kit.css). In `wheel_proportions_test.dart`: `desktop.signSeparatorInner == 232 / 300` and `compact.signSeparatorInner == 222 / 300` (exact), plus `closeTo(signBandInner - 18 / 300, 1e-12)` for both tables (not `==`: `250/300 − 18/300` differs from `232/300` in the last bit), and the equality / hash tests include the new field. The `kit.js` second-source test resolves its path with `repoRoot()` (created in this task), so it passes from the repo root and under `melos run test`.
- [ ] **Step 2: Run** `fvm flutter test packages/feature_wheel/test/canvas/sign_element_test.dart packages/feature_wheel/test/geometry/wheel_proportions_test.dart`; expect FAIL (undefined names).
- [ ] **Step 3: Implement** the enum and `elementOf` (an exhaustive `switch` on `ZodiacSign`, so a new sign fails to compile), `repoRoot()`, and the field defined as `(250 - 18) / referenceRadius` / `(240 - 18) / referenceRadius` (the same form as `degreeNumberRadius`) with a doc comment citing `kit.js` (`rTick − 18`).
- [ ] **Step 4: Run the same command;** expect PASS.
- [ ] **Step 5: Commit** `feat(ZOD-WHL-002): add the sign-element table and the separator radius`.

### Task 2: the layer's inputs (`WheelPaintContext`, painter, canvas)

**Files:** modify `wheel_layer.dart`, `wheel_painter.dart`, `wheel_canvas.dart`, `test/support/wheel_harness.dart`, `test/canvas/wheel_canvas_test.dart`.

**Interfaces:**
- Consumes: `ZodiacColors` and `ZodiannTextStyles` from `shared_ui` (both `ThemeData` extensions).
- Produces: `WheelPaintContext({…, required ZodiacColors zodiac, required TextStyle glyphStyle})`; `WheelPainter({…, required this.zodiac, required this.glyphStyle})`, both in `shouldRepaint`.

- [ ] **Step 1: Failing tests** in `wheel_canvas_test.dart`: the probe layer receives a context whose `zodiac` equals the theme's `ZodiacColors` and whose `glyphStyle` equals `ZodiannTextStyles.glyph` (graphite and porcelain); a theme switch repaints (painter reports `shouldRepaint` true when only `zodiac` changes, and when only `glyphStyle` changes).
- [ ] **Step 2: Run** the file; expect FAIL.
- [ ] **Step 3: Implement** the fields; `WheelCanvas` reads both with `Theme.of(context).extension<…>()!`. Existing tests that build a `WheelPaintContext` or `WheelPainter` directly (grep `WheelPaintContext(` and `WheelPainter(` under `packages/feature_wheel/test`) get the new arguments through a harness helper, not copies.
- [ ] **Step 4: Run** `fvm flutter test packages/feature_wheel`; expect PASS (the previous 50 tests unchanged in meaning).
- [ ] **Step 5: Commit** `feat(ZOD-WHL-002): hand layers the zodiac colours and glyph style`.

### Task 3: `SignRingLayer` and the grid hand-off

**Files:** create `lib/src/canvas/sign_ring_layer.dart`, `test/canvas/sign_ring_layer_test.dart`; modify `proportion_grid_layer.dart`, `wheel_canvas.dart` (default `layers`), `wheel_harness.dart`, `feature_wheel.dart`, `test/canvas/proportion_grid_test.dart`, `test/canvas/wheel_canvas_test.dart` (the "644 × 656 gives R 300, halo ring radius 306" test), `test/wheel_screen_test.dart:81-104` (the resize test needs a `drawCircle` at 240/300 R).

**Interfaces:**
- Consumes: Task 1 and 2 outputs; `WheelGeometry.offsetOf(longitude, ringFraction, pointerLongitude:)`, `ringRadius`, `center`.
- Produces: `final class SignRingLayer implements WheelLayer` (`const SignRingLayer()`), exported.

Paint order inside the layer, per the kit: for `i` in 0…11 (`a0 = i·30°`): the sector path (outer arc from `a0` to `a0 + 30°` at `signBandOuter`, line to the inner arc at `a0 + 30°`, inner arc back to `a0`) filled with `elementColor(i)` at `zodiac.signTintOpacity`; the glyph centred at longitude `a0 + 15°`, radius `(signBandOuter + signBandInner) / 2`, size `signGlyphSize · R`, colour `elementColor(i)`; the separator from `(a0, signBandOuter)` to `(a0, signSeparatorInner)`, `line`, width 1 kit unit (`R / 300`). Then, in the kit's order, the outer circle in `accentLine`, the inner circle in `line`, and the halo (`signBandOuter` + 10 units = `haloRadius`) in `line` at 50 %, each width 1 kit unit, each drawn with `drawCircle`. The glyph is centred by laying out a `TextPainter` (`ZodiannGlyphs.signs[i]`, `context.textDirection`) and centring its width and height on the point, plus one named, documented centring constant (0 until Task 4 Step 3), because the kit says `text-anchor: middle; dominant-baseline: central`. `glyphStyle` is the one text input added to the context now; WHL-003 / WHL-004 may replace it by the whole `ZodiannTextStyles` (a recorded design choice, to be revisited by the first of them).

- [ ] **Step 1: Failing tests** in `sign_ring_layer_test.dart`, using a recording canvas for geometry (the `paints` matcher) and a pixel render for colour:
  - **Order and count:** 12 sector paths, 12 separators, 12 glyph paragraphs, then 3 circles (outer rim, inner rim, halo), in the kit's order, with the recorded-canvas matcher (`paints`).
  - **Glyph identity:** with the bundled fonts loaded, for each `i` the pixel crop around glyph `i`'s centre in the ring render equals a crop of `ZodiannGlyphs.signs[i]` painted alone with the same style at the same offset (a swapped or reversed list fails; the recorded `Paragraph` exposes no text and the test font gives every glyph the same box, so this is the check).
  - **Positions, as literals** (R = 300, centre (322, 334), pointer 0): Aries separator (322, 38) → (322, 102) desktop and (322, 112) compact; Taurus separator (174, 77.656) → (206, 133.082); Aries glyph centre (251.342, 70.302) desktop and (252.636, 75.132) compact; Pisces glyph centre (392.658, 70.302); at pointer 123.4 Aries' outer point is (569.115, 496.942), at 359.9 it is (321.483, 38.000) (tolerance 0.01). The expected glyph point is the ring point plus the layer's named centring constant, read independently of the layer's code. Also at a second size (R = 150).
  - **Sector geometry:** each recorded sector path `includes` (`a0 + 0.5°`, mid radius) and (`a0 + 29.5°`, mid radius), and `excludes` (`a0 − 0.5°`, mid), (`a0 + 30.5°`, mid), (`a0 + 15°`, `signBandOuter` + 1 unit) and (`a0 + 15°`, `signBandInner` − 1 unit), at pointer 0, 123.4 and 359.9 (pins direction, extent and rotation; a clockwise or 29° sweep fails).
  - **Colour and tint:** each sector's fill is its element's `ZodiacColors` colour at `signTintOpacity` (graphite 0.10, porcelain 0.09); each glyph is the element colour at full opacity; separators and the inner rim are `line`, the outer rim is `accentLine`. Expected values come from the tokens table typed in the test, not from the layer.
  - **Glyph size:** each recorded paragraph's `height` equals `signGlyphSize · R` (21 / 300 desktop, 30 / 300 compact; the glyph role has height 1.0), at two canvas sizes.
  - **No glyph rotates:** no `#rotate` or `#transform` invocation is recorded.
  - **Tiny radius:** `R = 1` paints with no exception and no NaN in any recorded offset.
  - **Text scale 2.0:** pixels are identical to scale 1.0.
  - **Theme switch:** repaint changes tint and colours.
  - **Grid hand-off (T2 b):** the grid tests pump `layers: const [ProportionGridLayer()]` explicitly and assert the circle count (`paintsExactlyCountTimes(#drawCircle, 3)`: body disc ring, body label ring, inner disc outline, plus the inner-disc fill as a `drawCircle` fill, so the expected count is stated as 4 and the test names each); no circle at `signBandOuter`, `signBandInner` or `haloRadius`. The default `WheelCanvas` (no `layers` argument) draws the ring only: its circles are exactly the rims and the halo, each once. The WHL-001 halo test ("644 × 656 gives R 300, halo ring radius 306") and the resize test (`wheel_screen_test.dart:81-104`, a `drawCircle` at 240/300 R) now read the ring layer's circles.
- [ ] **Step 2: Run** `fvm flutter test packages/feature_wheel/test/canvas packages/feature_wheel/test/wheel_screen_test.dart`; expect FAIL.
- [ ] **Step 3: Implement** `SignRingLayer` as above; the sector path uses `Path.arcTo` on the two circles. Remove the three ring entries (outer rim, inner rim, halo) from the grid layer and update its doc comment (it names the rings that remain: scaffolding with no kit counterpart, except the inner disc, which WHL-007 or WHL-004 takes). Default `WheelCanvas.layers` becomes `[SignRingLayer()]`. Export from `feature_wheel.dart`. Per-paint `TextPainter` layout (12 per frame) is accepted for now (see Risks).
- [ ] **Step 4: Run** `fvm flutter test packages/feature_wheel`; expect PASS.
- [ ] **Step 5: Commit** `feat(ZOD-WHL-002): render the zodiac sign ring`.

### Task 4: fidelity to the design (criteria 1–3)

**Files:** create `tool/wheel/render_sign_ring_references.dart`, `packages/feature_wheel/test/fixtures/sign_ring/` (PNGs, `manifest.json`, `README.md`), `packages/feature_wheel/test/canvas/sign_ring_fidelity_test.dart`, `test/design/wheel_ring_png_test.dart`; modify the harness (font loading via `shared_ui/test/support/load_bundled_fonts.dart` pattern, a capture helper).

- [ ] **Step 1: The reference tool.** Following `tool/drawer/render_drawer_references.dart` (Chrome's `--screenshot` CLI, no CSS-injection API): the tool writes a temporary wrapper page (query `?theme=<dark|light>`) that links `_source/kit.css` and `_source/kit.js` by absolute file URL. Its body is `margin:0; background: var(--surface)` (the panel background the PNGs are drawn on), it holds a 644 px-wide `div`, and `wheelSVG({ pointerLon: 227.05, compact: <bool> })` is inserted into that div, so R = 300 px at (322, 334). `227.05` is `BODIES[0].lon` (`kit.js:170`, the Sun; `kit.js:296` defaults `pointerLon` to it); the tool passes it explicitly and writes it to `manifest.json`. The page's own `<style>` hides `.tick, .deg-lbl, .inner, .asp, .connector, .body-bg, .body-glyph, .body-deg, .pointer, .pointer-line, .hub` and **not** the halo (the halo is now this layer's). Chrome runs with `--headless=new --window-size=644,656 --force-color-profile=srgb --font-render-hinting=none --allow-file-access-from-files --screenshot=…` (the flags of `_source/render/render.js`). It cannot load `wheel.html` itself: that page picks compact by `innerWidth <= 1100` and sizes the SVG by CSS inside a panel. Output: 4 PNGs (desktop / compact × dark / light) and a manifest with the SHA-256 of `kit.js` and `kit.css`; regenerate only when they change. Run it and commit them.
- [ ] **Step 2: Failing fidelity test** (`sign_ring_fidelity_test.dart`). Render `WheelCanvas(state: WheelState(pointerLongitude: 227.05), layers: [SignRingLayer()])` (the literal typed in the test and checked against the manifest; at pointer 0 every check would fail for a reason that has nothing to do with glyph centring) at 644 × 656, with the bundled fonts loaded from `<repoRoot()>/packages/shared_ui/assets/fonts/…`, painting `ZodiannSurfaces.surface` behind the canvas (a `ColoredBox` in the harness's `wrap`, matching the reference). Compare with the reference by one extractor over the annulus `signBandInner − 20 … signBandOuter + 2` units: sector fill colours at 12 sample points per sign within ±2 per channel (points avoid the glyph box around (`a0 + 15°`, mid radius) and stay ≥ 2 px from separators and rims); separator and rim pixel positions within 1 px; glyph ink centroid per sign within 2 px and bounding box within 2 px; mean absolute difference over the annulus under a ceiling calibrated as in FND-009 (`max(round_up(worst × 1.5, 3), floor)`), recorded in the fixtures README. Expected: FAIL before the glyph centring constant is tuned, then PASS.
- [ ] **Step 3: Tune** only the layer's named glyph-centring constant (TextPainter metrics versus `dominant-baseline: central`), documented in the layer; no change to the proportions, and Task 3's tests must stay green without edits (they add the same named constant).
- [ ] **Step 4: Glyph font check** (the UI-002 pattern; a widget test has no emoji face to fall back to, and `ui.Paragraph` exposes no resolved family list). (a) The style the layer lays out has `fontFamily` `ZodiannFonts.notoSansSymbols`, `package` `ZodiannFonts.package` and the glyph role's fallback list, and every string ends in U+FE0E; (b) with bundled fonts loaded, each sign glyph's advance width differs from the same string in a missing family (as `packages/shared_ui/test/fonts/font_rendering_test.dart:68-83`); (c) monochrome rendering is checked on a device in Task 5 Step 2 (all 29 glyphs are already covered by `glyph_presentation_test.dart`).
- [ ] **Step 5: L-6 in Flutter.** Render the same ring in `Locale('en')` and `Locale('he')` through the app's script builder (`MaterialApp.builder` with `withZodiannScript`, real delegates, so RTL and the Hebrew script are real): the two images are byte-identical, desktop and compact, dark and light, and at `textScaler` 2.0.
- [ ] **Step 6: L-6 in the designer PNGs** (criterion 3; tolerance per T4). `test/design/wheel_ring_png_test.dart` (root package, `image ^4.13.1` is a root dev dependency) loads `01-zodiac-wheel_desktop_en_dark.png` and `_he_dark.png`, finds each wheel's centre and radius from the accent-line rim **with a horizontal ray** (a vertical scan at 12 o'clock hits the pointer line, `kit.js:343`), crops the same box around both and masks as T4 says. Measured by the plan reviewer (the test re-measures, it does not trust these): integer shift dx = 490, dy = 0, en centre about (475, 535), ring about 1.06× the kit, rim about 313 px and halo about 324 px from the centre; in the 255–318 px annulus dark 75 / light 102 differing pixels, maximum difference 1 per channel; inside the band (≥ 265 px) dark 2 / light 10, all on the Libra separator at screen angle about 43°. The wheel panel sits on a different side in each file, so the centre is located per image. Repeat for the `_light_` pair. The test asserts the rim was found in both (a self-check).
- [ ] **Step 7: Mutation proof.** Each of these edits to production code must turn a named test red, then be restored: element table rotated by one sign; glyph list reversed; separator inner radius = band inner edge; sector sweep 29° or 31°; clockwise sweep; tint 0.11; x negated unconditionally (caught by Task 3 positions and the fidelity test); `WheelCanvas`'s LTR `Directionality` removed and the layer mirroring on `Directionality.of` (caught by Step 5); glyph rotated with its sector; rim colours swapped; halo dropped; the grid also drawing the rims (double draw). Record the list in the commit message.
- [ ] **Step 8: Run** `fvm dart run melos run lint` and `fvm dart run melos run test`; expect exit 0 for both.
- [ ] **Step 9: Commit** `test(ZOD-WHL-002): check the sign ring against the design`.

### Task 5: verify, review, document, hand over

- [ ] **Step 1:** run lint, the full tests, and `cd apps/astro_mobile; fvm flutter build apk --debug` (as WHL-001 did); record the counts and the commit.
- [ ] **Step 2:** device check (the S22 Ultra used in NAV-003 if connected, else emulator-5554): a throwaway debug entry (not committed) shows the wheel; confirm the glyphs are monochrome and the ring matches the reference by eye; record which device. If no device is available, record that and the reason (the layer is not routed until WHL-025).
- [ ] **Step 3:** one fresh whole-branch review (`requesting-code-review`); fix Critical / Important findings test-first.
- [ ] **Step 4:** update the task file (`Status`, ticked criteria with evidence, the T1 note), `docs/development/TASKS.md`, `docs/PROGRESS.md` (Current Task, Completed Tasks with commands, results and commit, Technical Decisions T1 / T2 / T3, Git State; also correct the stale "PR open" line for WHL-001, which is merged `06c377c`), and the grid-layer note in the deferred minors. Add Notes to the task files: ZOD-WHL-003 ("30° marks are WHL-002's separators; draw no tick at multiples of 30°", `kit.js:318`), the owner of the inner-disc fill (WHL-007 or WHL-004), and ZOD-WHL-002 itself (T1, T3, T4).
- [ ] **Step 5:** push `task/ZOD-WHL-002-zodiac-sign-ring`, open the PR, then add the PR link in a follow-up docs commit.

## Acceptance mapping

| Criterion | Proven by |
|---|---|
| 1. All 12 signs in order, element colour, glyph | Task 1 literal and kit.js tables; Task 3 order, colour and position tests; Task 4 pixel fidelity |
| 2. Tint opacity and rim match the design | T1 decision; Task 3 tint/rim colour tests; Task 4 sector-fill sampling against Chrome in both themes |
| 3. Ring pixel-identical in en and he | Task 4 steps 5 (Flutter render) and 6 (designer PNGs) |

## Risks and open items

- **T1 and T2** above need an answer before implementation.
- **Glyph centring:** `dominant-baseline: central` has no exact TextPainter equivalent; fidelity thresholds are measured, not assumed (Task 4 step 2).
- **PNG scale:** the designer PNGs may not be at 1×; Task 4 step 6 derives the scale from the rim and compares at that scale, and the test reports what it found.
- **Chrome availability** for the reference tool (as FND-009 / FND-008 / NAV-002); `CHROME` overrides the path. The committed PNGs mean the tests need no Chrome.
- **Grid hand-off (T2 b):** the grid leaves the default layers. Its body-disc and body-label rings have no counterpart in the kit (pure scaffolding, they disappear with the grid); its inner-disc fill (kit `.inner`) is assigned by a Note to WHL-007 or WHL-004, since no task file owns it today. Recorded in PROGRESS at close-out.
- **Per-paint cost:** 12 `TextPainter` layouts per paint; WHL-010 drags at frame rate. Accepted now; cache per style and size if profiling flags it.
- **Context design:** `glyphStyle` is one text field; WHL-003 / WHL-004 may replace it with the whole `ZodiannTextStyles`.

## Plan review

### Round 1 (comprehensive) — verdict: needs user decision

- **C1 (Critical), exact `==` between `232/300` and `250/300 − 18/300` fails for desktop:** applied (exact literals plus `closeTo(…, 1e-12)`; the field is defined as `(250 - 18) / referenceRadius`).
- **C2 (Critical), the reference is drawn at pointer 227.05°, the plan rendered at 0°:** applied (Task 4 Steps 1–2 pass and check `227.05`).
- **I1** the reference tool as described could not work (compact by `innerWidth`, CSS-sized SVG, no injection API): applied (wrapper page, explicit `compact`, Chrome flags).
- **I2** no background in the Flutter capture: applied (`surface` behind the canvas; sample points avoid glyph boxes and edges).
- **I3** assertions the `paints` matcher cannot check, sector geometry unpinned: applied (glyph-identity crops, include / exclude points, paragraph height, no-rotate calls, literal coordinates from the reviewer).
- **I4** glyph position test vs the later centring tune: applied (a named constant, 0 until Task 4 Step 3; Task 3 stays green).
- **I5** wrong grid owners, PROGRESS's open item: applied as T2 (widened to the halo), option b recommended, ownership stated truthfully; **the decision is the user's**.
- **I6** existing tests that depend on the grid's circles: applied (Task 3 Files and steps).
- **I7** a font check that cannot fail: applied (family and package, advance-width pattern, device monochrome check).
- **I8** cwd-relative file reads: applied (`repoRoot()` helper).
- **Minor:** M1 line range, M2 apk command, M3 mutants, M4 script builder, M5 T1 note, M6 recorded in Risks, M7 Note for WHL-003, M8 Risks line, M9 throwaway entry: all applied.
- **Needs user decision (open):** T1 tint 10 % / 9 % vs 11 %; T2 the grid and halo ownership; T4 criterion 3's tolerance against the designer PNGs (the designer's own pairs differ by up to 1 per channel).

### Round 2

Pending.
