# ZOD-FND-005 - Flutter app shell bootstrap (`apps/astro_mobile`)

## Metadata

- **ID:** ZOD-FND-005
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Done (iOS build/runtime verification outstanding)
- **Scope:** MVP

## Description

Create the running Flutter application shell: entry point, dependency injection wiring, theme application, and the root widget tree that later navigation and screen work plugs into.

## Implementation Details

- Set up Riverpod as the app-wide state management root (ARCH-3).
- Wire dependency injection so `EphemerisPort` implementations (Swiss Ephemeris primary, astronomy-engine backup) are swappable with a single provider override (ARCH-4).
- Apply the light/dark `ThemeData` produced in [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) at the root.
- Set up `flutter_localizations` and the `intl` package scaffolding (consumed fully in ZOD-L10 tasks).

## Design Reference

No direct design reference applies to wiring; the resulting shell's visual chrome is covered by ZOD-NAV tasks referencing `design-reference/zodiann/MASTER.md` §5.

## Acceptance Criteria

- [ ] App boots to a blank themed screen on iOS and Android.
  - [x] Widget-level shell verification (`test/app_shell_test.dart`: blank screen, light/dark/live switch, English fallback, Hebrew RTL and Hebrew Material strings).
  - [x] Android debug APK builds (`flutter build apk --debug`).
  - [x] Android on-device run: installed and launched on emulator-5554 (AOSP Android 9, API 28, x86 with ARM translation), blank light screen and blank dark screen in night mode, no crash (2026-11-13).
  - [x] iOS project scaffolded (`com.zodiann.app`; checked statically only).
  - [ ] **Outstanding:** iOS build + runtime (needs a Mac; ZOD-FND-004's task file includes no macOS runner or iOS build).
- [x] Swapping the injected `EphemerisPort` (e.g., to a fake) requires touching only the DI wiring, not feature code. Evidence: `one override binds the port`, `boots with a fake EphemerisPort bound by one override`, `main() mounts ZodiannApp under a ProviderScope wired to appOverrides`.
- [x] The app has a single root `ProviderScope` (in `main()`) as the app-wide Riverpod container, with no nested scopes. ARCH-3's "screen state is kept in one provider per screen (Riverpod), and derived values (cells, highlights) are pure functions of the state" is verified by the screen tasks once screens exist: ZOD-WHL-001 (wheel) and ZOD-SQR-001 (square).

## Dependencies

- [ZOD-FND-001](../foundations-architecture/ZOD-FND-001-set-up-the-melos-monorepo-workspace.md) — Set up the Melos monorepo workspace
- [ZOD-FND-002](../foundations-architecture/ZOD-FND-002-define-the-ephemerisport-interface-contract.md) — Define the `EphemerisPort` interface contract

## Specification References

- ARCH-2
- ARCH-3
- ARCH-4

## Notes

Product-owner decisions (2026-11-12, plan `docs/plans/ZOD-FND-005-flutter-app-shell.md`):

1. **App identifier:** `com.zodiann.app` (Android `applicationId`/`namespace`, iOS bundle ID); display name "Zodiann".
2. **Theme:** UI-001's ThemeData cannot exist yet (UI-001 → FND-013 → FND-005), so this task applies a placeholder seam, `AppTheme.light`/`AppTheme.dark` in `lib/src/theme/app_theme.dart` (plain `ThemeData`, no color literals, `ThemeMode.system`). FND-013 and UI-001 replace it.
3. **Boot verification:** widget tests + Android APK build; the Android on-device run was done on emulator-5554 at the product owner's direction. iOS build/runtime is outstanding (needs a Mac).
4. **Criterion 3:** reworded (ARCH-3 is one Provider per screen, not one ProviderScope per screen) and handed over to ZOD-WHL-001 and ZOD-SQR-001, which each carry an ARCH-3 acceptance criterion.
5. **Status with criterion 1 unchecked:** Done with the outstanding device verification recorded — a conscious departure from "never mark complete before criteria are verified", limited to verification this machine cannot perform.

**Provider boundary:** `ephemerisPortProvider` (`apps/astro_mobile/lib/src/di/`) is an app-level placeholder and not a provider contract for feature packages. The first task that consumes `EphemerisPort` from a feature package decides where the feature-accessible contract lives and how `appOverrides` binds it.

**Flutter 3.50 note:** `package:flutter/material.dart` and `flutter_localizations`' `GlobalMaterialLocalizations` are deprecated; app code imports `package:material_ui/material_ui.dart`.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
