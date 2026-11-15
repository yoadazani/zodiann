# ZOD-FND-009 Icon Set (Generated Dart Drawing Code) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** All 33 Zodiann icons render in the app through one widget, `ZodiannIcon`. It draws at 20 px in controls and 16 px in small buttons and fields, and `iconBack()` / `iconFwd()` follow the reading direction. The drawing data is generated from the source SVGs, with no new runtime dependency.

**Architecture:**
- **Generator.** A root dev tool, `tool/gen_icons.dart`, parses `design-reference/zodiann/assets/icons/*.svg` with a strict parser. Anything unsupported is an error. It emits `packages/shared_ui/lib/src/icons/zodiann_icons.g.dart`: one `const ZodiannIconData` per icon, absolute path commands only, formatted by `dart format`. `--check` regenerates in memory and fails if the committed file differs. It runs first in `melos run lint` (`icons:check`), and a root test repeats it on every `melos run test`.
- **Widget.** `ZodiannIcon` is a `CustomPaint` widget that draws one `ZodiannIconData` with SVG semantics.
  - The 24-unit viewBox is scaled uniformly to the icon size and centred, so the stroke scales with it, as in the browser.
  - Fill is painted before stroke, with round caps and joins.
  - Size and colour come from `IconTheme`, like Material's `Icon`. The Zodiann themes set `iconTheme.size = ZodiannSize.icon` (20). `ZodiannButton` already supplies 16.
- **Direction.** `iconBack()` / `iconFwd()` return a `ZodiannDirectionalIcon`. It picks `chevL` or `chevR` from `Directionality.of(context)` at build time, as `kit.js` `iconBack` / `iconFwd` do. Nothing is ever transformed or mirrored.
- **Fidelity.** Reference sheets are rendered by headless Chrome from the same SVG files at 16, 20, 48, 60 and 96 px, and committed as test fixtures with the SVGs' SHA-256s. A Flutter test renders the same sheets with `ZodiannIcon` and compares the alpha per icon.

**Tech Stack:** Flutter 3.50.0 / Dart 3.14.0 (FVM), `package:test` (root), `flutter_test`, `xml ^7.1.0` (new **root dev_dependency** only; already in `pubspec.lock` transitively at 7.1.0, the latest; pure Dart, no network), `crypto` (already a `shared_ui` dev dependency). Reference images: Google Chrome 157 headless, run manually.

**Spec:** `docs/superpowers/specs/2026-11-15-zod-fnd-009-icon-set-design.md` (product-owner decisions, 2026-11-15). Task: `docs/development/foundations-architecture/ZOD-FND-009-integrate-the-33-icon-set-as-svg-assets.md`. Design: `design-reference/zodiann/MASTER.md` §4 (20 / 16), §11 (icons, chevrons swap, six never mirror), §13. Second source: `design-reference/zodiann/_source/kit.js:208-244` (`IC`, `iconBack`, `iconFwd`) and `kit.css:121-122` (`svg.i` 20 px, `.sm` 16 px, `stroke: currentColor`).

## Product-owner decisions (2026-11-15)

- **Option 1 chosen:** generate Dart drawing code from the SVGs. `flutter_svg` 2.4.0 and `vector_graphics` 1.3.1 both depend on `http`, which the FND-007 guard (`test/architecture/no_network_test.dart`, `networkPackages`) forbids at runtime.
- No `flutter_svg`, no `vector_graphics`, no new runtime dependency. **The FND-007 no-network guard is not modified.**
- The SVGs in `design-reference/` are the single source of truth. The generated file is never edited by hand.
- The generator is deterministic, has a `--check` mode, and fails explicitly on unsupported elements, attributes or values.
- Paths, circles, rects, fills, strokes, stroke widths and viewBox proportions are preserved. The sizes are `ZodiannSize.icon` and `ZodiannSize.iconSmall`.
- `iconBack()` / `iconFwd()` use `Directionality`. No icon is mirrored automatically. `chevL`, `chevR` and all the others draw identically in both directions.
- Tests cover all 33 icons, both sizes, LTR / RTL selection, and visual fidelity against the source SVGs.
- **Documented deviation:** the task text says "register all 33 SVGs as app assets". Instead, the SVGs stay in `design-reference/`, and the app bundles generated Dart drawing code.

## Facts established while planning (2026-11-15)

- **The icon files:**
  - 33 files, all `viewBox="0 0 24 24"`, `width="24" height="24"`. Root attributes: `xmlns`, `fill="none"`, `stroke="currentColor"`, `stroke-width="1.6"`, `stroke-linecap="round"`, `stroke-linejoin="round"`.
  - Child elements: only `path` (37), `circle` (14), `rect` (3). No `<g>` and no `transform`.
  - Child attributes: `d`, `cx`, `cy`, `r`, `x`, `y`, `width`, `height`, `rx`, `fill`, `stroke`. Colour values: only `none` and `currentColor`.
- **Path commands used:** `M L H V A` and `a c s h l v z`.
  - Compact arc flags occur: `rotate.svg` has `a7.5 7.5 0 11-2.2-5.3`.
  - Implicit repeats occur: `chevD.svg` has `M7 10l5 5 5-5`.
  - Smooth cubics `s` occur in `globe.svg`.
  - `Q q T t m C S` are unused.
- **Fills:** play and pause are fill-only (`stroke="none"`). `more`'s three dots and `target`'s centre dot set `fill="currentColor"` and **inherit the stroke**, so they are filled and stroked: the dot radius is r + 0.8.
- **Second source:** `kit.js` `IC` holds the same 33 inner markups. `_source/render/assets.js` exported the SVG files from it.
- **Headless Chrome works without Node packages.** This command wrote a 96 × 96 RGBA PNG (colour type 6), with a transparent background, that renders `globe` correctly:
  `chrome.exe --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --default-background-color=00000000 --window-size=96,96 --screenshot=<png> file:///<html>`
  - Chrome is at `C:/Program Files/Google/Chrome/Application/chrome.exe`, version 157.0.8103.78.
- **Formatting:** `dart format` reads stdin, so `'…' | fvm dart format` prints the formatted source. The generator formats through `Platform.resolvedExecutable format`, the pinned SDK under `fvm dart run` and Melos.
- **Guards on the generated file:** it uses only its own constructors, never `Size(`, `SizedBox(`, `EdgeInsets` or `Color(`, so the UI-003 dimension guard and the colour guard never see a literal.
- **Network guard scope:** the guard checks members' runtime closures only (`includeDevDependencies: false`), and the root package isn't a member. A root dev dependency is neither shipped nor checked.

## Global Constraints

