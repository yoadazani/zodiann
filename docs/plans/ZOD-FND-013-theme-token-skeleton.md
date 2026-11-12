# ZOD-FND-013 Design-Token Theme Skeleton Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give Zodiann its token-based theme structure: five typed `ThemeExtension`s plus a `ColorScheme`, wired into a dark (Graphite) and a light (Porcelain) `ThemeData` that the app can switch at runtime. Add an automated guard so no hard-coded color appears outside the token files (ARCH-7).

**Architecture:**
- The theme lives in `packages/shared_ui`, the package documented as "buttons, drawer and design tokens". Feature packages can import it; they could not import the app.
- Each MASTER.md §2 group is one immutable `ThemeExtension` class, whose fields are exactly that group's tokens: `ZodiannSurfaces`, `SquareColors`, `ZodiacColors`, `AspectColors`, `BodyColors`.
- A `ZodiannTokens` bundle holds one theme's five extensions. `buildZodiannTheme(ZodiannTokens)` derives the `ColorScheme` and the `ThemeData` from it, so each color has a single source.
- Token values live only in `lib/src/theme/tokens/` (`graphite_tokens.dart`, `porcelain_tokens.dart`). For now they hold **placeholders** derived from Material's default scheme (no literals). ZOD-UI-001 replaces those two files' contents with MASTER.md's exact values.
- The app replaces FND-005's `AppTheme` seam with `ZodiannTheme.graphite` / `ZodiannTheme.porcelain`. It reads `ThemeMode` from an app-level `themeModeProvider` (default `system`), which is what makes runtime switching possible.
- A root architecture test fails on any color literal in `lib/` outside the token directory.

**Tech Stack:** Flutter 3.50.0 / Dart 3.14.0 (FVM), material_ui ^1.11.0, flutter_riverpod ^3.5.0 (app only), astro_core (for `Body`).

**Spec:** `assets/zodiann-specification.md` (ARCH-3, ARCH-7, NFR-X5). Design: `design-reference/zodiann/MASTER.md` §2. Task: `docs/development/foundations-architecture/ZOD-FND-013-establish-the-design-token-theme-skeleton-dark-light-colorscheme.md`.

## Product-owner decisions (2026-11-13)

1. **Token values are placeholders**, not MASTER.md's values. Each token maps to a role of Material's default `ColorScheme` for its brightness (`ThemeData(brightness: b).colorScheme`), with no hex literals. The blank shell looks as it does today. ZOD-UI-001 fills in the exact MASTER.md §2 values, which keeps the task boundary exact.

## Global Constraints

- Import `package:material_ui/material_ui.dart`, never `package:flutter/material.dart` or `flutter/cupertino.dart` (deprecated; fails `--fatal-infos`).
- No color literal anywhere in `lib/` except `packages/shared_ui/lib/src/theme/tokens/` (ARCH-7). The guard in Task 4 enforces this.
- Token names and counts are MASTER.md §2's, exactly:
  - surfaces: 19;
  - square: 15;
  - zodiac: 4 element colors plus a sign-tint opacity;
  - aspects: 3;
  - bodies: 11.
- `shared_ui` must not depend on Riverpod (it is a widget/token library). The theme-mode provider stays in the app.
- `astro_core` stays pure Dart (ARCH-2). `shared_ui` depends on it, never the reverse.
- Out of scope:
  - exact token values, swatch harness (ZOD-UI-001);
  - typography (UI-002);
  - spacing/radius (UI-003);
  - components (UI-004+);
  - the theme picker UI and persisting the choice (ZOD-SET-003, ZOD-SET-007/FND-006);
  - the logo's light/dark variants.

## Design decisions (mine, for your confirmation)

- **Field names** are MASTER token names in lowerCamelCase: `bg-raised` → `bgRaised`, `surface-2` → `surface2`, `axis-fill` → `axisFill`, `sel-outer` → `selOuter`, `asp-conj` → `conj`.
  - Each extension also exposes `Map<String, Color> get tokens`, keyed by the **exact MASTER names** (`'bg-raised'`, `'asp-conj'`, …). `ZodiacColors` adds `double signTintOpacity` outside the map.
  - The map is what the tests pin against MASTER, and what UI-001's swatch harness iterates.
