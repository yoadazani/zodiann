# ZOD-FND-005 Flutter App Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `apps/astro_mobile` a running Flutter app for Android and iOS. It boots to a blank themed screen and provides the composition root that later screens plug into: Riverpod at the root, a single `EphemerisPort` injection point, a theme seam, and localization scaffolding.

**Architecture:**
- `main()` wraps `ZodiannApp` in a `ProviderScope` whose overrides come from one list, `appOverrides`. That list is the DI wiring (ARCH-3, ARCH-4).
- `ephemerisPortProvider` is the one place an `EphemerisPort` is bound. No implementation exists yet (ZOD-EPH-002/003), so its default throws a descriptive error. A fake or a real adapter is bound with one override, and feature code never names a concrete adapter.
- The theme is a placeholder seam, `AppTheme.light` / `AppTheme.dark`, with no color literals; ZOD-FND-013 and ZOD-UI-001 replace it.
- Localization is the Global delegates plus `supportedLocales` en and he, with English first (L-1, L-2). `.arb` files and `gen-l10n` belong to ZOD-L10-001.

**Tech Stack:** Flutter 3.50.0 / Dart 3.14.0 (FVM), flutter_riverpod ^3.5.0, material_ui (latest compatible; 1.11.0 resolved), flutter_localizations (SDK), intl ^0.20.3 (the minimum `flutter_localizations` requires), and the existing `astro_core` (path dependency in the pub workspace).

`package:flutter/material.dart` and `flutter_localizations`' `GlobalMaterialLocalizations` are deprecated since Flutter 3.47, and either one fails `--fatal-infos`. All Material types and `GlobalMaterialLocalizations.delegates` therefore come from `package:material_ui/material_ui.dart`; the SDK's own app template does the same. `flutter_localizations` and `intl` stay as declared dependencies for ZOD-L10-001's gen-l10n, but app code does not import `flutter_localizations` for Material delegates.

**Spec:** `assets/zodiann-specification.md` (ARCH-2, ARCH-3, ARCH-4, ARCH-7, L-1, L-2, L-4). Task: `docs/development/foundations-architecture/ZOD-FND-005-flutter-app-shell-bootstrap-apps-astro-mobile.md`.

## Product-owner decisions (2026-11-12, this planning session)

1. **App identifier:** `com.zodiann.app` for both the Android `applicationId` (and `namespace`) and the iOS `PRODUCT_BUNDLE_IDENTIFIER`. The display name is "Zodiann".
2. **Theme:** the task file says to apply UI-001's ThemeData, but UI-001 depends on FND-013, which depends on FND-005. So FND-005 applies a **placeholder seam**: plain `ThemeData` light and dark with no color literals, following the device setting (`ThemeMode.system`), in a single file `app_theme.dart`. FND-013 and UI-001 replace the seam's contents. A note goes in the task file.
3. **Boot verification:** this Windows machine has no Android device or emulator and cannot build iOS. The criterion "boots to a blank themed screen on iOS and Android" is verified by:
   - a widget test that boots the real root widget (light and dark);
   - `flutter build apk --debug`.

   On-device runs on Android and iOS are recorded as **deferred** to the CI pipeline (ZOD-FND-004) or a Mac. The task's criterion is closed with that note; it is not claimed as fully verified.
4. **Criterion 3 (provider scope per screen):** handed over. FND-005 closes it as "root `ProviderScope` in place; no screens exist". Notes are added to ZOD-WHL-001 and ZOD-SQR-001 (the first Square screen task): "one provider per screen (ARCH-3), verified by this task".

## Global Constraints

