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

## Product-owner decisions (2026-11-17, plan review round 1)

- **Gate 1:** proceed. The scaffold consumes no ephemeris or crossing data, so Gate 1 (ZOD-TST-001..013, TST-017; `TASKS.md` §5.1, spec line 692) applies from the first wheel task that consumes core output (ZOD-WHL-004). Recorded in PROGRESS Technical Decisions at execution.
- **Table switch:** ZOD-WHL-001 owns the desktop / compact switch at the 1100 breakpoint (D5). ZOD-WHL-024 narrows to applying the compact sizes inside each layer; its Notes say so.
- **D7, degree-number radius:** the design draws the kit's value, `rNum = rSignIn − 26` (the PNGs are rendered from `kit.js` by `_source/render/render.js`, so they cannot disagree with it). MASTER's "22 px inside the band" is the discrepancy and is not edited (the NAV-002 / UI-009 precedent: `kit.js` and the PNGs win). WHL-003's "22px inset desktop / 14px compact" reads 14 as an inset, but 14 is the compact **font size** (`kit.js` `sz.dl`); its Notes now say so. Task 1 still checks the desktop PNG by pixels as a confirmation and reports the result.
- **Router wiring (D6):** not in this task. `WheelScreen` is exported and proven at feature level; no app file changes.

## Decisions (D1–D5 proposed, confirm at approval; D6–D7 decided)

D1–D7 here are this plan's own labels; `DESIGN_DECISIONS.md` D6 / D7 are called "design decision D6 / D7".


