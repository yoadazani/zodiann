# ZOD-WHL-001 Wheel Canvas and Proportion System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The scaffold every wheel-drawing task paints onto: one `CustomPainter` on one `RepaintBoundary`, sized to the available space, with every ring and mark positioned as a fraction of the outer radius `R` (desktop and compact tables), a fixed LTR island, and the counter-clockwise longitude convention baked in once. The task's own visible content is the empty proportion grid (rings only).

**Architecture:**
- **`WheelProportions`** (immutable, const `desktop` / `compact`): MASTER §7.2's table as fractions of `R`. Later tasks read from it and never hold a radius literal.
- **`WheelGeometry`** (pure): a proportions table bound to a concrete radius and centre. It owns the longitude → pixel conversion (`offsetOf`) and the fit of the drawing into a box.
- **`WheelState` + `wheelStateProvider`** (`flutter_riverpod`): the screen's single provider (ARCH-3). It holds the longitude under the fixed pointer. Everything else is a pure function of it (`WheelGeometry` takes no `Ref`).
- **`WheelLayer`** (`abstract interface class`): one ordered paint step. `WheelPainter` is the single `CustomPainter` and runs its layers in order. WHL-002…009 each add a layer. This task adds `ProportionGridLayer` only.
- **`WheelCanvas`** (widget): `LayoutBuilder` → `RepaintBoundary` → `Directionality(ltr)` → `CustomPaint(WheelPainter)`. **`WheelScreen`** (`ConsumerWidget`) picks the proportion table by breakpoint and reads the provider.

**Tech Stack:** Flutter 3.50.0 / Dart 3.14.0 (FVM), `flutter_riverpod ^3.5.0`, `shared_ui` (tokens, `ZodiannBreakpoint`), `astro_core` (`normalizeDegrees`), `flutter_test`. No dependency the workspace does not already resolve.

**Spec / sources:** Task `docs/development/zodiac-wheel/ZOD-WHL-001-build-the-wheel-canvas-and-proportion-system.md`. Specification: ARCH-3, ARCH-5, ARCH-8, L-6 (`assets/zodiann-specification.md` lines 551–572). Design: `design-reference/zodiann/MASTER.md` §7.2 (table and orientation); `_source/kit.js:296-345` (`wheelSVG`, the geometry the table was rounded from); `screens/01-zodiac-wheel_desktop_en_dark.png`, `responsive/mobile/zodiac-wheel_mobile_en_dark.png` and `responsive/tablet/zodiac-wheel_tablet_en_dark.png` (measurement only).

## Proposed decisions (confirm at approval)

- **D1: values come from the kit, not the rounded table.** MASTER's fractions are `kit.js` units over `R = 300`, rounded (`296/300 = 0.98667`, MASTER says 0.987). Store `units / 300`. Tests compare to MASTER's printed values with a tolerance of 0.0005, and to the kit units exactly.
- **D2: fixed-pixel sizes scale with `R`.** In the kit those pixel sizes (ticks 5/9/14, glyph 17/27, disc r 14/21, dot r 3.2/4.5, label sizes) live in the same viewBox as `R = 300`, so they scale with the drawing. The compact table exists because they shrink on a phone. They are stored as `units / 300` too; callers get pixels from `WheelGeometry`. (ARCH-8: logical pixels.)
- **D3: the layer seam.** One painter, ordered `WheelLayer`s. Without it, WHL-002…009 would edit one growing painter, and the L-6 and single-canvas tests would have nothing to inject an asymmetric probe through. It is one small interface, not a framework.
- **D4: state is only the pointer longitude (default 0°).** The kit seeds the pointer with the first body's longitude. No bodies exist yet. WHL-009/010/014 extend `WheelState` (time, drag mode) and keep it the one provider.
- **D5: compact is "not desktop".** Desktop below/above is `ZodiannBreakpoint.desktop` (≥ 1100, MASTER §6); phone and tablet use the compact table (MASTER §7.2 header).
- **D6: no router wiring in this task (recommended).** The task file's criteria need no route, `WheelScreen` is not the real screen (WHL-025 builds the layout around it), and swapping the wheel route's `ScreenStub` breaks ~15 test sites that anchor on `find.byType(ScreenStub)` (the wheel is the default route). `WheelScreen` is exported and proven at feature level. **Cost of the alternative:** wiring now needs `appRouterProvider` to pass a real `screenBuilder`, and those tests to override it. Say so at approval if you want it now; PROGRESS's "replaces the blank wheel ScreenStub" note then moves here instead of WHL-025.
- **Open (measure, do not guess):** MASTER says degree numbers sit "22 px inside the band"; `kit.js` has `rNum = rSignIn − 26`. Task 1 measures the desktop PNG and records which value the design draws. WHL-003 (numbers) is the consumer.