- Never `const` / hard-code a color in app code (ARCH-7). No hex literals.
- No hard-coded user-visible strings (L-8); the shell shows no text. `MaterialApp.title` is not set: ZOD-L10-001 adds `onGenerateTitle`.
- `astro_core` stays pure Dart (ARCH-2). The app depends on it, never the reverse. The existing `test/architecture` guard must stay green.
- Latest stable dependencies. The dry run on 2026-11-12 resolved flutter_riverpod 3.5.0, riverpod 3.5.0 and intl 0.20.3 in the workspace with no other changes to pinned versions.
- Gates: `fvm dart run melos run lint` (analyze `--fatal-infos` + format) and `fvm dart run melos run test`, both exit 0.
- No import of `package:flutter/material.dart` or `package:flutter/cupertino.dart`: both are deprecated and fail `--fatal-infos`.
- Don't add go_router (ZOD-FND-014), `.arb` / gen-l10n (ZOD-L10-001), ThemeExtensions (ZOD-FND-013), storage (ZOD-FND-006), icons or fonts (FND-007/008/009).
- `supportedLocales` is a placeholder; ZOD-L10-001 replaces it with the generated `AppLocalizations.supportedLocales`. First-launch persisted detection (L-2) belongs to ZOD-L10-002 and the in-app override (L-3) to ZOD-L10-003. This task only wires Flutter's default resolution.
- Runtime Swiss→backup fallback selection (ARCH-4) is not in this task's scope.

## Design decisions (mine, for your confirmation)

- **Where `ephemerisPortProvider` lives:** in the app (`lib/src/di/`), the composition root. Feature packages don't exist yet. When they need positions (ZOD-WHL-*), each feature either declares its own provider that the app overrides, or the provider moves to a shared package. That choice belongs to the first consuming task, not here.
- **Unbound default throws** `StateError('No EphemerisPort is bound. Override ephemerisPortProvider in appOverrides (lib/src/di/app_overrides.dart).')`. It does not silently return a fake: an unbound source must fail loudly, never produce positions (R-2 spirit). The blank shell never reads it, so the app boots.
- **`appOverrides` is empty today.** The task that first ships a real adapter into the app adds its binding here (likely ZOD-EPH-002/003/004 or the first consuming screen task), and that task's plan records the ownership. Tests build their own `ProviderScope` with a fake.
- **Platform folders** come from `flutter create --platforms=android,ios --org com.zodiann --project-name astro_mobile .` run inside `apps/astro_mobile`. The generated IDs are Android `com.zodiann.astro_mobile` and iOS `com.zodiann.astroMobile`. Then:
  - set the IDs to `com.zodiann.app`:
    - Android: `namespace` and `applicationId` in `app/build.gradle.kts`. Move `MainActivity.kt` to `kotlin/com/zodiann/app/`, change its `package` line to `package com.zodiann.app`, and remove the old directory. A stale package line still builds but crashes at launch.
    - iOS: all **six** `PRODUCT_BUNDLE_IDENTIFIER` lines in `project.pbxproj`: three Runner lines set to `com.zodiann.app` and three RunnerTests lines set to `com.zodiann.app.RunnerTests`.
  - set the display name to "Zodiann": Android `android:label`, iOS `CFBundleDisplayName` and `CFBundleName`;
  - delete the generated sample `lib/main.dart` and `test/widget_test.dart` before writing ours;
  - keep the generated `.metadata` and the app-level `.gitignore`;
  - delete the generated `README.md` (the repo README covers it).

  `flutter create` leaves the existing `pubspec.yaml` alone. It only adds `android/**` and `ios/**` to the analyzer excludes in `analysis_options.yaml`; keep those and verify with `git diff`.

## File Structure

- `apps/astro_mobile/pubspec.yaml`: add `flutter_riverpod`, `material_ui` (direct, as required by `depend_on_referenced_packages`), `flutter_localizations`, `intl` and `astro_core` (path `../../packages/astro_core`).
- `apps/astro_mobile/lib/main.dart`: `void main()` only.
- `apps/astro_mobile/lib/src/app.dart`: `ZodiannApp` (the root `MaterialApp`) and `ShellHome` (the blank screen).
- `apps/astro_mobile/lib/src/theme/app_theme.dart`: the `AppTheme` placeholder seam.
- `apps/astro_mobile/lib/src/di/ephemeris_providers.dart`: `ephemerisPortProvider`.
- `apps/astro_mobile/lib/src/di/app_overrides.dart`: `appOverrides`.
- `apps/astro_mobile/test/app_shell_test.dart`: widget tests (boot, theme, locale).
- `apps/astro_mobile/test/di/ephemeris_providers_test.dart`: DI tests.
- `apps/astro_mobile/android/`, `apps/astro_mobile/ios/`: generated platform projects.

