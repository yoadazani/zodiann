# ZOD-L10-007 + ZOD-L10-013 Entity Keys and Hebrew Terminology Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:**
- Every sign, body, aspect and compass direction has a stable, language-independent key (L-9).
- Translated names come only from `ZodiannLocalizations`, looked up by key.
- Storage and computation code can't reach translated strings.
- The Hebrew names follow each language's tradition. The product owner confirmed this in a written decision record (ZOD-L10-013, D20).

**Architecture:**
- **Key enums in the pure-Dart cores.** `Body` already exists in `astro_core`. This task adds `ZodiacSign` (12) and `AspectKind` (5) to `astro_core`, and `CompassDirection` (8) to `gann_core`. Each has `toJson()` returning its `name` and a `fromJson` that throws `FormatException` on unknown input, as `Body` does. Each key list is pinned by a literal test, so a rename or reorder that would change persisted keys fails.
- **Name lookups in `shared_ui`.** An extension `ZodiannEntityNames on ZodiannLocalizations` maps each key to its generated getter through exhaustive switches. A new enum value therefore can't compile without a translation, and the key-parity guard forces the Hebrew string.
- **The names** are 36 new ARB keys, taken from the design kit's string tables (`design-reference/zodiann/_source/kit.js`), which rendered the approved en / he screens. A test cross-checks the ARB values against kit.js as a second source.
- **Criterion 1.** A root architecture test fails if a storage or computation package (`astro_core`, `gann_core`, `ephemeris_*`, `shared_storage`) imports `shared_ui` or `flutter_localizations`, depends on them at runtime (directly or transitively), or mentions `ZodiannLocalizations`. Together with the pure-Dart guard, this means storage and computation code can't *produce* translated strings.
  - Entity-valued model fields are enum-typed (`Crossing.body: Body`), so they can only hold keys.
  - Free-text `String` fields (`SquareConfig.name`, a user-defined `HighlightRule.label`) are user content, not entity names. The default `HighlightRule.label`s are keys that the UI translates.

**Tech Stack:** Flutter 3.50.0 / Dart 3.14.0 (FVM), `package:test` (cores and root), `flutter_test` (`shared_ui`), gen-l10n (ZOD-L10-001), and `dependency_closure.dart`'s `findForbiddenDependencies` over `dart pub deps --json` (as `no_network_test.dart` does). There are no new third-party dependencies. `shared_ui` gains a path dependency on `gann_core` (pure Dart; ARCH-2's direction holds).

**Spec:** `assets/zodiann-specification.md` L-9, L-8, "Translation and content" (the open decision). Design: `design-reference/zodiann/DESIGN_DECISIONS.md` D20; `_source/kit.js:13-19, 33-48, 82-115, 152-195, 370`. Tasks: `docs/development/localization/ZOD-L10-007-implement-stable-language-independent-entity-keys.md`, `docs/development/localization/ZOD-L10-013-resolve-and-document-the-symbol-translation-open-decision.md`.

## Product-owner decisions (2026-11-14)

- **T1: D20 is confirmed.** Astrological names are translated per each language's tradition. L10-013 is grouped into this task. Its decision record is the first commit after the reviewed plan (Task 0) and is cited by L10-007.
- **T2: Hebrew aspect names follow the design:** צמידות, סקסטייל, ריבוע, טריין, אופוזיציה (the approved Hebrew screens).
- **T3: Outer planets use the common Hebrew names:** אורנוס, נפטון, פלוטו (as in the design), not the Academy's proposals (אורון, רהב).
  - These planets have no traditional Hebrew names, so their Hebrew-script forms are a recorded exception to L10-007 criterion 2's "not transliteration".
- **T4: Key enums are added now:**
  - `ZodiacSign` (`astro_core`): EPH-005 produces it (sign-from-longitude), and WHL-002 and the positions table (WHL-018) consume it.
  - `AspectKind` (`astro_core`): ASP-001 adds the angles and orbs.
  - `CompassDirection` (`gann_core`): the cell details (SQR-012) and the export's direction column use it.

