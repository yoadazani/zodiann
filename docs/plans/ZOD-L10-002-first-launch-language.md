# ZOD-L10-002 First-Launch Language Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (sequential, native; see "Execution mode"). Steps use checkbox (`- [ ]`) syntax.

**Goal:** On the first launch the app takes its language from the device (Hebrew if the device asks for Hebrew, otherwise English), saves that choice, and never runs the detection again, so a later in-app choice (ZOD-L10-003) is never overwritten.

**Architecture:** A pure resolver turns the device's locale list into a supported language. A small bootstrap reads the saved language through `SettingsStore` (`packages/shared_storage`): a valid saved value wins, otherwise it detects, saves, and returns the detected language. `main()` runs the bootstrap before the first frame and hands the result to `ZodiannApp` through a provider, which sets `MaterialApp.locale`. Everything lives in the app layer (`apps/astro_mobile`); feature packages never import it. This is the first task that ships local storage in the running app, so it also settles Android Auto Backup for the language (decision O2).

**Tech Stack:** Flutter 3.50 / Dart 3.14, Riverpod, `shared_storage` (`SettingsStore`, `PrefsSettingsStore` over `shared_preferences`), `shared_ui` (`ZodiannLocalizations.supportedLocales`).

**Task:** `docs/development/localization/ZOD-L10-002-implement-first-launch-language-detection.md`. **Spec:** `assets/zodiann-specification.md` L-1, L-2, L-3, DATA-1, DATA-5, DATA-6. **Design:** none applies; the settings mockup `design-reference/zodiann/screens/04-settings_desktop_en_dark.png` shows the language control with **English** selected (not "System") on a device in the Asia/Jerusalem zone, which supports saving a concrete language.

## Facts established while planning (2026-11-23)

