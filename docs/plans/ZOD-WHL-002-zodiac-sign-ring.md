# ZOD-WHL-002 Render the zodiac sign ring: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (default, sequential) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. No work here is independent enough for subagents (every task edits the same layer, context and proportion files).

**Goal:** Draw the wheel's outer ring of 12 equal 30° sectors, Aries to Pisces, each with its element tint, its 30° separator, its element-coloured glyph, and the sign band's two rims, as one new `WheelLayer`.

**Architecture:** A new `SignRingLayer` (one `WheelLayer`, ARCH-5: no widget per sign) runs first in the painter's list and draws sectors, glyphs, separators, then the two band rims, in the kit's order. `WheelPaintContext` gains the two theme inputs the layer needs (`ZodiacColors`, the glyph `TextStyle`), so layers still read no provider and no `Theme`. `ProportionGridLayer` stops drawing the two sign-band circles, which the new layer now owns.

**Tech Stack:** Flutter 3.50 / Dart 3.14, `feature_wheel`, `shared_ui` (`ZodiacColors`, `ZodiannGlyphs`, `ZodiannTextStyles`, `ZodiannSurfaces`), `astro_core` (`ZodiacSign`), headless Chrome for references (the NAV-002 pattern).

**Spec:** `assets/zodiann-specification.md` WH-1, L-6; `design-reference/zodiann/MASTER.md` §7.2 ("Sign band", "Sign glyphs"), §2.3; task file `docs/development/zodiac-wheel/ZOD-WHL-002-render-the-zodiac-sign-ring.md`; the kit `design-reference/zodiann/_source/kit.js` `wheelSVG` (lines 296-372) and `kit.css` (lines 300-315), which render the PNGs and so win over MASTER's prose (PROGRESS D1 / D7 precedent).

## Product-owner decisions needed (open at plan time)

- **T1: tint opacity.** Three sources disagree. MASTER §7.2 and the task's Implementation Details say 11 % (desktop). MASTER §2.3, `kit.css` (`--sign-tint: .10` dark / `.09` light), `ZodiacColors.signTintOpacity` (0.10 / 0.09, shipped in UI-001) and therefore the reference PNGs say 10 % / 9 %. The task's criterion 2 says "11 % dark / 9 % light per §2.3", which no source states. **Recommendation:** use `ZodiacColors.signTintOpacity` (10 % dark / 9 % light), because it is the value the PNGs are rendered with and the token already exists; record that MASTER §7.2's 11 % and the task's 11 % are not edited (NAV-002 / UI-009 precedent), and add a note to the task file. **Cost of the alternative:** 11 % needs a second token, and the ring would no longer match the PNGs.
- **T2: who owns the band's rims.** The kit draws the `accent-line` outer circle and the `line` inner circle together with the sectors, after them. Today `ProportionGridLayer` draws both. **Recommendation:** `SignRingLayer` draws them (so removing the scaffolding grid later cannot remove the sign band's rim, and the task's "accent-line rim" is true of this layer), and the grid drops those two circles and keeps the halo, the two body rings and the inner disc until WHL-006 / WHL-007 / WHL-008 take them. **Cost of the alternative:** the grid keeps drawing them and the tint would paint over the rim stroke unless the grid runs after the ring layer, so the criterion depends on scaffolding.
- **T3 (informational, kit-driven):** the separator is not band-only. The kit draws each from the outer rim to `signBandInner − 18` units, so it runs 18 units past the inner edge across the tick zone (PNG evidence). The plan follows the kit.
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
| `packages/feature_wheel/lib/src/canvas/wheel_canvas.dart` (modify) | reads both from `Theme`; default layers `[SignRingLayer(), ProportionGridLayer()]` |
| `packages/feature_wheel/lib/src/geometry/wheel_proportions.dart` (modify) | new field `signSeparatorInner` (232/300 desktop, 222/300 compact), in `==` / `hashCode` |
| `packages/feature_wheel/lib/src/canvas/proportion_grid_layer.dart` (modify) | drops the two sign-band circles (T2) |
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

- [ ] **Step 1: Failing tests.** `sign_element_test.dart`: a literal table of the 12 `(ZodiacSign, element)` pairs copied from `kit.js` `SIGNS` (fire: aries, leo, sagittarius; earth: taurus, virgo, capricorn; air: gemini, libra, aquarius; water: cancer, scorpio, pisces); `ZodiacSign.values` has length 12 and `elementOf` covers every value; each element appears exactly 3 times, and signs `i` and `i + 4` share an element. A second test reads `kit.js` text and checks each `k: '<sign>'` line's `el:` against `elementOf` (second source, as UI-001 did for kit.css). In `wheel_proportions_test.dart`: `desktop.signSeparatorInner == 232 / 300`, `compact.signSeparatorInner == 222 / 300`, equal to `signBandInner − 18 / 300`, and that the equality / hash tests include the new field.
- [ ] **Step 2: Run** `fvm flutter test packages/feature_wheel/test/canvas/sign_element_test.dart packages/feature_wheel/test/geometry/wheel_proportions_test.dart`; expect FAIL (undefined names).
- [ ] **Step 3: Implement** the enum and `elementOf` (an exhaustive `switch` on `ZodiacSign`, so a new sign fails to compile) and the field with its doc comment citing `kit.js` (`rTick − 18`).
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

