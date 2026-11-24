# ZOD-IOS-002 - Verify the app shell build and runtime on iOS

## Metadata

- **ID:** ZOD-IOS-002
- **Category:** iOS (`ios/tasks/`)
- **Parent tasks:** [ZOD-FND-005](../../foundations-architecture/ZOD-FND-005-flutter-app-shell-bootstrap-apps-astro-mobile.md) (iOS build and runtime); [ZOD-FND-007](../../foundations-architecture/ZOD-FND-007-bundle-offline-fonts-and-verify-no-network-dependency.md) (iOS checks)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started (blocked: needs macOS and Xcode; see Notes)
- **Scope:** MVP

## Description

Build the app on iOS and run it for the first time. This is the root of the iOS track: every other iOS task needs an iOS build that exists. It also owns the iOS launch and configuration items that no task owned (recorded in `docs/PROGRESS.md` Blockers, 2026-11-12 to 2026-11-16).

## Implementation Details

Moved from ZOD-FND-005:

- Build the iOS app (`flutter build ios`) and run it on an iOS simulator or device: blank themed screen, light and dark, no crash. The project was scaffolded and checked statically only (`com.zodiann.app`).
- ZOD-FND-004's CI includes no macOS runner or iOS build; whether and how CI builds iOS is part of this task's evidence, subject to the no-spending constraint.

Moved from ZOD-FND-007 (its Android and static checks stay there):

- Run `apps/astro_mobile/integration_test/offline_fonts_test.dart` on iOS in airplane mode: all four weights of both families render offline. (Android evidence exists; iOS was static only.)
- After the first iOS build generates the Podfile or SwiftPM setup (`integration_test` is the app's first plugin), re-run `test/architecture/no_network_test.dart` and confirm no network permission, entitlement, ATS, Bonjour or local-network key appeared in the generated iOS project.

Items recorded in PROGRESS Blockers that no task owned:

- The launch screen is hard-coded white (`ios/Runner/Base.lproj/LaunchScreen.storyboard`): white flash in dark mode. Use `systemBackgroundColor`.
- `Info.plist` lacks `CFBundleLocalizations` (`en`, `he`), which iOS needs to treat the bundle as Hebrew-capable and to show the per-app language picker (L-3).

## Design Reference

No direct design reference applies to the shell; the launch screen follows the app's dark and light surfaces (`design-reference/zodiann/MASTER.md`).

## Acceptance Criteria

- [ ] App boots to a blank themed screen on iOS. *(ZOD-FND-005 criterion 1, iOS clause: "…on iOS and Android"; the Android clause is verified there.)*
- [ ] All four weight variants of both font families render correctly offline on iOS (airplane-mode test). *(ZOD-FND-007 criterion 1, iOS run.)*
- [ ] No network permission is declared in the iOS entitlements or the generated iOS project. *(ZOD-FND-007 criterion 3, re-checked on the generated project.)*
- [ ] The launch screen follows the system appearance with no white flash in dark mode.
- [ ] `Info.plist` declares `CFBundleLocalizations` (`en`, `he`) and the per-app language picker offers Hebrew and English (L-3).

## Dependencies

- [ZOD-FND-005](../../foundations-architecture/ZOD-FND-005-flutter-app-shell-bootstrap-apps-astro-mobile.md) — Android and shared half (Done)
- [ZOD-FND-007](../../foundations-architecture/ZOD-FND-007-bundle-offline-fonts-and-verify-no-network-dependency.md) — Android and static half (Done)

## Specification References

- ARCH-2
- DATA-7
- L-3

## Notes

- **Blocked: macOS access** (owner constraint 2026-11-20: no spending). iOS builds need macOS and Xcode.
- The two fixes (launch screen, `CFBundleLocalizations`) are small code changes; they are made and verified here, test-first where a test can exist on the host (a static check of the plist keys and the storyboard colour).

---

*Part of the [Zodiann development task breakdown](../../TASKS.md). iOS-specific tasks live in `docs/development/ios/tasks/`; see [`../../README.md`](../../README.md) and the iOS section of [`../../TASKS.md`](../../TASKS.md).*