- **No new runtime dependency** in any member. Root `dev_dependencies` gains `xml: ^7.1.0` only. `test/architecture/no_network_test.dart` is unchanged and green.
- **Single source:** the generator reads only `design-reference/zodiann/assets/icons/*.svg`. Hand edits to `zodiann_icons.g.dart` are always caught by `icons:check` and the root freshness test.
- **Header** of the generated file, verbatim: `// GENERATED by tool/gen_icons.dart from design-reference/zodiann/assets/icons/*.svg (ZOD-FND-009).` and on the next line `// Do not edit. Regenerate: fvm dart run tool/gen_icons.dart`.
- **Supported SVG subset, and nothing else:**
  - Root `svg` attributes: `xmlns`, `width`, `height`, `viewBox`, `fill`, `stroke`, `stroke-width`, `stroke-linecap`, `stroke-linejoin`.
  - `path`: `d` plus the paint attributes.
  - `circle`: `cx cy r` plus paint.
  - `rect`: `x y width height rx ry` plus paint.
  - Paint attributes: `fill`, `stroke`, `stroke-width`, `stroke-linecap` (`butt|round|square`), `stroke-linejoin` (`miter|round|bevel`). Colours: `none` or `currentColor`.
  - `viewBox` must be `0 0 W H` with `W == width` and `H == height`.
  - Path commands: `MmLlHhVvCcSsAaZz`.
  - **Required:** the root must declare `width`, `height`, `viewBox` and all five paint attributes (`fill`, `stroke`, `stroke-width`, `stroke-linecap`, `stroke-linejoin`). SVG's initial values (black fill, butt, miter) are never assumed. The `viewBox` may use spaces or commas.
  - **XML nodes:** an XML declaration is allowed. A DOCTYPE, processing instruction, CDATA or comment anywhere throws. Non-whitespace text anywhere throws.
  - **Path grammar:**
    - `d` is non-empty and starts with `M`/`m`;
    - numbers after `Z`/`z` without a new command throw;
    - an arc flag other than `0`/`1` throws;
    - a lone `-` or `1e` throws.
  - **Values:**
    - `r`, `width`, `height` and `stroke-width` must be > 0;
    - `rx`, `ry` and the arc radii must be ≥ 0;
    - with only `rx` given, `ry = rx`, and the reverse;
    - `d`, `cx`, `cy`, `r`, `x`, `y`, `width` and `height` are required on their element, and a missing one throws. Only `rx`/`ry` are optional.
  - **File names:** each must match `^[a-z][A-Za-z0-9]*$`, and must not be a Dart reserved word or `values`. An empty icons directory throws.
  - Everything else (another element, attribute or value, child content inside a shape, `Q`/`T`, a malformed number) throws `IconGeneratorException`. The message names the file as `'$name.svg'`, plus the element and the attribute or command.
- **Sizes:** only `ZodiannSize.icon` (20) and `ZodiannSize.iconSmall` (16). No numeric size literal in `lib/`.
- **Analysis and format:** `dart analyze --fatal-infos` and `dart format --set-exit-if-changed` pass on `tool/`, the root `test/` and `shared_ui`, the generated file included.
- **Naming:** project prefix `Zodiann`. The task's "thin `AppIcon` wrapper" is `ZodiannIcon` (the convention of `ZodiannButton` and `ZodiannSize`). Icon constants keep the SVG file names (`ZodiannIcons.chevL`, `ZodiannIcons.x`).
- **Commands:** run as `fvm dart …` / `fvm flutter …` from PowerShell, and Melos as `fvm dart run melos run <script>`.

## Out of scope

- The logo SVGs (`assets/zodiann-logo*.svg`, MASTER §11 "Logo"): drawer (NAV-*) and About (ABT-*) tasks own them.
- Icon buttons (46 × 46 / 36): component and NAV tasks.
- Glyphs (`ZodiannGlyphs`): font-based, UI-002.
- A CI job that regenerates references: there is no CI yet (FND-004). References are regenerated manually.
- Swapping UI-004's blank 16 × 16 placeholder in `button_sheet_test.dart:357,399` for a real icon (U1, product owner 2026-11-15: Option A). The UI-004 suites stay unchanged; NAV/WHL screens use real icons.

## Review Focus

