# ZOD-WHL-003 Render the degree scale: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (default, sequential) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. No work here is independent enough for subagents (every task edits the same layer, context and proportion files).

**Goal:** Draw the wheel's degree scale: the 1° / 5° / 10° tick marks running inward from the sign band's inner edge, and the "10" and "20" labels inside each sign, as one new `WheelLayer`.

**Architecture:** A new `DegreeScaleLayer` (one `WheelLayer`, ARCH-5: no widget per tick or label) runs after `SignRingLayer` in `WheelCanvas`'s default list. It draws 348 `drawLine` ticks (every degree except multiples of 30°, which are WHL-002's separators) and 24 labels with `TextPainter`. `WheelPaintContext` gains one text input, `labelStyle` (the `ZodiannTextStyles.micro` role: UI family by script, tabular figures), so layers still read no provider and no `Theme`. Three tick stroke widths join `WheelProportions` (kit units / R, like every other size).

**Tech Stack:** Flutter 3.50 / Dart 3.14, `feature_wheel`, `shared_ui` (`ZodiannSurfaces.text2` / `text3`, `ZodiannTextStyles`), headless Chrome for references (the WHL-002 / NAV-002 pattern).

**Spec:** `assets/zodiann-specification.md` WH-2, L-6; `design-reference/zodiann/MASTER.md` §7.2 ("Degree ticks", "Degree numbers"), §3 (tabular figures); task file `docs/development/zodiac-wheel/ZOD-WHL-003-render-the-degree-scale.md`; the kit `design-reference/zodiann/_source/kit.js` `wheelSVG` (lines 296-348, ticks 316-323) and `kit.css` (lines 304-307), which render the PNGs and so win over MASTER's prose (PROGRESS D1 / D7 precedent).

## Product-owner decisions

- **P1: tick colour and weight (decided 2026-11-19: follow the kit).** MASTER §7.2 and the task say all ticks are `text-2`. The kit draws the 1° ticks in `text-3` at 0.8 px, the 5° ticks in `text-3` at 1 px and the 10° ticks in `text-2` at 1.2 px (`kit.css:304-306`), and the degree labels in `text-3` (`kit.css:307`). The layer follows the kit (it renders the PNGs, and criterion 3 says "matches the reference screenshot"). MASTER and the task file are not edited; Task 4 adds a Note to the task file.
- **P2 (informational, kit-driven):** no tick at multiples of 30° (`kit.js:318`); the 30° mark is WHL-002's separator, which runs from the outer rim to `signBandInner − 18` units and so crosses the whole tick zone (the longest tick ends at `signBandInner − 14`). The labels are the kit's `d % 30`, i.e. "10" and "20" in every sign, drawn at every 10° multiple that is not a multiple of 30°.
- **P3 (informational):** the label radius is `WheelProportions.degreeNumberRadius` (`signBandInner − 26` units, ZOD-WHL-001 decision D7) and the font size `degreeNumberFontSize` (9.5 desktop, 14 compact); both already exist. MASTER's "22 px inside the band" is not used (WHL-001 D7). WHL-001 confirmed the radius only by eye; Task 3 measures it against the Chrome reference and the designer PNG.
- **P4 (design choice, handed over by WHL-002):** the context gains `labelStyle` (the `micro` role), not the whole `ZodiannTextStyles`; WHL-004's body-degree label derives from it with `copyWith(fontSize, fontWeight)`. Recorded in PROGRESS Technical Decisions in Task 4.
- **Gate 1:** the layer reads no ephemeris or crossing output (pure geometry of 0°–360°), so Gate 1 applies from ZOD-WHL-004.

## Global Constraints