## Global Constraints

- **ARCH-5:** one `CustomPainter` on one `RepaintBoundary`; no widget per tick, degree or body.
- **ARCH-3:** one Riverpod provider for this screen; derived values are pure functions of its state; no nested `ProviderScope` (the app's root scope is used).
- **L-6:** the drawing never mirrors; the painter and any canvas text sit under `Directionality(textDirection: TextDirection.ltr)`.
- **Orientation:** longitude increases counter-clockwise; the fixed pointer is at 12 o'clock (`kit.js`: `ang = (90 + lon − pointerLon)°`, `P = (r·cos, −r·sin)`).
- **ARCH-7 / tokens:** no colour literal (colours from `ZodiannSurfaces` via `Theme.of(context).extension<…>()!`); the UI-003 dimension guard (`test/architecture/no_magic_dimensions_test.dart`) and colour guard stay green.
- **No user-visible text** in `lib/` (L10-001 guard): this task draws none.
- **Flutter commands run as `fvm flutter …` / `fvm dart …`; Melos as `fvm dart run melos <cmd>`.** Packages import `material_ui`, not `material.dart` (as `ScreenStub` does).
- **Scope:** no signs, ticks, bodies, pointer, readout, interaction or router wiring. Those are WHL-002…025.

## Review Focus

- **Zero, tiny or non-finite constraints** (a collapsed layout, `Size.zero`): paints nothing and does not throw. Test in Task 4.
- **Unbounded height** (the canvas inside a scroll view on a phone): it takes its height from the width and the drawing's aspect (644:656), never `Infinity`. Test in Task 4.
- **Longitude out of range** (`-10`, `360`, `725`, `-1e-15`): the state always holds `[0, 360)`. `NaN` / infinity throws `ArgumentError` (from `normalizeDegrees`); the state stays unchanged. Test in Task 3.
- **Resize across 1100 and theme switch while shown:** the painter repaints with the new table and colours (`shouldRepaint`); state survives the resize. Test in Task 5.
- **RTL app (Hebrew):** nothing moves, and text drawn by any layer gets `TextDirection.ltr`. Test in Task 4, with a probe layer.

## File Structure

`packages/feature_wheel/` (all new unless stated):

| File | Responsibility |
|---|---|
| `pubspec.yaml` (modify) | add `astro_core`, `flutter_riverpod`, `material_ui`, `shared_ui` |
| `lib/feature_wheel.dart` (modify) | exports |
| `lib/src/geometry/wheel_proportions.dart` | the §7.2 table as fractions of `R` |
| `lib/src/geometry/wheel_geometry.dart` | `fit`, ring radii in pixels, `offsetOf` |
| `lib/src/state/wheel_state.dart` | `WheelState`, `WheelController`, `wheelStateProvider` |
| `lib/src/canvas/wheel_layer.dart` | `WheelLayer`, `WheelPaintContext` |
| `lib/src/canvas/proportion_grid_layer.dart` | the rings-only grid |
| `lib/src/canvas/wheel_painter.dart` | the one `CustomPainter` |
| `lib/src/canvas/wheel_canvas.dart` | the widget (fit, `RepaintBoundary`, LTR island) |
| `lib/src/wheel_screen.dart` | `WheelScreen` |
| `test/…` | one test file per source file, plus `test/support/wheel_harness.dart` |

`test/architecture/wheel_single_provider_test.dart` (root, new): the ARCH-3 source guard.

## Task 1: `WheelProportions` and the package wiring

**Files:** modify `packages/feature_wheel/pubspec.yaml`, `lib/feature_wheel.dart`; create `lib/src/geometry/wheel_proportions.dart`, `test/geometry/wheel_proportions_test.dart`.

**Interfaces:**
- Produces:
  ```dart
  @immutable final class WheelProportions {
    const WheelProportions({ /* every field below, required, named */ });
    static const double referenceRadius = 300;               // kit units
    static const WheelProportions desktop;  static const WheelProportions compact;
    // fractions of R (desktop | compact), kit units / 300:
    final double haloRadius;            // 306/300 | same        (MASTER 1.02)
    final double signBandOuter;         // 296/300 | same        (0.987)
    final double signBandInner;         // 250/300 | 240/300     (0.833 | 0.80)
    final double tickInnerEdge;         // = signBandInner (ticks run inward from the band)
    final double tickLengthDegree;      //  5/300
    final double tickLengthFive;        //  9/300
    final double tickLengthTen;         // 14/300
    final double degreeNumberRadius;    // (signBandInner·300 − 26)/300 — see the open item
    final double degreeNumberFontSize;  // 9.5/300 | 14/300
    final double signGlyphSize;         // 21/300 | 30/300
    final double bodyDiscRadiusAt;      // 192/300 | 180/300     (0.64 | 0.60)
    final double bodyDiscRadius;        // 14/300 | 21/300
    final double bodyGlyphSize;         // 17/300 | 27/300
    final double bodyLabelRadiusAt;     // 164/300 | 140/300     (0.547 | 0.467)
    final double bodyLabelFontSize;     // 11.5/300 | 19/300
    final double innerDiscRadius;       // 136/300 | 112/300     (0.453 | 0.373)
    final double trueDotRadius;         // 3.2/300 | 4.5/300
    final double minBodySeparationDegrees; // 11 | 16 (degrees, not a fraction)
    // the drawing's extent around the centre (kit viewBox −322 −334 644 656), in R:
    final double extentX; // 322/300   final double extentTop; // 334/300   final double extentBottom; // 322/300
    double get aspectRatio; // (2·extentX) / (extentTop + extentBottom) = 644/656
  }
  ```
  Values are `const` expressions such as `296 / referenceRadius`. The `…At` suffix means "ring radius at which it sits"; use these names exactly.
- Consumes: nothing.

- [ ] **Step 1: wire the package.** Add to `packages/feature_wheel/pubspec.yaml` `dependencies`: `astro_core` and `shared_ui` as `path: ../astro_core` / `path: ../shared_ui` (as `apps/astro_mobile/pubspec.yaml` does with `../../packages/…`), `flutter_riverpod: ^3.5.0`, `material_ui: ^1.11.0`. Run `fvm dart run melos bootstrap`. Expected: exit 0, root `pubspec.lock` unchanged (all four already resolve).
- [ ] **Step 2: write the failing test** `wheel_proportions_test.dart`, with these cases:
  - `desktop` fractions equal MASTER's printed values within 0.0005: halo 1.02, band 0.987 → 0.833, body discs 0.64, labels 0.547, inner 0.453. `compact`: band → 0.80, discs 0.60, labels 0.467, inner 0.373, other rows equal `desktop`'s.
  - `desktop` equals the kit units exactly: `signBandOuter * 300 == 296`, `bodyDiscRadiusAt * 300 == 192`, `trueDotRadius * 300` ≈ 3.2 (`closeTo(…, 1e-9)`).
  - ticks `5/9/14` units, glyph and disc sizes `17/14` desktop and `27/21` compact, separation `11` and `16`.
  - invariants for both tables: `haloRadius > signBandOuter > signBandInner > bodyDiscRadiusAt > bodyLabelRadiusAt > innerDiscRadius > 0`; `aspectRatio` is within 1e-9 of `644/656`.
- [ ] **Step 3: run it, expect FAIL** (`WheelProportions` undefined): `cd packages/feature_wheel; fvm flutter test test/geometry/wheel_proportions_test.dart`.
- [ ] **Step 4: implement `WheelProportions`** as specified. Doc each field with its MASTER row. Export it from `feature_wheel.dart`.
- [ ] **Step 5: measure the open item.** Decode `screens/01-zodiac-wheel_desktop_en_dark.png` (as the NAV-001 plan did, a throwaway script in the scratchpad, not committed) and locate the "10" degree-number centres against the band's inner edge. Keep `degreeNumberRadius` at kit's `−26` if the PNG agrees; use `−22` if it shows 22. Put the measured value, the script's one-line result and the choice in the field's doc comment. Report it at execution.
- [ ] **Step 6: run it, expect PASS.** Run `fvm dart run melos run analyze` for the package. Expected: no issues.
- [ ] **Step 7: commit** `feat(ZOD-WHL-001): add the wheel proportion table`.

## Task 2: `WheelGeometry`

**Files:** create `lib/src/geometry/wheel_geometry.dart`, `test/geometry/wheel_geometry_test.dart`; export from `feature_wheel.dart`.

**Interfaces:**
- Consumes: `WheelProportions` (Task 1).
- Produces:
  ```dart
  @immutable final class WheelGeometry {
    const WheelGeometry({required WheelProportions proportions, required double radius, required Offset center});
    factory WheelGeometry.fit(Size box, WheelProportions proportions); // largest R whose extents fit; content centred in the box
    final WheelProportions proportions; final double radius; final Offset center;
    double ringRadius(double fraction);           // fraction * radius
    Offset offsetOf(double longitude, double ringFraction, {double pointerLongitude = 0}); // absolute, centre included
    double angleOf(double longitude, {double pointerLongitude = 0}); // radians, math convention (CCW from +x), kit's `ang`
    // equality + hashCode on all three fields
  }
  ```
  `fit` returns `radius: 0` for an empty or non-finite box. `offsetOf` takes a fraction of `R` (not pixels).
- Orientation, exactly the kit's: `angleOf = (90 + (longitude − pointerLongitude))° in radians`; `offsetOf = center + Offset(r·cos a, −r·sin a)` with `r = ringRadius(ringFraction)`.

- [ ] **Step 1: write the failing test.** Cases (use `closeTo(…, 1e-9)`):
  - with `pointerLongitude 0`, radius 300, centre (0, 0), fraction 1: longitude 0 → `(0, −300)` (12 o'clock); 90 → `(−300, 0)` (9 o'clock, **counter-clockwise**); 180 → `(0, 300)`; 270 → `(300, 0)`.
  - `pointerLongitude 90` puts longitude 90 at 12 o'clock; `pointerLongitude 10` moves longitude 10 to 12 o'clock and longitude 40 by 30° counter-clockwise of it. Negative and ≥ 360 inputs give the same point as their normalised value.
  - `centre` is added: the same cases with centre (100, 50).
  - `ringRadius(signBandOuter) == 0.98667·radius` for `desktop`.
  - `fit`: a 644 × 656 box → radius 300 with centre (322, 334) (the kit's origin); a 1000 × 656 box → radius 300, centre x 500, y 334; a 644 × 1000 box → radius 300, centre x 322, y `(1000 − 656)/2 + 334`; a 322 × 328 box → radius 150. `Size.zero`, `Size(0, 100)`, `Size(double.nan, 100)` and `Size(double.infinity, 100)` give radius 0.
  - value equality (two equal geometries are `==`).
- [ ] **Step 2: run it, expect FAIL.**
- [ ] **Step 3: implement.** `fit`: `radius = min(box.width / (2·extentX), box.height / (extentTop + extentBottom))`; `center = Offset(box.width / 2, (box.height − (extentTop + extentBottom)·radius) / 2 + extentTop·radius)`. No imports beyond `dart:math` and `package:flutter/painting.dart`; **no riverpod** (guarded in Task 3).
- [ ] **Step 4: run it, expect PASS.** Then analyze.
- [ ] **Step 5: commit** `feat(ZOD-WHL-001): add the wheel geometry and orientation convention`.

## Task 3: the screen's single provider (ARCH-3)

**Files:** create `lib/src/state/wheel_state.dart`, `test/state/wheel_state_test.dart`, `test/architecture/wheel_single_provider_test.dart` (root); export from `feature_wheel.dart`.

**Interfaces:**
- Produces:
  ```dart
  @immutable final class WheelState {
    const WheelState({this.pointerLongitude = 0});   // [0, 360); asserted
    final double pointerLongitude;                    // value equality
  }
  class WheelController extends Notifier<WheelState> {
    @override WheelState build();                    // const WheelState()
    void setPointerLongitude(double longitude);      // state = WheelState(pointerLongitude: normalizeDegrees(longitude))
  }
  final NotifierProvider<WheelController, WheelState> wheelStateProvider;
  ```
- This is the **only** provider declaration in `packages/feature_wheel/lib`.

- [ ] **Step 1: write the failing tests.**
  - `wheel_state_test.dart` (a `ProviderContainer`): default is `0`; `setPointerLongitude(-10)` → 350; `360` → 0; `725` → 5; `-1e-15` → 0 (never 360); a value change notifies listeners; setting the same value does not notify; `NaN` and `double.infinity` throw `ArgumentError` and leave the state unchanged.
  - `wheel_single_provider_test.dart` (root, `package:test`, same walk and `cleanDartSource` helper as `no_magic_dimensions_test.dart`): in `packages/feature_wheel/lib` there is exactly **one** provider declaration (a regex on cleaned source for `…Provider<…>(` / `Provider(` constructors, excluding `ProviderScope` and `ProviderContainer`), zero `ProviderScope` and zero `ProviderContainer` occurrences, and no file under `src/geometry/` mentions `riverpod` (the derived values are pure). Add controls on inline strings so the scanner is proven: a source with two providers fails, one with a `ProviderScope(` fails, one with `ref.watch(` inside `geometry/` fails.
- [ ] **Step 2: run, expect FAIL** (`fvm flutter test` in the package; `fvm dart test test/architecture/wheel_single_provider_test.dart` at the root).
- [ ] **Step 3: implement** `WheelState`, `WheelController`, `wheelStateProvider`. `normalizeDegrees` is from `astro_core`. Skip the state write when the new value `==` the old.
- [ ] **Step 4: run, expect PASS.** Mutation check: add a second provider to a scratch copy of `lib/` and confirm the guard test goes red; revert. Record it.
- [ ] **Step 5: commit** `feat(ZOD-WHL-001): add the wheel's single state provider and its guard`.

## Task 4: layers, painter, canvas, proportion grid

**Files:** create `lib/src/canvas/wheel_layer.dart`, `proportion_grid_layer.dart`, `wheel_painter.dart`, `wheel_canvas.dart`, `test/support/wheel_harness.dart`, `test/canvas/proportion_grid_test.dart`, `wheel_canvas_test.dart`; export from `feature_wheel.dart`.

**Interfaces:**
- Consumes: `WheelGeometry`, `WheelProportions`, `WheelState`.
- Produces:
  ```dart
  final class WheelPaintContext {   // what a layer is given
    const WheelPaintContext({required Canvas canvas, required WheelGeometry geometry, required WheelState state,
        required ZodiannSurfaces surfaces, required TextDirection textDirection});
    // plain final fields with the same names
    double get pointerLongitude;  // state.pointerLongitude
  }
  abstract interface class WheelLayer { void paint(WheelPaintContext context); }
  final class ProportionGridLayer implements WheelLayer { const ProportionGridLayer(); }
  final class WheelPainter extends CustomPainter {
    WheelPainter({required this.proportions, required this.state, required this.surfaces,
        required this.textDirection, required this.layers});
    // paint: WheelGeometry.fit(size, proportions); if radius <= 0 return; layers in order
    // shouldRepaint: any field differs (layers by list identity-or-element equality)
  }
  class WheelCanvas extends StatelessWidget {
    const WheelCanvas({super.key, required this.proportions, required this.state,
        this.layers = const [ProportionGridLayer()]});
  }
  ```
- `ProportionGridLayer` strokes six concentric circles at the table's radii (`haloRadius` in `line` at 50 % opacity, `signBandOuter` in `accentLine`, `signBandInner`, `bodyDiscRadiusAt`, `bodyLabelRadiusAt`, `innerDiscRadius` in `line`; hairline stroke) and fills the inner disc with `bgRaised` first. Radii come from `geometry.ringRadius(...)`; colours from `surfaces`.
- `WheelCanvas.build`: `LayoutBuilder`; size = `Size(w, bounded ? maxHeight : w / proportions.aspectRatio)`; child `RepaintBoundary(child: Directionality(textDirection: TextDirection.ltr, child: Builder(builder: (c) => CustomPaint(size: size, painter: WheelPainter(…, surfaces: Theme.of(c).extension<ZodiannSurfaces>()!, textDirection: Directionality.of(c), …)))))`. Non-finite or non-positive size paints nothing.

- [ ] **Step 1: write `wheel_harness.dart`** (test support): `pumpWheelCanvas(tester, {size, proportions, state, layers, textDirection, locale, brightness})` mounting a themed `MaterialApp` (the app's `ZodiannTheme` for the brightness; see how `packages/shared_ui/test/support` builds one) with a fixed-size box, and an `OrientationProbeLayer` (test-only `WheelLayer`) that fills a small circle at `geometry.offsetOf(90, ringFraction, pointerLongitude: …)` and records the `textDirection` it was given.
- [ ] **Step 2: write the failing tests.**
  - `proportion_grid_test.dart`: for each table (`desktop`, `compact`) at two box sizes (644 × 656 and 322 × 328), `expect(renderObject, paints..circle(x: cx, y: cy, radius: expectedFraction·R, …))` for each of the six rings, in order; `expectedFraction` is the **MASTER-printed** value (tolerance 0.0005·R), not read from the table object. A mutation (a ring radius off by 2 %) must fail it. The inner disc fill precedes the strokes.
  - `wheel_canvas_test.dart` (one test per bullet):
    - **single canvas (ARCH-5):** under `WheelCanvas` there is exactly one `CustomPaint` whose painter is a `WheelPainter`, exactly one `RepaintBoundary` that is its ancestor within the canvas, and **zero** `Positioned`, `Transform`, `Text`, `Stack` and `Opacity` descendants; the widget count under `WheelCanvas` is equal at pointer 0° and 123.4° and with 1 or 3 layers.
    - **never mirrors (L-6):** pumped in an RTL `Directionality` with `Locale('he')`, the probe's circle is at the same position as under LTR (left of centre for longitude 90, at pointer 0), the probe records `TextDirection.ltr`, and the nearest `Directionality` above the wheel's `CustomPaint` is LTR. Mutation: delete the `Directionality` wrapper and confirm the probe and ancestor tests fail.
    - **sizing:** a 644 × 656 box gives radius 300 with the grid's outer ring at 306; a wider box centres the drawing; a bounded-width, unbounded-height parent (a `SingleChildScrollView`) yields height = width / aspect and does not throw; `SizedBox.shrink`, 0 × 100 and 100 × 0 boxes paint no circles and throw nothing.
    - **repaint:** a changed pointer longitude, a changed proportions table and a changed brightness each repaint (`shouldRepaint` true); an identical rebuild does not.
- [ ] **Step 3: run, expect FAIL.**
- [ ] **Step 4: implement** the four files as specified. The painter reads no provider; `WheelCanvas` takes state as a parameter. Keep the stroke widths and the 50 % opacity as named private constants in the layer (a hairline needs no token, and the UI-003 guard does not scan `Paint.strokeWidth`; if it flags something, say so, do not add an exemption).
- [ ] **Step 5: run, expect PASS.** Run the two root guards, `fvm dart test test/architecture/no_magic_dimensions_test.dart test/architecture/no_color_literals_test.dart`, then analyze and format-check the package.
- [ ] **Step 6: commit** `feat(ZOD-WHL-001): add the single wheel painter, canvas and proportion grid`.

## Task 5: `WheelScreen`

**Files:** create `lib/src/wheel_screen.dart`, `test/wheel_screen_test.dart`; export from `feature_wheel.dart`.

**Interfaces:**
- Consumes: `wheelStateProvider`, `WheelCanvas`, `WheelProportions`, `ZodiannBreakpoint.forWidth` (`shared_ui`).
- Produces: `class WheelScreen extends ConsumerWidget { const WheelScreen({super.key}); }`. It watches `wheelStateProvider`, chooses `WheelProportions.desktop` when `ZodiannBreakpoint.forWidth(MediaQuery.sizeOf(context).width) == ZodiannBreakpoint.desktop`, else `compact`, and returns a `WheelCanvas` centred in its space. No `ProviderScope`.

- [ ] **Step 1: write the failing tests.**
  - **ARCH-3 at runtime:** mount `WheelScreen` under one `ProviderScope(observers: [counter])`; `counter.added` has exactly one provider (`wheelStateProvider`), and `find.byType(ProviderScope)` finds exactly one (the test's root).
  - **Derived values are pure functions of the state:** two `WheelScreen`s with equal state paint identical circles (`paints` matcher); changing only the state through `wheelStateProvider` changes the probe-visible geometry and nothing else.
  - **Table choice:** width 1099 → compact radii, 1100 → desktop radii (`paints` on the signBandInner ring), at a fixed height; resizing across 1100 while shown keeps `pointerLongitude` (set to 42) and repaints.
  - **Theme switch:** dark → light repaints with the light `line` colour.
  - **Render check (not an assertion):** a scratchpad-only test run writes `wheel_grid_{desktop,compact}_{dark,light}.png` through `RepaintBoundary.toImage` (inside `tester.runAsync`). The executor reads them and states in the report that the rings sit where `screens/01-zodiac-wheel_desktop_en_dark.png` has them. They are not committed.
- [ ] **Step 2: run, expect FAIL.**
- [ ] **Step 3: implement `WheelScreen`.**
- [ ] **Step 4: run, expect PASS.**
- [ ] **Step 5: commit** `feat(ZOD-WHL-001): add the wheel screen host on one provider`.

## Task 6: verify, document, hand over

- [ ] **Step 1: full verification** on the task branch, recording exit codes, counts and any failing excerpt: `fvm dart run melos run lint` (l10n, icons, launcher checks, analyze with infos fatal, format check) and `fvm dart run melos run test`. Expected: all green, with the workspace's existing test counts plus the new ones. Show that `apps/astro_mobile` is untouched (`git diff --stat main -- apps` empty).
- [ ] **Step 2: mutation proof.** Run each mutant, confirm the named test fails, restore. (1) halo `306` → `312`; (2) flip `offsetOf`'s `−r·sin` to `+r·sin`; (3) drop the `Directionality` wrapper; (4) add a second provider; (5) paint a ring from a literal radius instead of `geometry.ringRadius`; (6) `fit` ignores `extentTop`. Record the results in PROGRESS.
- [ ] **Step 3: independent whole-branch review** with `requesting-code-review` (a fresh reviewer, not this session); fix Important findings test-first.
- [ ] **Step 4: documentation** (only after Steps 1–3 pass): tick the four acceptance criteria in the task file with evidence (commands, commit); `TASKS.md` status; PROGRESS (Current Task, Completed, Next Recommended, Technical Decisions D1–D6 and the `degreeNumberRadius` ruling, Verification with the covered commit, Git State, deferred review minors). Note for the next session: WHL-002 adds the sign ring as a `WheelLayer`; the grid layer then stays as a debug layer or is removed, WHL-002's plan decides.
- [ ] **Step 5: push and PR** per the project's Git rules (`gh pr create`, then the follow-up `docs(ZOD-WHL-001): record PR link` commit). Never merge without approval.

## Acceptance mapping

| Criterion | Proven by |
|---|---|
| 1. Empty grid at the table's fractions, desktop and compact | Task 4 `proportion_grid_test.dart` (MASTER-printed values, two sizes, mutants 1 and 5); Task 5 render check |
| 2. Never mirrors under RTL | Task 2 orientation cases; Task 4 RTL test with probe (mutants 2 and 3) |
| 3. One `CustomPaint` / `RepaintBoundary`, no per-element widgets | Task 4 single-canvas test |
| 4. ARCH-3: one provider, pure derived values, no nested scope | Task 3 source guard (mutant 4) and Task 5 runtime observer test |

## Risks and open items

- **Decisions D1–D6 need your confirmation**, above all D6 (router wiring) and D3 (the layer seam).
- **`degreeNumberRadius`:** MASTER (22 px) vs `kit.js` (26) is resolved by measuring the PNG in Task 1 and recorded, not guessed.
- **Accessibility of the canvas** (a semantic label, a focus ring, keyboard rotation) is not here; the wheel's accessibility and focus tasks own it. A painted-only wheel has no semantics until then.
- **Fixed pixel sizes scale with `R`** (D2). If WHL-024 (compact variant) finds a floor is needed for legibility on very small boxes, it adds a clamp in `WheelGeometry`, not in the table.
- **The grid layer is scaffolding.** It draws hairline rings for radii that WHL-002/003/004/008 draw properly (some, like `bodyDiscRadiusAt`, have no ring of their own in the finished design).
- **Execution method:** sequential in one session (the six tasks form one dependency chain: proportions → geometry → state → painter → screen). Nothing is independent enough for subagents.
- **Git:** branches from `main` (NAV-003 is merged); touches no app file.
