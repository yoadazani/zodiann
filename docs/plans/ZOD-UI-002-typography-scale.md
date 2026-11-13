# ZOD-UI-002 Typography Scale Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every MASTER.md §3 type role an exact `TextStyle` (family, weight, size, line height, tracking, tabular figures), map them onto Material's `TextTheme`, and resolve the family by language: Plex Sans for Latin, Plex Sans Hebrew for Hebrew. Also centralise the astrological glyph strings with U+FE0E, so no glyph renders as a colour emoji.

**Architecture:**
- **Styles:**
  - A new `ThemeExtension`, `ZodiannTextStyles`, in `shared_ui` holds one style per MASTER role (plus the two phone sizes and a glyph style).
  - `buildZodiannTextStyles(ZodiannSurfaces s, ZodiannScript script)` builds it.
  - `buildZodiannTextTheme(ZodiannTextStyles)` maps the roles onto all 15 Material `TextTheme` slots.
- **Themes:**
  - `buildZodiannTheme(tokens, {script = latin})` installs both, so `ZodiannTheme.graphite` / `.porcelain` stay Latin.
  - `withZodiannScript(ThemeData, ZodiannScript)` swaps the typography for another script and keeps everything else.
  - The app applies it in `MaterialApp.builder` from the resolved locale.
- **Glyphs:** `ZodiannGlyphs` holds the 29 astrological glyph strings, each followed by U+FE0E: signs by zodiac order, bodies by `Body`, aspects, and ℞.
- **Verification:**
  - Pure tests pin every value to MASTER's table, typed in.
  - In-host `FontLoader` rendering tests prove the line heights, tracking, weights and digit widths with the real fonts.
  - A test-only specimen harness mirrors the reference "Typography" board for a side-by-side check.
  - An on-device test proves the glyphs render monochrome, so not as emoji.

**Tech Stack:** Flutter 3.50.0 / Dart 3.14.0 (FVM), material_ui 1.11.0, flutter_test, integration_test (SDK, already a dev dependency of the app). No new dependencies.