**Files:** create `lib/src/canvas/sign_ring_layer.dart`, `test/canvas/sign_ring_layer_test.dart`; modify `proportion_grid_layer.dart`, `wheel_canvas.dart` (default `layers`), `wheel_harness.dart`, `feature_wheel.dart`, `test/canvas/proportion_grid_test.dart`.

**Interfaces:**
- Consumes: Task 1 and 2 outputs; `WheelGeometry.offsetOf(longitude, ringFraction, pointerLongitude:)`, `ringRadius`, `center`.
- Produces: `final class SignRingLayer implements WheelLayer` (`const SignRingLayer()`), exported.

Paint order inside the layer, per the kit: for `i` in 0…11 (`a0 = i·30°`): the sector path (outer arc from `a0` to `a0 + 30°` at `signBandOuter`, line to the inner arc at `a0 + 30°`, inner arc back to `a0`) filled with `elementColor(i)` at `zodiac.signTintOpacity`; the glyph centred at longitude `a0 + 15°`, radius `(signBandOuter + signBandInner) / 2`, size `signGlyphSize · R`, colour `elementColor(i)`; the separator from `(a0, signBandOuter)` to `(a0, signSeparatorInner)`, `line`, width 1 kit unit (`R / 300`). Then the outer circle in `accentLine` and the inner circle in `line`, width 1 kit unit. The glyph is centred by laying out a `TextPainter` (`ZodiannGlyphs.signs[i]`, `context.textDirection`) and centring its width and height on the point, then checking the optical result against Chrome in Task 4 (kit: `text-anchor: middle; dominant-baseline: central`).