- **ARCH-5:** one `CustomPainter`, one `RepaintBoundary`; no widget per tick or label.
- **ARCH-3:** the screen's one provider is untouched; the layer is a pure function of its context.
- **L-6:** the scale runs counter-clockwise from the pointer-relative 0° and the digits are Western, in the same place and drawn left to right in every language; the layer never branches on text direction, and label text gets `TextDirection.ltr` from the context.
- **ARCH-7:** no colour literal in `lib/`; colours from `ZodiannSurfaces` (`text2`, `text3`).
- **UI-003 dimension guard** (`test/architecture/no_magic_dimensions_test.dart`) stays green: lengths, radii and stroke widths come from `WheelProportions` fractions, never literals in the layer.
- **Typography:** the label style derives from the `ZodiannTextStyles.micro` role with `copyWith(fontSize, color)`; it keeps tabular figures (MASTER §3: "Tabular figures everywhere"); never build a `TextStyle` from scratch. Label strings are produced from the degree number, never typed as literals in a `Text`; they go through `TextPainter`, not `Text` (L10-001 guard).
- **Logical pixels (ARCH-8).**
- **Commands:** `fvm flutter …`, `fvm dart …`, `fvm dart run melos <cmd>`; import `material_ui`, never `material.dart`.
- **Scope:** no bodies, connectors, pointer, interaction, router wiring (WHL-004…025); no change to `SignRingLayer`. Compact values come only through the existing compact table (WHL-024 owns responsive polish).

## Review Focus

