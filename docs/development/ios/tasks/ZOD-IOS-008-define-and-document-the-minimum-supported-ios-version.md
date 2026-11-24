# ZOD-IOS-008 - Define and document the minimum supported iOS version

## Metadata

- **ID:** ZOD-IOS-008
- **Category:** iOS (`ios/tasks/`)
- **Parent task:** [ZOD-NFR-011](../../performance-accessibility-reliability/ZOD-NFR-011-define-and-document-the-supported-ios-android-version-range.md) (the iOS clauses)
- **Phase:** Phase 1
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Pin and document the minimum iOS version the app supports, based on the Flutter version chosen (NFR-C1 defers this decision to "the start of development"). The Android minimum stays in ZOD-NFR-011.

## Implementation Details

Moved from ZOD-NFR-011:

- Record the chosen Flutter SDK version's minimum-supported iOS version and the value the project sets (`IPHONEOS_DEPLOYMENT_TARGET` in the Xcode project, the Podfile `platform :ios` line once it exists).
- Verify the range is compatible with the FFI and native-build approach proven for iOS in [ZOD-IOS-001](ZOD-IOS-001-verify-the-swiss-ephemeris-and-astronomy-engine-ffi-bindings-on-ios.md).

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] A documented minimum iOS version exists and is referenced by the iOS platform configuration. *(ZOD-NFR-011 criterion, iOS clause: "A documented minimum iOS and Android version exists and is referenced by `pubspec.yaml`/platform manifests." The Android clause stays in NFR-011.)*
- [ ] The minimum iOS version is verified compatible with the iOS FFI and native-build approach. *(ZOD-NFR-011 implementation detail, iOS verification.)*

## Dependencies

- [ZOD-NFR-011](../../performance-accessibility-reliability/ZOD-NFR-011-define-and-document-the-supported-ios-android-version-range.md) — Android and shared half
- [ZOD-IOS-001](ZOD-IOS-001-verify-the-swiss-ephemeris-and-astronomy-engine-ffi-bindings-on-ios.md) — the compatibility check needs the iOS binding

## Specification References

- NFR-C1

## Notes

- Choosing and recording the number can be done on Windows from the Flutter SDK's own documentation; the compatibility verification needs macOS (owner constraint 2026-11-20: no spending).

---

*Part of the [Zodiann development task breakdown](../../TASKS.md). iOS-specific tasks live in `docs/development/ios/tasks/`; see [`../../README.md`](../../README.md) and the iOS section of [`../../TASKS.md`](../../TASKS.md).*