## Facts established while planning (2026-11-14)

- **What exists today:**
  - `Body` (`astro_core`) already has stable JSON keys, and `body_test.dart` pins its value names.
  - No sign, aspect or direction type exists.
  - EPH-005's task file says it will "produce a stable sign key (Aries…Pisces)", so this task defines that key, and EPH-005 returns it.
  - `ZodiannGlyphs` has `signs` (a 12-element list in zodiacal order), `body(Body)`, and named aspect constants.
- **No UI layer exists yet.**
  - `apps/astro_mobile/lib` (shell only), `packages/feature_*/lib` (stubs) and `shared_ui/lib` (theme, button, l10n) contain no entity names.
  - The data model's `String` fields are `SquareConfig.id/name`, `HighlightRule.id/label/colorToken`. The default rule labels are already keys (`'axes'`, `'diagonals'`, `'eighths'`).
  - So L10-007's audit finds nothing to fix. The guard and the typed-field convention keep it that way.
- **Spiral angle convention** (`gann_core` `SpiralCell.angle`): `θ = 45° · i / k`, with 0° on the west axis (cell 2) increasing clockwise. It is exact on axes and diagonals. kit.js `COMPASS` agrees: 0 W, 45 NW, 90 N, 135 NE, 180 E, 225 SE, 270 S, 315 SW.
- **Design-kit names** (en / he), used as the expected values:
  - **Signs:** Aries טלה, Taurus שור, Gemini תאומים, Cancer סרטן, Leo אריה, Virgo בתולה, Libra מאזניים, Scorpio עקרב, Sagittarius קשת, Capricorn גדי, Aquarius דלי, Pisces דגים.
  - **Bodies:** Sun שמש, Moon ירח, Mercury כוכב חמה, Venus נוגה, Mars מאדים, Jupiter צדק, Saturn שבתאי, Uranus אורנוס, Neptune נפטון, Pluto פלוטו, Mean node ראש הדרקון.
  - **Aspects:** Conjunction צמידות, Sextile סקסטייל, Square ריבוע, Trine טריין, Opposition אופוזיציה.
  - **Directions:** west מערב, north-west צפון-מערב, north צפון, north-east צפון-מזרח, east מזרח, south-east דרום-מזרח, south דרום, south-west דרום-מערב. English directions are lower case because the design uses them mid-sentence ("Axis, west").