- **Count and classes:** exactly 348 ticks (288 one-degree, 36 five-degree, 24 ten-degree), none at a multiple of 30°, no tick at 360° twice. Test in Task 2.
- **Labels never at a sign boundary:** 24 labels, texts "10" / "20" only, none "0" or "30". Test in Task 2.
- **Pointer longitude ≠ 0 and the wrap:** the scale rotates with the wheel (`offsetOf(..., pointerLongitude:)`), labels stay upright; test 123.4 and 359.9. Test in Task 2.
- **Tiny radius:** R = 1 paints with no exception and no NaN offset. Test in Task 2.
- **Hebrew locale / script swap and text scale 2.0:** the digits do not change size, family or position (the layer uses the table's sizes, never `MediaQuery.textScaler`); the en and he renders are compared byte for byte. The kit itself switches `font-ui` to Plex Sans Hebrew under `lang="he"` (`kit.css:108`, `kit.js:9`), and the two faces' digits have identical outlines, advances and vertical metrics (checked in the Regular TTFs), so the en and he renders are expected to be byte-identical; if they differ, compare the designer's he PNG labels first and surface it (Task 3 Step 4), not hide it.
- **Theme switch:** the three tick classes and the labels change colour with no stale cache (`shouldRepaint`). Test in Task 2.

## File Structure

| File | Responsibility |
|---|---|
| `packages/feature_wheel/lib/src/geometry/wheel_proportions.dart` (modify) | new fields `tickStrokeDegree`, `tickStrokeFive`, `tickStrokeTen` (0.8 / 1 / 1.2 kit units over R), in `==` / `hashCode` |
| `packages/feature_wheel/lib/src/canvas/wheel_layer.dart` (modify) | `WheelPaintContext` gains `labelStyle` |
| `packages/feature_wheel/lib/src/canvas/wheel_painter.dart` (modify) | new field, passed on, compared in `shouldRepaint` |
| `packages/feature_wheel/lib/src/canvas/wheel_canvas.dart` (modify) | reads `ZodiannTextStyles.micro`; default layers `[SignRingLayer(), DegreeScaleLayer()]` |
| `packages/feature_wheel/lib/src/canvas/degree_scale_layer.dart` (create) | `DegreeScaleLayer` and the pure tick table `DegreeTick` / `degreeTicks()` |
| `packages/feature_wheel/lib/feature_wheel.dart` (modify) | exports |
| `packages/feature_wheel/test/canvas/degree_scale_layer_test.dart` (create) | unit and canvas tests |
| `packages/feature_wheel/test/canvas/degree_scale_fidelity_test.dart` (create) | Chrome-reference comparison |
| `packages/feature_wheel/test/support/wheel_harness.dart` (modify) | default layers; `OrientationProbeLayer` records `labelStyles` |
| `packages/feature_wheel/test/support/load_wheel_fonts.dart` (modify) | also loads `ibm-plex-sans/IBMPlexSans-Regular.ttf` and `ibm-plex-sans-hebrew/IBMPlexSansHebrew-Regular.ttf` under `packages/shared_ui/<ZodiannFonts.plexSans / plexSansHebrew>` (today it loads only the symbol fonts and Noto Sans, so labels would render in the test fallback face); add `Future<void> loadWheelTextFonts()` beside `loadWheelGlyphFonts()` (Regular weights only; `micro` is w400); `loadWheelGlyphFonts` is unchanged, so the WHL-002 tests keep loading exactly what they load today; the degree-scale tests call both in `setUpAll` |
| `tool/wheel/kit_reference.dart` (create) | the Chrome invocation, PNG size check and manifest writer, extracted from `render_sign_ring_references.dart` (which is refactored to use it; its four PNGs and manifest stay byte-identical) |
| `tool/wheel/render_degree_scale_references.dart` (create) | Chrome references (hides everything but ticks and labels) |
| `packages/feature_wheel/test/fixtures/degree_scale/` (create) | 4 reference PNGs, manifest with SHA-256 of the kit files, README |
| `test/design/wheel_scale_png_test.dart` (create, root) | designer PNG: tick classes and label centres (criterion 3) |

---

### Task 1: the stroke widths and the label style input

**Files:** modify `wheel_proportions.dart`, `wheel_layer.dart`, `wheel_painter.dart`, `wheel_canvas.dart`, `test/support/wheel_harness.dart`, `test/geometry/wheel_proportions_test.dart`, `test/canvas/wheel_canvas_test.dart`, `test/canvas/sign_ring_layer_test.dart` (its context helper, line 68).

**Interfaces:**
- Produces: `WheelProportions.tickStrokeDegree` / `tickStrokeFive` / `tickStrokeTen` (fractions of `R`: `0.8 / referenceRadius`, `1 / referenceRadius`, `1.2 / referenceRadius`, identical in `desktop` and `compact`); `WheelPaintContext({…, required TextStyle labelStyle})`; `WheelPainter({…, required this.labelStyle})`.

- [ ] **Step 1: Failing tests.** `wheel_proportions_test.dart`: the three stroke fields equal `0.8 / 300`, `1 / 300`, `1.2 / 300` in both tables (typed literally; source: `kit.css:304-306`), and equality / hash include them (a table differing only in one stroke is unequal). `wheel_canvas_test.dart`: the probe layer's context `labelStyle` equals `ZodiannTextStyles.micro` of the theme (graphite and porcelain), has `fontFeatures` containing `FontFeature.tabularFigures()`, and `shouldRepaint` is true when only `labelStyle` changes.
- [ ] **Step 2: Run** `fvm flutter test packages/feature_wheel/test/geometry packages/feature_wheel/test/canvas/wheel_canvas_test.dart`; expect FAIL (undefined names).
- [ ] **Step 3: Implement** the fields (doc comments cite `kit.css`), the context and painter field, and `WheelCanvas` reading `Theme.of(context).extension<ZodiannTextStyles>()!.micro`. The existing direct constructions get the argument: `_context` in `sign_ring_layer_test.dart` (lines 63-76) and `painter()` in `wheel_canvas_test.dart` (lines 245-263, with a `TextStyle? labelStyle` parameter used by the repaint test); `OrientationProbeLayer` gains a `labelStyles` list for the context test.
- [ ] **Step 4: Run** `fvm flutter test packages/feature_wheel`; expect PASS (the previous tests unchanged in meaning).
- [ ] **Step 5: Commit** `feat(ZOD-WHL-003): add the tick stroke widths and the label style input`.

### Task 2: `DegreeScaleLayer`

**Files:** create `lib/src/canvas/degree_scale_layer.dart`, `test/canvas/degree_scale_layer_test.dart`; modify `wheel_canvas.dart` (default `layers`), `wheel_harness.dart`, `feature_wheel.dart`, and the tests that count default-layer drawing (`wheel_canvas_test.dart` default-layer assertions, `test/wheel_screen_test.dart:81-104`; grep for `drawLine` and `paintsExactlyCountTimes` under `packages/feature_wheel/test`).

**Interfaces:**
- Consumes: Task 1; `WheelGeometry.offsetOf(longitude, ringFraction, pointerLongitude:)`, `ringRadius`; `WheelProportions.tickInnerEdge`, `tickLengthDegree` / `Five` / `Ten`, `degreeNumberRadius`, `degreeNumberFontSize`, `tickStroke*`.
- Produces: `enum TickClass { degree, five, ten }`; `final class DegreeTick { const DegreeTick(this.degree, this.tickClass); final int degree; final TickClass tickClass; }`; `List<DegreeTick> degreeTicks()` (pure, 348 entries, degrees 1…359 except multiples of 30, ascending); `final class DegreeScaleLayer implements WheelLayer` (`const DegreeScaleLayer()`), exported; `static const double labelCentringFactor` (a fraction of the label size, 0 until Task 3 Step 3, like WHL-002's glyph constant); `static TextStyle labelStyleOf(WheelPaintContext context)` = `context.labelStyle.copyWith(fontSize: degreeNumberFontSize · R, color: surfaces.text3)`, used by `paint`.

Draw order, as the kit: for `d` in 0…359 skipping `d % 30 == 0`: the tick line from `(d, tickInnerEdge)` to `(d, tickInnerEdge − length)` (butt caps, width per class), then, when `d % 10 == 0`, the label text `(d % 30).toString()` (never a string literal or interpolation in `TextSpan(text:)`, which `test/architecture/no_text_literals_test.dart` flags) centred at `(d, degreeNumberRadius)`, size `degreeNumberFontSize · R`, colour `text3`, upright, `TextDirection.ltr` from the context. Tick colours: `degree` and `five` `text3`, `ten` `text2` (P1).

- [ ] **Step 1: Failing tests** in `degree_scale_layer_test.dart` (recording canvas for geometry, a pixel render for colour):
  - **Table:** `degreeTicks()` has 348 entries; 288 / 36 / 24 per class; no degree divisible by 30; every `d % 10 == 0` is `ten`, every `d % 10 == 5` is `five`, the rest `degree`; ascending and unique. The table is checked against an independently written literal rule in the test (not by re-running the layer's expression): the ten-class degrees are exactly `{10, 20, 40, 50, …, 350}` (typed as a list).
  - **Lines:** the recorded `drawLine` calls number 348, in ascending degree order; at R = 300, centre (322, 334), pointer 0, desktop, against expected points (tolerance 0.01) computed in the test by its own two-line helper from the closed form `centre + r·(−sin d, −cos d)` (never by the layer's code), for d = 1, 5, 10, 11, 359, with start radius 250 and lengths 5 / 9 / 14 / 5 / 5, and for the compact table (start radius 240). The same rows at pointer 123.4 and 359.9 (the wrap) and at R = 150 (half the offsets).
  - **Strokes and colours:** each recorded line's paint width is `R / 300 × {0.8, 1, 1.2}` per class and `strokeCap` is butt; colours: `degree` / `five` are `surfaces.text3`, `ten` is `surfaces.text2`, in graphite and porcelain (expected values typed from the token table).
  - **Font self-check:** with the text fonts loaded (`setUpAll`), a `TextPainter` laying out `'10'` with `labelStyleOf` at desktop R = 300 has width 11.4 ± 0.1 (Plex digits advance 0.6 em: 2 × 0.6 × 9.5 = 11.4; the Noto Sans fallback gives 10.87 and the FlutterTest face about 19, both outside the tolerance), for the English and the Hebrew-script styles; without this the label pixel tests could pass on fallback boxes.
  - **`labelStyleOf`:** keeps `FontFeature.tabularFigures()`, the context's family and fallback, size `degreeNumberFontSize · R` (9.5 / 300 desktop, 14 / 300 compact), colour `text3`.
  - **Labels:** 24 recorded paragraphs; their heights equal `1.45 × degreeNumberFontSize · R` (the `micro` role's line height, `zodiann_text_styles.dart:233`); each centre is `offset + (longestLine / 2, height / 2)` as in WHL-002, and sits at `degreeNumberRadius` on the longitudes 10, 20, 40, 50, … (literal points at pointer 0, 123.4, 359.9); with the bundled fonts loaded, the pixels around label centres equal a reference render that paints `'10'` or `'20'` with the same style at the same offset, and are not equal to a render of `'0'` or `'30'` (a label at a sign boundary or a wrong digit fails; the recorded `Paragraph` exposes no text, as WHL-002 found).
  - **Upright, no transform:** no `#rotate` / `#transform` recorded.
  - **Tiny radius:** R = 1: no exception, no NaN in any recorded offset.
  - **Text scale 2.0:** pixels identical to scale 1.0 (pump a `SizedBox.shrink()` between the two renders, so a cached picture cannot hide a missing `shouldRepaint` field: WHL-002's deferred minor).
  - **Theme switch:** repaint changes the three classes' colours and the labels'.
  - **Default layers:** a default `WheelCanvas` draws the ring then the scale (the ring's three circles precede the first tick line; none of the scale's lines is drawn at a multiple of 30°).
- [ ] **Step 2: Run** `fvm flutter test packages/feature_wheel/test/canvas`; expect FAIL.
- [ ] **Step 3: Implement** `degreeTicks()` and `DegreeScaleLayer` as above; one `Paint` per class reused across ticks only if the recording canvas test shows it is safe, otherwise one per line (WHL-002 recorded that a recording canvas keeps the object it was given). Default `WheelCanvas.layers` becomes `[SignRingLayer(), DegreeScaleLayer()]`; export from `feature_wheel.dart`. The 24 `TextPainter` layouts per paint are accepted until WHL-010 profiles drag at frame rate (recorded in Risks).
- [ ] **Step 4: Run** `fvm flutter test packages/feature_wheel`; expect PASS.
- [ ] **Step 5: Commit** `feat(ZOD-WHL-003): render the degree scale`.

### Task 3: fidelity to the design (criteria 1–3)

**Files:** create `tool/wheel/render_degree_scale_references.dart`, `packages/feature_wheel/test/fixtures/degree_scale/` (4 PNGs, `manifest.json`, `README.md`), `test/canvas/degree_scale_fidelity_test.dart`, `test/design/wheel_scale_png_test.dart`; modify the harness if a capture helper is missing.

- [ ] **Step 1: The reference tool.** First extract the Chrome invocation, the PNG size check and the manifest writer of `tool/wheel/render_sign_ring_references.dart` (private top-level functions today) into `tool/wheel/kit_reference.dart`, and make the sign-ring tool use it; re-running it must leave its four PNGs and manifest byte-identical (`git status` clean). This check needs the Chrome version recorded in `fixtures/sign_ring/manifest.json`; if Chrome has updated, check the refactor by diff instead (the Chrome flags, the CSS and the manifest fields unchanged) and restore the committed fixtures with `git checkout -- packages/feature_wheel/test/fixtures/sign_ring`; never commit sign-ring fixtures regenerated by a different Chrome in this task. Then the degree-scale tool follows the same wrapper page, flags and 644 × 656 size check. The page's `<style>` hides everything except the scale: `svg.wheel > *:not(.tick):not(.deg-lbl) { display: none }`. `pointerLon` is `227.05` (`BODIES[0].lon`, `kit.js:170`), written to the manifest. Output: 4 PNGs (desktop / compact × dark / light) and the SHA-256 of `kit.js`, `kit.css`, `assets/fonts/fonts.css`. Run it and commit the files.
- [ ] **Step 2: Failing fidelity test.** For each reference render `WheelCanvas(proportions: …, state: const WheelState(pointerLongitude: 227.05), layers: const [DegreeScaleLayer()])` at 644 × 656 with the bundled fonts (`setUpAll` loads the text fonts too, see the File Structure row), over `ZodiannSurfaces.surface`, and compare through one extractor: for every non-multiple-of-30 degree, sample the ray at radii `signBandInner − 2 / − 7 / − 12` units and require the tick class the reference shows (present / absent at each radius, so a wrong length fails); tick pixel positions within 1 px; label ink centroid for all 24 labels within 2 px of the reference centroid, with the **measured** radius of the centroids reported against `degreeNumberRadius` (the check WHL-001 only did by eye); mean absolute difference over the scale annulus (`signBandInner − 40 … signBandInner + 1` units; the compact "10" ink reaches about 204.8 units at horizontal or diagonal positions, half-extents 7.6 × 5.1 at 14 units, so 40 leaves a margin) under a ceiling calibrated as in FND-009 (`max(round_up(worst × 1.5, 3), floor)`, the floor as in `_ceilings` of `sign_ring_fidelity_test.dart`), recorded in the fixtures README. Expected: FAIL before the label centring constant is tuned, then PASS.
- [ ] **Step 3: Tune** only `DegreeScaleLayer.labelCentringFactor` (TextPainter metrics versus `dominant-baseline: central`), documented in the layer; Task 2's tests stay green without edits.
- [ ] **Step 4: L-6 in Flutter.** Render the scale in `Locale('en')` and `Locale('he')` through the app's script builder (`MaterialApp.builder` with `withZodiannScript`, real delegates), desktop and compact, dark and light, and at `textScaler` 2.0 (a `SizedBox.shrink()` pumped between renders): the images must be byte-identical. The kit itself draws the labels in Plex Sans Hebrew under `lang="he"` (`kit.css:108`) and the two faces' digits have identical outlines and advances, so a difference is not expected: if the renders differ, compare the designer's he PNG labels first and surface it to the user instead of picking a side.
- [ ] **Step 5: The designer PNG** (criterion 3). `test/design/wheel_scale_png_test.dart` (root package, `image` is a root dev dependency) reuses the centre-and-radius finder of `test/design/wheel_ring_png_test.dart` (horizontal ray; extract it into `test/support/` if it is private; WHL-002's tests stay green), then on `01-zodiac-wheel_desktop_en_dark.png` and `_he_dark.png` (and the `_light_` pair): for every non-multiple-of-30 degree outside ±1.5° of a body longitude (connectors end at `rTick − 1`, `kit.js:334`) classify the tick from ray samples at the three radii and require the class given by a test-local rule (skip `d % 30 == 0`; `d % 10 == 0` → ten, `d % 5 == 0` → five, else degree; written in the test, because `feature_wheel` is not importable from the pure-Dart root package, which runs under `dart test`); find the "10" and "20" ink centroids in the first sign and require them at the kit radius within 2 px (scaled by the measured rim); assert the self-check that the rim was found in both files; assert the en and he scales equal within 1 per channel over the scale annulus (WHL-002's T4 tolerance). The test re-measures; the thresholds are calibrated and recorded, not guessed.
- [ ] **Step 6: Mutation proof.** Each edit to production code must turn a named test red, then be restored: tick lengths 5 / 9 / 14 swapped; ticks drawn at multiples of 30°; labels at multiples of 30° (texts "0" / "30"); label radius `signBandInner − 22` (MASTER's value); `degree` and `five` ticks in `text2`; all strokes one width; ticks starting at `signSeparatorInner`; x negated unconditionally; labels rotated with their longitude; tabular figures dropped in `labelStyleOf` (killed by the `labelStyleOf` test) and in `WheelCanvas`'s `labelStyle` (killed by Task 1's context test); `labelStyleOf` ignoring the context size (MediaQuery scale applied). Note: `tnum` is a no-op for the bundled Plex faces (their digits are all 0.6 em already), so no pixel test can see the feature; only the style tests guard it. Record the list in the commit message.
- [ ] **Step 7: Run** `fvm dart run melos run lint` and `fvm dart run melos run test`; expect exit 0 for both.
- [ ] **Step 8: Commit** `test(ZOD-WHL-003): check the degree scale against the design`.

### Task 4: verify, review, document, hand over

- [ ] **Step 1:** run lint, the full tests, and `cd apps/astro_mobile; fvm flutter build apk --debug`; record the counts and the commit.
- [ ] **Step 2:** device check if a device is authorized (a throwaway debug entry, not committed): ticks and labels crisp at the phone size, the label digits legible at 14 / 300 R; record the device, or that none was available (the layer is unrouted until WHL-025).
- [ ] **Step 3:** one fresh whole-branch review (`requesting-code-review`); fix Critical / Important findings test-first.
- [ ] **Step 4:** update the task file (`Status`, ticked criteria with evidence, a Note for P1: MASTER §7.2 and the task say all ticks `text-2`, the kit and the PNGs say `text-3` for 1° / 5°; not edited), `docs/development/TASKS.md`, `docs/PROGRESS.md` (Current Task, Completed Tasks with commands, results and commit, Technical Decisions P1–P3, Git State; correct the stale "PR open" wording for WHL-002, which is merged), and the measured label radius (closing the WHL-001 "by eye" open item).
- [ ] **Step 5:** push `task/ZOD-WHL-003-degree-scale`, open the PR, then add the PR link in a follow-up docs commit.

## Acceptance mapping

| Criterion | Proven by |
|---|---|
| 1. Tick length varies correctly at 1° / 5° / 10° all the way around | Task 2 table, line-literal and stroke tests; Task 3 Step 2 radial class sampling against Chrome, Step 5 against the designer PNG |
| 2. "10" and "20" at the correct position in every sign, never at 0 | Task 2 label tests (24 labels, texts, longitudes, no "0" / "30"); Task 3 centroid checks |
| 3. Matches the reference's tick density and label placement | Task 3 Steps 2 and 5 (calibrated ceilings, measured label radius) |

## Risks and open items

- **Digit face under the Hebrew script** (Review Focus): unresolved until Task 3 Step 4; surfaces to the user if the en and he renders differ.
- **Label vertical centring:** `dominant-baseline: central` has no Flutter equivalent; the one tuned constant is measured against Chrome, as WHL-002's.
- **Perf:** 348 `drawLine` and 24 `TextPainter` layouts per paint; accepted until WHL-010 profiles rotation at frame rate (cache the labels and ticks in a `Picture` per pointer-independent layout if it is flagged).
- **Designer PNG sampling** depends on the wheel's scale in the PNG (about 1.06 × the kit); the test measures it per image.
- **Not in scope, inherited:** the inner-disc fill (WHL-004), router wiring (WHL-025), on-device look of WHL-002 (still outstanding).

## Plan review

Reviewer note: the dedicated `plan-reviewer` agent could not start in round 1 (its definition named the invalid model `sonnet 5.5`, since fixed in PR #37), so both rounds ran as a `general-purpose` subagent (opus) given the body of `.claude/agents/plan-reviewer.md`, as the workflow allows.

### Round 1 (comprehensive) — verdict: approve after corrections

0 Critical, 4 Important, 7 Minor; nothing needing a product-owner decision. All applied:

- **I1 (applied):** the test font loader did not load Plex Sans / Plex Sans Hebrew, so the label pixel tests and the en / he byte comparison would have run on the fallback face. `load_wheel_fonts.dart` added to File Structure; a font self-check test (width of "10" ≈ 11.4); `setUpAll` loads the text fonts in Task 3.
- **I2 (applied):** `TextSpan(text: '${d % 30}')` would fail the L10-001 guard (`test/architecture/text_literals.dart`); the label text is `(d % 30).toString()`.
- **I3 (applied):** the root package is pure Dart and cannot import `degreeTicks()`; the designer-PNG test uses a test-local class rule.
- **I4 (applied):** the "tabular figures dropped" mutant cannot be killed by pixels (the Plex digits are all 0.6 em, no `tnum`); `labelStyleOf` added so style tests guard it, with the mutant list and a note updated.
- **M1 (applied)** the kit switches to Plex Sans Hebrew under `lang="he"` (the earlier "Latin face" wording was wrong); **M2 (applied)** the real constructor sites named; **M3 (applied)** the reference tool's helpers extracted to `tool/wheel/kit_reference.dart`; **M4 (applied)** label height is 1.45 × size; **M5 (applied)** annulus widened to `signBandInner − 36` and the ceiling floor named; **M6 (applied)** P4 records the `labelStyle` choice; **M7 (applied)** a `SizedBox.shrink()` between the en / he and text-scale renders.
- Open items: none.

### Round 2 (focused on the revision, `6e66097..aaf24e6`) — verdict: approve

0 Critical, 0 Important, 5 Minor. All round-1 findings resolved (M5 resolved differently, see M4 below). The reviewer re-derived the "10" width (Plex 11.4, Noto Sans 10.87), the 1.45 line height, and checked that loading the Plex fonts changes no WHL-002 test, that the `kit_reference.dart` refactor keeps the WHL-002 fixtures valid, and that the text-literal guard accepts `(d % 30).toString()`. Minors, all applied:

- **M1:** the loader helper is `loadWheelGlyphFonts()`; add `loadWheelTextFonts()` beside it, the old one unchanged.
- **M2:** the font self-check names all three faces' widths (11.4 / 10.87 / about 19).
- **M3:** "only hinting differs" was unverified; the faces' digit outlines, advances and vertical metrics are identical, so the en and he renders are expected to be byte-identical.
- **M4:** annulus widened to `signBandInner − 40` (the compact "10" ink reaches about 204.8 units at horizontal and diagonal positions).
- **M5:** the byte-identical regeneration check needs the Chrome version in the manifest; otherwise check by diff and never commit fixtures from a different Chrome.
- Open items: none.