- **`BodyColors.of(Body body)`** is an exhaustive `switch` over `astro_core`'s `Body`, so adding a body fails to compile until it has a color. The `tokens` keys are `Body.name`.
- **ColorScheme mapping** (structure, owned here):

  | `ColorScheme` role | Token |
  |---|---|
  | `primary` | `accent` |
  | `onPrimary` | `onAccent` |
  | `secondary` | `accent` |
  | `onSecondary` | `onAccent` |
  | `error` | `danger` |
  | `onError` | `onAccent` |
  | `surface` | `surface` |
  | `onSurface` | `text` |
  | `onSurfaceVariant` | `text2` |
  | `surfaceContainerLowest` | `bg` |
  | `surfaceContainerLow` | `bgRaised` |
  | `surfaceContainer` | `surface` |
  | `surfaceContainerHigh` | `surface2` |
  | `surfaceContainerHighest` | `surface3` |
  | `outline` | `line` |
  | `outlineVariant` | `lineSoft` |
  | `scrim` | `scrim` |

  In addition, `ThemeData.scaffoldBackgroundColor` = `bg`. MASTER defines no secondary or tertiary colors, so the monochrome accent fills those roles.
- **Placeholders** come from the top-level `ZodiannTokens placeholderTokens(Brightness b)`, defined in the token directory and deleted by UI-001. The mapping:
  - **`ZodiannSurfaces`:**

    | Token | Placeholder role |
    |---|---|
    | `bg` | `surface` |
    | `bgRaised` | `surfaceContainerLow` |
    | `surface` | `surface` |
    | `surface2` | `surfaceContainerHigh` |
    | `surface3` | `surfaceContainerHighest` |
    | `line` | `outline` |
    | `lineSoft` | `outlineVariant` |
    | `text` | `onSurface` |
    | `text2`, `text3` | `onSurfaceVariant` |
    | `accent`, `accentStrong`, `focus` | `primary` |
    | `accentSoft` | `primaryContainer` |
    | `accentLine` | `outline` |
    | `onAccent` | `onPrimary` |
    | `scrim` | `scrim` |
    | `danger` | `error` |
    | `ok` | `tertiary` |

  - **Every data token** (square, zodiac, aspect, body) maps to `outline`; nothing paints them yet.
  - `signTintOpacity` is `0.10` dark and `0.09` light. These are MASTER's values: numbers, not colors, and needed for the type to be meaningful.

  **Consequence:** with `bg` = default `surface`, the shell's scaffold color is unchanged from FND-005, which satisfies "no visual regression" (decision 1). `surfaceContainerLowest` in the built scheme then equals `surface`, which is harmless until UI-001.
- **`themeModeProvider`** is a `NotifierProvider<ThemeModeController, ThemeMode>` in `apps/astro_mobile/lib/src/theme/theme_mode_provider.dart`, default `ThemeMode.system`, with `void set(ThemeMode mode)`.
  - Like `ephemerisPortProvider`, it is an **app-level placeholder, not a contract for feature packages**.
  - ZOD-SET-003 (picker) and ZOD-SET-007/FND-006 (persistence) decide where the feature-accessible contract lives. Its doc comment says so.
  - It is app-wide state, not screen state, so ARCH-3's one-provider-per-screen rule is unaffected.
