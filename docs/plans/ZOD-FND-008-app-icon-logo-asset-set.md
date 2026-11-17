# ZOD-FND-008 App Icon and Logo Asset Set Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the existing Zodiann logo as the Android and iOS launcher icon, and as a theme-aware in-app `ZodiannLogo` that can never render below 40 px.

**Architecture:** The in-app mark is the two committed 1024 px PNGs (`on-dark`, `on-light`), copied byte-for-byte into `shared_ui` and chosen by the theme's brightness. Launcher icons are rendered from the source SVG by a root dev tool that drives headless Chrome (the FND-009 pattern), then committed with a source-hash manifest and checked in `lint`. No new runtime dependency.

**Tech Stack:** Flutter 3.50 / Dart 3.14, `shared_ui` assets, a root `tool/` script, headless Chrome 157, Android adaptive icons (API 26+), iOS `AppIcon.appiconset`.

**Task:** `docs/development/foundations-architecture/ZOD-FND-008-package-and-integrate-the-app-icon-logo-asset-set.md`. **Design:** `design-reference/zodiann/MASTER.md` §11 (Logo), §5 (drawer header 40), About hero 132; `DESIGN_DECISIONS.md` D5a; sources `design-reference/zodiann/assets/zodiann-logo{,-on-dark,-on-light}.{svg,png}`.

## Product-owner decisions (2026-11-16)