- **D1: values come from the kit, not the rounded table.** MASTER's fractions are `kit.js` units over `R = 300`, rounded (`296/300 = 0.98667`, MASTER says 0.987). Store `units / 300`. Tests compare to MASTER's printed values with a tolerance of 0.0005, and to the kit units with `closeTo(units, 1e-9)`.
- **D2: fixed-pixel sizes scale with `R`.** In the kit those pixel sizes (ticks 5/9/14, glyph 17/27, disc r 14/21, dot r 3.2/4.5, label sizes) live in the same viewBox as `R = 300`, so they scale with the drawing. The compact table exists because they shrink on a phone. They are stored as `units / 300` too; callers get pixels from `WheelGeometry`. (ARCH-8: logical pixels.)
- **D3: the layer seam.** One painter, ordered `WheelLayer`s. Without it, WHL-002…009 would edit one growing painter, and the L-6 and single-canvas tests would have nothing to inject an asymmetric probe through. It is one small interface, not a framework.
- **D4: state is only the pointer longitude (default 0°).** The kit seeds the pointer with the first body's longitude. No bodies exist yet. WHL-009/010/014 extend `WheelState` (time, drag mode) and keep it the one provider.
- **D5: compact is "not desktop".** Desktop below/above is `ZodiannBreakpoint.desktop` (≥ 1100, MASTER §6); phone and tablet use the compact table (MASTER §7.2 header).
- **D6: no router wiring in this task (decided above; reasoning kept).** The task file's criteria need no route, `WheelScreen` is not the real screen (WHL-025 builds the layout around it), and swapping the wheel route's `ScreenStub` breaks 26 references in 6 test files that anchor on `find.byType(ScreenStub)` (the wheel is the default route). `WheelScreen` is exported and proven at feature level. **Cost of the alternative:** wiring now needs `appRouterProvider` to pass a real `screenBuilder`, and those tests to override it. PROGRESS's "replaces the blank wheel ScreenStub" note stays with WHL-025.
- **D7 (decided above):** `degreeNumberRadius` follows the kit (`rSignIn − 26`); Task 1 confirms it against the desktop PNG and reports.

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
- **Unbounded height or width** (the canvas in a scroll view on a phone, or in a `Row`): it takes the missing side from the other and the drawing's aspect (644:656), never `Infinity`; unbounded both ways is `Size.zero`. Test in Task 4.
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
    final double degreeNumberRadius;    // (signBandInner·300 − 26)/300 — D7 (kit value; confirmed against the PNG in Step 5)
    final double degreeNumberFontSize;  // 9.5/300 | 14/300
    final double signGlyphSize;         // 21/300 | 30/300
    final double bodyDiscRadiusAt;      // 192/300 | 180/300     (0.64 | 0.60)
    final double bodyDiscRadius;        // 14/300 | 21/300
    final double bodyGlyphSize;         // 17/300 | 27/300
    final double bodyLabelRadiusAt;     // 164/300 | 140/300     (0.547 | 0.467)
    final double bodyLabelFontSize;     // 11.5/300 | 19/300
    final double innerDiscRadius;       // 136/300 | 112/300     (0.453 | 0.373)
    final double trueDotRadius;         // 3.2/300 | 4.5/300
    // the drawing's extent around the centre (kit viewBox −322 −334 644 656), in R:
    final double extentX; // 322/300   final double extentTop; // 334/300   final double extentBottom; // 322/300
    double get aspectRatio; // (2·extentX) / (extentTop + extentBottom) = 644/656
  }
  ```
  Values are `const` expressions such as `296 / referenceRadius`. The `…At` suffix means "ring radius at which it sits"; use these names exactly.
- Consumes: nothing.

- [ ] **Step 1: wire the package.** Add to `packages/feature_wheel/pubspec.yaml` `dependencies`: `astro_core` and `shared_ui` as `path: ../astro_core` / `path: ../shared_ui` (as `apps/astro_mobile/pubspec.yaml` does with `../../packages/…`), `flutter_riverpod: ^3.5.0`, `material_ui: ^1.11.0`. Run `fvm dart run melos bootstrap`. Expected: exit 0, root `pubspec.lock` unchanged (all four already resolve). Then `git status --short`: a root pub get can delete the tracked generated files under `packages/shared_ui/lib/l10n/` (PROGRESS records this); if they show as deleted, restore them with `git checkout -- packages/shared_ui/lib/l10n` and never commit the deletion. Expected after the restore: only `packages/feature_wheel/pubspec.yaml` modified.
- [ ] **Step 2: write the failing test** `wheel_proportions_test.dart`, with these cases:
  - `desktop` fractions equal MASTER's printed values within 0.0005: halo 1.02, band 0.987 → 0.833, body discs 0.64, labels 0.547, inner 0.453. `compact`: band → 0.80, discs 0.60, labels 0.467, inner 0.373, `haloRadius`, `signBandOuter`, the three tick lengths and the extents equal `desktop`'s (every other row differs in compact, `kit.js:299-300`).
  - `desktop` equals the kit units: every `field * WheelProportions.referenceRadius` comparison against a kit-unit value uses `closeTo(units, 1e-9)`, never `==` (for example `21/300·300` is `21.000000000000004`). So `signBandOuter` is `closeTo(296, 1e-9)` and `bodyDiscRadiusAt` is `closeTo(192, 1e-9)`.
  - ticks `5/9/14` units, glyph and disc sizes `17/14` desktop and `27/21` compact.
  - invariants for both tables: `haloRadius > signBandOuter > signBandInner > bodyDiscRadiusAt > bodyLabelRadiusAt > innerDiscRadius > 0`; `aspectRatio` is within 1e-9 of `644/656`.
- [ ] **Step 3: run it, expect FAIL** (compilation error, undefined class `WheelProportions`): `cd packages/feature_wheel; fvm flutter test test/geometry/wheel_proportions_test.dart`.
- [ ] **Step 4: implement `WheelProportions`** as specified. Doc each field with its MASTER row. Export it from `feature_wheel.dart`.
- [ ] **Step 5: confirm D7 against the PNG.** Decode `screens/01-zodiac-wheel_desktop_en_dark.png` (as the NAV-001 plan did, a throwaway script in the scratchpad, not committed) and locate the "10" degree-number centres against the band's inner edge. Convert PNG pixels to kit units with `units = px · 296 / rimPx` (measure the accent rim `rSignOut` and the label centres; labels are centred, `kit.css:307`). `degreeNumberRadius` stays `(signBandInner·300 − 26)/300` (D7). If the measured inset differs from 26 by more than 1 kit unit, do not change the value: stop and report the measurement. Put the measured value and the script's one-line result in the field's doc comment, and report it at execution.
- [ ] **Step 6: run it, expect PASS:** `cd packages/feature_wheel; fvm flutter test test/geometry/wheel_proportions_test.dart` (all pass), then `fvm dart analyze --fatal-infos .` (expect `No issues found!`).
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
  - `ringRadius(WheelProportions.desktop.signBandOuter)` is `closeTo(296.0, 1e-9)` at radius 300 (kit units).
  - `fit`: a 644 × 656 box → radius 300 with centre (322, 334) (the kit's origin); a 1000 × 656 box → radius 300, centre x 500, y 334; a 644 × 1000 box → radius 300, centre x 322, y `(1000 − 656)/2 + 334`; a 322 × 328 box → radius 150. `Size.zero`, `Size(0, 100)`, `Size(double.nan, 100)` and `Size(double.infinity, 100)` give radius 0.
  - value equality (two equal geometries are `==`).
- [ ] **Step 2: run it, expect FAIL** (compilation error, undefined class `WheelGeometry`).
- [ ] **Step 3: implement.** `fit`: `radius = min(box.width / (2·extentX), box.height / (extentTop + extentBottom))`; `center = Offset(box.width / 2, (box.height − (extentTop + extentBottom)·radius) / 2 + extentTop·radius)`. No imports beyond `dart:math` and `package:flutter/painting.dart`; **no riverpod** (guarded in Task 3).
- [ ] **Step 4: run it, expect PASS** (`fvm flutter test test/geometry/wheel_geometry_test.dart`), then `fvm dart analyze --fatal-infos .` (expect `No issues found!`).
- [ ] **Step 5: commit** `feat(ZOD-WHL-001): add the wheel geometry and orientation convention`.

## Task 3: the screen's single provider (ARCH-3)

**Files:** create `lib/src/state/wheel_state.dart`, `test/state/wheel_state_test.dart`, `test/architecture/wheel_single_provider_test.dart` (root); export from `feature_wheel.dart`.

**Interfaces:**
- Produces:
  ```dart
  @immutable final class WheelState {
    const WheelState({this.pointerLongitude = 0});   // [0, 360); a debug assert (release relies on setPointerLongitude normalising)
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
  - `wheel_single_provider_test.dart` (root, `package:test`, same walk and `cleanDartSource` helper as `no_magic_dimensions_test.dart`): in `packages/feature_wheel/lib` there is exactly **one** provider declaration (`RegExp(r'\b(?:[A-Z]\w*)?Provider\b(?:\s*\.\s*\w+)*\s*(?:<[^;{}()]*>)?\s*\(')` on cleaned source: it matches only an identifier ending in `Provider` at a word start followed by `(`, so lowercase provider variables, `ProviderScope`, `ProviderContainer` and `ProviderObserver` never match; also flag `@riverpod` / `@Riverpod(`, since there is no codegen), zero `ProviderScope` and zero `ProviderContainer` occurrences, and no file under `src/geometry/` mentions `riverpod` (the derived values are pure). Add controls on inline strings so the scanner is proven: a source with two providers fails, one with a `ProviderScope(` fails, one with `ref.watch(` inside `geometry/` fails; `ref.watch(wheelStateProvider.select((s) => s.pointerLongitude))` alone counts 0, `NotifierProvider<A, List<int>>(A.new)` counts 1, `Provider((ref) => 1)` counts 1 and `Provider<int>((ref) => 1)` counts 1. The assertion is `expect(count, 1, reason: 'expected 1 provider declaration, found $count')`. Document in the guard and in PROGRESS: it counts screen-state providers; a dependency-injection provider (for example the `EphemerisPort` binding, FND-005 Notes) needs an explicit decision and a named allowlist entry here.
- [ ] **Step 2: run, expect FAIL** (`fvm flutter test test/state/wheel_state_test.dart` in the package: undefined `WheelState`; `fvm dart test test/architecture/wheel_single_provider_test.dart` at the root: `Expected: <1> Actual: <0>`, reason `expected 1 provider declaration, found 0`).
- [ ] **Step 3: implement** `WheelState`, `WheelController`, `wheelStateProvider`. `normalizeDegrees` is from `astro_core`. Skip the state write when the new value `==` the old.
- [ ] **Step 4: run, expect PASS** (both commands from Step 2).
- [ ] **Step 5: commit** `feat(ZOD-WHL-001): add the wheel's single state provider and its guard`.
- [ ] **Step 6: mutation check (after the commit, so the file is tracked).** Temporarily append `final otherProvider = NotifierProvider<WheelController, WheelState>(WheelController.new);` to `packages/feature_wheel/lib/src/state/wheel_state.dart`, run the root guard, expect FAIL (`expected 1 provider declaration, found 2`), then restore with `git checkout -- packages/feature_wheel/lib/src/state/wheel_state.dart` and confirm `git status --short` is clean. Record it.

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
- `ProportionGridLayer` strokes six concentric circles at the table's radii (`haloRadius` in `line` at 50 % opacity, `signBandOuter` in `accentLine`, `signBandInner`, `bodyDiscRadiusAt`, `bodyLabelRadiusAt`, `innerDiscRadius` in `line`; stroke width one kit unit, `geometry.radius / WheelProportions.referenceRadius`) and fills the inner disc with `bgRaised` first. Radii come from `geometry.ringRadius(...)`; colours from `surfaces`.
- `WheelCanvas.build`: `LayoutBuilder`; size: both bounded → `(maxWidth, maxHeight)`; width bounded only → `(w, w / aspectRatio)`; height bounded only → `(h · aspectRatio, h)`; neither bounded → `Size.zero` (an infinite size would assert in `RenderCustomPaint`); child `RepaintBoundary(child: Directionality(textDirection: TextDirection.ltr, child: Builder(builder: (c) => CustomPaint(size: size, painter: WheelPainter(…, surfaces: Theme.of(c).extension<ZodiannSurfaces>()!, textDirection: Directionality.of(c), …)))))`. Non-finite or non-positive size paints nothing.

- [ ] **Step 1: write `wheel_harness.dart`** (test support): `pumpWheelCanvas(tester, {size, proportions, state, layers, textDirection, locale, brightness})` mounting a themed `MaterialApp` (the app's `ZodiannTheme` for the brightness; see how `packages/shared_ui/test/support` builds one) with `localizationsDelegates: const [ZodiannLocalizations.delegate, ...GlobalMaterialLocalizations.delegates]` and `supportedLocales: ZodiannLocalizations.supportedLocales` (without them `Locale('he')` falls back to English and the ambient direction stays LTR), with a fixed-size box, and an `OrientationProbeLayer` (test-only `WheelLayer`) that fills a small circle at `geometry.offsetOf(90, ringFraction, pointerLongitude: …)` and records the `textDirection` it was given.
- [ ] **Step 2: write the failing tests.**
  - `proportion_grid_test.dart`: for each table (`desktop`, `compact`) at two box sizes (644 × 656 and 322 × 328), match the render object with an ordered `paints` chain of `..something((method, args) { … })` predicates (the `circle` matcher compares exactly and cannot express a tolerance). Each predicate returns false unless `method == #drawCircle`, then `expect`s `(args[0] as Offset).dx` / `.dy` `closeTo(cx / cy, 1e-6)` and `(args[1] as double)` `closeTo(expectedFraction · R, 0.0005 · R)`. Order: first the inner-disc **fill** (`bgRaised`), then six strokes: `haloRadius`, `signBandOuter`, `signBandInner`, `bodyDiscRadiusAt`, `bodyLabelRadiusAt`, `innerDiscRadius`. `expectedFraction` is the **MASTER-printed** literal (1.02, 0.987, 0.833 | 0.80, 0.64 | 0.60, 0.547 | 0.467, 0.453 | 0.373), not read from the table object. A mutation (a ring radius off by 2 %) must fail it.
  - `wheel_canvas_test.dart` (one test per bullet):
    - **single canvas (ARCH-5):** under `WheelCanvas` there is exactly one `CustomPaint` whose painter is a `WheelPainter`, exactly one `RepaintBoundary` that is its ancestor within the canvas, and **zero** `Positioned`, `Transform`, `Text`, `Stack` and `Opacity` descendants; the widget count under `WheelCanvas` is equal at pointer 0° and 123.4° and with 1 or 3 layers.
    - **never mirrors (L-6):** pumped in an RTL `Directionality` with `Locale('he')`, the probe's circle is at the same position as under LTR (left of centre for longitude 90, at pointer 0), the probe records `TextDirection.ltr`, and the nearest `Directionality` above the wheel's `CustomPaint` is LTR. **Control:** `Directionality.of` at the `WheelCanvas` element is `TextDirection.rtl` (the ambient direction really is RTL). Mutation: delete the `Directionality` wrapper; the probe's recorded `textDirection` and the ancestor check fail (the position check cannot, since a `CustomPaint` never mirrors).
    - **sizing:** a 644 × 656 box gives radius 300 with the grid's outer ring radius `closeTo(306, 1e-6)`; inside `Row(children: [WheelCanvas(…)])` with height 328 the width is 328·644/656 and nothing throws (unbounded width); a wider box centres the drawing; a bounded-width, unbounded-height parent (a `SingleChildScrollView`) yields height = width / aspect and does not throw; `SizedBox.shrink`, 0 × 100 and 100 × 0 boxes paint no circles and throw nothing.
    - **repaint:** a changed pointer longitude, a changed proportions table and a changed brightness each repaint (`shouldRepaint` true); an identical rebuild does not.
- [ ] **Step 3: run, expect FAIL** (compilation error, undefined `WheelPainter` / `WheelCanvas`).
- [ ] **Step 4: implement** the four files as specified. The painter reads no provider; `WheelCanvas` takes state as a parameter. Keep the stroke widths and the 50 % opacity as named private constants in the layer (the UI-003 guard does not scan `Paint.strokeWidth`; if it flags something, say so, do not add an exemption). The stroke width is one kit unit, `geometry.radius / WheelProportions.referenceRadius` (`kit.css:301`, `.frame` is `stroke-width: 1` in viewBox units, so it scales with `R` like everything else, D2), not a device hairline.
- [ ] **Step 5: run, expect PASS.** Run the two root guards, `fvm dart test test/architecture/no_magic_dimensions_test.dart test/architecture/no_color_literals_test.dart`, then analyze and format-check the package.
- [ ] **Step 6: commit** `feat(ZOD-WHL-001): add the single wheel painter, canvas and proportion grid`.

## Task 5: `WheelScreen`

**Files:** create `lib/src/wheel_screen.dart`, `test/wheel_screen_test.dart`; export from `feature_wheel.dart`.

**Interfaces:**
- Consumes: `wheelStateProvider`, `WheelCanvas`, `WheelProportions`, `ZodiannBreakpoint.forWidth` (`shared_ui`).
- Produces: `class WheelScreen extends ConsumerWidget { const WheelScreen({super.key}); }`. It watches `wheelStateProvider`, chooses `WheelProportions.desktop` when `ZodiannBreakpoint.forWidth(MediaQuery.sizeOf(context).width) == ZodiannBreakpoint.desktop`, else `compact`, and returns a `WheelCanvas` centred in its space. No `ProviderScope`.

- [ ] **Step 1: write the failing tests.**
  - **ARCH-3 at runtime:** mount `WheelScreen` under one `ProviderScope(observers: [counter])`; `counter.added` has exactly one provider (`wheelStateProvider`), and `find.byType(ProviderScope)` finds exactly one (the test's root).
  - **State reaches the painter, and only the state:** after `container.read(wheelStateProvider.notifier)` (get `container` with `ProviderScope.containerOf(tester.element(find.byType(WheelScreen)))`; never `UncontrolledProviderScope`, which would break the exactly-one-`ProviderScope` assertion) then `.setPointerLongitude(42)`, the `WheelPainter` of the `CustomPaint` under `WheelScreen` has `state == WheelState(pointerLongitude: 42)` and an unchanged `proportions`. Purity of the derived geometry is proven at unit level (Task 2: equal inputs give an equal `WheelGeometry`) and by the Task 3 guard (no riverpod under `src/geometry/`; the painter reads no provider).
  - **Table choice:** width 1099 → compact radii, 1100 → desktop radii (`paints` on the signBandInner ring), at a fixed height; resizing across 1100 while shown keeps `pointerLongitude` (set to 42) and repaints.
  - **Theme switch:** dark → light repaints with the light `line` colour.
  - **Render check (not an assertion):** a scratchpad-only test run writes `wheel_grid_{desktop,compact}_{dark,light}.png` through `RepaintBoundary.toImage` (inside `tester.runAsync`). The executor reads them and states in the report that the rings sit where `screens/01-zodiac-wheel_desktop_en_dark.png` has them. They are not committed.
- [ ] **Step 2: run, expect FAIL** (compilation error, undefined `WheelScreen`).
- [ ] **Step 3: implement `WheelScreen`.**
- [ ] **Step 4: run, expect PASS.**
- [ ] **Step 5: commit** `feat(ZOD-WHL-001): add the wheel screen host on one provider`.

## Task 6: verify, document, hand over

- [ ] **Step 1: full verification** on the task branch, recording exit codes, counts and any failing excerpt: `fvm dart run melos run lint` (l10n, icons, launcher checks, analyze with infos fatal, format check) and `fvm dart run melos run test`. Expected: all green, with the workspace's existing test counts plus the new ones. Show that `apps/astro_mobile` is untouched (`git diff --stat main -- apps` empty).
- [ ] **Step 2: mutation proof.** Run each mutant, confirm the named test fails, restore. (1) halo `306` → `312`; (2) flip `offsetOf`'s `−r·sin` to `+r·sin`; (3) drop the `Directionality` wrapper; (4) add a second provider; (5) paint a ring from a literal radius instead of `geometry.ringRadius`; (6) `fit` ignores `extentTop`. Record the results in PROGRESS.
- [ ] **Step 3: independent whole-branch review** with `requesting-code-review` (a fresh reviewer, not this session); fix Important findings test-first.
- [ ] **Step 4: documentation** (only after Steps 1–3 pass): tick the four acceptance criteria in the task file with evidence (commands, commit); `TASKS.md` status; PROGRESS (Current Task, Completed, Next Recommended, Technical Decisions: WHL-001 D1–D7 (D6 no router wiring; D7 degree-number radius follows `kit.js` `rSignIn − 26`, with the PNG confirmation result); Gate 1 applies from ZOD-WHL-004, not WHL-001; ZOD-WHL-001 owns the desktop / compact table switch at 1100 and WHL-024 applies the compact sizes per layer; the single-provider guard's scope (screen-state providers; DI providers need a named allowlist entry), Verification with the covered commit, Git State, deferred review minors). Note for the next session: WHL-002 adds the sign ring as a `WheelLayer`; the grid layer then stays as a debug layer or is removed, WHL-002's plan decides.
- [ ] **Step 5: push and PR** per the project's Git rules (`gh pr create`, then the follow-up `docs(ZOD-WHL-001): record PR link` commit). Never merge without approval.

## Acceptance mapping

| Criterion | Proven by |
|---|---|
| 1. Empty grid at the table's fractions, desktop and compact | Task 4 `proportion_grid_test.dart` (MASTER-printed values, two sizes, mutants 1 and 5); Task 5 render check |
| 2. Never mirrors under RTL | Task 2 orientation cases; Task 4 RTL test with probe (mutants 2 and 3) |
| 3. One `CustomPaint` / `RepaintBoundary`, no per-element widgets | Task 4 single-canvas test |
| 4. ARCH-3: one provider, pure derived values, no nested scope | Task 3 source guard (mutant 4); Task 2 geometry equality; Task 5 runtime observer test and painter-state test |

## Risks and open items

- **Decisions D1–D5 need your confirmation** (above all D3, the layer seam). D6 and D7 are decided (see Product-owner decisions).
- **`degreeNumberRadius`:** decided (D7): follows `kit.js` (`rSignIn − 26`); MASTER's 22 px is the documented discrepancy. Task 1 Step 5 confirms against the PNG and reports; a mismatch stops for review.
- **The body display-spread threshold** (11° desktop / 16° compact, design decision D6, still pending approval in `TASKS.md` §6.2) is not stored here. ZOD-WHL-005 defines it; WHL-024 applies it in compact.
- **Accessibility of the canvas** (a semantic label, a focus ring, keyboard rotation) is not here; the wheel's accessibility and focus tasks own it. A painted-only wheel has no semantics until then.
- **Fixed pixel sizes scale with `R`** (D2). If WHL-024 (compact variant) finds a floor is needed for legibility on very small boxes, it adds a clamp in `WheelGeometry`, not in the table.
- **The grid layer is scaffolding.** It draws thin (one kit unit) rings for radii that WHL-002/003/004/008 draw properly (some, like `bodyDiscRadiusAt`, have no ring of their own in the finished design).
- **Execution method:** sequential in one session (the six tasks form one dependency chain: proportions → geometry → state → painter → screen). Nothing is independent enough for subagents.
- **Git:** branches from `main` (NAV-003 is merged); touches no app file.

## Plan review

Reviewed by the `plan-reviewer` subagent before the user saw the plan (two rounds).

### Round 1 (comprehensive) — verdict: needs user decision

| ID | Severity | Finding | Outcome |
|---|---|---|---|
| C1 | Critical | `paints..circle` compares exactly, so MASTER-printed radii could not be asserted | Applied: ordered `..something` predicates with `closeTo`, MASTER literals |
| C2 | Critical | `0.98667·R` misses 296 by 1e-3 | Applied: `closeTo(296.0, 1e-9)` |
| C3 | Critical | `==` on kit-unit values fails on floating point | Applied: `closeTo(units, 1e-9)` throughout |
| I1 | Important | `WheelScreen` purity test could not observe anything | Applied: painter-state assertion; purity proven at unit and guard level |
| I2 | Important | unbounded width reaches `CustomPaint` | Applied: four-case sizing rule, `Row` test |
| I3 | Important | root pub get deletes tracked l10n files | Applied: restore step |
| I4 | Important | `minBodySeparationDegrees` pre-empts pending design decision D6 | Applied: removed, noted in Risks |
| I5 | Important | provider regex loose | Applied (and corrected in round 2, I1) |
| I6 | Important | mutation step used an unscanned copy | Applied (and corrected in round 2, I2) |
| I7 | Important | RTL test could pass without RTL | Applied: delegates in the harness, RTL control assertion |
| M1–M8 | Minor | table wording, stroke width, commands, RED reasons, "26 references in 6 files", PNG conversion, guard scope, debug assert | Applied |
| Needs user decision 1–4 | — | Gate 1; table-switch owner; degree-number radius; router wiring | Decided by the user 2026-11-17 (see Product-owner decisions); WHL-003 and WHL-024 Notes updated |

### Round 2 (focused on the revision) — verdict: approve after corrections

| ID | Severity | Finding | Outcome |
|---|---|---|---|
| C1 | Critical | Task 1 Step 5 let the executor switch to −22, against D7 | Applied: value stays; a mismatch above 1 kit unit stops and reports |
| I1 | Important | provider regex missed a bare `Provider(` | Applied: `(?:[A-Z]\w*)?Provider`, two new controls |
| I2 | Important | mutation restore fails on an untracked file | Applied: mutation moved to Step 6, after the commit |
| I3 | Important | "D7" collides with `DESIGN_DECISIONS.md` D7 | Applied: WHL-003 Note and the plan disambiguate |
| I4 | Important | Task 6 documentation dropped two decisions | Applied |
| I5 | Important | Risks section stale | Applied |
| M1–M7 | Minor | stale wording, stroke wording, one failure format, `containerOf`, citation, acceptance row, WHL-024 ownership of the 16° | Applied |

**Open items:** none needing a decision. D1–D5 remain proposals for approval (D3, the layer seam, is the one to look at). Execution-time confirmation: the desktop PNG check in Task 1 Step 5.