## Review Focus

1. **Device language not supported (fr, ar, and so on):** L-2 says fall back to English. Pinned by `unsupported device locale falls back to English`.
2. **Hebrew device:** the whole shell must be RTL from day one (ARCH-7, L-4). Pinned by `Hebrew device locale resolves to he and lays out RTL`.
3. **Device in dark mode:** the shell must follow it without a restart-only path. Pinned by the light/dark boot tests and `switching platform brightness re-themes the running app`.
4. **Reading the port before an adapter is bound:** it must fail with a message naming where to bind it, never return something. Pinned by `unbound ephemerisPortProvider throws a StateError naming appOverrides`.
5. **The shell must not touch the port while booting:** if the root widget eagerly read the port, the app would crash until EPH-002 exists. Pinned by `boots with no overrides` (the default throws, so any read fails the test).

---

## Tasks

### Task 1: Platform scaffolding and dependencies

**Files:**
- Create: `apps/astro_mobile/android/**`, `apps/astro_mobile/ios/**`, `apps/astro_mobile/.metadata`, `apps/astro_mobile/.gitignore` (generated)
- Modify: `apps/astro_mobile/pubspec.yaml`, `pubspec.lock`

**Interfaces:**
- Produces: a Flutter app package with Android and iOS projects whose ID is `com.zodiann.app`, and the dependencies `flutter_riverpod`, `flutter_localizations`, `intl`, `astro_core` available to `lib/`.

Bash calls start at the repo root and need `export PATH="$PATH:/c/Users/user/AppData/Local/Pub/Cache/bin"` for `fvm`.

- [ ] **Step 1: Generate.** Run `cmd //c "cd apps\\astro_mobile && fvm flutter create --platforms=android,ios --org com.zodiann --project-name astro_mobile ."`. Expected: "All done!". Then:
  - `git diff -- apps/astro_mobile/pubspec.yaml` must be empty;
  - `git diff -- apps/astro_mobile/analysis_options.yaml` must show only the two added excludes `android/**` and `ios/**`. Keep them: Flutter re-adds them on every `flutter create` or `flutter analyze`.

  Restore anything else that changed.
- [ ] **Step 2: Remove samples.** Delete the generated `lib/main.dart`, `test/widget_test.dart` and `README.md`.
- [ ] **Step 3: Set the IDs and display name** as listed under Design decisions, then check:
  - `grep -rnE "astro_mobile|astroMobile" apps/astro_mobile/android/app apps/astro_mobile/ios/Runner apps/astro_mobile/ios/Runner.xcodeproj` → no identifier or label hits;
  - `grep -c "PRODUCT_BUNDLE_IDENTIFIER = com.zodiann.app;" apps/astro_mobile/ios/Runner.xcodeproj/project.pbxproj` → `3`;
  - `grep -c "PRODUCT_BUNDLE_IDENTIFIER = com.zodiann.app.RunnerTests;" …` (same file) → `3`;
  - `android/app/src/main/kotlin/com/zodiann/app/MainActivity.kt` starts with `package com.zodiann.app`, and `kotlin/com/zodiann/astro_mobile/` no longer exists.
- [ ] **Step 4: Add dependencies.**
  - `cmd //c "cd apps\\astro_mobile && fvm flutter pub add flutter_riverpod intl material_ui"`. Never write `^` inside `cmd //c "…"`: cmd strips it, leaving exact pins. Pub writes caret constraints for the latest compatible versions; expect `flutter_riverpod: ^3.5.0`, `intl: ^0.20.3` and `material_ui: ^1.11.0` in `git diff apps/astro_mobile/pubspec.yaml`.
  - `cmd //c "cd apps\\astro_mobile && fvm flutter pub add flutter_localizations --sdk=flutter"`
  - `cmd //c "cd apps\\astro_mobile && fvm flutter pub add astro_core --path=../../packages/astro_core"`

  Expected:
  - `git diff -- pubspec.yaml` at the root is empty; only `apps/astro_mobile/pubspec.yaml` and `pubspec.lock` change;
  - the lock gains only additions (`flutter_riverpod`, `riverpod`, `state_notifier`, `material_ui`, `cupertino_ui`, `intl`, `flutter_localizations`, `uuid`, `fixnum`), with no existing version changed.