- **Spec:** L-2 "On first launch the language is set by the device language. If the device language is not supported, the default is English." L-3 the settings selector overrides the device language, applies immediately, "the choice is saved in the user settings". DATA-6 lists "language and theme choice" as local-only data.
- **Task text:** read the device locale **once** on first launch, "not on every launch, since a later in-app override (ZOD-L10-003) must persist and not be overwritten by this check again". Supported set `he`, `en`; anything else English.
- **Today:** `ZodiannApp` (`apps/astro_mobile/lib/src/app.dart`) sets no `locale`; Flutter's default resolution over `ZodiannLocalizations.supportedLocales` (generated, English first) decides on every launch, and `test/l10n_test.dart` proves that path. `main()` is a one-line `runApp`.
- **Storage:** `SettingsStore` / `SettingsKey<T>` / `PrefsSettingsStore(SharedPreferencesAsync, {reporter})` exist and are tested (ZOD-FND-006), but **no production code uses them**: `astro_mobile` takes `shared_storage` only as a **dev dependency** today (Task 0 changes this). `SharedPreferencesAsync()` asserts a registered platform instance, so it must not be built at import time (host tests have none). A read of a wrong-typed value throws `StorageException(corrupt)`; failures are also reported on the optional `StorageFailureReporter` (the stream ZOD-NFR-014's banner will listen to).
- **Android Auto Backup** is on by default (the manifest has no `allowBackup`), so a saved language would be uploaded to the user's Google backup, against DATA-5 and DATA-6; the owner item recorded in PROGRESS says to decide it before any task wires the stores into production. This is that task. iOS: `shared_preferences` writes `NSUserDefaults`, which iCloud and device backups include and which cannot be excluded per key; excluding the SQLite file is ZOD-DAT-002's.
- **Neighbours:** ZOD-SET-002's control is "System / עברית / English"; ZOD-L10-003 (override, depends on this task) and ZOD-SET-007 (`UserSettings`, whose spec field list does not name language) build on the stored value. ZOD-DAT-007 restores screens, not language.
- **Dart `Locale`:** `Locale('iw').languageCode` is `he` (dart:ui maps deprecated language subtags), which matters because Android has reported the legacy code.

## Product-owner decisions

None taken yet. The defaults below are what the plan implements unless the owner says otherwise (see "Open decisions").

## Decisions

- **D1. Match the device's languages in the order the user listed them** (`PlatformDispatcher.locales`): the first entry whose language is supported wins (`[fr, he]` gives Hebrew), region and script ignored (`he_IL`, `en_GB`, `zh_Hans`), nothing matched gives English. This is how the platforms and Flutter's default resolution treat the list. The alternative is the primary language only (`[fr, he]` gives English). *(O1)*
- **D2. The supported set is `ZodiannLocalizations.supportedLocales`** (L-1: adding a language is a new ARB file, not a code change); the fallback is `Locale('en')`, pinned by a test that it is in that set.
- **D3. Save the detected concrete language, `he` or `en`,** under `SettingsKey<String>('language')`, at first launch. A valid saved value always wins. Whether the settings control's "System" segment is a stored value or means "re-resolve now" is ZOD-L10-003 / ZOD-SET-002's call; the key and its two values are this task's contract and the plan's Task 5 records the note on both. *(O3)*
- **D4. An invalid saved value is not a choice:** a value outside the supported set, or one of the wrong type (`StorageException(corrupt)`), is treated as a first launch and overwritten with the detected language.
- **D5. Storage failures never stop the app.** A failed read (storage unavailable) resolves from the device and does **not** write; a failed write still returns the detected language (the next launch detects again, which is correct because nothing was saved). Failures are already reported by `PrefsSettingsStore`; the banner is ZOD-NFR-014's.
- **D6. Resolve before the first frame.** `main()` awaits the bootstrap and passes the result through a provider override, so the app never shows the wrong language first. `appLocaleProvider` defaults to `null` (follow the device, as today) so existing tests that pump `ZodiannApp` without overrides keep their meaning; a test pins that `main()` runs the bootstrap, since a null default would otherwise hide a `main()` that forgets it.
- **D7. Android Auto Backup off:** `android:allowBackup="false"` on `<application>`, pinned by a test; nothing is uploaded to the Google backup. iOS stays as a recorded, unverified limit. *(O2)*
- **D8. `shared_storage` and `shared_preferences` become runtime dependencies of `astro_mobile`** (both are dev dependencies today; `main()` imports `SharedPreferencesAsync`, which `shared_storage` does not re-export, and `depend_on_referenced_packages` would fail otherwise), and `shared_preferences_platform_interface` becomes a dev dependency (the tests use its in-memory platform). Only `SettingsStore` code runs; no `SquareStore` code does. The no-network and dependency-closure guards must stay green, and the third-party inventory is re-checked and edited (certain, not conditional: its own text says to re-check when `shared_storage` becomes a regular dependency).

## Design (API)

```dart
// apps/astro_mobile/lib/src/localization/language.dart
/// The device's languages in preference order -> a supported language.
Locale resolveDeviceLanguage(List<Locale> deviceLocales, List<Locale> supported);

/// The saved key.
const SettingsKey<String> languageKey = SettingsKey<String>('language');

/// A valid saved language, else detect, save and return the detected one.
Future<Locale> loadOrDetectLanguage({
  required SettingsStore store,
  required List<Locale> deviceLocales,
  List<Locale>? supported,   // null: ZodiannLocalizations.supportedLocales
});

// apps/astro_mobile/lib/src/localization/app_locale_provider.dart
/// The language the app was started in; null follows the device.
final Provider<Locale?> appLocaleProvider = Provider<Locale?>((ref) => null);

// apps/astro_mobile/lib/src/bootstrap.dart
/// Everything `main()` binds before the first frame.
Future<List<Override>> bootstrapOverrides({
  required SettingsStore store,
  required List<Locale> deviceLocales,
});
```

- `ZodiannApp` passes `locale: ref.watch(appLocaleProvider)` to `MaterialApp.router`; the typography (`withZodiannScript`) and direction already follow the resolved locale.
- `main()` becomes `async`: `WidgetsFlutterBinding.ensureInitialized()`, build `PrefsSettingsStore(SharedPreferencesAsync())`, `await bootstrapOverrides(store: …, deviceLocales: PlatformDispatcher.instance.locales)`, then `runApp(ProviderScope(overrides: …))`. `bootstrapOverrides` returns `[...appOverrides, appLocaleProvider.overrideWithValue(locale)]`.
- The `language` value is the language code (`he`, `en`); `ZOD-L10-003` turns `appLocaleProvider` into a notifier with a setter.

## Global Constraints

- Feature packages never import the app layer (PROGRESS conventions); this task adds app-layer code only plus one manifest attribute and one pubspec move.
- No network permission and no network package in any runtime closure (`test/architecture/no_network_test.dart`, DATA-7, DATA-8).
- Material types from `package:material_ui`, never `flutter/material.dart`; every user-visible string from `ZodiannLocalizations` (this task adds none).
- Run `test/architecture` with `dart test test/architecture`, never `flutter test`; Flutter commands as `fvm flutter …`, Melos as `fvm dart run melos …`; run long checks one process at a time.
- A root `fvm flutter pub get` deletes the generated l10n files in `packages/shared_ui/lib/l10n/`: restore with `git checkout -- packages/shared_ui/lib/l10n` and never commit the deletion.

## Review Focus

Inputs the task and spec imply and no acceptance criterion exercises; each has a test in the named task.

1. **Several device languages** (`[fr, he]`, `[he, en]`, `[en, he]`): the first supported entry in order wins. (Task 1)
2. **Region, script and legacy codes** (`he_IL`, `en_GB`, `zh_Hans_CN`, `iw`, an empty list): handled without a crash; empty and unsupported give English. (Task 1)
3. **A saved choice against a different device language, both ways** (saved `he` on an English device, saved `en` on a Hebrew device): the saved value wins and nothing is written. (Task 2)
4. **Corrupt or unsupported saved values** (`fr`, `''`, a stored `int`): re-detected and overwritten, no crash. (Task 2)
5. **Storage failing:** a read that throws `unavailable` resolves from the device and writes nothing; a write that throws still returns the detected language. (Task 2)
6. **The second launch with the first launch's data** (a real `PrefsSettingsStore` over an in-memory platform): the detection does not run again after the device language changed. (Task 3)
7. **A `main()` that forgets the bootstrap** (the null default would hide it). (Task 3)

## Out of scope

- The settings language control and the in-app override (ZOD-L10-003, ZOD-SET-002), including the meaning of "System".
- `UserSettings` (ZOD-SET-007), the storage-failure banner (ZOD-NFR-014), restoring screens (ZOD-DAT-007).
- Following later device-language changes while running or between launches (L-2 sets the language once; after the first launch only the selector changes it).
- iOS: `CFBundleLocalizations` in `Info.plist` and the iOS backup behaviour stay with the existing iOS items (no macOS access).

## File structure

- Create `apps/astro_mobile/lib/src/localization/language.dart`: `resolveDeviceLanguage`, `languageKey`, `loadOrDetectLanguage`.
- Create `apps/astro_mobile/lib/src/localization/app_locale_provider.dart`: `appLocaleProvider`.
- Create `apps/astro_mobile/lib/src/bootstrap.dart`: `bootstrapOverrides`.
- Modify `apps/astro_mobile/lib/main.dart` (async, bootstrap), `apps/astro_mobile/lib/src/app.dart` (`locale:`), `apps/astro_mobile/pubspec.yaml` (`shared_storage` and `shared_preferences` to `dependencies`, `shared_preferences_platform_interface: ^2.4.2` to `dev_dependencies`, and the "Dev only" and "No production wiring" comments), `apps/astro_mobile/android/app/src/main/AndroidManifest.xml` (`allowBackup`).
- Create tests: `apps/astro_mobile/test/localization/language_test.dart` (resolver and bootstrap with a fake store), `.../first_launch_test.dart` (real store, app wiring, `main()` guard), `.../manifest_backup_test.dart` or an extension of `platform_links_test.dart`, whichever already reads the manifest.
- Documentation: the task file (Completion notes), `docs/development/TASKS.md`, notes on ZOD-L10-003, ZOD-SET-002 and ZOD-SET-007, and the FND-006 Notes lines in the SET-007 and DAT-002 task files that mention Auto Backup; `docs/PROGRESS.md` (Architecture Conventions "Language", Technical Decisions, Verification, Git State, the Auto Backup item, the "No production wiring" statement in the FND-006 entry, and the record that PR #59 (ZOD-UI-010) merged as `513a088`); `docs/licensing/third-party-inventory.md` **(mandatory)**: every row whose Scope says "dev only today (dev dependency of apps/astro_mobile)" (`drift`, `shared_preferences*`, `sqlite3`, `stream_transform`), the scope sentence that says to re-check when `shared_storage` becomes a regular dependency (about line 144), the "drift (reserved row)" (about line 191, already stale) and the SQLite binary paragraph (state what Task 4 Step 4 measured: whether `libsqlite3.so` is in the release APK); compare the `fvm dart pub deps --json` closure of `astro_mobile` against sections 2 and 3 and update any other row whose scope changed.

## Tasks

### Task 0: Dependencies

**Files:** modify `apps/astro_mobile/pubspec.yaml`.

- [ ] **Step 1: Move** `shared_storage` and `shared_preferences: ^2.5.6` from `dev_dependencies` to `dependencies`, add `shared_preferences_platform_interface: ^2.4.2` to `dev_dependencies`, and rewrite the "Dev only" and "No production wiring" comments to say the app uses `SettingsStore` from first launch (ZOD-L10-002).
- [ ] **Step 2: Resolve:** from the root `fvm flutter pub get`, then `git checkout -- packages/shared_ui/lib/l10n` if the generated l10n files were deleted (never commit the deletion). Expected: resolves; `git diff --stat pubspec.lock` shows nothing (the workspace lock marks these packages `transitive` either way), and no lock change is committed; `fvm flutter analyze --fatal-infos` in `apps/astro_mobile` clean.
- [ ] **Step 3: Commit** `build(ZOD-L10-002): make local storage a runtime dependency of the app`. `shared_preferences_platform_interface` is used by the Task 2 and 3 tests, so it stays even though nothing imports it yet. The guard tests and the builds are in Task 4.

### Task 1: The resolver (TDD)

**Files:** create `lib/src/localization/language.dart` (resolver only); test `test/localization/language_test.dart`.

**Interfaces:** Produces `Locale resolveDeviceLanguage(List<Locale> deviceLocales, List<Locale> supported)`.

- [ ] **Step 1: Write the failing tests** (names, with assertions):
  - `a Hebrew device resolves to he` (`[Locale('he','IL')]` gives `Locale('he')`); `an English device resolves to en` (`en_GB`, `en_US`).
  - `an unsupported device resolves to en` (`[Locale('fr')]`, `[Locale.fromSubtags(languageCode:'zh', scriptCode:'Hans', countryCode:'CN')]`, `[Locale('ar')]`).
  - `the first supported language in the list wins`: `[fr, he]` gives `he`, `[he, en]` gives `he`, `[en, he]` gives `en`, `[fr, de, he]` gives `he`.
  - `the legacy Hebrew code iw resolves to he`: `[Locale('iw')]`.
  - `an empty list resolves to en`.
  - `the result is always one of the supported locales, never a region variant` (`he_IL` returns the `Locale('he')` instance from `supported`).
  - `English is a supported language` (pins D2: `Locale('en')` is in `ZodiannLocalizations.supportedLocales`).
- [ ] **Step 2: Run** `cd apps/astro_mobile; fvm flutter test test/localization/language_test.dart`; expected: a compile failure (`resolveDeviceLanguage` undefined).
- [ ] **Step 3: Implement** `resolveDeviceLanguage`: for each device locale in order, return the supported entry whose `languageCode` equals it; otherwise the supported `Locale('en')`.
- [ ] **Step 4: Run** the same command; all pass.
- [ ] **Step 5: Commit** `feat(ZOD-L10-002): resolve the device language`.

### Task 2: Load or detect, with a fake store (TDD)

**Files:** modify `language.dart`; test `language_test.dart` (a second group; the fake is an in-memory `SettingsStore` in `test/localization/support/`).

**Interfaces:** Consumes `SettingsStore`, `SettingsKey`, `StorageException`. Produces `languageKey`, `Future<Locale> loadOrDetectLanguage({required SettingsStore store, required List<Locale> deviceLocales, List<Locale>? supported})`.

- [ ] **Step 1: Write the failing tests:**
  - `first launch detects and saves`: empty store, `[he_IL]`, returns `he`, the store holds `'he'` under `language`, exactly one write.
  - `the second launch reads the saved value and writes nothing, whatever the device says`: saved `'he'`, device `[en]` returns `he`; saved `'en'`, device `[he]` returns `en`; zero writes both times.
  - `an unsupported saved value is re-detected and overwritten` (`'fr'`, `''`); `a wrong-typed saved value (an int) is re-detected and overwritten`, via a fake that throws `StorageException(corrupt)` on read.
  - `a failed read (unavailable) resolves from the device and does not write`.
  - `a failed write still returns the detected language` and does not throw.
  - `unexpected errors other than StorageException propagate` (a programming error is not swallowed).
- [ ] **Step 2: Run** `cd apps/astro_mobile; fvm flutter test test/localization/language_test.dart`; expected: failures per new test (`loadOrDetectLanguage` undefined).
- [ ] **Step 3: Implement** per D3 to D5, catching only `StorageException` (read: `unavailable` and `full` skip the write, `corrupt` and `unsupportedVersion` treat as unset and overwrite; write: swallow `StorageException`).
- [ ] **Step 4: Run** the same command; all pass; `cd apps/astro_mobile; fvm flutter analyze --fatal-infos`.
- [ ] **Step 5: Commit** `feat(ZOD-L10-002): detect the language once and save it`.

### Task 3: The wiring (TDD)

**Files:** create `app_locale_provider.dart`, `bootstrap.dart`; modify `app.dart`, `main.dart`; test `test/localization/first_launch_test.dart`.

**Interfaces:** Consumes Tasks 1 and 2, `appOverrides`. Produces `appLocaleProvider`, `bootstrapOverrides`.

- [ ] **Step 1: Write the failing tests:**
  - Setup: in `setUp` set `SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty()` (from `shared_preferences_platform_interface`, as `packages/shared_storage/test/prefs_settings_store_test.dart` does) **before** any `SharedPreferencesAsync()` is built; a "second launch" builds a **new** `PrefsSettingsStore(SharedPreferencesAsync())` over the same platform object (or `InMemorySharedPreferencesAsync.withData(...)`) and drops the first.
  - `a Hebrew device opens the app in Hebrew on first launch` (acceptance 1): a real `PrefsSettingsStore` over that in-memory platform, `bootstrapOverrides` with `[he_IL]`, pump `ZodiannApp`; `Localizations.localeOf` is `he`, `Directionality` is RTL, `ZodiannLocalizations.of(context).localeName` is `he`.
  - `a French device opens the app in English` (acceptance 2): `Locale('fr')`; locale `en`, LTR.
  - `the second launch never re-runs the detection` (acceptance 3): one store shared across two `bootstrapOverrides` calls; the first with `[he]`, the second with `[en]` after the "device language changed"; the second app is Hebrew, and a spy store shows no write on the second launch.
  - `an explicit choice stored before the launch survives`: store seeded `'en'`, device `[he]`; English. And `a saved he with a French device stays Hebrew` (pins that a stored value is never re-resolved).
  - `a failing store still opens the app in the device language`: a store whose `read` throws `StorageException(unavailable)`, device `[he]`; the app is Hebrew and nothing was written.
  - `ZodiannApp without overrides still follows the device` (the existing `l10n_test.dart` cases keep passing unchanged).
  - `main() runs the bootstrap`: `lib/main.dart` source **with its comments stripped** contains `ensureInitialized`, `await bootstrapOverrides(` and `overrides:` taking the result (the null default would hide a `main()` that forgets it; a comment must not satisfy the check).
- [ ] **Step 2: Run** `cd apps/astro_mobile; fvm flutter test test/localization/first_launch_test.dart`; expected: compile failure (`bootstrapOverrides`, `appLocaleProvider` undefined).
- [ ] **Step 3: Implement** the provider, `bootstrapOverrides`, the `locale:` line in `ZodiannApp`, and the async `main()` per "Design (API)". `main()` builds `PrefsSettingsStore(SharedPreferencesAsync())` itself, never at import time.
- [ ] **Step 4: Run** the same command and `cd apps/astro_mobile; fvm flutter test` (the whole app suite, including `l10n_test.dart` and the navigation tests); all pass; analyze clean.
- [ ] **Step 5: Commit** `feat(ZOD-L10-002): start the app in the detected language`.

### Task 4: Guards, builds and Android backup (TDD where testable)

**Files:** modify `AndroidManifest.xml`; test the manifest in `apps/astro_mobile/test/platform_links_test.dart` (it already parses the manifest); the dependency move itself was Task 0.

- [ ] **Step 1: Write the failing test** `the Android manifest turns Auto Backup off`: parses `android/app/src/main/AndroidManifest.xml` and asserts `<application android:allowBackup="false">`, and that neither `android:fullBackupContent` nor `android:dataExtractionRules` re-enables it. Run it; expected: it fails (the attribute is missing).
- [ ] **Step 2: Implement:** add `android:allowBackup="false"` to `<application>`.
- [ ] **Step 3: Run** the manifest test, then, one at a time, `fvm dart test test/architecture/no_network_test.dart test/architecture/dependency_closure_test.dart` from the root and `fvm dart test test/architecture`; all pass. Record which packages `shared_storage` adds to the release closure (`drift`, `sqlite3`, `shared_preferences` and its platform plugins, and their own dependencies; `fvm dart pub deps --json` filtered as the guards do) and that none is a network package; the result feeds the mandatory inventory edit in Task 5 Step 4.
- [ ] **Step 4: Build checks** (the biggest risk of the dependency move). From `apps/astro_mobile`: `fvm flutter build apk --debug` and `fvm flutter build apk --release` both succeed (the `sqlite3` build hook downloads a precompiled SQLite from GitHub at build time, now also for release, and CI builds will need that access). On the **release** APK: `aapt2 dump permissions` shows no `INTERNET`, `aapt2 dump xmltree <apk> AndroidManifest.xml` (the **merged** manifest, so a plugin manifest cannot re-enable it) shows `allowBackup` false, and `unzip -l` says whether `libsqlite3.so` is present (tree-shaking may drop it because `openSquareStore` is unused). Record the APK size either way.
- [ ] **Step 5: Commit** `feat(ZOD-L10-002): turn off Android Auto Backup`.

### Task 5: Verification, device check, review, documentation

- [ ] **Step 1: Device check, if an emulator or a device is available** (no device was authorized in earlier sessions; ask before touching a physical device): install the debug APK, set the device language to Hebrew, clear app data, launch (Hebrew, RTL); clear app data, set French, launch (English); with the app in Hebrew, switch the device to English and relaunch without clearing data (still Hebrew). Record each result; if no device is available, record "not verified on a device" and keep the widget-level proof.
- [ ] **Step 2: Verification:** from the root, one process at a time: `fvm dart run melos run lint`, `fvm dart run melos run test`; record counts, exit codes and the head commit.
- [ ] **Step 3: Whole-branch review** by a fresh reviewer (`requesting-code-review`), given the Review Focus; fix Critical and Important findings test-first.
- [ ] **Step 4: Documentation** after verification: the task file (tick the criteria, Completion notes), `TASKS.md`, notes on ZOD-L10-003 (turn `appLocaleProvider` into a notifier; the `language` key and `he` / `en` values; the meaning of `System`), ZOD-SET-002, and ZOD-SET-007 (**`UserSettings` must include or migrate the existing `language` key so it does not become a second source of truth**; L10-003 and L-3 say the choice is "saved in the user settings"), the FND-006 Notes lines in the SET-007 and DAT-002 task files (Auto Backup is now off on Android), `docs/PROGRESS.md` (Architecture Conventions "Language", Technical Decisions D1 to D8, Verification, Git State, close the Auto Backup owner item for Android and keep iOS open, correct the "No production wiring" statement, and record that PR #59 merged as `513a088`), and the licensing inventory (mandatory, see File structure).
- [ ] **Step 5: Commit, push, open the PR** per the workflow; record the PR link in `docs/PROGRESS.md` as a small follow-up commit.

## Acceptance criteria mapping

1. A device set to Hebrew opens the app in Hebrew on first launch: Task 3 (`first launch` Hebrew test through the real store and `ZodiannApp`), Task 5 Step 1 on a device if available.
2. A device set to French opens the app in English: Task 1 (resolver) and Task 3.
3. After the first launch the detection never re-runs and overrides an explicit choice: Task 2 (the saved value wins, nothing is written) and Task 3 (two launches over one store, and an explicit choice seeded beforehand).

## Execution mode

Sequential, native (`executing-plans`). No independent work: the tasks build on one file and one interface chain. Subagents only for the mandatory plan review and the whole-branch review.

## Risks

- **Moving `shared_storage` to a runtime dependency** could trip the no-network or dependency-closure guards, add the `sqlite3` native library to the release build, or need GitHub access at build time. Task 4 checks each and records the result; the fallback is to import only the settings half through a narrower entry point.
- **`allowBackup="false"` on Android 12 and later** also governs device-to-device transfer; the manifest test pins the attribute and Task 4 Step 4 reads the built manifest, but the transfer behaviour itself is not exercised on a device.
- **A null `appLocaleProvider` default** can hide a `main()` that skips the bootstrap; the source-level test is the guard (D6).
- **Reading storage before `runApp`** adds the preferences read to cold start (expected tens of milliseconds); Task 5 Step 1 notes any visible delay on a device.
- **iOS** is unverified (no macOS access), including how `NSUserDefaults` backs up.

## Open decisions (for the owner; defaults are implemented)

- **O1 (D1):** the device's languages are matched **in order** (`[fr, he]` gives Hebrew). Alternative: the primary language only (`[fr, he]` gives English). The ordered list is how Android, iOS and Flutter resolve it.
- **O2 (D7):** turn Android Auto Backup **off** now (`allowBackup="false"`), so the saved language (and later settings) is never uploaded to the Google backup, as DATA-5 and DATA-6 require. iOS: `NSUserDefaults` is part of iCloud and device backups and cannot be excluded per key; accept and record it (excluding the SQLite file is ZOD-DAT-002's). Alternative: hold persistence until a different approach is chosen, which would break "never re-runs".
- **O3 (D3):** save the **concrete** language (`he` or `en`) at first launch, as the task text says and the settings mockup shows (English selected). What the control's "System" segment stores or means is ZOD-L10-003 / ZOD-SET-002's decision. Alternative: store nothing until the user chooses, and let a "System" default follow the device on every launch (no first-launch write, but not what the task describes).
- **O4 (D6):** resolve before the first frame (a short wait in `main()`) rather than switching language after the first frame (a possible flash of the wrong language).
- **O5 (D4):** treat an invalid or corrupt saved language as a first launch and overwrite it.

## Plan review

### Round 1 (comprehensive) - verdict: approve after corrections

| ID | Severity | Finding | Done |
|---|---|---|---|
| C1 | Critical | `main()` imports `shared_preferences`, which is only a dev dependency of the app | Applied: both `shared_storage` and `shared_preferences` move to `dependencies` (D8, File structure, Task 0) |
| I1 | Important | The dependency move (Task 4) came after the code and tests that need it; the tests import `shared_preferences_platform_interface`, not declared in the app | Applied: new Task 0 makes all pubspec changes first, including the dev dependency; Task 4 renamed "Guards, builds and Android backup" |
| I2 | Important | The runtime-closure change and the licensing inventory were treated as conditional | Applied: inventory edit mandatory; Task 4 builds `--release` too, checks permissions, the merged manifest and whether `libsqlite3.so` ships, and records the size and the CI GitHub-access note |
| I3 | Important | The first-launch test did not say how the platform is set up | Applied: `SharedPreferencesAsyncPlatform.instance` in `setUp`; a second launch builds a new store over the same platform object |
| M1 | Minor | The `main()` guard is a source grep a comment could satisfy | Applied: comments stripped, three tokens required |
| M2 | Minor | Check the merged manifest, not only the source one | Applied (Task 4 Step 4) |
| M3 | Minor | Stale doc text ("Dev only", "No production wiring", FND-006 Notes lines) | Applied (File structure, Task 0, Task 5) |
| M4 | Minor | `UserSettings` must include or migrate the `language` key | Applied (Task 5 notes) |
| M5 | Minor | Add a failing-store wiring test and a saved-`he`-with-French-device test | Applied (Task 3) |

Needs user decision: none new. Tell the owner: O2 is the Auto Backup decision the PROGRESS owner item asked for before wiring, and O3 means a later device-language change never takes effect.

### Round 2 (focused on the revision, `7e6a12f..91ad085`) - verdict: approve after corrections

| ID | Severity | Finding | Done |
|---|---|---|---|
| I1 | Important | The mandatory inventory edit listed too few rows (`stream_transform`, the scope sentence, the stale "drift (reserved row)", the SQLite binary paragraph, other drift dependencies) | Applied: File structure and Task 4 Step 3 now name every row and say the measured closure and release-APK result feed the edit |
| M1 | Minor | Task 0 Step 2 wording about the lock file | Applied |
| M2 | Minor | The new dev dependency is unused until Task 2 and 3 | Applied (a sentence in Task 0 Step 3) |
| M3 | Minor | Context line still said "only as a dev dependency" | Applied ("today (Task 0 changes this)") |
| M4 | Minor | No stale Task 4 pointers remain | Verified by the reviewer |

Open items after two rounds: none from the reviewer. Needs user decision: none new; O1 to O5 stand.