- **A. `.fvmrc`:** its uncommitted newline change stays in the working tree and is never staged.
- **B. Android:** adaptive icon **plus** legacy PNGs. The mark is scaled into the adaptive 66 dp safe zone. (The gradient's highlight centre also sits slightly higher in the visible 72 dp than on the tile; note it in the visual review.)
- **C. iOS:** full-bleed **opaque** squares (no alpha, no pre-rounded corners). iOS applies its own mask.
- **D. Ownership (round-1 review U1):** FND-008 owns the generator and the **full** launcher set (its AC1 needs it). ZOD-REL-001 narrows to store-listing assets (Play 512 px icon, feature graphic), store validation tooling, and any themed / dark / tinted variants, reusing `gen_launcher_icons.dart`. Task 5 adds a note to REL-001.
- **E. iOS evidence (U2):** static verification only (sizes, colour type, corner colours). The task closes as "Done (iOS on-device / Xcode check outstanding)" like FND-005, and the check joins the existing iOS Blocker in `PROGRESS.md`.
- **F. AC2 (U3):** proven at widget level: `ZodiannLogo` at 40 and 132 in both themes with live switching. Placement is NAV-002's and ABT-001's; Task 5 adds a "From ZOD-FND-008" note to each.

## Facts established while planning (2026-11-16)

- **Source SVGs** (1024 × 1024): the tile is `<rect width="1024" height="1024" rx="230" fill="url(#bg)"/>` and exists only in `zodiann-logo.svg`. Gradients and `stroke-opacity` are used throughout, and the zodiac glyphs are path data (about 30 KB).
- **Source PNGs** are 1024 × 1024 RGBA (all three).
- **`flutter_svg` is excluded** by `test/architecture/no_network_test.dart` (`networkPackages`; FND-009 plan: it depends on `http`). MASTER §11 and the task both allow the PNGs, so using them is not a deviation. Extending the FND-009 generator to gradients was rejected as scope creep.
- **Existing launcher art is Flutter's default:** `ic_launcher.png` at 48 / 72 / 96 / 144 / 192 (palette PNGs, five `mipmap-*dpi` folders, no adaptive resources), `AndroidManifest.xml` has `android:icon="@mipmap/ic_launcher"`, and `AppIcon.appiconset` holds 15 PNGs plus `Contents.json` (the 1024 one is RGB).
- **No logo code exists** in `lib/` of `apps/astro_mobile` or `packages/shared_ui`. The drawer (NAV-002: header 76 high, logo 40) and About hero (ABT-001: logo 132) don't exist yet.
- **Adaptive geometry:** 108 dp canvas, 66 dp safe-zone circle. The mark's outer ring is `r = 446` with a 4-unit stroke, so its ink reaches radius 448 of 512 (diameter 896 / 1024). The foreground mark is drawn at side `L = S · 66 · 1024 / (108 · 896)` ≈ 0.6984 · S for a foreground of side S. Reviewer measurement with Chrome 157 (max ink radius vs limit `33 dp × density + 1 px`, centre `((S−1)/2, (S−1)/2)`): S 108 → 33.68 / 34; 162 → 50.40 / 50.5; 216 → 66.05 / 67; 324 → 99.24 / 100; 432 → 132.62 / 133. (Using 892 overshoots by 291 pixels at 432.)
- **Packaged asset keys:** `flutter test` in `shared_ui` builds `assets/…` into the bundle, and `flutter_test`'s asset mock (`_binding_io.dart` `mockFlutterAssets`) also serves `packages/shared_ui/assets/…` by stripping the package's own prefix, so `Image.asset(…, package: 'shared_ui')` loads from the default test bundle (round-2 reviewer proved it in a scratch package). Images decode outside fake-async, so a test that needs pixels must precache inside `tester.runAsync`.
- **iOS `Contents.json`:** 19 image entries but only **15 distinct filenames** (four are shared by an iPhone and an iPad entry: `20x20@2x` 40, `29x29@1x` 29, `29x29@2x` 58, `40x40@2x` 80). Chrome 157 already writes colour type 2 (RGB, no `tRNS`) for fully opaque renders.
- **Line endings:** `core.autocrlf=true` and no `.gitattributes`, so SVG hashes are computed over the file with CRLF normalised to LF (as FND-009). PNG hashes are raw bytes.
- **Headless Chrome works for rasterising** (`render_icon_references.dart`), at `C:/Program Files/Google/Chrome/Application/chrome.exe` or `$CHROME`.

## Global Constraints

- **No new runtime dependency** in any member. Root `dev_dependencies` may gain `image` only (Task 3), checked against Flutter's pins (`test_api 0.7.14`, `matcher 0.12.20`, `material_color_utilities 0.13.0`). `no_network_test.dart` is unchanged and green.
- **Logo is never smaller than 40 px:** `ZodiannSize.logoMin = 40`; asserted at runtime and guarded statically (Task 1).
- **Sizes** come from `ZodiannSize` tokens, never numeric literals in `lib/` (UI-003 guard).
- **Assets are byte-identical copies** of `design-reference` files, recorded with SHA-256. Never redrawn or recoloured.
- **Variants follow `Theme.of(context).brightness`**, not the platform's, so the app's own dark / light / system setting decides.
- **Launcher outputs are derived, never hand-edited:** `fvm dart run tool/launcher/gen_launcher_icons.dart`, checked by `launcher:check` (in `lint`) and a root test.
- **Commands:** `fvm dart …` / `fvm flutter …` from PowerShell; Melos as `fvm dart run melos run <script>`. Gates: `lint`, `test`, plus `flutter build apk --debug`.
- **Staging:** every commit stages explicit paths (`git add <paths>`); never `git add -A`, `git add .` or `git commit -a`. Before each commit `git status` must still show `.fvmrc` as unstaged (decision A).
- **Hashes:** SVG SHA-256s are over the file with CRLF normalised to LF; PNG hashes are raw bytes.
- **Naming:** project prefix `Zodiann` (`ZodiannLogo`). The task has no "AppLogo".

## Out of scope

- The drawer header and About hero themselves (NAV-002, ABT-001). This task delivers `ZodiannLogo` and proves it at 40 and 132 in both themes.
- Android 13 themed (monochrome) icon, web / desktop icons, splash screen art, notification icons.
- Logo in exported files (MASTER §11): not in this task; the Excel export tasks decide.
- AC3 is about in-app rendering. Launcher sizes below 40 (iOS 20 / 29 px, Android mdpi 48 dp) are platform-mandated and exempt.
- iOS 18 dark and tinted app-icon variants, the Play Store 512 px listing icon and store validation tooling: owned by ZOD-REL-001 (decision D).
- iOS on-device and Xcode asset-catalog verification (no Mac; recorded as outstanding like FND-005).
- Redrawing, recolouring or re-exporting the artwork.

## Review Focus

1. **iOS alpha:** any alpha channel (even fully opaque) in an `AppIcon` PNG fails App Store validation. Expect colour type 2 for all 15 files; pinned by test.
2. **Adaptive clipping:** a foreground mark outside the 66 dp safe zone gets cropped by round launcher masks. Measured ink radius is tested.
3. **Logo below 40 px:** a future caller passing 24 would blur the hairlines. Runtime assert plus a call-site guard.
4. **Theme switch while visible:** the variant must change live with no restart, and under the app's own theme mode, not the OS one.
5. **Stale launcher art:** an SVG edit without regenerating leaves old icons. `launcher:check` fails on a hash mismatch.

---

### Task 1: Tokens, bundled PNGs and `ZodiannLogo`

**Files:**
- Modify: `packages/shared_ui/lib/src/theme/tokens/zodiann_dimensions.dart` (add to `ZodiannSize`), `packages/shared_ui/lib/shared_ui.dart` (export), `packages/shared_ui/pubspec.yaml` (assets)
- Create: `packages/shared_ui/assets/logo/zodiann-logo-on-dark.png`, `…-on-light.png` (byte copies), `packages/shared_ui/assets/logo/SOURCES.md`, `packages/shared_ui/lib/src/widgets/zodiann_logo.dart`
- Modify (tests): `packages/shared_ui/test/fonts/font_assets_test.dart` (its OFL assertion at lines ~98–99 compares the whole `flutter: assets:` set, so compare only the `assets/fonts/` entries: `assets.where((a) => a.startsWith('assets/fonts/')).toSet()`); `packages/shared_ui/test/theme/dimensions_test.dart` (add `logoMin` 40, `logoDrawer` 40, `logoAbout` 132 to the `ZodiannSize` table, citing MASTER §11, §5, §9)
- Test: `packages/shared_ui/test/logo/logo_assets_test.dart`, `packages/shared_ui/test/logo/zodiann_logo_test.dart`, `apps/astro_mobile/test/logo_asset_test.dart`, `test/architecture/logo_size_guard_test.dart` (root)

**Interfaces:**
- Produces: `ZodiannSize.logoMin = 40.0`, `ZodiannSize.logoDrawer = 40.0`, `ZodiannSize.logoAbout = 132.0`; `class ZodiannLogo extends StatelessWidget { const ZodiannLogo({super.key, this.size = ZodiannSize.logoDrawer, this.semanticLabel}); final double size; final String? semanticLabel; }`. Decorative (excluded from semantics) when `semanticLabel` is null; a caller supplying a label passes a localized string. Asserts `size >= ZodiannSize.logoMin`. It sizes itself with a private `SingleChildRenderObjectWidget` whose render object extends `RenderConstrainedBox` with `BoxConstraints.tight(Size.square(size))`, so intrinsics report `size`. In debug its `performLayout` throws a `FlutterError` naming `ZodiannSize.logoMin` when `constraints.maxWidth < size || constraints.maxHeight < size`. A tight parent therefore cannot shrink the logo below its size (AC3), while larger parents are allowed (the image scales down to fit them, never below `size`). The image uses `gaplessPlayback: true` so a theme switch never shows a blank frame.

- [ ] **Step 1: Write the failing tests**
  - `logo_assets_test.dart`: the two PNGs equal `design-reference/zodiann/assets/zodiann-logo-on-{dark,light}.png` byte for byte and their SHA-256 matches `SOURCES.md`; both are 1024 × 1024 RGBA; the files are declared in `pubspec.yaml`.
  - `zodiann_logo_test.dart` (test names): `uses the dark mark under the dark theme`, `uses the light mark under the light theme`, `follows the app theme, not the platform brightness` (platform dark, `MaterialApp.themeMode` light → light mark), `switches live when the theme changes` (uses `pumpAndSettle`: `ThemeData.lerp` flips `brightness` at t = 0.5), `drawer size 40 and About size 132 lay out exactly 40 and 132 square` (in a `Center`, loose constraints), `size below ZodiannSize.logoMin throws an AssertionError`, `a parent that forces it below its size is reported` (24 × 24 tight box → `tester.takeException()` is a `FlutterError`), `is excluded from semantics without a label and exposes it with one`, `renders the bundled mark through the package key` (default test bundle; precached with `await tester.runAsync(() => precacheImage(provider, context))`; the `RawImage` has a non-null 1024 × 1024 `image`), `a larger tight parent is not reported` (`SizedBox.square(dimension: ZodiannSize.logoAbout)` around `ZodiannLogo()` → `tester.takeException()` is null), `lays out under an IntrinsicHeight ancestor` (no exception, height 40). The asset is identified by the `ImageProvider` key's asset name and package.
  - `apps/astro_mobile/test/logo_asset_test.dart` (call `TestWidgetsFlutterBinding.ensureInitialized()` first): `rootBundle.load('packages/shared_ui/assets/logo/zodiann-logo-on-dark.png')` and `…-on-light.png` both succeed (the real packaged key).
  - `logo_size_guard_test.dart`: reuses `cleanDartSource` and `topLevelArguments` from `test/architecture/dart_source.dart`. Scans `lib/` of every member for `ZodiannLogo(`; each `size:` argument must start with `ZodiannSize.logo`; no `Image.asset` / `AssetImage` naming `zodiann-logo` outside `zodiann_logo.dart`. The `zodiann-logo` check runs on the raw file text (`RegExp(r'zodiann-logo-on-(dark|light)\.png')`, outside `zodiann_logo.dart`), because `cleanDartSource` blanks string contents; the `size:` check uses the cleaned source. Tests: `scans shared_ui and the app, including zodiann_logo.dart` (the scanned list names `packages/shared_ui/lib/src/widgets/zodiann_logo.dart`, which makes it non-vacuous while no call site exists), and two positive controls (`size: 24` in a fixture string is flagged; a fixture file containing `Image.asset('assets/logo/zodiann-logo-on-dark.png')` is flagged).
- [ ] **Step 2: Run to verify they fail.** `fvm flutter test test/logo` in `packages/shared_ui`: compile errors (`ZodiannLogo`, `ZodiannSize.logoMin` undefined) and missing asset files. Root: `fvm dart test test/architecture/logo_size_guard_test.dart`: the non-vacuity test fails (`zodiann_logo.dart` not found). App: `fvm flutter test test/logo_asset_test.dart` fails (asset missing).
- [ ] **Step 3: Implement** the tokens, copy the two PNGs, write `SOURCES.md` (file → source path → SHA-256), add the pubspec `assets:` entries, and implement `ZodiannLogo` with `Image.asset(…, package: 'shared_ui', width: size, height: size, gaplessPlayback: true)` inside that render object. The decode strategy (`cacheWidth` against full-size decode with `FilterQuality.high`) is decided in Task 2; start with `FilterQuality.high`.
- [ ] **Step 4: Run to verify they pass**, then the full `shared_ui` suite (`fvm flutter test` in `packages/shared_ui`), the root `fvm dart test test/architecture`, and `fvm dart run melos run lint`.
- [ ] **Step 5: Commit** — `feat(ZOD-FND-008): add the logo size tokens, bundled marks and ZodiannLogo`.

### Task 2: Rendering fidelity at 40 and 132

**Files:**
- Create: `tool/logo/render_logo_references.dart` (root, run by hand like the icon references), `packages/shared_ui/test/fixtures/logo/` (Chrome renders of each `on-{dark,light}.svg` at 40, 80, 120, 132, 264, 396 px = 40 and 132 at 1×/2×/3× where applicable, plus `manifest.json`: Chrome version, sizes, SVG SHA-256s over LF-normalised text, and a `README.md` modelled on the icons README)
- Modify: `packages/shared_ui/test/support/icon_capture.dart`: `captureWidget` gains `double devicePixelRatio = 1` (`physicalSize = Size(width * dpr, height * dpr)`, `view.devicePixelRatio = dpr`, `toImage(pixelRatio: dpr)`; the returned `Pixels` are `width·dpr × height·dpr`; update the header comment; existing callers are unchanged); `zodiann_logo.dart` only if the measurement below chooses the other decode strategy
- Test: `packages/shared_ui/test/logo/logo_fidelity_test.dart`

**Interfaces:**
- Consumes: `ZodiannLogo` (Task 1); `packages/shared_ui/test/support/icon_capture.dart`.

- [ ] **Step 1: Write the failing test.** Before each capture, run `await tester.runAsync(() => precacheImage(provider, context))` (images decode outside fake-async). Render at 40 and 132, at device pixel ratios 1 / 2 / 3, in both themes. For each, compare the alpha channel and the mean colour against the matching Chrome reference. The test records the measured mean absolute alpha difference and fails above a ceiling calibrated in Step 4. Also assert the 40 px render keeps its hairline ring (alpha at the outer-ring radius is above a calibrated floor).
- [ ] **Step 2: Run to verify it fails.** Expected: the reference fixture files are not found.
- [ ] **Step 3: Write `render_logo_references.dart`** (headless Chrome, transparent background, `--screenshot`, size flags as in `render_icon_references.dart`) and run `fvm dart run tool/logo/render_logo_references.dart`; commit the PNGs and manifest.
- [ ] **Step 4: Calibrate and decide.** Measure `cacheWidth = size × dpr` against full decode with `FilterQuality.high` for the worst case (40 px at dpr 1 and 3). Keep the strategy with the lower difference, set the ceiling just above the measured worst, and record both numbers in the plan's calibration record. If neither keeps the hairlines visible at 40, stop and report: it is a design question, not an implementation one.
- [ ] **Step 5: Run to verify it passes**, then lint and the full `shared_ui` suite. **Mutation proofs:** swap the two assets, force `FilterQuality.none`, render at 24 px, remove the constraint check; each must fail a named test.
- [ ] **Step 6: Commit** — `test(ZOD-FND-008): pin the logo's rendering against the source SVGs`.

### Task 3: Launcher-icon generator (tool side)

**Files:**
- Create: `tool/launcher/launcher_spec.dart` (pure: size tables and variant derivation), `tool/launcher/gen_launcher_icons.dart`
- Modify: root `pubspec.yaml` (`dev_dependencies: image: ^4.13.1`; a `launcher:check` Melos script, `run: dart run tool/launcher/gen_launcher_icons.dart --check`, placed after `icons:check` in `lint`, and the `lint` description updated to "l10n:check + icons:check + launcher:check + analyze + format:check"), root `pubspec.lock`
- Test: `test/tool/launcher_spec_test.dart`

**Interfaces:**
- Produces (in `launcher_spec.dart`):
  - `String fullBleedSvg(String tiledSvg)`: replaces the single `rx="230"` with `rx="0"`; throws `LauncherException` unless exactly one occurrence.
  - `String backgroundSvg(String tiledSvg)`: the root `<svg>` with its `<defs>` and only the tile `<rect>` with `rx="0"`; throws `LauncherException` unless exactly one `rx="230"` rect exists.
  - `List<IosIcon> iosIcons(String contentsJson)`: `IosIcon{String filename; int pixels}`, **one per distinct filename** (15 for the current `Contents.json`, which has 19 entries); `pixels = size × scale` (e.g. `20x20` @`3x` → 60; `83.5x83.5` @`2x` → 167). Throws `LauncherException` if the same filename appears with different pixel sizes or a non-integer `size × scale`.
  - `const androidLegacy = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}`; `androidAdaptive = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}`.
  - `double foregroundMarkSide(int canvasPx)`: `canvasPx · 66 · 1024 / (108 · 896)`.
  - `class LauncherException implements Exception`.
- The tool accepts `--check`, `--source-dir=<dir>` (default `design-reference/zodiann/assets`) and `--root=<dir>` (the root that output paths and `tool/launcher/manifest.json` resolve against; default `.`). Any other argument prints usage and exits 64. Exit codes: 0 up to date, 1 stale or missing, 2 bad input, 64 usage.
- The tool writes outputs only under `<root>/apps/astro_mobile/android/app/src/main/res/` and `<root>/apps/astro_mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/`, then `<root>/tool/launcher/manifest.json`.

- [ ] **Step 1: Write the failing tests** for the pure functions: `fullBleedSvg` on the real `zodiann-logo.svg` yields no `rx="230"` and is otherwise identical; throws on zero and on two occurrences; `backgroundSvg` on the real SVG contains `id="bg"`, exactly one `<rect` (carrying `rx="0"` and `fill="url(#bg)"`), and no `<circle`, `<line` or `<path` (the source has 26 rects: the tile plus 25 grid cells), and throws on zero or two tile rects; `iosIcons` over the real `Contents.json` returns exactly 15 entries, with `pixels` equal to `size × scale` computed independently from the parsed JSON, plus the literal `20@3x → 60`, `83.5@2x → 167`, `1024@1x → 1024`, a conflicting-duplicate case that throws, and the note that `Icon-App-20x20@2x` and `Icon-App-40x40@1x` are both 40 px but different files (as are `40x40@3x` and `60x60@2x`, both 120); `foregroundMarkSide(432)` is `closeTo(301.714, 0.001)` and `foregroundMarkSide(108)` is `closeTo(75.43, 0.01)`; the density tables equal the literals above.
- [ ] **Step 2: Run to verify they fail.** Expected: compile error, `launcher_spec.dart` does not exist.
- [ ] **Step 3: Implement `launcher_spec.dart`**, then `gen_launcher_icons.dart`:
  - **iOS:** rasterise `fullBleedSvg(zodiann-logo.svg)` at each `pixels` value with headless Chrome, then re-encode as **RGB (no alpha)** with `package:image` (Chrome 157 already writes RGB for opaque renders; the re-encode is a safeguard). Before writing an iOS icon the generator fails (exit 2) unless every rasterised pixel has alpha 255.
  - **Android legacy:** rasterise the tiled `zodiann-logo.svg` as is (RGBA, transparent corners) at each legacy size.
  - **Android adaptive foreground:** rasterise `zodiann-logo-on-dark.svg` at S × S with its root `viewBox` set to `-221.09 -221.09 1466.18 1466.18` (1024 · 108 · 896 / (66 · 1024) = 1466.18 units, centred), so the mark spans `foregroundMarkSide(S)` px at every density on a transparent canvas, one per adaptive density.
  - **Android adaptive background:** rasterise `backgroundSvg(zodiann-logo.svg)` at 432 px, opaque, as `drawable-nodpi/ic_launcher_background.png`.
  - `manifest.json`: SHA-256 of the **two** SVGs used (`zodiann-logo.svg`, `zodiann-logo-on-dark.svg`; LF-normalised), Chrome version, and every output path (relative to `<root>`, forward slashes, so `--check` compares the same strings on Windows) with its pixel size and its raw-byte SHA-256; also the LF-normalised SHA-256 of `tool/launcher/launcher_spec.dart`, so a geometry change without regenerating fails `--check`.
  - `--check`: recomputes the source hashes, the expected output list and **each output file's hash**, and exits 1 on any mismatch or missing file (no Chrome needed, so it is fast and deterministic), 2 on bad input, 0 otherwise.
- [ ] **Step 4: Run to verify they pass** (`fvm dart test test/tool/launcher_spec_test.dart` from the root; analyze and format clean).
- [ ] **Step 5: Commit** — `build(ZOD-FND-008): add the launcher icon generator`.

### Task 4: Generate, wire and verify the launcher icons statically

**Files:**
- Create: `apps/astro_mobile/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` (`<adaptive-icon>`: background `@drawable/ic_launcher_background`, foreground `@mipmap/ic_launcher_foreground`), `drawable-nodpi/ic_launcher_background.png`, `mipmap-*dpi/ic_launcher_foreground.png`, `tool/launcher/manifest.json`
- Modify (by the generator): `mipmap-*dpi/ic_launcher.png` (legacy), the 15 `AppIcon.appiconset` PNGs
- Test: `test/architecture/launcher_icons_test.dart` (root)

**Interfaces:**
- Consumes: `launcher_spec.dart`, `package:image` for pixel reads (root dev dependency).

- [ ] **Step 1: Write the failing test** (names): `every AppIcon filename in Contents.json exists with its exact pixel size`; `every iOS icon is RGB with no alpha channel` (PNG colour type 2, no `tRNS`); `the 1024 and 167 iOS icons have the tile gradient in every corner` (top corners within ±3 per channel of (27,27,29), bottom corners within ±3 of (19,19,20), top-centre within ±3 of (35,35,37), no corner pixel equal to (0,0,0); a leftover rounded tile would turn the corners into RGB (0,0,0)); `legacy icons are RGBA with transparent corners and the right size per density`; `adaptive foregrounds are S × S per density, transparent at the corners, and every pixel with alpha > 8 lies within radius 33 dp × density + 1 px of the centre, centre = ((S−1)/2, (S−1)/2)` (the safe-zone check; the measured margin is under 0.4 px at 108 and 432, so if a regenerated foreground fails, fix the geometry, never the tolerance); `the adaptive background is opaque 432 px`; `the manifest names the live SHA-256 of the two SVGs and every output file`; `AndroidManifest still points at @mipmap/ic_launcher`; and the `--check` tests, run against a temp copy of the inputs and outputs via `--source-dir` and `--root`: `--check exits 0 on the committed tree`, `--check exits 1 when a source SVG byte is changed`, `--check exits 1 when an output PNG is changed`, `--check exits 2 when the source SVG has two rx="230" rects`, `--check exits 64 on an unknown argument`; and `the adaptive icon XML names the generated layers` (`mipmap-anydpi-v26/ic_launcher.xml` exists; root `<adaptive-icon>`; `<background android:drawable="@drawable/ic_launcher_background"/>`; `<foreground android:drawable="@mipmap/ic_launcher_foreground"/>`).
- [ ] **Step 2: Run to verify it fails.** Expected: the AppIcon PNGs are Flutter's palette / RGBA defaults, the adaptive files are missing, and the manifest is missing.
- [ ] **Step 3: Run `fvm dart run tool/launcher/gen_launcher_icons.dart`**, add the adaptive XML, review the generated images visually (open the 1024 iOS, the xxxhdpi foreground over its background, and a legacy 192), and commit them.
- [ ] **Step 4: Run to verify it passes**, then `fvm dart run melos run lint` (with `launcher:check`) and `fvm dart run melos run test`. **Mutation proofs:** keep an alpha channel in one iOS icon; scale the foreground to 0.9 of the canvas; leave `rx="230"` in the iOS source; edit an SVG byte without regenerating; overwrite one legacy PNG with the old Flutter icon; keep the cell rects in `backgroundSvg`; delete `ic_launcher.xml`. Each must fail a named test.
- [ ] **Step 5: Commit** — `feat(ZOD-FND-008): generate the launcher icons (Android adaptive + legacy, iOS full-bleed)`.

### Task 5: Device verification, review and close-out

**Files:**
- Modify: `docs/PROGRESS.md`, `docs/development/TASKS.md`, the task file's status, this plan (review and calibration records), and "From ZOD-FND-008" Notes in `docs/development/navigation/ZOD-NAV-002-implement-the-side-navigation-drawer.md`, `docs/development/about/ZOD-ABT-001-build-the-about-screen-hero.md` and `docs/development/release-preparation/ZOD-REL-001-package-the-launcher-icon-and-store-metadata-assets.md` (precedent: the "From ZOD-FND-014" note in NAV-002)

- [ ] **Step 1: Build and install.** `fvm flutter build apk --debug` and install on `emulator-5554` (Android 9, adaptive-capable). Capture a launcher screenshot (`adb exec-out screencap -p`) showing the new icon in the app drawer and on the home screen, and review it by eye: the mark is centred, not cropped by the launcher mask, and legible. The screenshot is **not** committed unless it is small; record what was observed. The emulator covers only the adaptive path; the legacy PNGs (API 24–25) and the iOS icons are verified statically only (decision E).
- [ ] **Step 2: Invoke `requesting-code-review`** over the whole branch; fix Critical and Important findings (promote minors that are cheap to test).
- [ ] **Step 3: Invoke `verification-before-completion`:** `lint` exit 0 (l10n, icons and launcher checks included), `test` exit 0, `flutter build apk --debug` ✓, `no_network_test` unchanged and green. Record the real counts.
- [ ] **Step 4: Update docs.** Task file status `Done (iOS on-device / Xcode check outstanding)`; `TASKS.md`; `PROGRESS.md` (Completed Tasks row with evidence; Current Task; Next Recommended Task; Technical Decisions: PNG route, full-bleed iOS, adaptive safe-zone geometry; Architecture Conventions: a **Logo** paragraph, "use `ZodiannLogo`, tokens, regenerate with `gen_launcher_icons.dart`"; Blockers: iOS icon check outstanding; Git State). Also **reconcile the stale NAV-001 rows** (PR #26 is merged). Mark the task "Done (iOS on-device / Xcode check outstanding)" and add the check to the existing iOS Blocker. Write the Notes: **NAV-002:** use `ZodiannLogo(size: ZodiannSize.logoDrawer)` and add a header test showing the variant switches with the app theme; **ABT-001:** use `ZodiannLogo(size: ZodiannSize.logoAbout)` with the same theme-switch test; **REL-001:** FND-008 delivered the generator (`tool/launcher/gen_launcher_icons.dart`) and the full Android / iOS launcher set; REL-001 narrows to store-listing assets, store validation tooling and any themed / dark / tinted variants.
- [ ] **Step 5: Commit and push** the task branch, open the PR into `main`, record the link in `PROGRESS.md` as a follow-up commit (SKILL.md Step 8).

## Open items for approval

1. **`image: ^4.13.1` as a root dev dependency** (pixel reads in the Task 4 tests, and the RGB re-encode safeguard for iOS; it depends only on `archive`). Alternative: a hand-rolled PNG reader and encoder with `dart:io` zlib. Recommended: `image`, if it resolves against Flutter's pins; otherwise the hand-rolled version.
2. **Android monochrome (themed) icon** is out of scope. Say if you want it added.
3. **Drawer and About placement** are left to NAV-002 and ABT-001; this task proves the widget at the specified sizes only.

## Plan review

### Round 1: Needs user decision (2 Critical, 10 Important, 11 Minor, 3 Needs user decision)

- **C1 (adaptive geometry used diameter 892; the ring's ink reaches 896):** applied. Formula, Facts, test literals and the safe-zone test now use 896; the reviewer's Chrome measurement is recorded in Facts.
- **C2 (bundled logo can't load in `shared_ui` tests; async decode; DPR 1 only):** applied in part. The `runAsync` precache and the `devicePixelRatio` parameter stand. The package-key premise was wrong; see round 2 C1.
- **I1–I10:** applied. `--check` hashes outputs (I1); CLI `--source-dir` / `--root` and exit codes 0/1/2/64 (I2); LF-normalised SVG hashes (I3); parent-constraint check (I4, mechanism corrected in round 2 I1); 15 distinct `Contents.json` filenames (I5); iOS corner gradient values (I6); explicit-path staging and `pubspec.lock` (I7); non-vacuous guard reusing `dart_source.dart` (I8); `backgroundSvg` (I9); Notes for NAV-002 / ABT-001 / REL-001 (I10).
- **M1–M11:** applied (live-switch `pumpAndSettle` and `gaplessPlayback`; `fvm dart run melos`; lint description; `image: ^4.13.1`; open-item evidence; token pins in `dimensions_test.dart`; capture-helper path and logo README; two SVGs hashed; decision B wording; out-of-scope list; legacy icons verified statically only).
- **U1 → decision D** (FND-008 owns the full launcher set; REL-001 narrows), **U2 → decision E** (static iOS verification; Done with the check outstanding), **U3 → decision F** (AC2 at widget level). All three answered by the product owner on 2026-11-16, recommended options.

### Round 2: Approve after corrections (2 Critical, 4 Important, 9 Minor, 0 Needs user decision)

- **C1 (`DiskAssetBundle` unnecessary and failing):** applied. `flutter_test` already serves `packages/shared_ui/…` keys, so the bundle and its support file are removed; Facts, Task 1 and Task 2 corrected.
- **C2 (new assets break `font_assets_test.dart`'s exact-set assertion):** applied. Task 1 narrows that assertion to `assets/fonts/` entries and runs the full `shared_ui` suite plus the root architecture tests before committing.
- **I1 (`LayoutBuilder` check rejects larger tight parents and breaks intrinsics):** applied. Replaced by a `RenderConstrainedBox`-based render object that throws only when the incoming maximum is below `size`; two tests added.
- **I2 (guard string check blanked by `cleanDartSource`):** applied. The asset-name check runs on raw text; second positive control added.
- **I3 (`backgroundSvg` test too weak):** applied. Exactly one `<rect` with `rx="0"` and `fill="url(#bg)"`; mutation proof added.
- **I4 (adaptive wiring untested):** applied. XML test and a `delete ic_launcher.xml` mutation added.
- **M1–M9:** applied (`captureWidget` DPR detail; foreground `viewBox` rasterisation; exit-2 test; relative forward-slash manifest paths; out-of-scope: exported files and platform-mandated sub-40 sizes; Task 5 status wording; `ensureInitialized`; expected RED reasons; `launcher_spec.dart` hash in the manifest).
- **Open items after round 2:** none needing a decision beyond the three listed in "Open items for approval".

## Calibration record (Task 2, 2026-11-16)

Flutter 3.50.0 tester vs Chrome 157.0.8103.78, α in [0, 1], worst of both themes, decode at `size × devicePixelRatio` with `FilterQuality.high` (the chosen strategy):

| Reference px | mean α | max α | mean colour |
|---|---|---|---|
| 40 | 0.0398 | 0.576 | 0.0283 |
| 80 | 0.0236 | 0.635 | 0.0169 |
| 120 | 0.0180 | 0.467 | 0.0131 |
| 132 | 0.0179 | 0.561 | 0.0129 |
| 264 | 0.0058 | 0.404 | 0.0043 |
| 396 | 0.0042 | 0.278 | 0.0032 |

The full-decode alternative (1024 px decoded, `FilterQuality.high`) measured worse at 40 px (0.0454 / 0.710 / 0.0328) and 80 px (0.0271 / 0.753 / 0.0195), and slightly better only at 396 px (0.0040 / 0.345 / 0.0030). Outer-band ink share 0.86…1.24 (full decode 0.84…1.25), whole-image ink 0.99…1.06. Ceilings sit about 20 % above the measured worst; the fidelity test also asserts the outer-band ink share within 0.75…1.35 and the whole-image ink within 0.95…1.10.

## Implementation record (2026-11-17)

- **Tasks 1–4** were implemented as planned, with these rulings: the below-size parent check *reports* a `FlutterError` instead of throwing from `performLayout` (a throw left the parents unsized and cascaded); the hairline floor became an outer-band ink share plus whole-image ink (an annulus under 1 px wide was noise at 40 px); `launcher:check` and its place in `lint` landed with the committed outputs in Task 4.
- **Device check:** an API 35 emulator (Pixel 9 Pro) was used, since the API 28 AVD the plan names doesn't exist on this machine; both are adaptive-capable.
- **Whole-branch review:** With fixes (0 Critical, 1 Important). Fixed test-first: a larger tight parent upscaled the small decode and blurred the mark (the `Image` is now centred, painting at exactly `size`); the squeeze check now tolerates `precisionErrorTolerance` (promoted from Minor, because `logoDrawer == logoMin`). Nine minors are deferred (listed in `docs/PROGRESS.md`).
- **Plan text correction:** `image` pulls `archive` and, through it, `posix` into the root lock (dev-only, harmless).