- [ ] **Step 5: Check that the gates still pass.** No `lib/` code exists yet; `dart analyze` on an empty `lib/` is fine. Run `cmd //c "fvm dart run melos run lint"`, expecting exit 0. `test/architecture` must stay green: run `cmd //c "fvm dart test test/architecture"` at the repo root, expecting all pass.
- [ ] **Step 6: Commit** `build(ZOD-FND-005): scaffold Android and iOS projects (com.zodiann.app) and add shell dependencies`. Stage `apps/astro_mobile` and `pubspec.lock`. Check `git status` first: exclude `build/`, `.dart_tool/` and the ignored Gradle/Pods artifacts, and never stage `.idea/` or `*.iml`.

### Task 2: DI — `ephemerisPortProvider` and `appOverrides` (TDD)

**Files:**
- Create: `apps/astro_mobile/lib/src/di/ephemeris_providers.dart`, `apps/astro_mobile/lib/src/di/app_overrides.dart`
- Test: `apps/astro_mobile/test/di/ephemeris_providers_test.dart`

**Interfaces:**
- Consumes: `EphemerisPort`, `Body`, `EphemerisResult`, `EclipticPosition`, `UtcRange` from `package:astro_core/astro_core.dart`.
- Produces:
  - `final Provider<EphemerisPort> ephemerisPortProvider`: its default throws the `StateError` given under Design decisions;
  - `final List<Override> appOverrides = List<Override>.unmodifiable(const <Override>[]);`, documented as the single place that binds sources. It is deliberately **not** a `const` literal. `ProviderScope`'s default `overrides` is `const <Override>[]`, so a const `appOverrides` would be the same canonical object, and the `main()` wiring test could not catch a missing `overrides:` (M6). The task that first ships a real adapter adds its binding inside the list. `app_overrides.dart` imports `package:flutter_riverpod/misc.dart` show `Override`; Riverpod 3 moved `Override` and `ProviderException` to `misc.dart`.

- [ ] **Step 1: Write the failing tests.** The test-local `_FakePort implements EphemerisPort` throws `UnimplementedError` from every member; identity is all that is checked.
  - `unbound ephemerisPortProvider throws a StateError naming appOverrides`: `ProviderContainer.test()`; `expect(() => container.read(ephemerisPortProvider), throwsA(isA<ProviderException>().having((e) => e.exception, 'exception', isA<StateError>().having((e) => e.message, 'message', contains('appOverrides')))))`. Riverpod 3.5.0 wraps the error, as verified by the reviewer. The test imports `package:flutter_riverpod/misc.dart` show `ProviderException`.
  - `one override binds the port`: a container with `overrides: [ephemerisPortProvider.overrideWithValue(fake)]`; `expect(container.read(ephemerisPortProvider), same(fake))`.
  - `appOverrides binds nothing yet`: `expect(appOverrides, isEmpty)`. This pins today's state; the task that first ships an adapter updates it deliberately.