**Spec:** `assets/zodiann-specification.md` L-13, L-14 (24-hour times, Western digits; this task only ensures the digits are tabular). Design: `design-reference/zodiann/MASTER.md` §3 (role table), §6 (phone < 700), §13. Cross-check: `design-reference/zodiann/components/components_dark.png`, "Typography" board (y ≈ 1140–1525 in the 1440-wide image), and `_source/components.html:76–85`, `_source/kit.css`. Task: `docs/development/shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md` (with FND-007's handoff Notes).

## Facts established while planning (2026-11-13)

- **MASTER §3 roles.** Values are size / line height and weight, tracking. Tracking in px = em × size. Blank line heights come from `kit.css`: `body { line-height: 1.45 }` is inherited, `.cell { line-height: 1.12 }`, and `.glyph { line-height: 1 }`.

  | Role (field) | Size | Line height | Weight | Tracking (em) | Source of blanks |
  |---|---|---|---|---|---|
  | Hero wordmark (`heroWordmark`) | 56 | 1.0 | 300 | −0.035 | |
  | Hero wordmark, phone (`heroWordmarkPhone`) | 40 | 1.0 | 300 | −0.035 | `about.html:26` |
  | Display readout (`displayReadout`) | 44 | 1.0 | 300 | −0.03 | |
  | Display readout, phone (`displayReadoutPhone`) | 34 | 1.0 | 300 | −0.03 | `wheel.html:58` |
  | Section title (`sectionTitle`) | 26 | 1.2 | 600 | −0.02 | |
  | Wordmark, drawer (`drawerWordmark`) | 20 | 1.45 | 600 | −0.01 | line height inherited |
  | Screen title (`screenTitle`) | 18 | 1.2 | 600 | −0.01 | |
  | Panel title (`panelTitle`) | 16 | 1.3 | 600 | 0 | MASTER gives none; `kit.css:179` has −.005em, MASTER wins |
  | Body (`body`) | 14 | 1.45 | 400 | 0 | |
  | Small (`small`) | 13 | 1.45 | 400 | 0 | MASTER "400–500"; 500 is `small.copyWith(fontWeight: w500)` |
  | Label (`label`) | 12 | 1.45 | 500 | 0 | |
  | Micro (`micro`) | 11 | 1.45 | 400 | 0 | MASTER "11–11.5": 11 is axis labels (`--fs-2xs`) |
  | Micro, square cells (`cell`) | 11.5 | 1.12 | 400 | 0 | 11.5 is cells (`kit.css:334`); highlighted cells use 500 via `copyWith` |
  | Glyphs (`glyph`) | null ("per context") | 1.0 | 400 | 0 | Noto Sans Symbols → Symbols 2 → Noto Sans |

- **Phone variants** apply below 700 logical px (MASTER §6). This task provides both styles; the screens (ABT, WHL, SQR) pick one by breakpoint. The breakpoint itself isn't defined here; UI-003, which has the per-breakpoint values, is its natural owner. The mockup's tablet readout (38 px, `wheel.html:44`) isn't in MASTER and isn't provided. That's for WHL-009 to raise if it's wanted.
- **Families (`kit.css:99–108`):**
  - **Latin:** `IBM Plex Sans`, then fallback `IBM Plex Sans Hebrew`.
  - **Hebrew:** `IBM Plex Sans Hebrew`, then fallback `IBM Plex Sans`. This also supplies ′ and ″, which Plex Hebrew lacks (FND-007 handoff).
  - **Both UI stacks then append `ZodiannFonts.glyphFallback`.** So a stray astrological glyph in UI text comes from a bundled font, never from a system emoji font. The mockup's `--font-ui` falls back to the system instead; this is a deliberate safety addition.
  - **Glyph style:** `Noto Sans Symbols`, then `[Noto Sans Symbols 2, Noto Sans]`.
  - All of them use `package: ZodiannFonts.package`, so the engine sees each as `packages/shared_ui/<family>`, including the fallbacks.
- **Tracking is applied in both scripts.** MASTER doesn't distinguish them. The reference board drops tracking on two of its Hebrew rows (inline styles) but keeps it on Display and Section, so that's inconsistent and MASTER wins.
- **Leading:** every style sets `leadingDistribution: TextLeadingDistribution.even`, which splits the leading like CSS so glyphs sit centred. `TextPainter.height == fontSize × height` holds for one line under either distribution. The line-height test checks the height; the value test checks `leadingDistribution`.
- **Glyph ′ ″ advances (units of 1000):**
  - Plex Sans: Light 232/400, Regular 242/419, Medium 253/451, SemiBold 260/471.
  - Plex Sans Hebrew: none.
  - Noto Sans: 232/408.

  So only ″ tells Plex Sans from Noto Sans at every weight. Plex digits have no digit–digit or digit–° kerning; the only kern pairs are ′ next to `.` or `,`.
- **`primaryTextTheme`** stays Material's default on purpose. In material_ui 1.11.0 it's read only on M2 paths and by `UserAccountsDrawerHeader`.
- **`ThemeData(...)` merges** `typography.black/white` into `textTheme` (`theme_data.dart:602,618`), while `copyWith(textTheme:)` doesn't (`:1765`). So `withZodiannScript` does the same merge itself.
- **Tabular figures:** every UI role gets `fontFeatures: [FontFeature.tabularFigures()]` (`kit.css:114`, "tabular figures everywhere"). Plex has no `tnum` feature, but all eight Plex files have equal-width digits (600 units, FND-007 review), so digits don't jitter. The jitter test proves it in both scripts.
- **Colour:** every style's `color` is `surfaces.text`. Roles carry no colour semantics; callers apply `text2` / `text3`. Under `lerp` the colour follows the theme.
- **`TextTheme` mapping** (all 15 slots, so nothing falls back to Material's Roboto-sized defaults):

  | Slot | Role |
  |---|---|
  | `displayLarge` | `heroWordmark` |
  | `displayMedium` | `displayReadout` |
  | `displaySmall` | `displayReadoutPhone` |
  | `headlineLarge` | `heroWordmarkPhone` |
  | `headlineMedium` | `sectionTitle` |
  | `headlineSmall` | `drawerWordmark` (20/600; M3 dialog titles use it, matching `kit.css:285` dialog h3 20/600) |
  | `titleLarge` | `screenTitle` (M3 `AppBar` title) |
  | `titleMedium` | `panelTitle` |
  | `titleSmall` | `small` at w500 |
  | `bodyLarge` | `body` (M3 text fields and list tiles use `bodyLarge`; the mockup's inputs are 14) |
  | `bodyMedium` | `body` (default text) |
  | `bodySmall` | `small` |
  | `labelLarge` | `body` at w500 (Material buttons; `kit.css:191` `.btn` is 14/500; UI-004 may refine) |
  | `labelMedium` | `label` |
  | `labelSmall` | `micro` |

- **Glyphs:**
  - Signs, Aries…Pisces: U+2648–U+2653.
  - `Body`:
    - sun ☉ U+2609, moon ☽ U+263D, mercury ☿ U+263F, venus ♀ U+2640, mars ♂ U+2642;
    - jupiter ♃ U+2643, saturn ♄ U+2644, uranus ♅ U+2645, neptune ♆ U+2646, pluto ♇ U+2647;
    - node ☊ U+260A.
  - Aspects (`_source/kit.js:189–195` `ASPECTS`; the spec's aspect table lists no glyphs): conjunction ☌ U+260C, sextile ⚹ U+26B9, square □ U+25A1, trine △ U+25B3, opposition ☍ U+260D.
  - Retrograde: ℞ U+211E.
  - This is the same 29-glyph set that FND-007 proved the glyph fonts cover.
  - No task owns a glyph map today. WHL-002/004/006/009/021 consume one, and WHL-006 cites UI-002 for ℞ + U+FE0E.
- **App locale:** `MaterialApp` resolves the locale (en first, he supported). `Localizations.localeOf(context)` is available inside `MaterialApp.builder`, below the `AnimatedTheme`. So the builder sees the animated theme and the resolved locale.
- **Sentence case:** Flutter has no text-transform. All-caps can only come from strings or from `toUpperCase()`. Material 3's buttons and tabs don't uppercase. No `toUpperCase(` exists today in `apps/*/lib` or `packages/*/lib` (checked).

## Global Constraints

- Values are exactly those in the role table above. Every px tracking is em × size.
- Fonts are named only through `ZodiannFonts` with `package: ZodiannFonts.package` (PROGRESS convention).
- No colour literals outside `shared_ui/lib/src/theme/tokens/` (ARCH-7). Styles take their colour from `ZodiannSurfaces`.
- Material types come from `package:material_ui/material_ui.dart`. `FontFeature` comes from `dart:ui`, re-exported by `package:flutter/painting.dart` via material_ui.
- No new dependencies. `lib/` must keep `test/architecture/no_network_test.dart` green.
- Before every commit: `cmd //c "fvm dart run melos run lint && fvm dart run melos run test"` exits 0.
- Toolchain:
  - In Bash, first `export PATH="$PATH:$LOCALAPPDATA/Pub/Cache/bin:$LOCALAPPDATA/Android/Sdk/platform-tools"`.
  - Use `cmd //c "…"` with no `^` inside.
  - Never stage `.idea/` or `.qodo/`.

## Out of scope

- **ZOD-UI-003:** breakpoint values and spacing tokens.
- **ZOD-UI-004+:** component text (buttons, fields, tags).
- **Screen tasks:** choosing a phone variant.
- **ZOD-L10-001:** translated strings, Hebrew date formats and FSI/PDI isolation (L-7).
- **ZOD-L10-011 / ZOD-L10-012:** 24-hour times and Western digits (L-13, L-14).
- **Screen tasks:** sign, body and aspect names (L-9).
- **ZOD-NFR-009:** contrast.
- **Text scaling:** not specified and not owned by any task. The styles use `TextScaler` defaults.

## Review Focus

1. **Hebrew UI rendering ′ or ″ wrongly**, as in `17°03′` in Hebrew mode. Covered by Task 3's `Hebrew roles draw ′ and ″ from IBM Plex Sans` (mutant R1) and by the specimen. Noto Sans in the UI fallback also prevents boxes.
2. **A glyph rendering as a colour emoji** on Android, whose system font maps ♈ to NotoColorEmoji. Covered by Task 5's on-device monochrome pixel test, with a mutant that uses the system font.
3. **Digit jitter in a changing readout** (degrees counting up). Covered by Task 3's digit-width test across all UI roles in both scripts.
4. **A locale change not reaching the typography**, so Hebrew mode keeps Plex Sans. Covered by Task 4's app tests for en, he and a live switch.
5. **The theme-mode animation breaking**, because `withZodiannScript` replaces the text theme mid-lerp. Covered by Task 4's mid-animation test: the colour is interpolated and the family is kept.

---

### Task 1: `ZodiannTextStyles`, `TextTheme` mapping, script switching

**Files:**
- Create: `packages/shared_ui/lib/src/theme/zodiann_text_styles.dart`
- Modify: `packages/shared_ui/lib/src/theme/zodiann_theme.dart`, `packages/shared_ui/lib/shared_ui.dart` (export)
- Test: `packages/shared_ui/test/theme/typography_test.dart`

**Interfaces:**
- Produces:
  ```dart
  enum ZodiannScript {
    latin, hebrew;
    /// `he` (and legacy `iw`) → hebrew; everything else → latin.
    static ZodiannScript forLocale(Locale locale);
  }

  @immutable
  final class ZodiannTextStyles extends ThemeExtension<ZodiannTextStyles> {
    const ZodiannTextStyles({required TextStyle heroWordmark, heroWordmarkPhone,
      displayReadout, displayReadoutPhone, sectionTitle, drawerWordmark,
      screenTitle, panelTitle, body, small, label, micro, cell, glyph});
    // one final TextStyle field per parameter
    /// Field name → style, in the table's order (for tests and harnesses).
    Map<String, TextStyle> get roles;
    @override ZodiannTextStyles copyWith({...all nullable});
    @override ZodiannTextStyles lerp(covariant ZodiannTextStyles? other, double t); // TextStyle.lerp per field; other == null → this
    @override bool operator ==(Object other); // same runtimeType and all 14 fields ==
    @override int get hashCode;              // Object.hashAll(roles.values)
  }

  ZodiannTextStyles buildZodiannTextStyles(ZodiannSurfaces s, ZodiannScript script);
  TextTheme buildZodiannTextTheme(ZodiannTextStyles r);
  ThemeData buildZodiannTheme(ZodiannTokens t, {ZodiannScript script = ZodiannScript.latin});
  /// [theme] with its text theme and ZodiannTextStyles rebuilt for [script]
  /// from its own ZodiannSurfaces; colours and other extensions unchanged.
  ThemeData withZodiannScript(ThemeData theme, ZodiannScript script);
  ```

- [ ] **Step 1: Write the failing tests** in `typography_test.dart`.
  - Type the role table in as a literal: `const _master = {'heroWordmark': (56.0, 1.0, FontWeight.w300, -0.035), …}`, 14 rows with `glyph` handled separately.
  - Iterate over `(graphiteTokens, porcelainTokens) × ZodiannScript.values`.
  - Tests:
    - `every role has MASTER's size, line height, weight and tracking`: `fontSize`, `height`, `fontWeight`, and `letterSpacing` `closeTo(em * size, 1e-9)`. `roles.keys` equals `_master.keys` plus `'glyph'`, in order.
    - `UI roles use the script's family with the planned fallback`:
      - **Latin:** `fontFamily == 'packages/shared_ui/IBM Plex Sans'` and `fontFamilyFallback == ['packages/shared_ui/IBM Plex Sans Hebrew', 'packages/shared_ui/Noto Sans Symbols', 'packages/shared_ui/Noto Sans Symbols 2', 'packages/shared_ui/Noto Sans']`.
      - **Hebrew:** `fontFamily == 'packages/shared_ui/IBM Plex Sans Hebrew'`, with `IBM Plex Sans` first in the fallback, then the same three.
    - `the glyph style uses the glyph fonts at 400 with no fixed size`: family `packages/shared_ui/Noto Sans Symbols`, fallback `[…/Noto Sans Symbols 2, …/Noto Sans]`, `w400`, `height 1.0`, `fontSize` null, `letterSpacing == 0` and `leadingDistribution == even`. Both are explicit, so a glyph span inside a tracked role doesn't inherit that role's px tracking.
    - `UI roles use tabular figures and even leading`: `fontFeatures` contains `FontFeature.tabularFigures()`, and `leadingDistribution == TextLeadingDistribution.even`.
    - `every style is coloured with the theme's text colour`: `color == tokens.surfaces.text`.
    - `no role is letter-spaced (sentence case, no eyebrows)`: every `letterSpacing ≤ 0`.
    - `the TextTheme fills all 15 slots from the roles`: each slot of `buildZodiannTextTheme(r)` (not `theme.textTheme`, which also has Material's typography merged in) equals the mapped role from the Facts table. `titleSmall` and `labelLarge` equal the role `copyWith(fontWeight: w500)`. No slot is null.
    - `the themes carry Latin typography`: `ZodiannTheme.graphite.extension<ZodiannTextStyles>()` equals `buildZodiannTextStyles(graphiteTokens.surfaces, latin)`, and `textTheme.bodyMedium!.fontFamily` is Plex Sans. The same for porcelain.
    - `withZodiannScript swaps only the typography`:
      - for `hebrew`, `textTheme.bodyMedium!.fontFamily` and the extension switch to Plex Sans Hebrew;
      - `colorScheme`, `scaffoldBackgroundColor` and all five colour extensions are unchanged (`same` instance or `==`);
      - `withZodiannScript(ZodiannTheme.graphite, latin).textTheme == ZodiannTheme.graphite.textTheme`, and the same after hebrew → latin. The same holds for porcelain.
    - `==/hashCode`: two `buildZodiannTextStyles(s, script)` calls are `==` with equal hashCodes. Changing any one field via `copyWith` makes them unequal.
    - `Material's localized text theme keeps every role's geometry` (`testWidgets`): under `ZodiannTheme.graphite`, read `Theme.of(ctx).textTheme`, after `ThemeData.localize` has merged in M3's `englishLike2021`. Each slot keeps its role's `fontSize`, `height`, `letterSpacing` and `fontWeight`.
    - `ZodiannScript.forLocale`:
      - `Locale('he')`, `Locale('he', 'IL')` and `Locale('iw')` give hebrew;
      - `Locale('en')`, `Locale('fr')` and `Locale('ar')` give latin.
    - `lerp and copyWith`:
      - `lerp(other, 0)` equals this and `lerp(other, 1)` equals other;
      - at 0.5, `body.color` equals `Color.lerp(a, b, .5)`;
      - `lerp(null, t)` returns this;
      - `copyWith(body: x).body == x`, and the other fields are unchanged.

- [ ] **Step 2: Run them and see them fail.** Run `cmd //c "cd packages\\shared_ui && fvm flutter test test/theme/typography_test.dart"`. Expected: compile failure, because the types don't exist.

- [ ] **Step 3: Implement.**
  - A private helper builds each UI role:

    `TextStyle _ui(String family, List<String> fallback, Color c, double size, double height, FontWeight w, double em) => TextStyle(fontFamily: family, fontFamilyFallback: fallback, package: ZodiannFonts.package, fontSize: size, height: height, fontWeight: w, letterSpacing: em * size, leadingDistribution: TextLeadingDistribution.even, fontFeatures: const [FontFeature.tabularFigures()], color: c)`.

    For `em == 0`, set `letterSpacing: 0`.
  - `buildZodiannTheme` passes `textTheme: buildZodiannTextTheme(styles)` and adds `styles` to `extensions`.
  - `withZodiannScript` asserts that `theme.extension<ZodiannSurfaces>()` is non-null. It then calls `theme.copyWith(textTheme: (theme.brightness == Brightness.dark ? theme.typography.white : theme.typography.black).merge(buildZodiannTextTheme(styles)), extensions: [...theme.extensions.values.where((e) => e is! ZodiannTextStyles), styles])`. That's the same merge the `ThemeData` constructor does.

- [ ] **Step 4: Run them and see them pass.** Run `cmd //c "cd packages\\shared_ui && fvm flutter test"`. Expected: all pass (the 59 existing tests plus the new ones). FND-013's theme tests must stay green.

- [ ] **Step 5: Mutation proofs.** Revert each after it fails:
  - **T1:** Section title tracking −0.02 → −0.01. Fails the MASTER-values test.
  - **T2:** Hebrew family set to Plex Sans. Fails the family test.
  - **T3:** drop `leadingDistribution`. Fails the tabular/leading test.
  - **T4:** `labelMedium` mapped to `small`. Fails the `TextTheme` test.
  - **T5:** `withZodiannScript` drops the colour extensions (`extensions: [styles]`). Fails the swap test.
  - **T6:** `==` ignores `cell`. Fails the `==` test.
  - **T7:** plain `copyWith(textTheme: buildZodiannTextTheme(styles))` without the merge. Fails the round-trip test.
  - **T8:** `body` with `letterSpacing: null`. Fails the localized-geometry test, because M3's +0.25 tracking comes back.

- [ ] **Step 6: Gates, then commit.** Commit as `feat(ZOD-UI-002): MASTER §3 text styles, TextTheme mapping and script switching`, with T1–T8 in the body.

### Task 2: `ZodiannGlyphs`

**Files:**
- Create: `packages/shared_ui/lib/src/theme/zodiann_glyphs.dart` (export it)
- Test: `packages/shared_ui/test/theme/glyphs_test.dart`

**Interfaces:**
- Produces:
  ```dart
  /// MASTER §3 astrological glyphs, each followed by U+FE0E (text
  /// presentation) so no platform renders it as emoji.
  abstract final class ZodiannGlyphs {
    static const String textPresentation = '\u{FE0E}';
    /// Aries … Pisces (index 0 = Aries).
    static const List<String> signs = [...12];
    static String body(Body b);           // exhaustive switch
    static const String conjunction, sextile, square, trine, opposition, retrograde;
    /// All 29, for tests and harnesses.
    static List<String> get all;
  }
  ```

- [ ] **Step 1: Write the failing tests.**
  - `every glyph is one MASTER code point followed by U+FE0E`: each string in `all` has `runes.length == 2`, and its last rune is 0xFE0E.
  - `signs are ♈…♓ in zodiac order`: `signs[i].runes.first == 0x2648 + i` for i in 0..11, and the length is 12.
  - `each body has its glyph`: a literal map from `Body` to code point (Facts) over `Body.values`.
  - `aspects and retrograde`: literal code points.
  - `the set is exactly the 29 glyphs the bundled fonts cover`: the base code points equal the literal 29-set used by FND-007's `glyph_coverage_test.dart`, typed in again here.

- [ ] **Step 2: Run and see it fail.** Run `cmd //c "cd packages\\shared_ui && fvm flutter test test/theme/glyphs_test.dart"`. Expected: compile failure.

- [ ] **Step 3: Implement.** Write every constant fully escaped, e.g. `'\u{2648}\u{FE0E}'`, with the character in a trailing comment, so the source shows exactly which code point is used.

- [ ] **Step 4: Run and see it pass.** Same command.

- [ ] **Step 5: Mutation proofs.**
  - **G1:** drop U+FE0E from `retrograde`. Fails the first test.
  - **G2:** swap the `body` glyphs for venus and mars. Fails the body test.

- [ ] **Step 6: Gates, then commit.** Commit as `feat(ZOD-UI-002): astrological glyph strings with text presentation`.

### Task 3: Rendering proofs and the specimen harness

**Files:**
- Create: `packages/shared_ui/test/support/load_bundled_fonts.dart`: `Future<void> loadBundledFonts()`, which loads every registered font file with one `FontLoader('packages/shared_ui/<family>')` per family. It's moved from FND-007's `font_rendering_test.dart` `_loadFonts`, and that test is changed to call it.
- Modify: `packages/shared_ui/test/fonts/font_rendering_test.dart` (use the shared loader).
- Create: `packages/shared_ui/test/support/typography_specimen.dart`: a test-only `TypographySpecimen` widget.
  - It mirrors `_source/components.html:78–84`. Each row has the caption (`Display 44, Plex 300` …), the English sample in the Latin role, and the Hebrew sample in the Hebrew role, right-aligned in an RTL `Directionality`.
  - The rows are Display, Section, Screen title, Panel title, Body, Label and Cell, with the reference's exact sample strings. The Cell row's right column is the reference's faint 12 px English caption, not a Hebrew sample.
  - Below the reference rows, an "Other roles" block, each row captioned with its role: Hero wordmark and its phone size, Display phone, Drawer wordmark, Small, Micro, and Glyphs (all 29 `ZodiannGlyphs.all` in the glyph style at 21). So every role appears in the harness (criterion 1).
  - Colours come from the ambient theme's `ZodiannSurfaces`.
  - It's wrapped in a `RepaintBoundary` keyed `typography-specimen`.
- Create: `packages/shared_ui/test/theme/typography_rendering_test.dart`.

**Interfaces:**
- Consumes: `buildZodiannTextStyles` and `ZodiannGlyphs` (Tasks 1 and 2), `ZodiannFonts`.

- [ ] **Step 1: Write the failing tests.** Call `TestWidgetsFlutterBinding.ensureInitialized()`, and use `setUpAll(loadBundledFonts)`. Measure with `TextPainter` (LTR for Latin, RTL for Hebrew). Tests:
  - `every UI role lays out one line at size × line height`: `painter.height` `closeTo(fontSize * height, 0.01)`, for each role in both scripts, with the sample `'Zodiann 17°03′'` (Hebrew: `'זודיאן 17°03′'`).
  - `tracking adds letterSpacing per character`: for each role with `em != 0`, `width(style) - width(style.copyWith(letterSpacing: 0))` is `closeTo(letterSpacing * n, 0.05)`, where n is the number of UTF-16 units of the sample. Use a Latin-only sample (`'Zodiann'`) and its Hebrew counterpart (`'זודיאן'`).
  - `each role renders in its own weight`: using the line-height samples (`'Zodiann 17°03′'` / `'זודיאן 17°03′'`), for roles whose weight isn't 400, `width(style) != width(style.copyWith(fontWeight: w400))`. That shows a distinct face loaded for that weight, not a fallback.
  - `digits do not jitter` (criterion 2): for every UI role in both scripts:
    - the ten single digits `'0'…'9'` lay out at one width;
    - all 100 readouts `'$a$b°$a$b′'` (a, b = 0…9) lay out at one width;
    - each readout's width differs from the same text in `'zodiann-missing-family'`, so it's not the fallback font;
    - as a non-degeneracy check, `'il'` and `'mw'` have different widths in the same style.
  - `Hebrew roles draw ′ and ″ from IBM Plex Sans`: for every UI role, for each of `'′'` and `'″'`:
    - `width(hebrewRole)` is `closeTo(width(latinRole), 0.01)`;
    - and, for ″ in every role and for ′ in roles whose weight isn't w300, it differs by more than 0.05 from the same character in `TextStyle(fontFamily: ZodiannFonts.notoSans, package: ZodiannFonts.package, fontSize: role.fontSize, fontWeight: role.fontWeight, letterSpacing: role.letterSpacing)`.

    Plex Light ′ and Noto ′ are both 232 units, so ′ at w300 can't be told apart by width; ″ makes the test decisive at every weight.
  - `glyphs render through the glyph fonts with an invisible selector`: for each of `ZodiannGlyphs.all` with the glyph style at `fontSize: 40`:
    - its width equals the width of the base code point without U+FE0E (within 0.01). The selector adds no box;
    - its width differs from the same glyph in `'zodiann-missing-family'`.
  - `specimen` (`testWidgets`): only runs when `ZODIANN_TYPE_DIR` is set. Pump `TypographySpecimen` at 1440 × 1100 under `ZodiannTheme.graphite`:
    - set `tester.view.physicalSize` with `devicePixelRatio = 1`, and reset both in `addTearDown`;
    - the specimen's `Column` uses `MainAxisSize.min` inside a top-aligned `Align`, so the PNG of the `typography-specimen` boundary is cropped to the content;
    - assert `tester.takeException()` is null, then write `typography_specimen_graphite.png`.

- [ ] **Step 2: Run and see it fail.** Run `cmd //c "cd packages\\shared_ui && fvm flutter test test/theme/typography_rendering_test.dart"` with `setUpAll` removed. Expected:
  - the line-height and tracking tests still pass on the test font;
  - the weight test, the ′ ″ test, and the "not the fallback" checks in the jitter and glyph tests FAIL.

  Restore `setUpAll`.

- [ ] **Step 3: Run and see it pass.** Then run the specimen with `ZODIANN_TYPE_DIR` set to the scratchpad. Compare it side by side with the reference crop (`components_dark.png`, x 40–1400, y 1140–1525), checking:
  - the same relative sizes and weights;
  - light Display with tight tracking;
  - Hebrew right-aligned in Plex Hebrew;
  - ′ drawn (not a box) in the Hebrew Display row;
  - aligned Cell digits.

  Record the result in the commit body.

- [ ] **Step 4: Mutation proofs.**
  - **R1:** Hebrew fallback without Plex Sans, so ′ and ″ fall to Noto Sans. Fails `Hebrew roles draw ′ and ″ from IBM Plex Sans`: ″ in every role, and ′ in the w400–600 roles.
  - **R2:** glyph style family set to Plex Sans with no fallback. Fails the glyph tests.

  Both mutants are applied in `zodiann_text_styles.dart`.

- [ ] **Step 5: Gates, then commit.** Commit as `test(ZOD-UI-002): rendering proofs and typography specimen harness`.

### Task 4: App wiring and the sentence-case guard

**Files:**
- Modify: `apps/astro_mobile/lib/src/app.dart`: add `builder: (context, child) => Theme(data: withZodiannScript(Theme.of(context), ZodiannScript.forLocale(Localizations.localeOf(context))), child: child!)`.
- Modify: `apps/astro_mobile/test/app_shell_test.dart` (reuse `_pumpShell(brightness:, locales:)`).
- Create: `test/architecture/sentence_case_test.dart`.

**Interfaces:**
- Consumes: `withZodiannScript` and `ZodiannScript.forLocale` (Task 1).

- [ ] **Step 1: Write the failing tests.**
  - App tests, using the existing `_pumpShell` pattern with `localesTestValue`, and reading `Theme.of(<ShellHome element>)`:
    - `English locale gets Plex Sans`: `textTheme.bodyMedium!.fontFamily == 'packages/shared_ui/IBM Plex Sans'`, and the `ZodiannTextStyles` extension agrees.
    - `Hebrew locale gets Plex Sans Hebrew`, with `Locale('he', 'IL')`.
    - `changing the device locale re-resolves the typography without restart`: en, then set `localesTestValue` to he, pump, and the family is Hebrew.
    - `the theme-mode animation keeps the script and interpolates colour`:
      - under he, switch the platform brightness and `pump()`, then `pump(100 ms)`, as FND-013's lerp test does;
      - mid-animation, `bodyMedium.fontFamily` is Plex Sans Hebrew;
      - `bodyMedium.color` is strictly between the two themes' `text` colours (≠ both).
  - `test/architecture/sentence_case_test.dart`:
    - `no UI source upper-cases text (sentence case)`: there's no `toUpperCase(` in `apps/*/lib/**.dart` or `packages/*/lib/**.dart`, ignoring text after `//`. The walk mirrors `no_color_literals_test.dart` (`apps/*/lib`, `packages/*/lib`). Unlike that test, it skips the pure-Dart members `astro_core`, `gann_core`, `ephemeris_swiss` and `ephemeris_astronomy`, which hold no UI text.
    - The failure message names the convention: "MASTER §3: sentence case; write the string in sentence case instead".

- [ ] **Step 2: Run and see them fail.** Run `cmd //c "cd apps\\astro_mobile && fvm flutter test"`. Expected: the Hebrew, live-switch and mid-animation tests fail, because without the builder the family stays Plex Sans. English passes already (Task 1 made the themes Latin), and that's expected. The architecture test passes immediately, since nothing upper-cases today, and is proven by mutant S1.

- [ ] **Step 3: Implement the builder.** Make it `const`-safe: `ZodiannApp` stays a `const` `ConsumerWidget`.

- [ ] **Step 4: Run them and see them pass.** Run `cmd //c "cd apps\\astro_mobile && fvm flutter test"` (16 existing plus the new ones) and `cmd //c "fvm dart test test/architecture"` (28 existing plus 1).

- [ ] **Step 5: Mutation proofs.**
  - **A1:** the builder always passes `ZodiannScript.latin`. Fails the Hebrew, live-switch and mid-animation tests.
  - **A2:** the builder uses `ZodiannTheme.graphite` instead of `Theme.of(context)`. Fails the light/animation tests, including FND-013's.
  - **S1:** add `'x'.toUpperCase()` to `shared_ui/lib/src/theme/zodiann_glyphs.dart`. Fails the sentence-case test.

- [ ] **Step 6: Gates, then commit.** Commit as `feat(ZOD-UI-002): resolve typography by locale in the app; sentence-case guard`.

### Task 5: On-device emoji proof and close-out

**Files:**
- Create: `apps/astro_mobile/integration_test/glyph_presentation_test.dart`.
- Modify: the UI-002 task file, `docs/development/TASKS.md`, `docs/PROGRESS.md`, and the WHL-006 task file (a Note that ℞ comes from `ZodiannGlyphs.retrograde`).

**Interfaces:**
- Consumes: `ZodiannGlyphs.all` and `buildZodiannTextStyles(...).glyph`. Fonts come from the app's font manifest.

- [ ] **Step 1: Write the integration test.**
  - Set up `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`, and add a helper `Future<(int dark, int coloured)> _inkOf(String text, TextStyle style)`:
    - paint `text` with `style.copyWith(fontSize: 64, color: <opaque black>)` onto a white canvas via `PictureRecorder` + `TextPainter.paint`;
    - call `toImage` and read the raw RGBA;
    - count pixels with `max(r, g, b) < 200` (ink) and pixels with `max(r, g, b) - min(r, g, b) > 24` (colour).
    - The black and white come from `porcelainTokens.surfaces.text` / `surface`, so no colour literals are needed even in test code.
  - Tests:
    - `every astrological glyph renders as monochrome text, not colour emoji`: for each of `ZodiannGlyphs.all` with the Latin glyph style, `dark > 50` (something is drawn) and `coloured == 0`.
    - `glyphs inside UI text also stay monochrome`: the same check with the Latin `body` style and with the Hebrew `body` style. That proves the UI stacks' glyph fallback.

- [ ] **Step 2: Run it on emulator-5554**, as FND-007 established (Flutter 3.50 refuses `flutter test -d` there):
  - `cmd //c "cd apps\\astro_mobile && fvm flutter build apk --debug -t integration_test/glyph_presentation_test.dart"`;
  - `adb -s emulator-5554 install -r apps/astro_mobile/build/app/outputs/flutter-apk/app-debug.apk`;
  - `adb -s emulator-5554 logcat -c`, then `adb -s emulator-5554 shell am start -n com.zodiann.app/.MainActivity`;
  - read `adb -s emulator-5554 logcat -d -s flutter`. Expected: `All tests passed!`.
  - **Detector proof, mutant E1:** render the base glyphs **without U+FE0E in the system font** (`fontFamily: 'zodiann-missing-family'`, no package). Expected on Android 9 (NotoColorEmoji): the monochrome test FAILS with `coloured > 0` for at least the signs. If the system font renders them monochrome anyway, the detector can't be proven on this image: record that and the ruling, and keep the test (it still guards against regressions on platforms with colour emoji). Revert E1 and reinstall the normal app afterwards (`fvm flutter build apk --debug` + `adb install -r`).

- [ ] **Step 3: Gates, then commit.** Commit the integration test as `test(ZOD-UI-002): on-device proof that glyphs never render as colour emoji`. Put the logcat results and the E1 outcome in the body.

- [ ] **Step 4: Whole-branch code review** (opus). Fix Critical and Important findings test-first, and defer minors.

- [ ] **Step 5: Close out the docs.**
  - **UI-002 task file:** status Done, the three criteria ticked. Notes:
    - the role table decisions (Panel title 0 tracking per MASTER over `kit.css`; Small and Micro defaults; inherited 1.45 line heights; Cell 11.5/1.12);
    - the 15-slot mapping;
    - glyph fallback in the UI stacks;
    - phone variants are fields, chosen by the screens;
    - criterion 3 was verified on the host (FontLoader width proofs) and on Android 9 x86 emulator-5554 (monochrome pixel test, plus the E1 outcome). iOS wasn't run (needs a Mac); run `integration_test/glyph_presentation_test.dart` there.
  - **WHL-006 Note:** use `ZodiannGlyphs.retrograde`.
  - **PROGRESS:**
    - Technical Decisions:
      - typography as a `ThemeExtension` plus a full `TextTheme`;
      - script resolution in `MaterialApp.builder`;
      - glyph strings centralised in `ZodiannGlyphs`.
    - Blockers → iOS: add "UI-002 glyph monochrome test on iOS" to the Mac verification list.
    - Architecture Conventions:
      - derive every text style from a `ZodiannTextStyles` role or a `textTheme` slot (`copyWith` for size or colour), never a `TextStyle` built from scratch;
      - astrological glyphs come only from `ZodiannGlyphs`;
      - sentence case is enforced by `sentence_case_test.dart`.
    - Verification block, Git State, next task.
  - **TASKS.md:** UI-002 Done.
  - Commit as `docs(ZOD-UI-002): close out typography scale`, then push, open the PR, and record the PR link.

## Plan review

### Round 1: Approve after corrections (2 Critical, 2 Important, 16 Minor, 0 Needs user decision)

The reviewer re-derived the role values from MASTER §3, `kit.css`, `about.html`, `wheel.html` and the reference board, and parsed the bundled fonts' cmap, hmtx, GSUB and GPOS tables. It confirmed:
- digits are 600 units in every Plex file, with no digit kerning and no `tnum` feature;
- Plex Hebrew lacks ′ and ″;
- no bundled font maps U+FE0E;
- the builder sees both `Localizations` and the animated theme.

**Critical (applied):**
- **C1:** `ZodiannTextStyles` had no value equality, but the tests (and `ThemeData.==` via `mapEquals`) rely on it. Added `==`/`hashCode`, a test, and mutant T6.
- **C2:** mutant R1 couldn't fail, because Noto Sans in the fallback supplies ′ ″ (with ′ the same width at Light). Added `Hebrew roles draw ′ and ″ from IBM Plex Sans`, which is decisive through ″, rewrote R1, and updated Review Focus 1.

**Important (applied):**
- **I1:** `withZodiannScript` now does the `typography.black/white` merge that the `ThemeData` constructor does. Added a round-trip equality test and mutant T7.
- **I2:** criterion 3's tested platforms (host, Android 9 x86) and iOS's absence are recorded in the Notes and the PROGRESS Blockers.

**Minor (all applied):**
- **M1:** corrected RED prediction for Task 3.
- **M2:** the mid-animation test is included in Task 4's RED and in A1.
- **M3:** the glyph style sets `letterSpacing: 0` and even leading explicitly.
- **M4:** the specimen gets an "Other roles" block, and the Cell row is clarified.
- **M5:** 100 mixed-digit readouts, plus a non-degeneracy check.
- **M6:** owners and sources corrected (contrast is NFR-009, text scaling is unowned, aspects come from `kit.js`, L10-011/012).
- **M7:** the tablet 38 px readout is noted as not provided.
- **M8:** leading wording.
- **M9:** a single test file named for Task 4.
- **M10:** glyph constants fully escaped.
- **M11:** the sentence-case scan covers all members except the pure-Dart ones.
- **M12:** an unneeded conditional removed.
- **M13:** `Run:` lines and the file list completed.
- **M14:** `primaryTextTheme` noted as deliberately left.
- **M15:** a localized-text-theme geometry test, with mutant T8.
- **M16:** the PROGRESS convention is narrowed to "derive from a role or slot".

### Round 2: Approve after corrections (0 Critical, 1 Important, 5 Minor)

The reviewer confirmed every round-1 correction is in the body. It verified that T7, T8 and R1 really fail, and that the FND-013 tests stay green with the added extension.

**Important (applied):**
- **I1:** the "Other roles" block made the specimen overflow a 1440 × 520 viewport. Now 1440 × 1100, a `min`-size `Column`, and a `takeException()` check.

**Minor (all applied):**
- **M1:** the ′ check against Noto is skewed by tracking. The Noto comparison now uses the role's tracking and skips ′ at w300 (232 = 232).
- **M2:** the 15-slot test reads `buildZodiannTextTheme(r)`, not the merged `theme.textTheme`.
- **M3:** the weight test names its samples.
- **M4:** the sentence-case exclusions are worded accurately.
- **M5:** the Task 1 commit lists T1–T8.

No open items remain after two rounds.