- **Forms these names don't cover:** the Hebrew adjective forms (`HE_ADJ`: מערבית …, used by the Hebrew highlight-line sentence in SQR-012 and the compass phrases noted in SQR-013) and the edge abbreviations (`axW`: W / מע׳, SQR-017). Those screens add their own keys.
- **Scope of "directions":** the compass direction of a square cell relative to the centre (L-9's "north-west"; SQ-17, EX-2). Motion states (direct / retrograde / mean) are screen strings.

## Global Constraints

- **Keys are names:** an entity's key is its enum value's `name`, and its JSON is that string. Never store an index or a translated name.
- **Typed fields:** a model field holding a sign, body, aspect or direction is typed as its key enum, never `String`.
- **Pinned key lists:** each enum's key list in a test equals a literal list. Changing it is a data-format change and needs an explicit decision.
- **ARB keys:** `sign<Name>`, `body<Name>`, `aspect<Name>`, `direction<Name>` (camelCase, for example `directionNorthWest`). Each template entry has an `@key` description.
- **Lookups:** only through `ZodiannEntityNames`, using exhaustive `switch` expressions with no `default`.
- **Dependencies:** the cores stay pure Dart. Delegates follow the L10-001 convention.
 Never run `git checkout .`, `git restore .` or `git stash` (they would revert `.fvmrc`); restore mutations by explicit path. Stage `pubspec.lock` only if `pub get` changed it. Commands as in L10-001 (`export PATH="$PATH:$LOCALAPPDATA/Pub/Cache/bin"`; gates `cmd //c "fvm dart run melos run lint && fvm dart run melos run test"`).

## Out of scope

- Aspect angles, orbs and detection (ASP-001), and sign-from-longitude (ZOD-EPH-005, which returns `ZodiacSign` instead of defining its own key).
- Glyph lookup by key: `ZodiannGlyphs` stays index- and name-based.
- Hebrew adjective and abbreviated direction forms (SQR-013, SQR-017), motion states, element names and screen copy.
- ICU plurals (L10-008), bidi isolation (L10-006), persistence code (FND-006), and the export's localization (XLS-016).

## Review Focus

1. **Reordering or renaming an enum value** would silently change persisted JSON. The pinned literal key lists must fail. Task 1.
2. **A Hebrew name that drifts from the approved design** (a typo, or an untranslated Latin name) must fail against both the literal table and kit.js. Task 2.
3. **A new enum value added without a translation** must fail to compile (exhaustive switch) or fail the key-parity guard. Task 2, with a proof.
4. **A storage package that starts importing or depending on localization** (`shared_storage` is a Flutter package, so this is a realistic risk) must fail the guard, while the app and the feature packages may. Task 3.
5. **Two keys in one entity set sharing a display name** would be ambiguous. Names must be distinct within each set in both languages. Task 2.

---

### Task 0: L10-013 decision record (the first commit after the reviewed plan)

**Files:**
- Modify:
  - the L10-007 and L10-013 task files (set both to In Progress in this commit; the record goes in L10-013's Notes);
  - `docs/development/TASKS.md`: add a bullet to §6.2's list of spec-level open items, and change "Two more" to "Three more". The bullet reads: **Resolved 2026-11-14** (product-owner decision, see the ZOD-L10-013 Notes): astrological names are translated per each language's tradition (D20 confirmed). Original item: the spec's "Translation and content" open decision.

- [ ] **Step 1: Write the record** in L10-013's Notes:
  - **Decision (2026-11-14, product owner):** D20 is confirmed. Names are translated per each language's tradition.
  - **Aspects:** the design's Hebrew names (T2), including the established transliterations סקסטייל, טריין, אופוזיציה.
  - **Outer planets:** the common Hebrew names אורנוס, נפטון, פלוטו (T3), not the Academy's אורון / רהב. Uranus, Neptune and Pluto have no traditional Hebrew names, so this is a recorded exception to L10-007 criterion 2's "not transliteration".
  - **Criterion 2 coverage:** criterion 2 is met for every sign, the classical bodies and the node.
  - **Source of truth:** `packages/shared_ui/lib/l10n/app_he.arb`, pinned by `entity_names_test.dart` against the design kit.
- [ ] **Step 2: Commit**: `docs(ZOD-L10-013): record the symbol-translation decision`.

### Task 1: Key enums with pinned keys

**Files:**
- Create: `packages/astro_core/lib/src/zodiac/zodiac_sign.dart`, `packages/astro_core/lib/src/aspects/aspect_kind.dart`, `packages/gann_core/lib/src/model/compass_direction.dart`
- Modify: `packages/astro_core/lib/astro_core.dart`, `packages/gann_core/lib/gann_core.dart` (exports)
- Test: `packages/astro_core/test/entity_keys_test.dart`, `packages/gann_core/test/model/compass_direction_test.dart`

**Interfaces:**
- Produces:
  - `enum ZodiacSign { aries, taurus, gemini, cancer, leo, virgo, libra, scorpio, sagittarius, capricorn, aquarius, pisces }`. `index` is the sign index 0–11. It has `String toJson()` and `static ZodiacSign fromJson(Object? json)`.
  - `enum AspectKind { conjunction, sextile, square, trine, opposition }`, in the spec's table order. It has `toJson` and `fromJson`.
  - `enum CompassDirection { west, northWest, north, northEast, east, southEast, south, southWest }`, with:
    - `double get angleDegrees => index * 45.0`;
    - `static CompassDirection? atAngle(double degrees)`, which returns the direction whose `angleDegrees` equals `degrees` exactly, else null;
    - `toJson` and `fromJson`.

- [ ] **Step 1: Write the failing tests.**
  - **`astro_core/test/entity_keys_test.dart`:**
    - `'Body JSON keys are pinned'`: `Body.values.map((b) => b.toJson())` equals the eleven literals. A comment notes that `body_test.dart` pins the value names, and this test pins the JSON form.
    - `'ZodiacSign keys are pinned, in zodiacal order'`: the twelve literals.
    - `'AspectKind keys are pinned, in table order'`: `['conjunction','sextile','square','trine','opposition']`.
    - For both new enums:
      - `'fromJson round-trips every key'`;
      - `'fromJson rejects unknown, wrong-case and non-string input'`: `'Aries'`, `'conj'`, `''`, `3`, `null` throw `FormatException`.
  - **`gann_core/test/model/compass_direction_test.dart`:**
    - the pinned key list `['west','northWest','north','northEast','east','southEast','south','southWest']`;
    - the round-trip and rejection tests (`'NW'`, `'north-west'`, `0`);
    - `'angleDegrees follows the spiral convention'`: 0, 45 … 315;
    - `'atAngle maps the eight axes and nothing else'`: each `angleDegrees` maps back to its direction, and 22.5, 360, −45 and 44.999 return null;
    - `'ring 1: cell 2 is west, corners are diagonals'`: cells 2…9 → west, northWest, north, northEast, east, southEast, south, southWest via `atAngle(spiralCell(n).angle!)`;
    - `'far rings stay exact'`: `atAngle(spiralCell(spiralNumberAt(-30, 0)).angle!) == west` and `atAngle(spiralCell(spiralNumberAt(30, -30)).angle!) == northEast`.
- [ ] **Step 2: Run them to verify they fail**
  - Run: `cmd //c "cd packages\\astro_core && fvm dart test test/entity_keys_test.dart"` and `cmd //c "cd packages\\gann_core && fvm dart test test/model/compass_direction_test.dart"`.
  - Expected: compile FAIL (`Undefined name 'ZodiacSign'` …); no test in either file runs.
 `atAngle`'s doc comment says it takes a spiral angle in [0, 360) (`SpiralCell.angle`); 360 returns null, so callers with a non-normalized angle normalize first. It also says the mapping assumes the SQ-8 orientation (start left, clockwise), which ZOD-EXT-010 must remap. Each doc comment states "the stable, language-independent key (L-9); never store an index or a translated name". Export them.
- [ ] **Step 4: Run the tests and the package suites**
  - Run: `cmd //c "cd packages\\astro_core && fvm dart test"` and `cmd //c "cd packages\\gann_core && fvm dart test"`.
  - Expected: all pass.
  - **Mutation proofs:**
    - swap `sextile` and `square` in `AspectKind` → the pinned list fails; restore;
    - rename `northWest` to `northwest` → the test file fails to compile; with its references updated, the pinned list fails; restore.
- [ ] **Step 5: Commit**: `feat(ZOD-L10-007): stable keys for signs, aspects and compass directions`.

### Task 2: Translated names, looked up by key

**Files:**
- Modify:
  - `packages/shared_ui/lib/l10n/app_en.arb`, `app_he.arb` (36 keys);
  - the generated `zodiann_localizations*.dart`;
  - `packages/shared_ui/pubspec.yaml` (add `gann_core: {path: ../gann_core}`);
  - `packages/shared_ui/lib/shared_ui.dart` (export);
  - the root `pubspec.lock` if it changes.
- Create: `packages/shared_ui/lib/src/l10n/entity_names.dart`
- Test: `packages/shared_ui/test/l10n/entity_names_test.dart`

**Interfaces:**
- Consumes: Task 1's enums.
- Produces: `extension ZodiannEntityNames on ZodiannLocalizations` with `String signName(ZodiacSign)`, `bodyName(Body)`, `aspectName(AspectKind)` and `directionName(CompassDirection)`.

- [ ] **Step 1: Write the failing test** `entity_names_test.dart`. It loads `ZodiannLocalizations` for `en` and `he` with `await ZodiannLocalizations.delegate.load(Locale(...))`.
  - **`'en and he names match the approved design, per key'`:** four literal tables `Map<Enum, (String en, String he)>` from the Facts section. Each covers every enum value (length equals `values.length`), and each lookup equals its literal.
  - **`'names are distinct within each entity set, in both languages'`.**
  - **`'kit.js agrees'`:** read `../../design-reference/zodiann/_source/kit.js`.
    - Split the `S` object at `^  en: {` and `^  he: {` (all block anchors use `multiLine: true`). The he block ends at the first `^};` after `he: {`.
    - Extract each scalar key with `RegExp("(?<![A-Za-z])$key: '([^']*)'")`, taking the first match within its block. That covers the aspects `conj` / `sextile` / `sq` / `trine` / `opp`, and the directions `W` / `NW` / `N` / `NE` / `E` / `SE` / `S` / `SW` in `COMPASS` order.
    - For `SIGNS` and `BODIES`, use row regexes `\{ k: '(\w+)'.*?en: '([^']*)', he: '([^']*)'`.
    - Map them to the enums (kit `conj` / `sq` / `opp` → conjunction / square / opposition; `node` → `Body.node`), and assert that every lookup equals kit.js.
  - **`'every Hebrew sign, body and node name is in Hebrew script'`:** `RegExp(r'^[א-ת\s-]+$')`. This catches an untranslated Latin name; the literal table and kit.js pin the traditional names.
- [ ] **Step 2: Run it to verify it fails**
  - Run: `cmd //c "cd packages\\shared_ui && fvm flutter test test/l10n/entity_names_test.dart"`
  - Expected: compile FAIL, because `signName` and the others aren't defined.
- [ ] **Step 3: Add the ARB keys and generate.**
  - **ARB keys:** `signAries` … `signPisces`; `bodySun` … `bodyPluto`, plus `bodyNode` ("Mean node"); `aspectConjunction` … `aspectOpposition`; `directionWest` … `directionSouthWest`.
  - **Template descriptions:**
    - signs: "Zodiac sign name (L-9). Hebrew per tradition (D20, L10-013)";
    - bodies: "Body name (L-9). Hebrew per tradition; outer planets per the L10-013 exception (D20, L10-013)"; `bodyNode`: "The mean ascending lunar node";
    - aspects: "Aspect name (L-9)";
    - directions: "Compass direction of a square cell from the centre, used mid-sentence ('Axis, west'), so lower case in English (L-9)".
  - **Generate:** run `cmd //c "cd packages\\shared_ui && fvm flutter gen-l10n"`.
  - **Dependencies:** add the `gann_core` path dependency, then run `cmd //c "fvm flutter pub get"` at the root.
- [ ] **Step 4: Implement `entity_names.dart`** with exhaustive `switch` expressions, and export it.
- [ ] **Step 5: Run the tests and gates**
  - Run: `cmd //c "cd packages\\shared_ui && fvm flutter test"`, `cmd //c "fvm dart test test/architecture"` and `cmd //c "fvm dart run melos run lint"`.
  - Expected: all pass. `app_en.arb` / `app_he.arb` each have 37 message keys (`appTitle` + 36), parity passes, and `l10n:check` is up to date.
- [ ] **Step 7: Mutation proofs (after the Step 6 commit).** For each one:
  1. apply the change, and run `cmd //c "cd packages\\shared_ui && fvm flutter gen-l10n"` if an ARB file changed;
  2. run the named check;
  3. restore with `git checkout -- <the exact paths changed>` (never `git checkout .` or `git restore .`), and regenerate;
  4. confirm `git status --short` shows only ` M .fvmrc`.

  The proofs:
  - **(a)** `signLeo` in `app_he.arb` → `Leo`, regenerated. Expected: `fvm flutter test test/l10n/entity_names_test.dart` fails the literal, kit.js and Hebrew-script tests.
  - **(b)** `bodyName(Body.venus)` → `bodyMars`. Expected: the literal and distinctness tests fail.
  - **(c)** A temporary `ZodiacSign.ophiuchus` in `packages/astro_core/lib/src/zodiac/zodiac_sign.dart`. Expected: `cmd //c "cd packages\\shared_ui && fvm dart analyze"` reports `non_exhaustive_switch_expression` in `entity_names.dart`, and `cmd //c "cd packages\\astro_core && fvm dart test test/entity_keys_test.dart"` fails the pinned list.

### Task 3: Storage and computation never reach localization (criterion 1)

**Files:**
- Create: `test/architecture/l10n_references.dart` (scanner), `test/architecture/l10n_references_test.dart` (unit tests), `test/architecture/no_l10n_in_core_test.dart` (walk and dependency check)

**Interfaces:**
- Produces:
  - `const keyOnlyPackages = ['astro_core', 'gann_core', 'ephemeris_swiss', 'ephemeris_astronomy', 'shared_storage']`;
  - `List<String> l10nReferences(String source)`: offending import or export statements, and `ZodiannLocalizations` mentions.

- [ ] **Step 1: Write the failing unit tests** `l10n_references_test.dart`.
  - **Flagged:**
    - `import 'package:shared_ui/shared_ui.dart';`
    - `import "package:shared_ui/shared_ui.dart";`
    - `import 'package:flutter_localizations/flutter_localizations.dart';`
    - `import 'package:shared_ui/l10n/zodiann_localizations.dart';`
    - `export 'package:shared_ui/shared_ui.dart';`
    - `import 'stub.dart' if (dart.library.ui) 'package:shared_ui/shared_ui.dart';`
    - a two-line import (`import\n  'package:shared_ui/shared_ui.dart';`)
    - `ZodiannLocalizations.of(context)`
  - **Not flagged:**
    - `import 'package:astro_core/astro_core.dart';`
    - `// ZodiannLocalizations`
    - `/* import 'package:shared_ui/shared_ui.dart'; */`
    - `final s = 'ZodiannLocalizations';`
- [ ] **Step 2: Write the walk** `no_l10n_in_core_test.dart`:
  - `'key-only sources never reach localization'`: every `lib/**.dart` of each key-only package has no `l10nReferences`, and the reason lists `path: hit`;
  - `'key-only packages never depend on localization at runtime'`: run `dart pub deps --json` once (as `no_network_test.dart` does). For each key-only package, `findForbiddenDependencies(deps, pkg, forbidden: {'shared_ui', 'flutter_localizations'}, includeDevDependencies: false)` is empty, with the path in the reason;
  - `'scans every key-only package'`: each directory exists, and `astro_core` / `gann_core` each contribute ≥ 1 file;

  - `'positive control: the app depends on localization'`: `findForbiddenDependencies(deps, 'astro_mobile', forbidden: {'shared_ui', 'flutter_localizations'}, includeDevDependencies: false).keys` equals `{'shared_ui', 'flutter_localizations'}`.
- [ ] **Step 3: Run them to verify they fail**
  - Run: `cmd //c "fvm dart test test/architecture/l10n_references_test.dart test/architecture/no_l10n_in_core_test.dart"`
  - Expected: compile FAIL, because `l10n_references.dart` doesn't exist.
- [ ] **Step 4: Implement `l10nReferences(source)`.**
  - Let `clean = cleanDartSource(source)`, which has the same length as `source`.
  - **(a)** For each match of `RegExp(r'^\s*(import|export)\s[^;]*;', multiLine: true)` in `clean`, take `source.substring(m.start, m.end)`: the raw statement at the same offsets, with comments already excluded. Flag it if it contains `['"]package:(shared_ui|flutter_localizations)/` anywhere, conditional alternatives included.
  - **(b)** Flag each `\bZodiannLocalizations\b` match in `clean`.
- [ ] **Step 5: Run them, then the mutation proofs**
  - Run the step 3 command → PASS.
  - **(1)** Add `import 'package:shared_ui/shared_ui.dart';` to `packages/shared_storage/lib/shared_storage.dart`. Expected: the source walk fails naming that file.
  - **(2)** Also add `shared_ui: {path: ../shared_ui}` to `shared_storage/pubspec.yaml` and run `cmd //c "fvm flutter pub get"`. Expected: the dependency test fails with `shared_storage -> shared_ui`.
  - Restore with `git checkout -- packages/shared_storage/lib/shared_storage.dart packages/shared_storage/pubspec.yaml` (and `pubspec.lock` only if pub get changed it), then run `cmd //c "fvm flutter pub get"` again. Confirm `git status --short` shows only ` M .fvmrc` plus Task 3's three new untracked test files.
- [ ] **Step 6: Commit**: `test(ZOD-L10-007): storage and computation packages never reach localization`.

### Task 4: Review and close-out

**Files:**
- Modify:
  - the L10-013 task file (Status Done, both criteria checked);
  - the L10-007 task file (Status Done, both criteria checked, the audit and the T3 exception; cites the L10-013 record);
  - `docs/development/TASKS.md` (both rows);
  - `docs/PROGRESS.md` (rows, the Localization convention, decisions T1–T4, verification, git state);
  - hand-off Notes in the following tasks:
    - **ASP-001:** `AspectKind` exists; add angle / orb, and keep the order and keys.
    - **EPH-005:** `ZodiacSign` exists in `astro_core`. The decomposition returns `ZodiacSign.values[⌊normalizeDegrees(l) / 30⌋]`; don't define another sign key.

    - **WHL-002 / WHL-009 / WHL-020:** the sign ring iterates `ZodiacSign.values`; the under-the-pointer sign and the crossings sign filter use `ZodiacSign` + `signName`. Filter state stores `ZodiacSign.name`, never a display name.
    - **SQR-012:** `CompassDirection.atAngle(cell.angle)` plus `directionName` for "Axis, west" / "ציר, מערב".  The Hebrew highlight-line sentence ("… צפונית למרכז") needs the adjective form, which `directionName` doesn't provide; add screen keys (an ICU `select` on `direction.name`), as for SQR-013.
    - **SQR-013:** the Hebrew adjective forms (צפונית …) aren't provided by `directionName`. Add screen keys, for example an ICU `select` on `direction.name`.
    - **SQR-017:** `CompassDirection` may pick the edge, but the abbreviations W / N / E / S and מע׳ … are SQR-017's own keys.
    - **SET-007:** `UserSettings` stores visible bodies as `Body` keys and orbs keyed by `AspectKind.name`, never by display names.
    - **XLS-005 / XLS-016:** the Cell list direction column comes from `CompassDirection` by key and is localized at export time.
    - **L10-006:** Hebrew names next to Latin runs.
    - **The square legend / rule UI** (ZOD-SQR-018, ZOD-EXT-008): the default `HighlightRule.label`s are keys, translated for display and never written back translated.

- [ ] **Step 1: Run the whole-branch review** (`requesting-code-review`, most capable model) with this plan's Review Focus. Fix Critical / Important findings test-first, and record Minor ones as deferred.
- [ ] **Step 2: Run the full gates**: `cmd //c "fvm dart run melos run lint && fvm dart run melos run test"`. Expected: exit 0.
- [ ] **Step 3: Write the docs.**
  - **L10-007 audit Note:** lists what was inspected (`apps/astro_mobile/lib`, `packages/feature_*/lib`, `shared_ui/lib`, and the model `String` fields), the result (no translated string stored or computed; the default rule labels are keys), and the guards.
  - **PROGRESS Localization convention** gains:
    - entity names come from `ZodiannEntityNames`;
    - entity-valued model fields are typed as their key enum, never `String`;
    - the key lists are pinned;
    - default `HighlightRule.label`s are keys that the UI translates and never writes back.
- [ ] **Step 4: Commit, push and open the PR** (`docs(ZOD-L10-007): close out entity keys and the L10-013 decision`). Then add the PR link to PROGRESS and push a follow-up commit.

## Open items for approval

None beyond approving the plan. T1–T4 are decided.

## Plan review

### Round 1: Approve after corrections (0 Critical, 6 Important, 8 Minor, 0 Needs user decision)

- **I1, applied.** EPH-005 owns sign-from-longitude and returns `ZodiacSign`. A hand-off is added, and the T4 wording is fixed.
- **I2, applied.** The hand-offs are retargeted:
  - SQR-012 (cell-details direction);
  - SQR-013 (adjective forms not covered);
  - SQR-017 (abbreviations are its own keys);
  - WHL-018 (names);
  - SET-007 (settings by key);
  - XLS-005 / XLS-016.
- **I3, applied.** Criterion 1 evidence is restated: the guard prevents producing translated strings, typed enum fields hold only keys, and free-text fields are user content. A typed-field convention is added, and the audit Note lists what was inspected.
- **I4, applied.** The import scanner reads whole import / export statements from raw offsets of the cleaned source (double quotes, conditional alternatives, multi-line, block comments), and unit cases are added.
- **I5, applied.** The dependency check uses `dart pub deps --json` + `findForbiddenDependencies` (runtime closure). The mutation proof targets `shared_storage` (source and dependency), and the false "pure-Dart guard fails too" claim is removed.
- **I6, applied.** The Hebrew-script test is renamed and its scope is stated. The T3 exception to "not transliteration" is recorded in the decision record and in the L10-007 Notes.
- **M1, applied.** The kit.js block split and the lookbehind key regex are specified (`E` vs `NE`).
- **M2, applied.** The compile-fail wording and the rename mutation proof are fixed.
- **M3, applied.** The Body test pins `toJson()` and references `body_test.dart`.
- **M4, applied.** A non-exhaustive-switch proof (`ophiuchus`) is added.
- **M5, applied.** The decision record moves to Task 0 (first commit), with a TASKS.md §6 "Resolved" line.
- **M6, applied.** The scanner is split into `l10n_references.dart` + its unit tests, and far-ring `atAngle` cases are added.
- **M7, applied.** The expected key count is fixed, and `pubspec.lock` staging is noted.
- **M8, applied.** This section.

### Round 2: Approve after corrections (1 Critical, 2 Important, 8 Minor, 0 Needs user decision)

- **C1, applied.** Task 2's mutation proofs move to a new Step 7, after the commit. They regenerate after ARB edits, restore by exact path, and check that `git status` shows only `.fvmrc`. Restoring before the commit would have wiped the step's own work.
- **I1, applied.** Task 3's restore step names its paths and expected `git status`, and a Global Constraint forbids `git checkout .`, `git restore .` and `git stash`.
- **I2, applied.** The SQR-012 hand-off warns that its Hebrew highlight-line sentence needs the adjective forms, and the Facts are corrected.
- **M1, applied.** The TASKS.md §6.2 bullet is spelled out.
- **M2, applied.** The legend task is named ZOD-SQR-018.
- **M3, applied.** A positive control is added for the dependency check.
- **M4, applied.** The kit.js regex flags are stated.
- **M5, applied.** `atAngle`'s doc comment covers its range and orientation assumptions.
- **M6, applied.** Hand-offs are added for WHL-002, WHL-009 and WHL-020.
- **M7, applied.** Task 0 follows the reviewed-plan commit and sets both tasks to In Progress.
- **M8, applied.** The body descriptions cite the L10-013 exception.
- **Open items:** none.