- [ ] **Step 2: Run it.** `cmd //c "fvm dart run melos exec --scope=astro_mobile -- flutter test test/di"`. Expected: FAIL to compile (`ephemeris_providers.dart` doesn't exist).
- [ ] **Step 3: Implement** the two files per Interfaces. The doc comment on `ephemerisPortProvider` cites ARCH-4 and says feature code reads it, never constructs an adapter.
- [ ] **Step 4: Run it again.** Expected: 3/3 PASS.
- [ ] **Step 5: Commit** `feat(ZOD-FND-005): single EphemerisPort injection point`.

### Task 3: Root widget, theme seam, localization (TDD)

**Files:**
- Create: `apps/astro_mobile/lib/main.dart`, `apps/astro_mobile/lib/src/app.dart`, `apps/astro_mobile/lib/src/theme/app_theme.dart`
- Test: `apps/astro_mobile/test/app_shell_test.dart`

**Interfaces:**
- Consumes: `appOverrides`, `ephemerisPortProvider` (Task 2).
- Produces:
  - All lib and test files import `package:material_ui/material_ui.dart`, never `package:flutter/material.dart`.
  - `class ZodiannApp extends StatelessWidget` with `const ZodiannApp({super.key})`: a `MaterialApp` with
    - `theme: AppTheme.light`, `darkTheme: AppTheme.dark`, `themeMode: ThemeMode.system`;
    - `localizationsDelegates: GlobalMaterialLocalizations.delegates` (from `material_ui`, which includes the widgets and Cupertino delegates);
    - `supportedLocales: const [Locale('en'), Locale('he')]` (English first, so Flutter's default resolution falls back to it);
    - `home: const ShellHome()`.
  - `class ShellHome extends StatelessWidget` with `const ShellHome({super.key})`: `const Scaffold()` with no text and no colors.
  - `abstract final class AppTheme { static final ThemeData light; static final ThemeData dark; }`: `ThemeData(brightness: Brightness.light)` and `ThemeData(brightness: Brightness.dark)`, with a comment saying this is the FND-013 / UI-001 seam.
  - `void main() => runApp(ProviderScope(overrides: appOverrides, child: const ZodiannApp()));`

- [ ] **Step 1: Write the failing tests.** Each test pumps `ProviderScope(child: ZodiannApp())` unless stated, and resets the platform test values in `addTearDown`.
  - `boots with no overrides to a blank themed screen`: pump and settle; `expect(tester.takeException(), isNull)`; `find.byType(ShellHome)` finds one; `find.byType(Text)` finds nothing.
  - `light device → light theme`: `tester.platformDispatcher.platformBrightnessTestValue = Brightness.light`; `Theme.of(tester.element(find.byType(ShellHome))).brightness == Brightness.light`.
  - `dark device → dark theme`: same with `Brightness.dark`.
  - `switching platform brightness re-themes the running app`: start light, set dark, `pumpAndSettle`, expect dark.
  - `the Scaffold paints the theme surface`: the ShellHome `Scaffold`'s rendered background equals `Theme.of(context).scaffoldBackgroundColor` in both brightnesses (read the `Material` under the `Scaffold`: `tester.widget<Material>(find.descendant(of: find.byType(Scaffold), matching: find.byType(Material)).first).color`).
  - `unsupported device locale falls back to English`: `tester.platformDispatcher.localesTestValue = const [Locale('fr')]`; `Localizations.localeOf(ctx) == const Locale('en')`; `Directionality.of(ctx) == TextDirection.ltr`.
  - `Hebrew device locale resolves to he and lays out RTL`: `[Locale('he', 'IL')]` → `Localizations.localeOf(ctx).languageCode == 'he'`, `Directionality.of(ctx) == TextDirection.rtl`, which proves the Global delegates are wired (`MaterialLocalizations.of(ctx)` resolving is only a smoke check, since `DefaultMaterialLocalizations` exists without them).
  - `boots with a fake EphemerisPort bound by one override`: `ProviderScope(overrides: [ephemerisPortProvider.overrideWithValue(fake)], child: ZodiannApp())`; then `ProviderScope.containerOf(tester.element(find.byType(ShellHome)), listen: false).read(ephemerisPortProvider)` is `same(fake)`. This shows the swap needs only the override, with no change to the app widget.
  - `main() mounts ZodiannApp under a ProviderScope wired to appOverrides`: `import 'package:astro_mobile/main.dart' as app;` then `app.main()` and `await tester.pump()`. Expect `tester.widget<ProviderScope>(find.byType(ProviderScope)).overrides` to be `same(appOverrides)`, and `find.byType(ZodiannApp)` to find one.
- [ ] **Step 2: Run it.** `cmd //c "fvm dart run melos exec --scope=astro_mobile -- flutter test test/app_shell_test.dart"`. Expected: FAIL to compile (`app.dart` doesn't exist).
- [ ] **Step 3: Implement** the three files per Interfaces.
- [ ] **Step 4: Run it again.** Expected: 9/9 PASS. Then run the whole app test dir: 12/12.
- [ ] **Step 5: Mutation check (RED evidence that the tests bite).** Apply each mutant, run the app tests, and confirm a failure (not a compile error). Restore, then `git diff --exit-code -- apps/astro_mobile/lib`. Record the counts in the commit body.
  - M1: `themeMode: ThemeMode.light` → the dark tests fail.
  - M2: `supportedLocales` with `he` first → the French fallback test fails.
  - M3: drop the `localizationsDelegates` → the Hebrew test fails.
  - M4: `ShellHome` reads `ref.watch(ephemerisPortProvider)` (as a `ConsumerWidget`) → the no-override boot test fails.
  - M5: the unbound default returns `_SomeStub()` instead of throwing → the DI StateError test fails. Keep the stub test-free; it is a throwaway.
  - M6: `main()` without `overrides: appOverrides` → the `main()` wiring test fails.
- [ ] **Step 6: Commit** `feat(ZOD-FND-005): root widget with theme seam, en/he localization and ProviderScope`.

### Task 4: Android build and close-out

- [ ] **Step 1: Android build.** `cmd //c "cd apps\\astro_mobile && fvm flutter build apk --debug"`. Expected: `✓ Built build\app\outputs\flutter-apk\app-debug.apk`. If it fails on unaccepted SDK licenses or missing cmdline-tools, **stop and ask the user**: accepting the Android SDK licenses is their legal acceptance. They can run `! fvm flutter doctor --android-licenses`. Do not work around it. Any other failure gets systematic debugging.
- [ ] **Step 2: Full gates.** `cmd //c "fvm dart run melos run lint && fvm dart run melos run test"`, both exit 0. Record the per-package counts.
- [ ] **Step 3: Whole-branch code review** (opus, `requesting-code-review`, with the Review Focus above). Fix Critical and Important findings test-first.
- [ ] **Step 4: Docs.**
  - Task file: Status Done, criteria ticked, with these notes:
    - criterion 1: widget test and APK verified; on-device Android/iOS deferred to FND-004 or a Mac;
    - criterion 2: proven by the override tests;
    - criterion 3: closed as "root `ProviderScope` in place; no screens exist", handed over (product-owner decision 4).
  - Task file Notes: the four product-owner decisions.
  - Add a Notes line to `zodiac-wheel/ZOD-WHL-001-…md` and `gann-square/ZOD-SQR-001-…md`: "ARCH-3 (handed over from ZOD-FND-005 criterion 3): the screen's state lives in exactly one provider (one provider per screen); verified by this task." Requirements and acceptance criteria stay unchanged.
  - TASKS.md: Done. PROGRESS.md:
    - completed row, technical decisions (app ID, theme seam, provider location, unbound throws);
    - Next Recommended Task;
    - Git State, which also fixes the stale TST-011 "PR open" entries (merged as `30ea9eb`).
- [ ] **Step 5: Commit, push, PR, record the PR link** per the workflow (Step 8).

## Acceptance Criteria → Evidence

| Criterion | Evidence |
|---|---|
| App boots to a blank themed screen on iOS and Android | Widget tests: boot with no overrides, light/dark/switch, Scaffold surface, fallback, RTL. `flutter build apk --debug` succeeds. iOS project generated with `com.zodiann.app`. **On-device runs deferred** (FND-004 CI or a Mac), recorded in the task file and PROGRESS. |
| Swapping the injected `EphemerisPort` touches only DI wiring | `one override binds the port`, `boots with a fake EphemerisPort bound by one override`, and `main() mounts ZodiannApp under a ProviderScope wired to appOverrides`. M4/M5/M6 show the tests catch a shell that reads the port or a default that doesn't throw. |
| Riverpod devtools show one provider scope per screen once screens exist | No screens exist yet. The root `ProviderScope` is in place. Per product-owner decision 4, the criterion is handed to ZOD-WHL-001 and ZOD-SQR-001 as "one provider per screen (ARCH-3)", with notes added to both task files. |

## Risks

- **`flutter build apk` on this machine:** cmdline-tools are missing and the licenses status is unknown. The build may stop at licenses, which is the user's step. Gradle's first run downloads several hundred MB.
- **Riverpod 3 API drift:** resolved by the round-1 review, which checked 3.5.0 directly. `Override` and `ProviderException` come from `misc.dart`, `ProviderContainer.test` exists, and errors are wrapped in `ProviderException`.
- **The generated iOS project can't be compiled here.** An ID typo in `project.pbxproj` would only show on a Mac. Step 3's greps, which check all six `PRODUCT_BUNDLE_IDENTIFIER` lines (3 Runner + 3 RunnerTests), mitigate this.
- **`dart analyze` in the workspace** now sees `flutter_riverpod`. If `flutter_lints` flags generated code, nothing generated is Dart outside `lib/` and `test/`, so it should not.

## Plan review

### Round 1: Needs user decision (1 Critical, 5 Important, 8 Minor, 1 decision)

- **C1 (Critical), applied.** `package:flutter/material.dart` and `flutter_localizations`' `GlobalMaterialLocalizations` are deprecated on Flutter 3.50 and fail `--fatal-infos` (reviewer confirmed with a scratch analyze). The plan now uses `package:material_ui/material_ui.dart` for all Material types and delegates. `material_ui` is a direct dependency, and a Global Constraint bans the deprecated imports.
- **I1, applied.** `Override` and `ProviderException` come from `package:flutter_riverpod/misc.dart`.
- **I2, applied.** iOS generates `com.zodiann.astroMobile`, and there are six `PRODUCT_BUNDLE_IDENTIFIER` lines. The `MainActivity.kt` package line must change too. The Step 3 checks now grep both spellings and count 3 + 3.
- **I3, applied.** `cd apps\astro_mobile` is inside each `cmd` call, and `pub add` is split into three commands; the root `pubspec.yaml` must stay unchanged.
- **I4, applied.** New test: `main()` mounts `ZodiannApp` under a `ProviderScope` whose overrides are `appOverrides`, plus mutant M6. Counts are now 9 + 3 = 12.
- **I5, applied.** EPH-002 is no longer named as owner of the `appOverrides` binding. The first task that ships an adapter adds it, and runtime fallback is out of scope.
- **M1, applied:** typed `ProviderException` → `StateError` assertion.
- **M2, applied:** `<Override>` typed. Made non-const in round 2 so that M6 is detectable.
- **M3, applied:** L10-001/002/003 ownership of `supportedLocales`, L-2 and L-3.
- **M4, applied:** `intl` wording and expected lock additions.
- **M5, applied:** never stage `.idea/` or `*.iml`.
- **M6, applied:** `{super.key}` constructors.
- **M7, applied:** `containerOf(..., listen: false)`.
- **M8, applied:** this record.
- **D1, decided by the product owner: hand over.** Criterion 3 is closed as "root `ProviderScope` in place", with notes added to ZOD-WHL-001 and ZOD-SQR-001 (decision 4).

### Round 2: Approve after corrections (1 Critical, 1 Important, 4 Minor; no user decisions)

The reviewer ran Tasks 1–3 as written in a scratch clone on the pinned SDK.

- **C1 (Critical), applied.** `ProviderScope`'s default `overrides` is `const <Override>[]`, which is the same canonical object as a const `appOverrides`. That let M6 survive (reproduced). `appOverrides` is now `List<Override>.unmodifiable(const <Override>[])`, and the reviewer confirmed M6 is then killed.
- **I1, applied.** `^` inside `cmd //c "…"` is stripped, which produced exact pins. `pub add` now runs without versions and pub writes the caret constraints.
- **M1, applied.** `flutter create` adds `android/**` and `ios/**` analyzer excludes to `analysis_options.yaml`; keep them.
- **M2, applied.** Corrected the expected lock additions (`uuid` and `fixnum` added, `listen` removed).
- **M3, applied.** The DI test imports `ProviderException` from `misc.dart`.
- **M4, applied.** The Hebrew test's RTL assertion is what proves the delegates are wired; `MaterialLocalizations` resolving is only a smoke check.

The rest was verified in the clone: lint and test gates pass, the Task 2 RED/GREEN cycle, the ID greps (3 + 3, no leftovers), and mutants M1–M5 all killed. No open items.
