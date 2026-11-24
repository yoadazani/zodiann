# ZOD-NFR-011 - Define and document the supported iOS/Android version range

## Metadata

- **ID:** ZOD-NFR-011
- **Category:** [Performance, Accessibility & Reliability](../README.md#performance-accessibility-reliability) (`performance-accessibility-reliability/`)
- **Phase:** Phase 1
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Pin and document the exact iOS/Android version range the app supports, based on the Flutter version chosen (NFR-C1 explicitly defers this decision to "the start of development").

## Implementation Details

- Record the chosen Flutter SDK version and its corresponding minimum-supported OS versions.
- Verify this range is compatible with the FFI/native-build approach proven in [ZOD-FND-003](../foundations-architecture/ZOD-FND-003-spike-swiss-ephemeris-ffi-binding-on-android-and-ios.md). *(Android here; the iOS compatibility check is criterion 2 of [ZOD-IOS-008](../ios/tasks/ZOD-IOS-008-define-and-document-the-minimum-supported-ios-version.md).)*

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] A documented minimum Android version exists and is referenced by `pubspec.yaml`/platform manifests. *(Split 2026-11-24: the original read "A documented minimum iOS and Android version exists and is referenced by `pubspec.yaml`/platform manifests." The iOS clause is criterion 1 of [ZOD-IOS-008](../ios/tasks/ZOD-IOS-008-define-and-document-the-minimum-supported-ios-version.md).)*

## Dependencies

- [ZOD-FND-001](../foundations-architecture/ZOD-FND-001-set-up-the-melos-monorepo-workspace.md) — Set up the Melos monorepo workspace
- [ZOD-FND-003](../foundations-architecture/ZOD-FND-003-spike-swiss-ephemeris-ffi-binding-on-android-and-ios.md) — Spike: Swiss Ephemeris FFI binding on Android and iOS

## Specification References

- NFR-C1

## Notes

- **From ZOD-FND-003 (2026-11-20; superseded by the 2026-11-24 note at the end of these Notes): blocked.** The owner split ZOD-FND-003: its Android half is verified (findings: [`docs/spikes/ZOD-FND-003-swiss-ephemeris-ffi.md`](../../spikes/ZOD-FND-003-swiss-ephemeris-ffi.md)) and its iOS half is pending (no macOS access; no spending allowed). The specification (R-7, ARCH-6) requires both platforms, so this task stays blocked until a real iOS computation is verified. Its status, scope and acceptance criteria are unchanged.

- **iOS split (2026-11-24, owner decision):** the iOS version clauses moved to [ZOD-IOS-008](../ios/tasks/ZOD-IOS-008-define-and-document-the-minimum-supported-ios-version.md). ZOD-FND-003 is Done for its Android and shared scope, so this task is no longer blocked for Android. Scope is otherwise unchanged.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Performance, Accessibility & Reliability" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