- **Hex guard:** `test/architecture/no_color_literals_test.dart` at the repo root runs in `melos run test:dart` (root package), the same mechanism as the ARCH-2 guard.
  - It scans every `.dart` file under `apps/*/lib/` and `packages/*/lib/`, except `packages/shared_ui/lib/src/theme/tokens/`.
  - The pure scanner `List<ColorLiteral> findColorLiterals(String source)` lives in `test/architecture/color_literals.dart` and is unit-tested on samples. It flags:
    - `Color(0x…)`;
    - `Color.fromARGB(`, `Color.fromRGBO(`, `Color.from(`;
    - `Colors.<name>` from material;
    - a quoted `#RRGGBB` or `#RRGGBBAA` string.
  - It ignores those patterns inside `//` comments.
  - It flags a decimal `Color(<int>)` too (`\bColor\(\s*(0x[0-9a-fA-F]+|\d+)\s*\)`), and `Colors.` or `CupertinoColors.` members (`\b(?:Cupertino)?Colors\.`; the word boundary keeps `squareColors.axis` and `BodyColors.new` legal).
  - Paths are normalized to `/` before the exemption check and in reports (Windows `listSync` returns `\`).
  - This satisfies "enforced by lint or review" as an automated check. Once ZOD-FND-004's CI runs `melos run test`, the guard runs there with no extra wiring.

## File Structure

- `packages/shared_ui/pubspec.yaml`: add `material_ui`, plus `astro_core` as a path dependency.
- `packages/shared_ui/lib/shared_ui.dart`: barrel that exports the theme API.
- `packages/shared_ui/lib/src/theme/zodiann_surfaces.dart`, `square_colors.dart`, `zodiac_colors.dart`, `aspect_colors.dart`, `body_colors.dart`: the five extensions.
- `packages/shared_ui/lib/src/theme/zodiann_tokens.dart`: the `ZodiannTokens` bundle (five extensions + `Brightness`).
- `packages/shared_ui/lib/src/theme/zodiann_theme.dart`: `buildZodiannTheme`, `ZodiannTheme.graphite` / `.porcelain`.
- `packages/shared_ui/lib/src/theme/tokens/graphite_tokens.dart`, `porcelain_tokens.dart`, `placeholder_tokens.dart`: values (placeholders now). This is the only directory where literals are allowed.
- `packages/shared_ui/test/theme/theme_extensions_test.dart`, `zodiann_theme_test.dart`, `samples.dart` (per-type sample builders and `sampleTokens(int seed, Brightness b)`).
- `apps/astro_mobile/pubspec.yaml`: add `shared_ui` (path).
- `apps/astro_mobile/lib/src/theme/theme_mode_provider.dart` (new); `lib/src/theme/app_theme.dart` (deleted); `lib/src/app.dart` (uses both).
- `apps/astro_mobile/test/theme_switch_test.dart` (new).
- `test/architecture/color_literals.dart`, `test/architecture/color_literals_test.dart`, `test/architecture/no_color_literals_test.dart` (new).

## Review Focus

1. **Theme switch animation:** `MaterialApp` animates between themes with `AnimatedTheme`, which calls each extension's `lerp` with `t` in (0, 1). A `lerp` that throws, returns `this`, or drops a field breaks every runtime toggle. Pinned by `lerp interpolates every token at t = 0.5` (per extension) and `toggling at runtime runs the theme animation without errors` (app, asserts an interpolated instance mid-animation; mutant G8).
2. **A component looks up an extension the theme lacks:** `Theme.of(context).extension<T>()!` would crash. Pinned by `both themes carry all five extensions`.
3. **MASTER and code drift apart** (a token renamed, missing or extra): UI-001 would fill the wrong set. Pinned by the `tokens` key-set tests against literal MASTER name lists, and by `BodyColors covers every Body`.
4. **A color literal slips into a component**, including through `Colors.white` or a `'#RRGGBB'` string. Pinned by the guard plus its scanner's sample tests, and by mutant G1.
5. **The theme mode set at runtime doesn't reach the running app,** or reaches the brightness but not the extensions. Pinned by `setting dark/light switches brightness and extensions without restart`.

---

## Tasks

Bash calls start at the repo root and need `export PATH="$PATH:$LOCALAPPDATA/Pub/Cache/bin"` (or wherever `fvm` lives) for `fvm`. Never write `^` inside `cmd //c "…"`.

### Task 1: The five token extensions (TDD)

**Files:**
- Modify: `packages/shared_ui/pubspec.yaml`
- Create: the five extension files
- Test: `packages/shared_ui/test/theme/theme_extensions_test.dart`

**Interfaces:**
- Produces, for each `X` in {`ZodiannSurfaces`, `SquareColors`, `ZodiacColors`, `AspectColors`, `BodyColors`}:
  - `final class X extends ThemeExtension<X>` with a const constructor whose `required` named `Color` fields are the tokens in MASTER order;
  - `X copyWith({Color? field, …})`;
  - `X lerp(covariant X? other, double t)`, using `Color.lerp(a, b, t)!` per field, and `lerpDouble` for `signTintOpacity` (`import 'dart:ui' show lerpDouble;`, which `material_ui` does not export; allowed in `shared_ui`, since ARCH-2 applies only to `astro_core`/`gann_core`). It returns `this` when `other` is null;
  - `Map<String, Color> get tokens`, keyed by MASTER names in MASTER order.
- `BodyColors` adds `Color of(Body body)` (exhaustive switch).

- [ ] **Step 1: Add dependencies.**
  - `cmd //c "cd packages\\shared_ui && fvm flutter pub add material_ui"`
  - `cmd //c "cd packages\\shared_ui && fvm flutter pub add astro_core --path=../../packages/astro_core"`

  Expected: the lock only gains entries (if any), and the root `pubspec.yaml` is unchanged.
- [ ] **Step 2: Write the failing tests.**
  - `test/theme/samples.dart` holds per-type builders (`sampleSurfaces(int seed)`, `sampleSquare`, `sampleZodiac`, `sampleAspects`, `sampleBodies`). Each passes named arguments in MASTER order with `Color.fromARGB(255, seed, i, 0)` for field index `i`. Literals are fine in tests; the guard only scans `lib/`.
  - Every key-set test also asserts `tokens.values.toList()` equals `List.generate(n, (i) => Color.fromARGB(255, seed, i, 0))`. This pins the `tokens` getter to the constructor fields, so a mis-wired entry such as `'surface-3': surface2` fails.
  - `ZodiannSurfaces tokens are MASTER §2.1, in order`: `expect(s.tokens.keys, ['bg','bg-raised','surface','surface-2','surface-3','line','line-soft','text','text-2','text-3','accent','accent-strong','accent-soft','accent-line','on-accent','focus','scrim','danger','ok'])`.
  - `SquareColors tokens are MASTER §2.2, in order`: `['axis-fill','axis-ink','axis','diag-fill','diag-ink','diag','eighth-fill','eighth-ink','cell-fill','cell-ink','cell-line','center','today','sel-outer','sel-inner']`.
  - `ZodiacColors tokens are MASTER §2.3 elements`: `['fire','earth','air','water']`, plus `signTintOpacity` carried through `copyWith` and `lerp`.
  - `AspectColors tokens are MASTER §2.3 aspects`: `['asp-conj','asp-soft','asp-hard']`.
  - `BodyColors covers every Body`: `tokens.keys` equals `Body.values.map((b) => b.name)` in order, and `of(b) == tokens[b.name]` for every `b`.
  - Per extension, `lerp interpolates every token at t = 0.5`: for every key, `a.lerp(b, .5).tokens[k] == Color.lerp(a.tokens[k], b.tokens[k], .5)`. Also `lerp(b, 0)` gives `a`'s tokens, `lerp(b, 1)` gives `b`'s, and `lerp(null, .5)` is `same(a)`.
  - Per extension, `copyWith changes exactly one token`: change the first and the last field. That one key differs and all others are equal; `copyWith()` with no arguments equals the original token map.
  - Per extension, `copyWith of every field yields the other sample`: `a.copyWith(<every field>: b.<field>)` has `tokens` equal to `b.tokens`, with `b` a different-seed sample. This catches a mis-wired middle parameter.
- [ ] **Step 3: Run it.** `cmd //c "fvm dart run melos exec --scope=shared_ui -- flutter test test/theme"`. Expected: FAIL to compile (the files don't exist).
- [ ] **Step 4: Implement** the five classes per Interfaces. Each class has a doc comment citing its MASTER section and saying that values live in `tokens/` (UI-001).
- [ ] **Step 5: Run it again.** Expected: all pass (5 key-set tests + 5 lerp + 5 copyWith-one + 5 copyWith-all = 20).
- [ ] **Step 6: Commit** `feat(ZOD-FND-013): typed ThemeExtensions for the MASTER §2 token groups`.

### Task 2: Token sets and the two themes (TDD)

**Files:**
- Create: `zodiann_tokens.dart`, `zodiann_theme.dart`, `tokens/placeholder_tokens.dart`, `tokens/graphite_tokens.dart`, `tokens/porcelain_tokens.dart`
- Modify: `lib/shared_ui.dart`
- Test: `packages/shared_ui/test/theme/zodiann_theme_test.dart`

**Interfaces:**
- Consumes: Task 1's classes.
- Produces:
  - `final class ZodiannTokens { const ZodiannTokens({required this.brightness, required this.surfaces, required this.square, required this.zodiac, required this.aspects, required this.bodies}); List<ThemeExtension<dynamic>> get extensions; }`.
  - The top-level `ZodiannTokens placeholderTokens(Brightness b)` lives in `tokens/placeholder_tokens.dart`. `ZodiannTokens` has no factory, so UI-001 deletes one file.
  - `final ZodiannTokens graphiteTokens = placeholderTokens(Brightness.dark);` and `final ZodiannTokens porcelainTokens = placeholderTokens(Brightness.light);`. UI-001 replaces each right-hand side with a literal `ZodiannTokens(...)`.
  - `ThemeData buildZodiannTheme(ZodiannTokens t)`: `ThemeData(brightness: t.brightness, colorScheme: ColorScheme(brightness: t.brightness, <mapping table>), scaffoldBackgroundColor: t.surfaces.bg, extensions: t.extensions)`. `ThemeData` asserts that the brightnesses match. Its doc comment notes that unset roles fall back to the constructor's defaults: `primaryContainer` → `primary`, `tertiary` → `secondary`, and `surfaceTint` → `primary` (accent tint on M3 elevated surfaces, which UI-003/UI-004 should revisit).
  - `abstract final class ZodiannTheme { static final ThemeData graphite = buildZodiannTheme(graphiteTokens); static final ThemeData porcelain = buildZodiannTheme(porcelainTokens); }`.
  - The barrel exports the five extensions, `ZodiannTokens`, `buildZodiannTheme`, `ZodiannTheme`, `graphiteTokens` and `porcelainTokens`. It does not export `placeholderTokens`.

- [ ] **Step 1: Write the failing tests.**
  - `graphite is dark and porcelain is light`: check the brightness of both `ThemeData`s and their `colorScheme`s.
  - `both themes carry all five extensions`: for each theme and each type, `theme.extension<T>()` is non-null and `same` as the corresponding `graphiteTokens` / `porcelainTokens` member.
  - `ColorScheme and scaffold derive from ZodiannSurfaces`: for both themes, every row of the mapping table (`primary == surfaces.accent`, …, `scrim == surfaces.scrim`), plus `scaffoldBackgroundColor == surfaces.bg`.
  - `buildZodiannTheme uses only the given tokens`: build from `sampleTokens(7, Brightness.dark)` (`samples.dart`), then check `colorScheme.primary == sample.surfaces.accent` and that the extensions are the sample instances. This proves no hidden default.
  - `placeholder signTintOpacity is MASTER's 10 % / 9 %`: `graphiteTokens.zodiac.signTintOpacity == 0.10` and `porcelainTokens… == 0.09`.
- [ ] **Step 2: Run it.** `cmd //c "fvm dart run melos exec --scope=shared_ui -- flutter test test/theme"`. Expected: FAIL to compile.
- [ ] **Step 3: Implement** per Interfaces and the Design decisions mapping.
- [ ] **Step 4: Run it again.** Expected: 5/5. Whole `shared_ui` suite: 25/25.
- [ ] **Step 5: Commit** `feat(ZOD-FND-013): Graphite and Porcelain themes built from token sets`.

### Task 3: App wiring and runtime toggle (TDD)

**Files:**
- Modify: `apps/astro_mobile/pubspec.yaml` (`cmd //c "cd apps\\astro_mobile && fvm flutter pub add shared_ui --path=../../packages/shared_ui"`), `lib/src/app.dart`
- Create: `lib/src/theme/theme_mode_provider.dart`
- Delete: `lib/src/theme/app_theme.dart`
- Test: `apps/astro_mobile/test/theme_switch_test.dart`

**Interfaces:**
- Consumes: `ZodiannTheme`, `graphiteTokens`, `porcelainTokens`, `ZodiannSurfaces` (Task 2).
- Produces:
  - `final class ThemeModeController extends Notifier<ThemeMode> { ThemeMode build() => ThemeMode.system; void set(ThemeMode mode); }`;
  - `final NotifierProvider<ThemeModeController, ThemeMode> themeModeProvider`;
  - `ZodiannApp` becomes a `ConsumerWidget`, keeping `const ZodiannApp({super.key})`, with `theme: ZodiannTheme.porcelain`, `darkTheme: ZodiannTheme.graphite` and `themeMode: ref.watch(themeModeProvider)`. Everything else is unchanged.

- [ ] **Step 1: Write the failing tests.** All pump `ProviderScope(child: ZodiannApp())`.
  - `defaults to following the device`: `platformBrightnessTestValue = dark` gives `Theme.of(ctx).extension<ZodiannSurfaces>()` `same` as `graphiteTokens.surfaces`; `light` gives `porcelainTokens.surfaces`.
  - `setting dark/light switches brightness and extensions without restart`: with a light device, read the container (`ProviderScope.containerOf(ctx, listen: false)`) and call `read(themeModeProvider.notifier).set(ThemeMode.dark)`, then `pumpAndSettle`. Brightness is dark and the surfaces are `same(graphiteTokens.surfaces)`. Then `set(ThemeMode.light)` and `pumpAndSettle` gives light and porcelain. Then set `platformBrightnessTestValue = Brightness.dark`, call `set(ThemeMode.system)` and `pumpAndSettle`: brightness is dark and the surfaces are `same(graphiteTokens.surfaces)`.
  - `toggling at runtime runs the theme animation without errors`: after `pumpAndSettle` on a light device, `set(ThemeMode.dark)`, then `await tester.pump()` (the animation starts at t = 0, so no `lerp` yet), then `await tester.pump(const Duration(milliseconds: 100))` (t = 0.5; `kThemeAnimationDuration` is 200 ms, linear curve). Assert `tester.takeException()` is null, and that `Theme.of(ctx).extension<ZodiannSurfaces>()` is neither `same(graphiteTokens.surfaces)` nor `same(porcelainTokens.surfaces)`. That proves an interpolated instance exists, so `lerp` ran (`lerp` returns a new instance). Then `pumpAndSettle` gives `same(graphiteTokens.surfaces)`. (The reviewer showed a single `pump(100 ms)` never calls `lerp`.)
  - **Existing FND-005 tests:** all 13 pass unchanged.
- [ ] **Step 2: Run it.** `cmd //c "fvm dart run melos exec --scope=astro_mobile -- flutter test"`. Expected: FAIL to compile (`themeModeProvider` doesn't exist).
- [ ] **Step 3: Implement.** Delete `app_theme.dart`. `grep -rn "AppTheme" apps/astro_mobile` → nothing.
- [ ] **Step 4: Run it again.** Expected: app 16/16 (13 + 3).
- [ ] **Step 5: Commit** `feat(ZOD-FND-013): app uses Graphite/Porcelain with a runtime theme-mode provider`.

### Task 4: Color-literal guard (TDD)

**Files:**
- Create: `test/architecture/color_literals.dart`, `test/architecture/color_literals_test.dart`, `test/architecture/no_color_literals_test.dart`

**Interfaces:**
- Produces:
  - `final class ColorLiteral { final int line; final String text; }`;
  - `List<ColorLiteral> findColorLiterals(String source)`, which ignores text after `//` on a line;
  - `bool isColorLiteralAllowed(String repoRelativePath)`, which normalizes `\` to `/` first and is true only under `packages/shared_ui/lib/src/theme/tokens/`.
  - The root tests import `package:test/test.dart`, not `flutter_test`, because the root package runs under `--no-flutter` in `test:dart`.

- [ ] **Step 1: Write the failing tests.**
  - `color_literals_test.dart` (scanner), three tests, one per bullet:
    - flags `Color(0xFF112233)`, `const Color(0x80FFFFFF)`, `Color.fromARGB(255, 1, 2, 3)`, `Color.fromRGBO(1, 2, 3, 1)`, `Color.from(alpha: 1, red: 0, green: 0, blue: 0)`, `Colors.white`, `Colors.transparent`, `'#1A2B3C'`, `"#1A2B3CFF"`, `Color(4278190080)`, `CupertinoColors.white`, each reporting the right line;
    - ignores `// Color(0xFF000000)`, `/// see Colors.white`, `colorScheme.primary`, `surfaces.bg`, `Color.lerp(a, b, t)`, `'#tag'`, `ThemeData(brightness: Brightness.dark)`, `squareColors.axisFill`, `bodyColors.of(b)` and `ZodiacColors.new`;
    - `isColorLiteralAllowed` is true for `packages/shared_ui/lib/src/theme/tokens/graphite_tokens.dart` and for `r'packages\shared_ui\lib\src\theme\tokens\graphite_tokens.dart'` (Windows separators), and false for `packages/shared_ui/lib/src/theme/zodiann_theme.dart` and `apps/astro_mobile/lib/src/app.dart`.
  - `no_color_literals_test.dart` (repo):
    - `no color literal in lib/ outside the token files`: walk `apps/*/lib` and `packages/*/lib` from the repo root (found the same way as `pure_dart_test.dart`), skip allowed paths, and collect `path:line text`. `expect(bad, isEmpty)`.
    - `scans a non-trivial set of files`: the scanned file count is ≥ 10, so a wrong root fails the test instead of passing vacuously. (35 files today).
    - `the token directory is exempted by the walk`: the set of skipped files, normalized to `/`, contains `packages/shared_ui/lib/src/theme/tokens/graphite_tokens.dart`. Report every path with `/` separators.
- [ ] **Step 2: Run it.** `cmd //c "fvm dart test test/architecture"`. Expected: FAIL to compile (`color_literals.dart` doesn't exist).
- [ ] **Step 3: Implement** the scanner with regexes over each line after stripping `//…`. A `//` inside a string literal is an accepted false negative; record it in the doc comment.
- [ ] **Step 4: Run it again.** Expected: the architecture suite passes, 17 + 3 scanner + 3 repo = 23.
- [ ] **Step 5: Mutation check.** Apply each mutant, confirm it is applied against a backup, run it, confirm the test **fails** (not a compile error), restore, and confirm `git diff --exit-code`. Record the counts in the commit body.
  - G1: `ShellHome` returns `const Scaffold(backgroundColor: Color(0xFF000000))` in `apps/astro_mobile/lib/src/app.dart` → `no color literal…` fails, naming `app.dart`.
  - G2: `Colors.white` in `zodiann_theme.dart` → it fails (theme code outside `tokens/` is not exempt).
  - G3: in `buildZodiannTheme`, map `primary` to `surfaces.text` → `ColorScheme and scaffold derive…` fails (catches only if `text != accent`; with placeholders they differ, `onSurface` vs `primary`).
  - G4: `ZodiannSurfaces.lerp` returns `this` → `lerp interpolates…` fails.
  - G5: drop `ok` from `ZodiannSurfaces.tokens` → the key-set test fails.
  - G6: `themeMode: ThemeMode.system` hard-coded in `app.dart` (not watching the provider) → `setting dark/light…` fails.
  - G7: remove `AspectColors` from `ZodiannTokens.extensions` → `both themes carry all five extensions` fails.
  - G8: `ZodiannSurfaces.lerp` throws `StateError` → `toggling at runtime runs the theme animation without errors` fails.
- [ ] **Step 6: Commit** `test(ZOD-FND-013): color-literal guard outside the token files (ARCH-7)`.

### Task 5: Close-out

- [ ] **Step 1: Gates.** `cmd //c "fvm dart run melos run lint && fvm dart run melos run test"`, both exit 0. Record the counts.
- [ ] **Step 2: On-device check** (the emulator used for FND-005, if it is running). Install and launch the debug APK, take light and dark (`cmd uimode night yes`) screenshots, and confirm a blank themed screen and no crash. If no device is available, record it as not run. It isn't required by this task's criteria; the widget tests cover them.
- [ ] **Step 3: Whole-branch code review** (opus, with the Review Focus). Fix Critical and Important findings test-first.
- [ ] **Step 4: Docs.**
  - Task file: Status Done; criterion 1 checked (Task 3 tests); criterion 2 checked (Task 4 guard, automated); Notes record the placeholder decision and the `themeModeProvider` boundary.
  - Add a Notes line to ZOD-UI-001: "Replace the right-hand sides in `packages/shared_ui/lib/src/theme/tokens/graphite_tokens.dart` / `porcelain_tokens.dart` with MASTER §2's literal values and delete `placeholder_tokens.dart`; the extension types, `tokens` maps and theme wiring exist (ZOD-FND-013)."
  - Add a Notes line to ZOD-SET-003: "`themeModeProvider` (apps/astro_mobile/lib/src/theme/) is an app-level placeholder; this task decides where the picker's provider contract lives."
  - Extend the ZOD-UI-001 note with: "`signTintOpacity` already carries MASTER's 0.10 / 0.09 (FND-013); keep them."
  - TASKS.md: Done.
  - PROGRESS: completed row, technical decisions (theme in `shared_ui`, placeholders, `ColorScheme` mapping, guard), marking the FND-005 row "Placeholder theme seam `AppTheme.light/dark`" as superseded by FND-013, verification, Next Recommended Task, Git State. Also fix FND-005 to "merged `e4a8859`" on this branch.
- [ ] **Step 5: Commit, push, PR, and record the PR link** per the workflow.

## Acceptance Criteria → Evidence

| Criterion | Evidence |
|---|---|
| Both themes compile and can be toggled at runtime with no visual regression (blank screen is fine) | Task 2 theme tests. Task 3 `setting dark/light switches brightness and extensions without restart` and `toggling at runtime runs the theme animation without errors`. The FND-005 suite is unchanged and green. On-device screenshots if a device is available. G6/G7 show that the tests bite. |
| No component file contains a raw hex color literal (enforced by lint or review) | `no_color_literals_test.dart` runs in `melos run test` (and therefore in FND-004's CI). Scanner sample tests; mutants G1/G2. |

## Risks

- **Scanner false positives** on future legitimate code (for example a `'#'` in a localized string). Mitigation: the pattern requires exactly 6 or 8 hex digits, and the sample tests pin the ignore cases. A real exemption needs a deliberate edit to `isColorLiteralAllowed`.
- **Placeholder values make some mutants weaker.** For example, with placeholders `text3 == text2`, so a swap between them is invisible. The structural tests use distinct-valued samples (Task 1's `sample`), which covers this. The mapping tests compare against the actual tokens, so they stay valid when UI-001 changes values.
- **`ThemeExtension` boilerplate (copyWith/lerp for 52 fields)** is error-prone by hand. Two tests catch it: the key-set test asserts `tokens.values` in constructor order with distinct sample values (catches a mis-wired getter), and `copyWith of every field yields the other sample` catches a mis-wired parameter. The lerp tests cover `lerp`.

## Plan review

### Round 1: Approve after corrections (0 Critical, 5 Important, 10 Minor; no user decisions)

- **I1, applied.** A single `pump(100 ms)` after toggling never calls `lerp`: the animation restarts at t = 0, as the reviewer reproduced with a throwing `lerp`. The test now pumps twice and asserts an interpolated `ZodiannSurfaces` instance mid-animation. Mutant G8 (`lerp` throws) was added, and the false "data tokens are shared" sentence removed.
- **I2, applied.** On Windows `listSync` returns `\` paths, so the token-directory exemption would silently fail once UI-001 adds literals. `isColorLiteralAllowed` now normalizes separators, with a backslash sample case and a `the token directory is exempted by the walk` test.
- **I3, applied.** The placeholder factory was described two ways; it is now the top-level `placeholderTokens` only.
- **I4, applied.** `bg` → default `surface`, so the scaffold color is unchanged from FND-005, as decision 1 promises (reviewer confirmed light `#FEF7FF` today).
- **I5, applied.** Key-set tests now assert `tokens.values` in constructor order with distinct samples (catches a mis-wired getter). A new `copyWith of every field yields the other sample` test catches a mis-wired middle parameter. Counts: shared_ui 20 + 5 = 25.
- **M1, applied:** `lerpDouble` from `dart:ui`.
- **M2, applied:** G1 uses `Scaffold(backgroundColor:)`.
- **M3, applied:** run commands added to Tasks 2 and 3.
- **M4, applied:** `test/theme/samples.dart` with per-type builders.
- **M5, applied:** `ColorScheme(brightness:)` and the unset-role fallbacks documented.
- **M6, applied:** FND-004 CI phrased as future.
- **M7, applied:** the FND-005 `AppTheme` decision is marked superseded, and the UI-001 note covers `signTintOpacity`.
- **M8, applied:** the scanner also flags decimal `Color(<int>)` and `CupertinoColors.`.
- **M9, applied:** root tests use `package:test`.
- **M10, applied:** FND-005 tests pass unchanged.

### Round 2 (final): Approve after corrections (0 Critical, 2 Important, 3 Minor; no user decisions)

The reviewer re-ran the planned toggle test in a scratch app: it passes with a correct `lerp` and fails with a throwing one, so G8 is caught. It also confirmed the 25 / 16 / 17 counts, the MASTER token lists, the `ColorScheme` fallbacks and the `lerpDouble` import.

- **I1, applied.** The edit script had stripped the backslashes from the two Windows-path lines (an empty code span and TAB characters); both are restored.
- **I2, applied.** `\w*Colors\.` would have flagged legitimate token use such as `squareColors.axisFill` and `bodyColors.of(b)`. The pattern is now `\b(?:Cupertino)?Colors\.`, and those three cases are in the "ignores" list.
- **M1, applied:** spelled out the order for the dark-device / `ThemeMode.system` step.
- **M2, applied:** corrected the reason the identity check proves `lerp` ran.
- **M3, applied:** exact architecture count, 17 + 3 + 3 = 23.

No open items.