1. **The design changes an SVG or adds a 34th icon.** Expect a loud failure, not a silent drift. `icons:check` and the root freshness test catch the code. The manifest SHA-256 test catches the reference sheets. The count test (33) forces a deliberate update. *Tests: Task 2 freshness; Task 4 manifest.*
2. **The icon sits in a larger or tight box** (a stretched button, a 46 × 46 icon button). It must draw at its own size, centred, never stretched to the box. *Test: Task 3 "tight 100 × 40 box draws a centred 20 px icon".*
3. **Large text scale.** At `textScaler` 2.0 icons stay 20 / 16, as Material icons do. *Test: Task 3.*
4. **Disabled and dimmed contexts.** `IconTheme.opacity` multiplies the alpha, as `Icon` does, so later disabled states work. *Test: Task 3.*
5. **A live language switch.** Switching en → he in a running tree swaps `iconBack()` immediately, with nothing cached from the old direction. *Test: Task 3, a live `Directionality` switch on the same element.*
6. **A forced-LTR island.** A back/forward button inside an L-7 island (dates and numbers kept LTR, e.g. WHL-016's time steppers) follows the island, because `iconBack()` reads the *nearest* `Directionality`. Keep `iconBack()` / `iconFwd()` outside such islands. This goes in the doc comment and in the PROGRESS **Icons** convention. *Test: Task 3 `'nested Directionality: iconBack follows the nearest ancestor'`.*

---

**Before Task 1:** the reviewed plan and the design doc are committed on the task branch (`docs(ZOD-FND-009): plan and design`) when the plan is presented.

### Task 1: Strict SVG parser (tool side)

**Files:**
- Create: `tool/icons/svg_icon.dart` (the IR plus `parseSvgIcon`)
- Modify: `pubspec.yaml` (root `dev_dependencies`: `xml: ^7.1.0`, alphabetical, edited by hand, then `fvm flutter pub get` from the workspace root; plain `dart pub get` can't resolve the Flutter members)
- Test: `test/tool/svg_icon_test.dart`

**Interfaces:**
- Produces (pure Dart, `tool/icons/svg_icon.dart`):
  - `final class IconGeneratorException implements Exception { IconGeneratorException(this.message); final String message; }`
  - `SvgIcon parseSvgIcon(String name, String source)`
  - `final class SvgIcon { final String name; final double viewBoxWidth, viewBoxHeight; final List<SvgShape> shapes; }`
  - `final class SvgPaint { final bool fill; final SvgStroke? stroke; }` and `final class SvgStroke { final double width; final String cap; final String join; }` (`cap` ∈ butt/round/square; `join` ∈ miter/round/bevel). `stroke == null` means `stroke="none"`.
  - `sealed class SvgShape { SvgPaint get paint; }`:
    - `SvgPath(List<SvgCommand> commands, SvgPaint paint)`
    - `SvgCircle(double cx, double cy, double r, SvgPaint paint)`
    - `SvgRect(double x, double y, double width, double height, double rx, double ry, SvgPaint paint)`
  - `sealed class SvgCommand`, **absolute only**:
    - `MoveTo(x, y)`, `LineTo(x, y)`, `CubicTo(x1, y1, x2, y2, x, y)`
    - `ArcTo(x, y, rx, ry, rotation, largeArc, sweep)`, with booleans for the flags
    - `Close()`
  - Every IR class has value `==` / `hashCode` for tests.

- [ ] **Step 1: Write the failing tests** in `test/tool/svg_icon_test.dart`. A helper `svg(String body, {String root = …})` wraps a body in the exact root of the real files.
  - `'root style: stroke-only path inherits 1.6 / round / round'`: `parseSvgIcon('t', svg('<path d="M4 7h16"/>')).shapes.single.paint == SvgPaint(fill: false, stroke: SvgStroke(1.6, 'round', 'round'))`.
  - `'fill="currentColor" stroke="none" → fill only'`, using play's literal `d`.
  - `'fill="currentColor" alone → fill and inherited stroke'`, using more's first circle: `SvgCircle(12, 5.5, 1.3, SvgPaint(fill: true, stroke: SvgStroke(1.6, 'round', 'round')))`.
  - `'relative and H/V commands become absolute'`: `M4 7h16M4 12h16M4 17h16` → `[MoveTo(4,7), LineTo(20,7), MoveTo(4,12), LineTo(20,12), MoveTo(4,17), LineTo(20,17)]`; `M12 3.5V7` → `LineTo(12,7)`.
  - `'implicit repeats'`: `M7 10l5 5 5-5` → `[MoveTo(7,10), LineTo(12,15), LineTo(17,10)]`. An `M` with extra pairs gives implicit `LineTo`s: `M1 1 2 2` → `[MoveTo(1,1), LineTo(2,2)]`.
  - `'z returns to the subpath start for the next relative command'`: `M8.5 6h2.5v12H8.5zM13 6h2.5v12H13z` → literal list. Add `M2 2h4zm1 1h1`, where the `m` is relative to (2,2) → `MoveTo(3,3), LineTo(4,3)`.
  - `'compact arc flags'`: rotate's `d` → `[MoveTo(19.5,12), ArcTo(17.3, 6.7, 7.5, 7.5, 0, true, true), MoveTo(19.5,4.5), LineTo(19.5,8.5), LineTo(15.5,8.5)]`. Compare doubles with `closeTo(…, 1e-9)` via a matcher on the fields.
  - `'absolute arcs'`: anchor's `A`-free `a` and moon's `A`, as literals.
  - `'s reflects the previous cubic control point'`: globe's second path, the first `c` then `s`. Expect the reflected `x1 = 2·cur.x − prev.x2`. Also: `s` after a non-cubic uses the current point as the first control point.
  - `'numbers: .4, -.5, 2.2-5.3, 1e-1'`: parsed as 0.4, −0.5, 2.2 / −5.3, 0.1.
  - `'circle and rect'`: calendar's `rect` → `SvgRect(4, 5.5, 16, 14.5, 2, 2, …)` (`ry` defaults to `rx`); `rx`/`ry` absent → 0.
  - **Explicit failures**, one test each. Each expects `throwsA(isA<IconGeneratorException>().having((e) => e.message, 'message', allOf(contains('t.svg'), contains(<the culprit>))))`:
    - elements `g`, `line`, `polyline`, `ellipse`, `text`;
    - attributes `transform`, `opacity`, `class`, `style`, `stroke-dasharray`, `fill-rule`, `stroke-miterlimit`;
    - `fill="#f00"`, `stroke="red"`;
    - `stroke-linecap="foo"`;
    - `viewBox="0 0 24 20"` with `height="24"`, `viewBox="2 0 24 24"`, a missing viewBox;
    - root `<path>`;
    - a circle without `r` or without `cx`, a rect without `width` or without `y`, a path without `d`;
    - `d` containing `Q`, `T`, `M4 x`, `M4` (a missing coordinate);
    - text inside a `<path>`, a child element inside a `<circle>`;
    - a root missing any one of the five paint attributes (five cases), or missing `width`;
    - a comment between shapes, a comment outside the root, a DOCTYPE, CDATA, a processing instruction, stray text between shapes. An XML declaration alone is accepted;
    - `d=""`, `d="L1 1"` (no leading move), `d="M1 1z 2 2"`, `a1 1 0 21 2 2` (flag 2), `M1 -`, `M1 1e`;
    - `r="0"`, `width="-1"` on a rect, `rx="-1"`, `stroke-width="0"`, a negative arc radius;
    - `ry` alone → `rx = ry` (positive case).
  - `'all 33 design files parse'`: read every `design-reference/zodiann/assets/icons/*.svg` and expect `hasLength(33)` with no throw.

- [ ] **Step 2: Run the tests and verify they fail.** Run: `fvm dart test test/tool/svg_icon_test.dart`. Expected: compile failure, `tool/icons/svg_icon.dart` not found.

- [ ] **Step 3: Implement `parseSvgIcon` in `tool/icons/svg_icon.dart`.**
  - Parse the XML with `package:xml`'s `XmlDocument.parse`. Only an XML declaration and whitespace-only text are allowed. Any comment, DOCTYPE, CDATA, processing instruction or non-whitespace text anywhere in the document throws.
  - Resolve paint by inheritance from the root: an element attribute overrides the root's.
  - The path tokenizer is a hand-written scanner:
    - number = `[-+]?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?`;
    - separators are whitespace and commas;
    - arc flags are a single `0`/`1` character, so `11-2.2` reads as flag 1, flag 1, −2.2.
  - Track the current point, the subpath start and the last cubic's second control point.

- [ ] **Step 4: Run the tests and verify they pass.** Run: `fvm dart test test/tool/svg_icon_test.dart`. Expected: all pass. Then `fvm dart analyze --fatal-infos tool test` exits 0.

- [ ] **Step 5: Commit.** Run `git add pubspec.yaml pubspec.lock tool/icons/svg_icon.dart test/tool/svg_icon_test.dart`, then `git commit -m "feat(ZOD-FND-009): strict SVG icon parser for the generator"`.

---

### Task 2: Runtime data model, emitter, generated file and `--check`

**Files:**
- Create: `packages/shared_ui/lib/src/icons/zodiann_icon_data.dart` (the hand-written model)
- Create: `tool/icons/icon_source_emitter.dart`
- Create: `tool/gen_icons.dart` (CLI: write by default, `--check` to verify)
- Create (generated): `packages/shared_ui/lib/src/icons/zodiann_icons.g.dart`
- Modify: root `pubspec.yaml` Melos scripts. Add `icons:check:`, in the existing block style, with `description: Fail if the generated icon code is stale (ZOD-FND-009).` and `run: dart run tool/gen_icons.dart --check`. Make it a `lint` step after `l10n:check`. Update `lint`'s description to `l10n:check + icons:check + analyze + format:check`.
- Test: `test/tool/icon_source_emitter_test.dart`, `test/tool/icons_generated_fresh_test.dart`, `packages/shared_ui/test/icons/icon_data_test.dart`. The last one checks that the runtime model's value equality and `hashCode` agree for equal and unequal instances of each shape and command. It also checks that `ZodiannIcons.values` has 33 distinct entries, in name order.

**Interfaces:**
- Consumes: Task 1's `parseSvgIcon`, `SvgIcon`, `IconGeneratorException`.
- Produces, runtime model in `zodiann_icon_data.dart` (all `const` constructors, value `==` / `hashCode`, Flutter `dart:ui` enums):
  - `final class ZodiannIconData { const ZodiannIconData({required this.name, required this.viewBoxWidth, required this.viewBoxHeight, required this.shapes}); final String name; final double viewBoxWidth, viewBoxHeight; final List<ZodiannIconShape> shapes; }`
  - `final class ZodiannIconPaint { const ZodiannIconPaint({this.fill = false, this.stroke}); }` and `final class ZodiannIconStroke { const ZodiannIconStroke(this.width, this.cap, this.join); final double width; final StrokeCap cap; final StrokeJoin join; }`
  - `sealed class ZodiannIconShape`:
    - `ZodiannIconPath(this.commands, this.paint)`
    - `ZodiannIconCircle(this.cx, this.cy, this.r, this.paint)`
    - `ZodiannIconRect(this.x, this.y, this.width, this.height, this.rx, this.ry, this.paint)`
  - `sealed class ZodiannPathCommand`: `IconMoveTo(x, y)`, `IconLineTo(x, y)`, `IconCubicTo(x1, y1, x2, y2, x, y)`, `IconArcTo(x, y, rx, ry, rotation, largeArc, clockwise)`, `IconClose()`.
    - The SVG sweep flag 1 maps to `clockwise: true`, because the y axis points down, as in Flutter's `Path.arcToPoint`.
- Produces, generated:
  - `abstract final class ZodiannIcons { static const ZodiannIconData alert = …; … static const List<ZodiannIconData> values = [alert, …]; }`
  - 33 constants named after the files and sorted by name with ordinal code-unit order (`alert, anchor, book, calendar, check, chevD, chevL, chevR, clock, copy, …`). `values` uses the same order.
- Produces, tool side:
  - `String emitIconsLibrary(List<SvgIcon> icons)`: unformatted Dart, icons sorted by name, doubles printed with `double.toString()`.
  - `Future<String> formatDart(String source)`: pipes the source through `Platform.resolvedExecutable format --stdin-name=packages/shared_ui/lib/src/icons/zodiann_icons.g.dart`, so later `analysis_options.yaml` formatter settings still match `format:check`. Throws `IconGeneratorException` on a non-zero exit.
  - `Future<String> generateIconsSource(Directory iconsDir)`: lists `*.svg`, sorts by code unit, validates the file names (Global Constraints), parses, emits, formats. An empty directory throws.
  - `gen_icons.dart` defines `const iconsDir = 'design-reference/zodiann/assets/icons'` and `const generatedPath = 'packages/shared_ui/lib/src/icons/zodiann_icons.g.dart'`, and runs from the workspace root.
    - Write mode writes LF.
    - `--check` compares the generated source with the committed file, with CRLF normalised to LF. When they differ it prints `Generated icons are stale; run: fvm dart run tool/gen_icons.dart` to stderr and exits 1. When they match it prints `Generated icons are up to date.` and exits 0.
    - Any `IconGeneratorException` prints its message and exits 2.
    - Accepted arguments: `--check`, `--icons-dir=<dir>` and `--out=<file>`. The last two override the two constants and exist for tests. Any other argument prints a usage line and exits 64.

- [ ] **Step 1: Write the failing emitter tests** in `test/tool/icon_source_emitter_test.dart`:
  - `'emits the header verbatim'`: the first two lines equal the Global Constraints header.
  - `'emits one const per icon, sorted, and values in the same order'`: feed `[icon('b'), icon('a')]`, expect `static const ZodiannIconData a` before `b`, and `values = [a, b]`.
  - `'maps every command and shape'`: for an IR with each `SvgCommand` and each `SvgShape`, the output contains `IconMoveTo(4.0, 7.0)`, `IconArcTo(17.3, 6.7, 7.5, 7.5, 0.0, true, true)`, `ZodiannIconRect(4.0, 5.5, 16.0, 14.5, 2.0, 2.0,`, `ZodiannIconStroke(1.6, StrokeCap.round, StrokeJoin.round)`, and `ZodiannIconPaint(fill: true)` (no stroke) for play.
  - `'deterministic: same output for shuffled input and repeated runs'`.
  - `'formatDart formats and rejects invalid source'`: `formatDart('void  main(){}')` → `'void main() {}\n'`; `formatDart('void main(')` throws `IconGeneratorException`.

- [ ] **Step 2: Write the failing freshness tests** in `test/tool/icons_generated_fresh_test.dart`:
  - `'the committed generated file is up to date'`: `generateIconsSource(Directory(iconsDir))` equals the committed file after CRLF → LF.
  - `'33 icons, named as the files'`: the design folder has exactly 33 `*.svg` files, and the generated file contains `static const ZodiannIconData <name> =` for each of them.
  - `'second source: kit.js IC matches the SVG files'`:
    - Extract `IC`'s entries from `design-reference/zodiann/_source/kit.js` with a regex over `name: '<markup>'` between `const IC = {` and `};`.
    - Expect the same 33 keys, and each SVG's inner markup (between the root `>` and `</svg>`, trimmed) equal to the kit.js markup.
  - `'--check exits 1 on a stale file and 0 on a fresh one'`:
    - Run `Process.run(Platform.resolvedExecutable, ['run', 'tool/gen_icons.dart', '--check'])` against the real tree and expect exit 0.
    - For the stale case, factor the check into `Future<int> checkGenerated({required Directory iconsDir, required File generated})` in `gen_icons.dart`. The test calls it with a temp copy whose generated file has one character changed, then with a missing file, and expects 1 both times.
  - `'invalid icon names fail'`: temp dirs with `Bad.svg`, `9a.svg`, `class.svg`, `values.svg` and an empty dir. Each throws `IconGeneratorException` naming the file or the directory.
  - `'an unsupported file fails the generator with exit 2'`: a temp icons dir holding one SVG with `<g>` → `checkGenerated` throws `IconGeneratorException`. The CLI maps that to exit 2; assert it by running the CLI with a `--icons-dir=<temp>` / `--out=<temp>` override, the only two other accepted arguments.

- [ ] **Step 2b: Write `packages/shared_ui/test/icons/icon_data_test.dart`.** It checks value equality and `hashCode` for each shape and command, and that `ZodiannIcons.values` has 33 distinct entries in name order. It imports `package:shared_ui/src/icons/…` directly, because the barrel export arrives in Task 3.

- [ ] **Step 3: Run the tests and verify they fail.**
  - Run: `fvm dart test test/tool/icon_source_emitter_test.dart test/tool/icons_generated_fresh_test.dart`. Expected: compile failure (missing `icon_source_emitter.dart` / `gen_icons.dart`).
  - In `packages/shared_ui`, run `fvm flutter test test/icons/icon_data_test.dart`. Expected: compile failure (no `zodiann_icon_data.dart`).

- [ ] **Step 4: Implement the model, the emitter and `gen_icons.dart`.** Then generate with `fvm dart run tool/gen_icons.dart`.
  - The generated library imports `dart:ui` (for `StrokeCap` / `StrokeJoin`) and `zodiann_icon_data.dart`.
  - Never edit the output by hand. If `dart analyze --fatal-infos` flags it, fix the emitter.

- [ ] **Step 5: Run and verify.**
  - `fvm dart test test/tool` → all pass.
  - `fvm flutter test test/icons/icon_data_test.dart` in `packages/shared_ui` → all pass.
  - `fvm dart run tool/gen_icons.dart --check` → `Generated icons are up to date.`, exit 0.
  - `fvm dart run melos run lint` → exit 0, with `icons:check` listed.
  - Hand-edit proof: change one digit in the generated file, run `--check`, expect exit 1. Then restore it with `fvm dart run tool/gen_icons.dart` and confirm `--check` exits 0. The file isn't committed yet, so `git checkout` can't restore it.

- [ ] **Step 6: Commit.** Run `git add tool/ test/tool/ pubspec.yaml packages/shared_ui/lib/src/icons/ packages/shared_ui/test/icons/icon_data_test.dart`, then `git commit -m "feat(ZOD-FND-009): generate icon drawing data from the source SVGs, with --check"`.

---

### Task 3: `ZodiannIcon`, the icon theme size, and direction

**Files:**
- Create: `packages/shared_ui/lib/src/icons/zodiann_icon.dart`
- Modify: `packages/shared_ui/lib/src/theme/zodiann_theme.dart`: both themes get `iconTheme: IconThemeData(size: ZodiannSize.icon, color: s.text)`. kit.css `svg.i` is 20 px with `currentColor`, and the body text is `text`.
- Modify: `packages/shared_ui/lib/shared_ui.dart`: export `src/icons/zodiann_icon.dart`, `src/icons/zodiann_icons.g.dart` and `src/icons/zodiann_icon_data.dart show ZodiannIconData`, alphabetically.
- Test: `packages/shared_ui/test/icons/zodiann_icon_test.dart`, `packages/shared_ui/test/icons/icon_direction_test.dart`; `packages/shared_ui/test/theme/zodiann_theme_test.dart` (add the iconTheme expectation)

**Interfaces:**
- Consumes: `ZodiannIconData`, `ZodiannIcons` (Task 2).
- Produces:
  - `class ZodiannIcon extends StatelessWidget { const ZodiannIcon(this.icon, {super.key, this.size, this.color, this.semanticLabel}); final ZodiannIconData icon; final double? size; final Color? color; final String? semanticLabel; }`
    - Size: `size ?? context.dependOnInheritedWidgetOfExactType<IconTheme>()?.data.size ?? ZodiannSize.icon`. Read the raw inherited data, because `IconTheme.of` substitutes Material's 24 fallback (`icon_theme.dart`, `IconTheme.of`).
    - Colour: `color ?? IconTheme.of(context).color`, with alpha × `IconTheme.of(context).opacity`.
    - Layout: `SizedBox.square(dimension: size)` holding a `CustomPaint` whose painter draws the icon at `size` **centred in the actual box**, never scaled to the box.
    - Semantics: with no label, `ExcludeSemantics`; with a label, `Semantics(label:, image: true)`.
  - `class ZodiannIconPainter extends CustomPainter`, used by tests and kept out of the barrel (`hide`):
    - scale = `size / max(viewBoxWidth, viewBoxHeight)`, the viewBox centred;
    - for each shape: fill first (`PaintingStyle.fill`), then stroke (`PaintingStyle.stroke`, width × scale, or via `canvas.scale`);
    - circle → `addOval`; rect → `addRRect` with `Radius.elliptical(rx, ry)`, each clamped to half the side as SVG does. Compute the clamped radii in locals first, so the UI-003 `Radius.` guard never sees a `/ 2` literal inside the call;
    - path commands → `moveTo` / `lineTo` / `cubicTo` / `arcToPoint(…, radius: Radius.elliptical(rx, ry), rotation:, largeArc:, clockwise:)` / `close`;
    - anti-aliased; `shouldRepaint` when the icon, size or colour changes.
  - `class ZodiannDirectionalIcon extends StatelessWidget { const ZodiannDirectionalIcon({super.key, required this.ltr, required this.rtl, this.size, this.color, this.semanticLabel}); }`. Its build returns `ZodiannIcon(Directionality.of(context) == TextDirection.rtl ? rtl : ltr, …)`.
  - `Widget iconBack({double? size, Color? color, String? semanticLabel})` → `ZodiannDirectionalIcon(ltr: ZodiannIcons.chevL, rtl: ZodiannIcons.chevR, …)`. Its doc comment carries Review Focus 6: it follows the nearest `Directionality`, so keep it outside forced-LTR islands.
  - `Widget iconFwd(…)` → `ltr: ZodiannIcons.chevR, rtl: ZodiannIcons.chevL`.

- [ ] **Step 1: Write the failing widget tests** in `zodiann_icon_test.dart`. Pump through `ZodiannTheme` dark unless stated.
  - **Pixel tests** (tight box, opacity, every icon paints, no mirroring) use the existing capture pattern (`button_sheet_test.dart:126-180`):
    - set `tester.view.physicalSize` and `tester.view.devicePixelRatio = 1`, with `addTearDown(tester.view.reset)`;
    - capture with `RepaintBoundary` → `toImage(pixelRatio: 1)` → `toByteData(format: ui.ImageByteFormat.rawStraightRgba)`, inside `tester.runAsync`.
  - Size tests that use `getSize` pump the icon inside `Center`, so it gets loose constraints.
  - `ZodiannIconPainter` exposes `icon`, `size` and `color` as final fields for these tests.
  - `'default size is ZodiannSize.icon (20) under the Zodiann theme'`: `tester.getSize(find.byType(ZodiannIcon)) == Size.square(ZodiannSize.icon)`.
  - `'no ambient size → 20, never the Material 24 fallback'`, under a bare `Directionality` with no theme.
  - `'IconTheme with colour only keeps 20'`: `IconTheme(data: IconThemeData(color: …))` inside the theme.
  - `'explicit size: ZodiannSize.iconSmall gives 16'`.
  - `'an ambient IconTheme size wins over the theme'`: `IconTheme(data: IconThemeData(size: ZodiannSize.iconSmall))` → 16.
  - `'inside ZodiannButton the icon is 16 and tinted with the label colour'`: `ZodiannButton(icon: ZodiannIcon(ZodiannIcons.save), …)`.
    - Read the painter: `tester.widget<CustomPaint>(find.descendant(of: find.byType(ZodiannIcon), matching: find.byType(CustomPaint))).painter as ZodiannIconPainter`.
    - Expect `size == ZodiannSize.iconSmall`, and the colour equal to the primary button's label colour from `ZodiannButtonColors`.
    - Read the painter rather than `getSize`, because the button's slot is a tight 16 × 16 and would report 16 for any icon size.
  - `'tight 100 × 40 box draws a centred 20 px icon'`: render `x` in a tight `SizedBox`. The ink's bounding box (alpha > 0) is centred, ±0.5 px, and no larger than 20 × 20.
  - `'textScaler 2.0 does not change the size'`.
  - `'colour: default is the theme text colour; explicit colour wins'`, in both themes (`text` from `ZodiannSurfaces`).
  - `'IconTheme opacity 0.5 halves the painted alpha'`: compare the peak alpha of `check` rendered at full and at half opacity, within ±2/255 of half.
  - `'decorative by default; labelled icons are announced'`: `tester.getSemantics`; with no label there's no semantics node for the icon.
  - `'every icon paints'`: each of the 33 `ZodiannIcons.values` at 16 and 20, centred in a transparent 2·size boundary. At least one pixel has alpha > 0.5, and every pixel outside the centred size × size square has alpha 0.
  - `zodiann_theme_test.dart`: `'iconTheme size 20 and colour text, in both themes'`. Also add the `iconTheme` assertion to `'buildZodiannTheme uses only the given tokens'`.

- [ ] **Step 2: Write the failing direction tests** in `icon_direction_test.dart`:
  - `'iconBack is chevL in LTR and chevR in RTL; iconFwd the reverse'`: under `Directionality`, read `tester.widget<ZodiannIcon>(find.byType(ZodiannIcon)).icon`.
  - `'switching the app to Hebrew swaps them'`: a `MaterialApp` with `ZodiannLocalizations` and the material_ui delegates, `locale: Locale('he')` versus `Locale('en')`. Back resolves to chevR under he and chevL under en.
  - `'live switch updates the same element'`: pump LTR, then RTL with the same keys. The icon changes without a remount (`tester.element` is identical).
  - `'nested Directionality: iconBack follows the nearest ancestor'`: `Directionality(ltr)` inside `Directionality(rtl)` → chevL (Review Focus 6).
  - `'no icon is mirrored: every icon paints identically in LTR and RTL'`: for each of the 33, the RTL raw RGBA bytes equal the LTR bytes. The named six get their own test with the same assertion, so a failure names them.
    - `wheel`, `grid`, `target` and `anchor` are exactly symmetric under x → 24 − x (checked against the SVGs), so the pixel test is meaningful only for `rotate`, `datewheel` and the chevrons. The structural test below covers the other four.
  - `'no Transform anywhere around or inside the icon'`: no `Transform` appears as a descendant of `ZodiannIcon` or of `ZodiannDirectionalIcon`, or between the test root and the icon (`find.ancestor`), in LTR or RTL.

- [ ] **Step 3: Run and verify they fail.** In `packages/shared_ui`, run `fvm flutter test test/icons test/theme/zodiann_theme_test.dart`. Expected: the icon tests fail to compile (`ZodiannIcon` undefined). `zodiann_theme_test.dart` compiles and fails on `iconTheme.size` (expected 20.0, actual null).

- [ ] **Step 4: Implement `zodiann_icon.dart`, the theme change and the exports.** If an existing theme test pins `iconTheme` (FND-013's "no hidden defaults"), update its expectation in the same commit and say so in the commit body.

- [ ] **Step 5: Run and verify they pass.**
  - `fvm flutter test` in `packages/shared_ui`: everything passes, including the UI-004 button suites unchanged.
  - Then `fvm dart run melos run test`: workspace green, `no_network_test` and `no_magic_dimensions_test` included.

- [ ] **Step 6: Mutation proofs.** Apply each mutation, run the suite, record the failing test, revert.
  - D1: swap `ltr` and `rtl` in `iconBack` → direction tests fail.
  - D2: read the direction once in the constructor through a static default (LTR) → the he test and the live-switch test fail.
  - D3: wrap `ZodiannIcon` in `Transform.flip(flipX: rtl)` → the "no icon is mirrored" test fails for chevL, chevR, rotate, datewheel and others.
  - D4: paint scaled to the box (`min(box.w, box.h) / 24`) → the tight-box test fails.
  - D5: ignore `IconTheme` size → the ambient-size test and the button test (painter size) fail.
  - D6: ignore opacity → the opacity test fails.
  - D7: size from `IconTheme.of(context).size` → the no-ambient-size and colour-only tests fail (24 instead of 20).

- [ ] **Step 7: Commit.** Run `git add packages/shared_ui`, then `git commit -m "feat(ZOD-FND-009): ZodiannIcon, theme icon size 20, iconBack/iconFwd by Directionality"`.

---

### Task 4: Visual fidelity against the source SVGs (Chrome references)

**Files:**
- Create: `tool/icons/render_icon_references.dart` (manual; Windows Chrome by default, `CHROME` env overrides)
- Create: `packages/shared_ui/test/fixtures/icons/sheet_{16,20,48,60,96}.png`, `manifest.json`, `README.md`
- Create: `packages/shared_ui/test/support/icon_sheet.dart` (harness)
- Test: `packages/shared_ui/test/icons/icon_fidelity_test.dart`, `packages/shared_ui/test/icons/icon_theme_render_test.dart`

**Interfaces:**
- Consumes: `ZodiannIcon`, `ZodiannIcons.values` (Task 3).
- Produces:
  - **Sizes.** 16 and 20 are the two product sizes. 48 and 60 are 3 × 16 and 3 × 20, standing in for high-density screens. 96 shows shape detail.
  - **Sheet layout.** All 33 icons in one row, ordered by file name in code-unit order: the generator's order, and therefore `ZodiannIcons.values`. The root Dart tool can't import the Flutter package. Cell `i` occupies `x ∈ [i·S, (i+1)·S)`, `y ∈ [0, S)`. The page is `33·S` wide and `max(S, 64)` tall. Icons are black, `#000`, on a transparent background.
  - **Chrome page.**
    - Each cell is `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" width="S" height="S" style="position:absolute;left:{i·S}px;top:0;display:block">` plus the file's inner markup. The root attributes are copied from the file itself.
    - CSS: `html,body{margin:0;padding:0;background:transparent;color:#000}`.
  - **Chrome flags.** The Facts command with `--window-size={33·S},{max(S,64)}`, plus `--force-color-profile=srgb`.
  - **The tool** checks each PNG's dimensions and fails otherwise.
  - **Manifest.** `manifest.json`: `{ "chrome": "157.0.8103.78", "sizes": [16, 20, 48, 60, 96], "svgSha256": { "<name>": "<hex>", … } }`. The SHA-256 is over the file bytes with CRLF normalised to LF.
  - **Harness.** `Future<ByteData> renderIconSheet(WidgetTester tester, double s, {Color? color, ThemeData? theme})` pumps the same layout. It places `ZodiannIcon(ZodiannIcons.values[i], size: s, color: color)`, and a null `color` uses the theme default. The fidelity test passes `const Color(0xFF000000)`.
    - It sets `tester.view.physicalSize = Size(33 * s, max(s, 64))` and `tester.view.devicePixelRatio = 1`, with `addTearDown(tester.view.reset)`.
    - It places each `ZodiannIcon(size: s, color: color)` with `Positioned(left: i * s, top: 0)` in a `Stack` inside a `RepaintBoundary`.
    - It captures with `toImage(pixelRatio: 1)` → `toByteData(format: ui.ImageByteFormat.rawStraightRgba)` inside `tester.runAsync`.
    - Reference PNGs are decoded with `ui.instantiateImageCodec`, also inside `runAsync`.
  - **Comparison.** `IconDiff compareCell(ByteData ref, ByteData actual, int width, int cell, int s)` returns `meanAbsAlpha`, `maxAbsAlpha` and `inkRatio` (Σα_actual / Σα_ref) over the cell. Alpha comes from `rawStraightRgba`.

- [ ] **Step 1: Write the render tool and generate the references.**
  - Run: `fvm dart run tool/icons/render_icon_references.dart`.
  - Expected: five PNGs and `manifest.json` under `packages/shared_ui/test/fixtures/icons/`.
  - Open `sheet_96.png` and `sheet_20.png` and check by eye that all 33 icons are there, in order, uncut.
  - `README.md` records:
    - the command, the Chrome version and the flags;
    - that the references are regenerated only when an SVG changes;
    - the deviation: the SVGs stay in `design-reference/` and the app bundles generated code.

- [ ] **Step 2: Write the failing fidelity tests** in `icon_fidelity_test.dart`:
  - `'references match the current SVGs'`: every SHA-256 in the manifest equals the current file's, and the manifest has exactly the 33 names. A changed SVG fails here with `regenerate references: fvm dart run tool/icons/render_icon_references.dart`.
  - `'every icon matches Chrome at <S> px'` for S ∈ {16, 20, 48, 60, 96}: per cell, `meanAbsAlpha ≤ meanCeiling[S]`, `maxAbsAlpha ≤ maxCeiling[S]`, and `inkRatio` ∈ [1 − inkTol[S], 1 + inkTol[S]]. A failure message names the icon and the size.
  - **Starting ceilings:**

    | S | meanCeiling | maxCeiling | inkTol |
    |---|---|---|---|
    | 96 | 0.010 | 0.35 | 0.03 |
    | 48, 60 | 0.020 | 0.45 | 0.05 |
    | 16, 20 | 0.035 | 0.60 | 0.08 |

  - **`'crisp: ink stays inside the stroke envelope'`** at 16 and 20. For each straight-segment icon (`menu`, `x`, `check`, `chevL`, `chevR`, `chevD`, `grid`), the peak alpha is ≥ 0.85 of Chrome's peak alpha in the same cell. This rules out a blurred, offset or half-pixel-smeared rendering.
  - **`'round caps and joins match Chrome'`** at 16, 20 and 96.
    - Caps: for `menu`, the ink in the caps region (defined below) is ≥ 0.7 × Chrome's ink in the same region.
    - Joins: for `chevL` and `check` at 96, take the pixels whose centre lies more than 0.8 units from the join vertex along the outer bisector (the half-plane past the round-join apex). Their summed alpha is ≤ Chrome's sum there + 0.5.
      - A miter join adds (0.8·√2 − 0.8)² × (96/24)² ≈ 1.76 alpha-pixels in that region (computed in review).
      - If calibration shows the anti-aliasing difference alone is above 0.5, stop and report. Never raise the tolerance past 1.0.
    - Caps region: the pixels whose centre x is < 4·S/24 or > 20·S/24.
    - SVGs and fixtures are read relative to `packages/shared_ui`, the `flutter test` working directory (`../../design-reference/zodiann/assets/icons`).

- [ ] **Step 2b: Run and verify they fail.** Run `fvm flutter test test/icons/icon_fidelity_test.dart`. Expected: compile failure, `test/support/icon_sheet.dart` missing. Then write the harness and run again: the fidelity tests run, and the calibration below starts.

- [ ] **Step 3: Run, measure and calibrate.**
  - Run `fvm flutter test test/icons/icon_fidelity_test.dart` and print the worst `mean`, `max` and `ink` per size.
  - If every icon is within the starting ceilings, tighten each ceiling to `max(round_up(worst × 1.5, 3 decimals), floor)`.
    - Floors: mean 0.002, max 0.10, inkTol 0.005. For ink, `worst` is `max |inkRatio − 1|`.
    - Never set a ceiling above its starting value.
    - Record the measured worst values per size in the plan's review record.
  - If any icon exceeds a starting ceiling:
    - **stop and debug** (superpowers:systematic-debugging) before touching thresholds;
    - a large miss on one icon means a parser or painter bug, such as an arc flag, `s` reflection or rect radius;
    - only an anti-aliasing difference shared across all icons may justify a higher ceiling, and the plan's review record must give the measured numbers and the reason.

- [ ] **Step 4: Mutation proofs.** Each mutation must fail at least one fidelity test at the stated size or sizes. Record which one, then revert. A mutation that survives means the ceilings are too loose: tighten them or stop and report.
  - F1: stroke width 1.4 instead of the parsed width (all sizes).
  - F2: `StrokeCap.butt` → the caps test (`menu`). The review computed ink ratios of 0.927 for `menu` and 0.931 for `x`, inside the starting inkTol, so the caps test is what catches it.
  - F3: drop the last shape of `wheel`.
  - F4: ignore `fill` (`target`, `more`, `play`, `pause`).
  - F5: flip the sweep flag to `!clockwise` (`rotate`, `datewheel`, `moon`).
  - F6: wrong `s` reflection, using `prev.x2` unreflected (`globe`).
  - F7: ignore the rect radius (`calendar`, `grid`, `copy`) at 96.
  - F8: scale by `size / 20` (all).
  - F9: emit the paths mirrored, `x → 24 − x`, for chevL only (`chevL` at every size).
  - F10: `StrokeJoin.miter` must fail the joins test (`chevL`, `check` at 96; a miter extends 0.331 units at 90°). Record the measured excess (expected ≈ 1.76).
  - F11: swap the `largeArc` and `clockwise` arguments (`moon`, `book`, `folder`, whose flags are 0/1).

- [ ] **Step 5: Write the light / dark render tests** in `icon_theme_render_test.dart`.
  - For each icon at 16 and 20, under the dark and the light theme with the default colour, on a transparent background: every pixel with straight alpha ≥ 0.5 (a₈ ≥ 128) has each RGB channel within ±2 of `ZodiannSurfaces.text` for that theme. Lower alphas are excluded, because un-premultiplying 8-bit pixels amplifies rounding.
  - Its alpha channel equals the black-icon render's within ±1/255 (the same geometry, a different tint).
  - Only when `ZODIANN_ICON_SPECIMEN_DIR` is set (as `ZODIANN_BUTTON_DIR` works in `button_sheet_test.dart`), the test also writes a specimen to `<dir>/icon_specimen_{dark,light}.png`. Step 6 sets it to `build` (git-ignored) with both sizes on `surface`, plus `iconBack` / `iconFwd` in LTR and RTL, for review by eye.

- [ ] **Step 6: Run and verify.** `fvm flutter test` in `packages/shared_ui` passes. Open both specimen PNGs and check by eye: crisp, the chevrons swapped in RTL, the six named icons unchanged.

- [ ] **Step 7: Commit.** Run `git add tool/icons/render_icon_references.dart packages/shared_ui/test docs/plans/ZOD-FND-009-svg-icon-set.md`, then `git commit -m "test(ZOD-FND-009): pixel fidelity against Chrome-rendered source SVGs at 16/20/48/60/96"`.

---

### Task 5: Review and close-out

**Files:**
- Modify: `docs/development/foundations-architecture/ZOD-FND-009-integrate-the-33-icon-set-as-svg-assets.md`: set the status, and add the deviation and PO decisions to **Notes**. The requirements and acceptance criteria are not rewritten.
- Modify: `docs/development/TASKS.md` (status), `docs/PROGRESS.md`:
  - Completed Tasks, Verification and Git State;
  - Technical Decisions: the generated icons, the deviation, `xml` as a root dev dependency, the theme `iconTheme`;
  - a new **Icons** block under Architecture Conventions: use `ZodiannIcon(ZodiannIcons.x)`, never a raw SVG; inside Material containers (`IconButton`, `AppBar`, `ListTile`), which inject an `IconTheme` size of 24, pass `size: ZodiannSize.icon` explicitly or set the container's `iconTheme` / `iconSize`; back / forward only via `iconBack()` / `iconFwd()`, kept outside forced-LTR islands; add or change an icon by editing the SVG, then run `gen_icons.dart` and `render_icon_references.dart`.

- [ ] **Step 1: Whole-branch code review.** Use superpowers:requesting-code-review. Apply Critical / Important findings test-first. Record deferred minors in PROGRESS.
- [ ] **Step 2: Verification.** Use superpowers:verification-before-completion. Every command must exit 0, and actual counts are recorded:
  - `fvm dart run melos run lint`
  - `fvm dart run melos run test`
  - `fvm dart run tool/gen_icons.dart --check`
  - `fvm flutter build apk --debug` in `apps/astro_mobile`
  - `git diff main --stat -- test/architecture/no_network_test.dart` (empty)
- [ ] **Step 3: Update the docs** listed above, then commit, push, open the PR and record the PR link (zodiann-development Step 8).
  - The plan and `docs/superpowers/specs/2026-11-15-zod-fnd-009-icon-set-design.md` are already committed on the task branch.
  - Never stage the unrelated `.fvmrc` change (its trailing newline was removed).

---

## Open items for approval

None. **U1 resolved (2026-11-15):** Option A, out of scope. Plan approved by the product owner the same day.

Calls made while planning, for you to check:
- `ZodiannIcon` instead of the task's `AppIcon`.
- The Zodiann themes set `iconTheme.size = 20` and colour `text`.
- Chrome renders the references, and they're regenerated manually.
- The fidelity ceilings are calibrated by the Task 4 procedure.

## Plan review

### Round 1: Needs user decision (0 Critical, 8 Important, 11 Minor, 1 Needs user decision)

| ID | Severity | Finding | Action |
|---|---|---|---|
| I1 | Important | `IconTheme.of` fills a missing size with Material's 24, so the `?? 20` fallback never ran | Applied: read the raw inherited `IconTheme`; two tests; mutant D7 |
| I2 | Important | The test view size and `runAsync` for pixel capture were unspecified (a 3168 px sheet vs the 800 × 600 default) | Applied: the harness sets the view, uses `Positioned`, and captures inside `runAsync`; Task 3 pixel tests use the same pattern |
| I3 | Important | The ±2 RGB check at alpha > 0.1 fails on correct code (un-premultiply rounding) | Applied: alpha ≥ 0.5, alpha equal within ±1/255 |
| I4 | Important | Calibration could collapse to 0; global ceilings let butt caps (ink 0.927) survive; joins never mutated | Applied: floors; a caps / joins test; F10 (miter), F11 (arc flag swap) |
| I5 | Important | Generator failure rules incomplete (root defaults, XML node kinds, path grammar, value ranges, file names) | Applied: Global Constraints rules plus one failure test each (Task 1); name and empty-dir tests (Task 2) |
| I6 | Important | `fvm dart pub get` contradicts the convention | Applied: `fvm flutter pub get` |
| I7 | Important | `iconBack()` inside a forced-LTR island follows the island | Applied: Review Focus 6, a nested-`Directionality` test, the doc comment, the PROGRESS convention |
| I8 | Important | Inline `<svg>` gaps break the sheet layout; the root tool can't import `ZodiannIcons.values` | Applied: absolute positioning, exact window size, code-unit file order |
| M1–M11 | Minor | Wording "axis-aligned"; Transform search scope + symmetric icons; theme RED expectation; explicit RED in Task 4; `Radius.` guard; `--stdin-name`; git hygiene; why 48 / 60; Melos block style; `'$name.svg'`; model equality test | All applied |
| U1 | Needs user decision | Replace UI-004's sheet placeholder with real icons? | Product owner chose Option A (out of scope), 2026-11-15 |

### Round 2: Approve after corrections (0 Critical, 2 Important, 10 Minor, 0 Needs user decision)

All round-1 corrections were verified as applied, with no contradictions between tasks, Interfaces and Global Constraints. The reviewer also confirmed Chrome 157 produces sheets of exactly 3168 × 96, 3168 × 64 and 528 × 64.

| ID | Severity | Finding | Action |
|---|---|---|---|
| I1 | Important | The joins tolerance (+0.05·S = 4.8 alpha-px) can't catch a miter join (≈ 1.76 alpha-px) | Applied: half-plane region past the round apex, tolerance +0.5 (never above 1.0); F10 records the measured excess |
| I2 | Important | The button test's `getSize` reads the tight 16 × 16 slot whatever the icon resolves; `getSize` tests need loose constraints | Applied: read the painter's `size` and `color`; size tests pump inside `Center`; D5 reworded |
| M1 | Minor | `icon_data_test.dart` had no write / RED / GREEN steps | Applied: Step 2b plus runs in Steps 3 and 5 |
| M2 | Minor | The hand-edit proof reverted an uncommitted file with `git checkout` | Applied: restore by regenerating |
| M3 | Minor | Task 1 Step 3 wording on comments was narrower than the constraints | Applied |
| M4 | Minor | A missing geometry attribute had no defined behaviour | Applied: required attributes, plus failure tests |
| M5 | Minor | The harness signature had a non-const default and omitted the icon | Applied: `{Color? color, ThemeData? theme}` |
| M6 | Minor | At 16 px the caps region could be empty | Applied: pixel-centre definition |
| M7 | Minor | Material containers inject an `IconTheme` size of 24 | Applied: PROGRESS Icons convention |
| M8 | Minor | The plan and design doc weren't committed; Task 4 didn't stage the calibration record | Applied: commit before Task 1; plan added to Task 4's commit |
| M9 | Minor | Specimens were written on every test run | Applied: only with `ZODIANN_ICON_SPECIMEN_DIR` |
| M10 | Minor | The working-directory-relative SVG path wasn't stated | Applied |

Two rounds done (the cap). U1 resolved: Option A. Plan approved 2026-11-15.
