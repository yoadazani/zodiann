# ZOD-L10-001 ARB Files and gen-l10n Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every user-visible string in the app flows from translation keys. One shared pair of files, `app_en.arb` and `app_he.arb`, feeds Flutter's `gen-l10n`. The generated `ZodiannLocalizations` is exported from `package:shared_ui`, so the app and every feature package can read it. The app shell is wired to it. The workspace gates fail when a key exists in one language file but not the other (criterion 1), and when shipped UI code passes a string literal to `Text()` (criterion 2).

**Architecture:**
- **ARB files and generator config** live in `packages/shared_ui` (`l10n.yaml`, `lib/l10n/app_{en,he}.arb`, `generate: true`). The product owner chose this on 2026-11-14 (N1): the app depends on `shared_ui`, and feature packages can depend on it (they can't import the app). Screen tasks add the `shared_ui` dependency when they first need it.
  - The generated Dart (`lib/l10n/zodiann_localizations*.dart`, class `ZodiannLocalizations`) is **committed**. A freshness check (`melos run l10n:check`, first in `lint`) regenerates it and fails if anything changed.
- **`ZodiannApp` delegates:** it takes `ZodiannLocalizations.delegate` plus material_ui's `GlobalMaterialLocalizations.delegates`. It does **not** use the generated `localizationsDelegates`, because that list references the deprecated `flutter_localizations` delegates.
  - `supportedLocales` comes from `ZodiannLocalizations.supportedLocales`.
  - The window title comes from `onGenerateTitle`.
- **Two root architecture tests** run on every `melos run test`, beside the existing guards in `test/architecture/`:
  - **key parity** across every `app_*.arb`;
  - **no string literal** in `Text(` / `SelectableText(` / `TextSpan(text:`, in shipped `lib/` code (N2).
  - The `Text()` scanner reuses the comment and string cleaner and the argument-list reader from `dimension_literals.dart`. Both move to a shared file.

**Tech Stack:** Flutter 3.50.0 / Dart 3.14.0 (FVM), `flutter_localizations` (SDK) + `intl ^0.20.3` (newly added to `shared_ui`; the app already declares both), `gen-l10n`, `package:test` for root tests, Melos 8. No new third-party packages.

**Spec:** `assets/zodiann-specification.md` L-1 (a new language needs only a new translation file), L-2 (English fallback), L-8 (keys, separate files per language, a test fails on a missing key), and the package layout (lines 537–541: `feature_wheel`, `feature_square`). Task: `docs/development/localization/ZOD-L10-001-set-up-arb-files-and-gen-l10n.md`.

## Product-owner decisions (2026-11-14)

- **N1: Localizations live in `shared_ui`.** It holds one ARB set, and `ZodiannLocalizations` is exported from `package:shared_ui`. `shared_ui` gains `flutter_localizations` and `intl`.
  - Affects every screen task: WHL-*, SQR-*, SET-*, NAV-*, SAV-* and ABT-*.
  - XLS-016's `shared_export_xlsx` receives localized strings from its caller, or depends on `shared_ui` if it is a Flutter package. That task decides.
- **N2: Criterion 2 covers shipped UI code.** The guard scans the `lib/` of every non-pure-Dart member. `test/`, `integration_test/` and test harnesses may use literal text, for example the ten `Text('…')` calls in `packages/shared_ui/test/support/typography_specimen.dart`. It will be recorded in the task file's Notes (Task 5).

## Facts established while planning (2026-11-14)

All of the following were verified with throwaway prototypes (in the app and in `shared_ui`) on this SDK, which were then reverted:

- **No synthetic package.** `synthetic-package: true` is a tool exit in Flutter 3.50. `gen-l10n` writes into `arb-dir`, and it refuses to run without `flutter: generate: true` in the pubspec. `shared_ui`'s existing `flutter:` section (fonts) takes the flag alongside.
- **Deprecated delegates in the output.** The generated main file imports `package:flutter_localizations` and lists the deprecated (since 3.47) `GlobalMaterialLocalizations.delegate` and `GlobalCupertinoLocalizations.delegate`. `--fatal-infos` reports two `deprecated_member_use` infos, which the generated `// ignore_for_file: type=lint` doesn't cover.
  - `header: "// ignore_for_file: deprecated_member_use"` fixes this.
  - With `format: true`, `dart format --set-exit-if-changed` passes. This was verified in `shared_ui` with `output-class: ZodiannLocalizations`.
- **`gen-l10n` exits 0 on a missing Hebrew key.** It prints `"he": 1 untranslated message(s)`, and the Hebrew class silently returns the English text. Only a separate test can make a missing key fail.
- **Regeneration:**
  - `flutter test` does **not** regenerate.
  - `flutter pub get` at the workspace root does.
  - `melos run lint` / `test` do not.
  - `gen-l10n` is deterministic: a re-run on an unchanged ARB leaves identical output.
- **Line endings.** `core.autocrlf=true` checks files out with CRLF, and `gen-l10n` writes LF. The freshness check normalises line endings.
- **Generated locales.** The generated `supportedLocales` is `[Locale('en'), Locale('he')]`, with English first. Flutter's default resolution therefore keeps falling back to English (L-2).
- **App name.** It is "Zodiann" in both languages: `design-reference/zodiann/_source/kit.js:17` and `:84` have `app: 'Zodiann'` for both en and he.
- **Window title.** `MaterialApp.title` defaults to `''`. With `onGenerateTitle` set, `WidgetsApp` builds `Title(title: onGenerateTitle(context))`, so `find.byType(Title)` reads it.
- **There is no CI workflow yet** (open item 3).
  - `.github/` doesn't exist, FND-004 is Not Started, and PRs run only GitGuardian.
  - As with every earlier guard, "fails CI" means failing `melos run lint` / `melos run test`, which FND-004's pipeline will run.
- **Overlap with L10-014** (open item 2). L10-014 asks for a named test that diffs the key sets.
  - Criterion 1 can't be met without one, so this task builds it, with the missing keys listed per file.
  - L10-014 later confirms the test against its own criterion inside FND-004's pipeline. Its scope isn't changed.

## Global Constraints

- **No hard-coded UI text (L-8):** every user-visible string comes from `ZodiannLocalizations.of(context)`.
- **Separate files:** `app_en.arb` (template) and `app_he.arb`, both in `packages/shared_ui/lib/l10n/`. A future language is one more `app_<code>.arb` (L-1). The parity test and the generated `supportedLocales` pick it up with no code change.
- **ARB metadata:** every template key carries an `@key` entry with a `description` (`required-resource-attributes: true`). Hebrew files carry no metadata.
- **Key names:** camelCase message keys, starting with a letter. `@@locale` matches the filename suffix.
- **Analysis:** generated files stay under `dart analyze --fatal-infos`. The only suppression is the `deprecated_member_use` header.
- **Imports:** only the generated file imports `package:flutter_localizations`. Hand-written code never does (FND-005). Material delegates come from `package:material_ui/material_ui.dart`.
- **Delegates:** always `const [ZodiannLocalizations.delegate, ...GlobalMaterialLocalizations.delegates]` (material_ui). Never `ZodiannLocalizations.localizationsDelegates`: it lists `flutter_localizations`' deprecated delegates, which register a different `MaterialLocalizations` type than material_ui's widgets read.
- **Commits:** never stage `.fvmrc`.
- **Commands:** run `export PATH="$PATH:$LOCALAPPDATA/Pub/Cache/bin"` first. The gates are `cmd //c "fvm dart run melos run lint && fvm dart run melos run test"`.

## Out of scope

- First-launch detection and persistence (L10-002) and the in-app override (L10-003). Flutter's default device-locale resolution stays.
- Real screen copy, sign and body names (L10-007, L10-013), ICU plurals (L10-008), date and number formats (L10-010–012), and bidi isolation (L10-006). Only `appTitle` is added.
- Switching `shared_ui`'s test harnesses to the new delegates. Their explicit RTL `Directionality` keeps working.
- A GitHub Actions pipeline (FND-004).
- Scanning `Semantics(label:)`, `Tooltip(message:)`, `semanticsLabel:`, `hintText:` and similar. These stay review-enforced, as documented in the scanner.

## Review Focus

1. **A key added only to `app_he.arb`** (the reverse direction) must fail too, naming the file and key. Task 3.
2. **An ARB edit without regenerating** must make `l10n:check` fail and name the stale file, even on a CRLF checkout. Task 2.
3. **A literal in a `Text` call that isn't on one line** must be flagged: multi-line, `const`, prefixed, raw, triple-quoted, interpolated, a named argument first, or adjacent strings. Lookalikes must not be flagged, and the scanner must not read past the call's closing parenthesis. Task 4.
4. **Swapping the delegate list must not lose Hebrew Material localizations,** nor change the English fallback for an unsupported locale. Task 1.
   - While `appTitle` is "Zodiann" in both languages, a hard-coded `onGenerateTitle: (_) => 'Zodiann'` can't be told apart by tests from the localized one. Code review checks it.
5. **A malformed or mislabelled ARB** (invalid JSON, a non-object top level, a `@@locale` that doesn't match its filename) must fail a named test that names the file, not crash suite loading. A third `app_fr.arb` is included automatically. Task 3.

---

### Task 1: ARB files, gen-l10n and app wiring

**Files:**
- Create: `packages/shared_ui/l10n.yaml`, `packages/shared_ui/lib/l10n/app_en.arb`, `packages/shared_ui/lib/l10n/app_he.arb`
- Generated and committed: `packages/shared_ui/lib/l10n/zodiann_localizations.dart`, `zodiann_localizations_en.dart`, `zodiann_localizations_he.dart`
- Modify:
  - `packages/shared_ui/pubspec.yaml`: add `flutter_localizations: {sdk: flutter}` and `intl: ^0.20.3` to dependencies, and `generate: true` under the existing `flutter:`;
  - `packages/shared_ui/lib/shared_ui.dart`: add `export 'l10n/zodiann_localizations.dart';`;
  - `apps/astro_mobile/lib/src/app.dart`;
  - `packages/shared_ui/test/support/button_harness.dart` (comment only): line 4 becomes "the harness registers no localization delegates, so `locale: Locale('he')` alone…";
  - the root `pubspec.lock`, only if `flutter pub get` changes it.
- Test:
  - `packages/shared_ui/test/l10n/zodiann_localizations_test.dart` (new);
  - `apps/astro_mobile/test/l10n_test.dart` (new);
  - `apps/astro_mobile/test/app_shell_test.dart`, unchanged and still green.

**Interfaces:**
- Produces: `ZodiannLocalizations`, exported by `package:shared_ui/shared_ui.dart`:
  - `ZodiannLocalizations.of(context)` is non-null;
  - `.appTitle`, `.localeName`, `ZodiannLocalizations.delegate`, `ZodiannLocalizations.supportedLocales`.

- [ ] **Step 1: Write the failing tests.**
  - **`shared_ui`'s `zodiann_localizations_test.dart`** pumps a `MaterialApp` with `locale:` set, `localizationsDelegates: const [ZodiannLocalizations.delegate, ...GlobalMaterialLocalizations.delegates]` and `supportedLocales: ZodiannLocalizations.supportedLocales`.
    - `'en resolves English strings'`: `localeName == 'en'` and `appTitle == 'Zodiann'`.
    - `'he resolves Hebrew strings'`: `localeName == 'he'` and `appTitle == 'Zodiann'`.
    - `'supportedLocales are en then he'`: equals `[Locale('en'), Locale('he')]`.
  - **The app's `l10n_test.dart`** pumps `ProviderScope(child: ZodiannApp())` with `tester.platformDispatcher.localesTestValue` (and `addTearDown(clearAllTestValues)`), like `app_shell_test`'s `_pumpShell`.
    - `'English device: ZodiannLocalizations resolves to en'`: `localeName == 'en'`, `appTitle == 'Zodiann'`.
    - `'Hebrew device: ZodiannLocalizations resolves to he'` (`Locale('he', 'IL')`): `localeName == 'he'`.
    - `'unsupported device locale: falls back to en'` (`Locale('fr')`): `localeName == 'en'`.
    - `'supportedLocales come from the ARB files'`: `MaterialApp.supportedLocales` equals `ZodiannLocalizations.supportedLocales`.
    - `'the window title is the localized app title'`:
      - `tester.widget<Title>(find.byType(Title)).title == 'Zodiann'`, and it equals `ZodiannLocalizations.of(ctx).appTitle`;
      - `MaterialApp.onGenerateTitle` is non-null;
      - `MaterialApp.title` is left at its default `''`.
    - `'the delegates are ZodiannLocalizations plus material_ui\'s Global delegates'`: `MaterialApp.localizationsDelegates` equals `[ZodiannLocalizations.delegate, ...GlobalMaterialLocalizations.delegates]`.
- [ ] **Step 2: Run them to verify they fail**
  - Run: `cmd //c "cd packages\\shared_ui && fvm flutter test test/l10n"` and `cmd //c "cd apps\\astro_mobile && fvm flutter test test/l10n_test.dart"`.
  - Expected: both FAIL to compile, because `ZodiannLocalizations` isn't defined.
- [ ] **Step 3: Add the config and the ARB files, then generate**
  - **`l10n.yaml`** has exactly these keys: `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-localization-file: zodiann_localizations.dart`, `output-class: ZodiannLocalizations`, `nullable-getter: false`, `required-resource-attributes: true`, `format: true`, `header: "// ignore_for_file: deprecated_member_use"`.
  - **`app_en.arb`:** `{"@@locale": "en", "appTitle": "Zodiann", "@appTitle": {"description": "The app name: window and task-switcher title. Not translated (design kit: app: 'Zodiann' in both languages)."}}`.
  - **`app_he.arb`:** `{"@@locale": "he", "appTitle": "Zodiann"}`.
  - **Generate:** `cmd //c "fvm flutter pub get && cd packages\\shared_ui && fvm flutter gen-l10n"`. Expected: three generated files, and no "untranslated" message.
  - **Export** the generated file from `shared_ui.dart`.
- [ ] **Step 4: Wire `ZodiannApp`** (`lib/src/app.dart`):
  - `localizationsDelegates: const [ZodiannLocalizations.delegate, ...GlobalMaterialLocalizations.delegates]`;
  - `supportedLocales: ZodiannLocalizations.supportedLocales`;
  - `onGenerateTitle: (context) => ZodiannLocalizations.of(context).appTitle`.

  Replace the "Placeholder until ZOD-L10-001" comment with a one-line note: English first in the generated list keeps the L-2 fallback, and the generated `localizationsDelegates` isn't used because it lists the deprecated `flutter_localizations` delegates.
- [ ] **Step 5: Run the tests and analyze**
  - Run: `cmd //c "cd packages\\shared_ui && fvm flutter test && cd ..\\..\\apps\\astro_mobile && fvm flutter test"`, then `cmd //c "fvm dart run melos run analyze && fvm dart run melos run format:check"`.
  - Expected: everything passes, including every existing `shared_ui` test and every `app_shell_test` test (Hebrew Material tooltip, French → English, no `Text` in the shell).
- [ ] **Step 6: Commit**: `feat(ZOD-L10-001): shared ARB files, gen-l10n and ZodiannLocalizations wiring` (the files above and the generated output; stage `pubspec.lock` only if `git status` shows it changed).

### Task 2: Generated-code freshness check

**Files:**
- Create: `tool/l10n_snapshot.dart` (pure functions), `tool/check_l10n.dart` (the script)
- Modify: the root `pubspec.yaml` (`melos.scripts`):
  - add `l10n:check`;
  - put it **first** in `lint`'s steps;
  - change the `lint` description to `l10n:check + analyze + format:check.`
- Test: `test/tool/l10n_snapshot_test.dart`

**Interfaces:**
- Produces:
  - `Map<String, String> snapshotGenerated(Directory l10nDir)` maps each `*.dart` basename to its content with `\r\n` replaced by `\n`.
  - `List<String> snapshotDiff(Map<String, String> before, Map<String, String> after)` returns `changed: <name>` / `added: <name>` / `removed: <name>`, sorted, and empty when the snapshots are equal.
  - `String flutterExecutable({required Map<String, String> environment, required String resolvedDartExecutable, required bool isWindows})`:
    - if `MELOS_SDK_PATH` is set, it returns `<MELOS_SDK_PATH>/bin/flutter`;
    - otherwise it returns the `bin/flutter` of the SDK whose `bin/cache/dart-sdk/bin/dart` is running, four directories above the Dart executable;
    - on Windows it adds a `.bat` suffix.

    The global Flutter on `PATH` is never used.

- [ ] **Step 1: Write the failing test** `test/tool/l10n_snapshot_test.dart`:
  - equal maps → `[]`;
  - a changed file → `['changed: a.dart']`;
  - an added file → `['added: b.dart']`;
  - a removed file → `['removed: b.dart']`;
  - `snapshotGenerated` on a temp dir holding `a.dart` (`"x\r\ny\r\n"`) and `app_en.arb` equals `{'a.dart': 'x\ny\n'}`;
  - CRLF vs LF of the same text → `[]`;
  - `flutterExecutable(environment: {'MELOS_SDK_PATH': '/sdk'}, resolvedDartExecutable: '/x/bin/cache/dart-sdk/bin/dart', isWindows: false) == '/sdk/bin/flutter'`;
  - without `MELOS_SDK_PATH`, the same Dart path gives `'/x/bin/flutter'`;
  - `MELOS_SDK_PATH: 'C:\sdk'` with `isWindows: true` gives `C:\sdk\bin\flutter.bat`;
  - with `isWindows: true` and `C:\x\bin\cache\dart-sdk\bin\dart.exe`, it gives `C:\x\bin\flutter.bat`. Compare with `p`-free normalisation: replace `\` with `/` before the assertion.
- [ ] **Step 2: Run it to verify it fails**
  - Run: `cmd //c "fvm dart test test/tool"`
  - Expected: a compile FAIL, because `tool/l10n_snapshot.dart` doesn't exist.
- [ ] **Step 3: Implement** the three functions in `tool/l10n_snapshot.dart`, then write `tool/check_l10n.dart`:
  1. snapshot `packages/shared_ui/lib/l10n`;
  2. `Process.run(flutterExecutable(...), ['gen-l10n'], workingDirectory: 'packages/shared_ui')`, exiting 1 with its output on failure;
  3. snapshot again;
  4. on a non-empty diff, print `Generated localizations were stale and have been regenerated; commit them:` and the lines, and exit 1. Otherwise print `Generated localizations are up to date.`

  The Melos script is `l10n:check: {description: Fail if the committed gen-l10n output is stale (ZOD-L10-001)., run: dart run tool/check_l10n.dart}`.
- [ ] **Step 4: Run the tests, then the mutation proof**
  - Run `cmd //c "fvm dart test test/tool"` → PASS.
  - Run `cmd //c "fvm dart run melos run l10n:check"` → "up to date", exit 0.
  - **Mutation proof:** change `app_he.arb`'s `appTitle` to `"Zodiann!"` without regenerating, then run `l10n:check`. Expected: exit 1 with `changed: zodiann_localizations_he.dart`. Restore both the ARB and the generated files with `git checkout -- packages/shared_ui/lib/l10n/`, then run `l10n:check` again. Expected: exit 0, "up to date", and `git status --short packages/shared_ui` prints nothing.
- [ ] **Step 5: Commit**: `build(ZOD-L10-001): fail lint when generated localizations are stale`.

### Task 3: Key-parity test (criterion 1)

**Files:**
- Create: `test/architecture/arb_keys.dart` (helpers), `test/architecture/arb_keys_test.dart` (helper unit tests), `test/architecture/l10n_key_parity_test.dart` (the guard)

**Interfaces:**
- Produces:
  - `Set<String> arbMessageKeys(String json)`: the top-level keys that don't start with `@`. It throws `FormatException` on invalid JSON or a non-object top level.
  - `String? arbLocale(String json)`: the `@@locale` value, or null.
  - `List<String> keyParityProblems(String template, Map<String, Set<String>> keysByFile)` returns one line per problem, sorted by file, with keys sorted within a line. Lines look like `app_he.arb is missing: k1, k2`, and `app_he.arb has keys not in app_en.arb: k3`.

- [ ] **Step 1: Write the failing helper tests** `arb_keys_test.dart`:
  - `arbMessageKeys('{"@@locale":"en","a":"A","@a":{},"b":"B"}') == {'a','b'}`;
  - invalid JSON throws `FormatException`;
  - `arbMessageKeys('[1]')` throws `FormatException`;
  - `arbLocale` of the first string is `'en'`, and `arbLocale('{"a":"A"}')` is null;
  - `keyParityProblems('app_en.arb', {'app_en.arb': {'a','b'}, 'app_he.arb': {'a'}}) == ['app_he.arb is missing: b']`;
  - he `{'a','b','c'}` → `['app_he.arb has keys not in app_en.arb: c']`;
  - both directions at once give two lines;
  - equal sets → `[]`;
  - a third `app_fr.arb` missing `a` is reported.
- [ ] **Step 2: Write the guard** `l10n_key_parity_test.dart`.
  - **Config:** it reads `packages/shared_ui/l10n.yaml` for `arb-dir` and `template-arb-file` (line regex, like the `shared_ui` tests' kit.css reads), then globs `<arb-dir>/app_*.arb`.
  - **Parsing:** files are read and parsed inside the test bodies (or `setUpAll`). A `FormatException` becomes a test failure naming the file: `'<file> is not a valid ARB JSON object: <message>'`.
  - **Tests:**
    - `'the template and at least en + he exist'`;
    - `'every ARB file is a valid JSON object'`;
    - `'every ARB file\'s @@locale matches its filename'`;
    - `'every language has exactly the template\'s keys'`: `keyParityProblems` is empty, with `reason` set to the problems joined by newlines;
    - `'every template key has @key metadata with a description'`.
- [ ] **Step 3: Run them to verify they fail**
  - Run: `cmd //c "fvm dart test test/architecture/arb_keys_test.dart test/architecture/l10n_key_parity_test.dart"`
  - Expected: a compile FAIL, because `arb_keys.dart` doesn't exist.
- [ ] **Step 4: Implement `arb_keys.dart`** with `dart:convert` `jsonDecode`, throwing `FormatException` when the result isn't a `Map<String, dynamic>`.
- [ ] **Step 5: Run them, then the mutation proofs (criterion 1)**
  - Run the step 3 command → PASS.
  - **(a)** Add `"probe": "Probe", "@probe": {"description": "x"}` to `app_en.arb` only. Expected: `app_he.arb is missing: probe`.
  - **(b)** Move `"probe"` to `app_he.arb` only. Expected: `app_he.arb has keys not in app_en.arb: probe`.
  - **(c)** Set `app_he.arb`'s `@@locale` to `"en"`. Expected: the locale test fails.
  - **(d)** Delete the closing `}` of `app_he.arb`. Expected: the parity guard fails naming `app_he.arb`.
  - **(e)** Remove `@@locale` from `app_he.arb`. Expected: the locale test fails naming `app_he.arb`.
  - After each one, restore with `git checkout -- packages/shared_ui/lib/l10n/`. Finally run `cmd //c "fvm dart run melos run l10n:check"`: exit 0.
- [ ] **Step 6: Commit**: `test(ZOD-L10-001): fail when a translation key is missing in either language`.

### Task 4: No string literal in `Text()` (criterion 2)

**Files:**
- Create: `test/architecture/dart_source.dart` (shared helpers), `test/architecture/text_literals.dart` (scanner), `test/architecture/text_literals_test.dart` (scanner unit tests), `test/architecture/no_text_literals_test.dart` (the walk)
- Modify: `test/architecture/dimension_literals.dart` (move `_clean` and `_topLevel` out and import them; no behaviour change)

**Interfaces:**
- Produces:
  - `String cleanDartSource(String source)` and `(int, String)? topLevelArguments(String code, int open)`: the existing `_clean` and `_topLevel`, moved to `dart_source.dart` and made public, with the same output.
  - `final class TextLiteral { final int line; final String call; }`:
    - `call` is the matched name without the parenthesis (`Text`, `SelectableText` or `TextSpan`), so `m.Text('x')` reports `Text`;
    - `line` is the 1-based line of the call name, so `TextSpan(style: s,\n text: 'x')` reports line 1.
  - `List<TextLiteral> findTextLiterals(String source)`: in the cleaned source, it finds `\b(Text|SelectableText|TextSpan)\s*\(` and reads only that call's argument list with `topLevelArguments`. It flags the call when either of these holds:
    - for `Text` / `SelectableText`, a positional (unnamed) argument begins with an optional `r` and a quote;
    - for `TextSpan`, the named argument `text:` begins that way.

    The doc comment lists the gaps: conditional expressions (`Text(c ? 'a' : 'b')`), `??` fallbacks (`Text(x ?? 'Fallback')`), string variables, and the out-of-scope named labels.
- **Scope (N2):** shipped UI source only, meaning the `lib/` of every non-pure-Dart member, generated `lib/l10n/` included. `test/`, `integration_test/` and harness code under `test/support/` may use literal text.

- [ ] **Step 1: Write the failing scanner tests** `text_literals_test.dart`:
  - **Flagged** (one hit, with the right line and call): `Text('Save')`; `const Text("Save")`; `Text(\n  'Save',\n)` (line 1); `Text(r'x')`; `Text('''x''')`; `Text('$n cells')`; `Text('a' 'b')`; `Text(key: k, 'Save')`; `m.Text('x')` (call `Text`); `SelectableText('x')`; `TextSpan(text: 'x')`; `TextSpan(style: s,\n text: 'x')` (line 1); `Text.rich(TextSpan(text: 'x'))` (one hit, `TextSpan`).
  - **Not flagged:** `Text(label)`; `Text(ZodiannLocalizations.of(context).appTitle)`; `Text(widget.label, maxLines: 1)`; `TextStyle(fontFamily: 'Plex')`; `MyText('x')`; `// Text('x')`; `/* Text('x') */`; `final s = "Text('x')";`; `Text(label, semanticsLabel: 'x')`; `TextSpan(children: [a])`; `Row(children: [Text(label), Tooltip(message: 'x')])`; `Text(label); foo('x');`; `Text(rows.first)`.
  - **The moved helpers are unchanged:** `dimension_literals_test.dart` still passes. It is the regression suite for both.
- [ ] **Step 2: Write the walk** `no_text_literals_test.dart`, mirroring `no_magic_dimensions_test.dart`. It covers every `apps/*/lib` and `packages/*/lib` `.dart` file outside the pure-Dart members (`astro_core`, `gann_core`, `ephemeris_swiss`, `ephemeris_astronomy`, as in `sentence_case_test.dart`). Tests:
  - `'no shipped UI source passes a string literal to Text, SelectableText or TextSpan'`: the hits are empty, and the reason lists `path:line call`;
  - `'scans the app, shared_ui and the generated localizations'`: the scanned paths include `apps/astro_mobile/lib/src/app.dart`, `packages/shared_ui/lib/src/widgets/zodiann_button.dart` and `packages/shared_ui/lib/l10n/zodiann_localizations.dart`, and there are at least 10.
- [ ] **Step 3: Run them to verify they fail**
  - Run: `cmd //c "fvm dart test test/architecture/text_literals_test.dart test/architecture/no_text_literals_test.dart"`
  - Expected: a compile FAIL, because `text_literals.dart` doesn't exist.
- [ ] **Step 4: Implement it.** Move the helpers, update `dimension_literals.dart` to import them, and write `findTextLiterals`.
- [ ] **Step 5: Run the architecture suite, then the mutation proof (criterion 2)**
  - Run: `cmd //c "fvm dart test test/architecture"` → all PASS.
  - **Mutation proof:** change `ShellHome.build` to `const Scaffold(body: Text('Hi'))`. Expected: the walk fails naming `apps/astro_mobile/lib/src/app.dart:<line> Text`. Revert.
- [ ] **Step 6: Commit**: `test(ZOD-L10-001): forbid string literals in Text, SelectableText and TextSpan`.

### Task 5: Review and close-out

**Files:**
- Modify:
  - the L10-001 task file (Status Done, both criteria checked, and Notes recording N1, N2 and criterion 1's gate meaning);
  - `docs/development/TASKS.md`;
  - `docs/PROGRESS.md`. Reconcile PR #21 as merged (`3b6f6b9`) and drop it from unmerged dependencies; add the L10-001 row, the conventions, Technical Decisions (N1, N2, committed generated code) and verification.
  - Hand-off Notes in L10-014, FND-004, L10-002, L10-003, L10-007, L10-008 and XLS-016.

- [ ] **Step 1: Run the whole-branch review** (`requesting-code-review`, most capable model) with this plan's Review Focus. Fix Critical / Important findings test-first, and record Minor ones as deferred.
- [ ] **Step 2: Run the full gates**: `cmd //c "fvm dart run melos run lint && fvm dart run melos run test"`. Expected: both exit 0, with `l10n:check` reporting "up to date" first in `lint`.
- [ ] **Step 3: Write the docs.**
  - **PROGRESS conventions → Localization:** how to add a string:
    1. add the key and its `@key` description to `packages/shared_ui/lib/l10n/app_en.arb`, and the key to `app_he.arb`;
    2. run `fvm flutter gen-l10n` in `packages/shared_ui` (or the root `flutter pub get`);
    3. commit the ARB and generated files;
    4. read the string with `ZodiannLocalizations.of(context).<key>`.
    5. register delegates as `const [ZodiannLocalizations.delegate, ...GlobalMaterialLocalizations.delegates]`, never the generated `localizationsDelegates`. It registers a different `MaterialLocalizations` type and loses the Hebrew Material strings.

    Generic `shared_ui` components (`ZodiannButton`) still take their label as a parameter. Non-translatable glyph text comes from `ZodiannGlyphs` (a non-literal), never a literal.
  - **Hand-offs:**
    - **L10-014:** the parity test exists and lists missing keys per file. L10-014 confirms it inside FND-004's pipeline.
    - **FND-004:** CI runs `melos run lint` (including `l10n:check`, which needs the pinned Flutter SDK) and `melos run test`.
    - **L10-002 / L10-003:** `supportedLocales` is generated, with English first.
    - **L10-007 / L10-008:** new keys need `@key` descriptions, and plurals use ICU syntax. Screens and test harnesses register the delegate list from convention item 5.
    - **XLS-016:** strings come from `ZodiannLocalizations`, which lives in `shared_ui`. That task decides how `shared_export_xlsx` receives them.
- [ ] **Step 4: Commit, push and open the PR** per the workflow (`docs(ZOD-L10-001): close out ARB localization`). Then add the PR link to PROGRESS and push a follow-up commit.

## Open items for approval

1. **Commit the generated Dart, guarded by `l10n:check`** (recommended), rather than gitignoring it. `flutter test` doesn't regenerate, so even a gitignored setup would need the check.
2. **Criterion 1's test is built here.** L10-014 keeps its scope and re-confirms the test once CI exists.
3. **"Fails CI" means failing the workspace gates** until FND-004 adds a pipeline.

## Plan review

### Round 1: Needs user decision (2 Critical, 3 Important, 8 Minor, 2 Needs user decision)

- **C1, applied.** `MaterialApp.title` defaults to `''`, not null. The title test now checks `Title`, `onGenerateTitle` and the default `''`.
- **C2, applied.** The freshness mutation proof restores with `git checkout -- …/l10n/`; the second run then exits 0 with a clean tree.
- **I1, applied.** The tests now cover a non-object top level and a null `@@locale`. Parsing happens inside the tests, so a bad file fails a test that names it, and mutation proof (d) breaks the JSON.
- **I2, applied (N1 → `shared_ui`).** All paths are retargeted to `packages/shared_ui`, the class is `ZodiannLocalizations` (exported from `package:shared_ui`), and `shared_ui` gains `flutter_localizations` + `intl`. A `shared_ui` test and an XLS-016 hand-off are added. This was re-verified by a prototype in `shared_ui`: three files, analyze and format clean.
- **I3, applied (N2 → `lib/` only).** The scope is stated in Task 4 and recorded in the task Notes.
- **M1, applied.** The delegate list is `const`.
- **M2, applied.** `TextLiteral.call` and `line` are defined.
- **M3, applied.** Two negative cases cover reading past the closing parenthesis.
- **M4, applied.** `flutterExecutable` resolves the pinned SDK (`MELOS_SDK_PATH`, else the running Dart's SDK) and is unit-tested.
- **M5, applied.** `l10n:check` runs first in `lint`, and the description is updated.
- **M6, applied.** The kit.css reference is corrected.
- **M7, applied.** The `??` gap is documented, and a `ZodiannGlyphs` convention line is added.
- **M8, applied.** Review Focus 4 notes that tests can't detect a hard-coded title, so code review checks it.
- **N1 and N2:** the product owner decided on 2026-11-14 (see above).
- **N3–N5:** the plan's own open items 1–3 are still awaiting approval.

### Round 2: Needs user decision (only the plan's open items 1–3; 0 Critical, 1 Important, 7 Minor)

- **I1, applied.** A Delegates Global Constraint, convention item 5 and a note in the L10-007/008 and screen hand-off now forbid the generated `ZodiannLocalizations.localizationsDelegates`. It is now public through `package:shared_ui`, and it registers `flutter_localizations`' `MaterialLocalizations` type instead of material_ui's.
- **M1, applied.** Feature packages *can* depend on `shared_ui`; they don't yet.
- **M2, applied.** `button_harness.dart`'s stale comment is updated (comment only).
- **M3, applied.** A missing `@@locale` fails the locale test, and mutation proof (e) is added.
- **M4, applied.** `Text(rows.first)` is added as a not-flagged case.
- **M5, applied.** A Windows test with `MELOS_SDK_PATH` set is added.
- **M6, applied.** The N2 Notes entry is now described as written in Task 5.
- **M7, applied.** `pubspec.lock` is staged only if it changes.
- **Open items 1–3:** the reviewer recommends accepting all three. They are awaiting the product owner.