- [ ] **Step 1: Failing tests** in `sign_ring_layer_test.dart`, using a recording canvas for geometry (the `paints` matcher) and a pixel render for colour:
  - **Order and count:** 12 sector paths, 12 separators, 12 glyph runs, 2 rim circles, in the kit's order; glyph `i` is `ZodiannGlyphs.signs[i]` (Aries first, Pisces last), the same index as `ZodiacSign.values[i]`.
  - **Positions:** the separator for sign `i` starts on the ray at `i·30°` (pointer 0°: Aries' start is 12 o'clock, then counter-clockwise: Taurus starts at 11 o'clock side), at radii `0.98667 R` and `signSeparatorInner · R`; glyph centres at `a0 + 15°` on the mid radius; checked at desktop and compact, at two sizes (300 and 644 px).
  - **Colour and tint:** each sector's fill is its element's `ZodiacColors` colour at `signTintOpacity` (graphite 0.10, porcelain 0.09); each glyph is the element colour at full opacity; separators and the inner rim are `line`, the outer rim is `accentLine`. Expected values come from the tokens table typed in the test, not from the layer.
  - **Glyph size:** `signGlyphSize · R` (21 / 300 desktop, 30 / 300 compact), at two canvas sizes.
  - **Rotation:** `pointerLongitude` 123.4 and 359.9 move every sector and separator by exactly that angle, and no glyph rotates (the glyph transform is a translation only).
  - **Tiny radius:** `R = 1` paints with no exception and no NaN in any recorded offset.
  - **Text scale 2.0:** pixels are identical to scale 1.0.
  - **Theme switch:** repaint changes tint and colours.
  - **Grid hand-off:** `ProportionGridLayer` no longer draws circles at `signBandOuter` and `signBandInner` (update `proportion_grid_test.dart`: four rings plus the inner-disc fill remain: halo, body disc ring, body label ring, inner disc); with both layers on, the outer rim is drawn exactly once.
- [ ] **Step 2: Run** `fvm flutter test packages/feature_wheel/test/canvas`; expect FAIL.
- [ ] **Step 3: Implement** `SignRingLayer` as above; the sector path uses `Path.arcTo` on the two circles. Remove the two ring entries from the grid layer and update its doc comment (it names the rings that remain and who will take each). Default `WheelCanvas.layers` becomes `[SignRingLayer(), ProportionGridLayer()]`. Export from `feature_wheel.dart`.
- [ ] **Step 4: Run** `fvm flutter test packages/feature_wheel`; expect PASS.
- [ ] **Step 5: Commit** `feat(ZOD-WHL-002): render the zodiac sign ring`.

### Task 4: fidelity to the design (criteria 1–3)

**Files:** create `tool/wheel/render_sign_ring_references.dart`, `packages/feature_wheel/test/fixtures/sign_ring/` (PNGs, `manifest.json`, `README.md`), `packages/feature_wheel/test/canvas/sign_ring_fidelity_test.dart`, `test/design/wheel_ring_png_test.dart`; modify the harness (font loading via `shared_ui/test/support/load_bundled_fonts.dart` pattern, a capture helper).

- [ ] **Step 1: The reference tool.** Following `tool/drawer/render_drawer_references.dart`: headless Chrome loads `_source/wheel.html`, injects CSS that hides every wheel element except the ring (`.tick`, `.deg-lbl`, `.inner`, `.asp`, `.connector`, `.body-bg`, `.body-glyph`, `.body-deg`, `.pointer`, `.pointer-line`, `.hub`, and the halo circle), and screenshots the wheel at 644 × 656 px (dpr 1) for desktop and compact, in dark and light. The manifest stores the SHA-256 of `kit.js`, `kit.css` and `wheel.html`; regenerate only when they change. Run it and commit the 4 PNGs.
- [ ] **Step 2: Failing fidelity test.** Render `WheelCanvas` with `[SignRingLayer()]` only, at 644 × 656, with the bundled fonts loaded, in the same four combinations, and compare with the reference by one extractor over the annulus `signBandInner − 20 … signBandOuter + 2` units: sector fill colours at 12 sample points per sign within ±2 per channel; separator and rim pixel positions within 1 px; glyph ink centroid per sign within 2 px and glyph ink bounding box within 2 px; mean absolute difference over the annulus under a ceiling calibrated as in FND-009 (`max(round_up(worst × 1.5), floor)`), recorded in the fixtures README. Expected: FAIL before the glyph centring is tuned, then PASS.
- [ ] **Step 3: Tune** only the glyph centring offset (TextPainter metrics versus `dominant-baseline: central`), documented in the layer; no change to the proportions.
- [ ] **Step 4: Glyph font check** (the UI-002 rule): every drawn glyph renders in the bundled glyph font, never the emoji face. Assert that the glyph paragraph's resolved font family list starts with the Symbols fonts and that the rendered ink is single-colour per sign (one hue, antialiasing aside), as UI-002 did.
- [ ] **Step 5: L-6 in Flutter.** Render the same ring in `Locale('en')` and `Locale('he')` (real delegates, so RTL is real): the two images are byte-identical, desktop and compact, dark and light.
- [ ] **Step 6: L-6 in the designer PNGs** (criterion 3). `test/design/wheel_ring_png_test.dart` (root package, `image ^4.13.1` is already a root dev dependency) loads `01-zodiac-wheel_desktop_en_dark.png` and `_he_dark.png`, finds each wheel's centre and radius from the accent-line rim, crops the same box around both, masks to the ring annulus, and asserts the pixels are equal (tolerance 0; if resampling forces more, record the measured maximum and justify it in the test). The panel position differs between the two files (the wheel panel is on the start side), so the test must locate the centre per image instead of assuming coordinates. Repeat for the `_light_` pair. The test also asserts the rim was found in both (a self-check, so a failed search cannot pass by comparing blanks).
- [ ] **Step 7: Mutation proof.** Each of these edits to production code must turn a named test red, then be restored: element table rotated by one sign; glyph list reversed; separator inner radius = band inner edge; sector sweep 29° or 31°; tint 0.11; the layer mirrored for RTL (negating x); glyph rotated with its sector; rim colours swapped; both rims drawn by the grid as well as the layer (double draw). Record the list in the commit message.
- [ ] **Step 8: Run** `fvm dart run melos run lint` and `fvm dart run melos run test`; expect exit 0 for both.
- [ ] **Step 9: Commit** `test(ZOD-WHL-002): check the sign ring against the design`.

### Task 5: verify, review, document, hand over

- [ ] **Step 1:** run lint, the full tests, and `flutter build apk --debug` (as WHL-001 did); record the counts and the commit.
- [ ] **Step 2:** device check (the S22 Ultra used in NAV-003 if connected, else emulator-5554): a throwaway debug entry shows the wheel; confirm the glyphs are monochrome and the ring matches the reference by eye; record which device. If no device is available, record that and the reason (the layer is not routed until WHL-025).
- [ ] **Step 3:** one fresh whole-branch review (`requesting-code-review`); fix Critical / Important findings test-first.
- [ ] **Step 4:** update the task file (`Status`, ticked criteria with evidence, the T1 note), `docs/development/TASKS.md`, `docs/PROGRESS.md` (Current Task, Completed Tasks with commands, results and commit, Technical Decisions T1 / T2 / T3, Git State; also correct the stale "PR open" line for WHL-001, which is merged `06c377c`), and the grid-layer note in the deferred minors.
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
- **Grid hand-off:** the grid still draws the halo, the body rings and the inner disc; each owner (WHL-006 / 007 / 008) must remove its ring from the grid when it adds its layer. Recorded in PROGRESS at close-out.
