# ZOD-REL-002 - Finalize and verify the native build pipeline (CMake/Xcode/native assets)

## Metadata

- **ID:** ZOD-REL-002
- **Category:** [Release Preparation](../README.md#release-preparation) (`release-preparation/`)
- **Phase:** Phase 4
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Harden [ZOD-FND-003](../foundations-architecture/ZOD-FND-003-spike-swiss-ephemeris-ffi-binding-on-android-and-ios.md)'s spike build process into a reproducible, documented release build for both platforms, including the packaged ephemeris data files.

## Implementation Details

- Confirm the build toolchain decision from [ZOD-FND-003](../foundations-architecture/ZOD-FND-003-spike-swiss-ephemeris-ffi-binding-on-android-and-ios.md) (CMake/Xcode vs. native assets) works in a clean CI release-build environment, not just a developer machine.
- Verify final app size with the data-file range chosen in [ZOD-FND-011](../foundations-architecture/ZOD-FND-011-decide-and-document-the-ephemeris-data-file-coverage-range.md).

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] A clean CI machine can produce an Android release build with no manual developer-machine-specific steps. *(Split 2026-11-24: the original read "…a release build for both platforms…". The iOS clause is criterion 1 of [ZOD-IOS-009](../ios/tasks/ZOD-IOS-009-finalize-and-verify-the-ios-release-build-pipeline.md).)*
- [ ] Final app size is documented and acceptable for store submission. *(Android here; the final iOS size is criterion 2 of [ZOD-IOS-009](../ios/tasks/ZOD-IOS-009-finalize-and-verify-the-ios-release-build-pipeline.md).)*

## Dependencies

- [ZOD-FND-003](../foundations-architecture/ZOD-FND-003-spike-swiss-ephemeris-ffi-binding-on-android-and-ios.md) — Spike: Swiss Ephemeris FFI binding on Android and iOS
- [ZOD-FND-011](../foundations-architecture/ZOD-FND-011-decide-and-document-the-ephemeris-data-file-coverage-range.md) — Decide and document the ephemeris data-file coverage range

## Specification References

- ARCH-6
- R-7

## Notes

- **From ZOD-FND-003 (2026-11-20; superseded by the 2026-11-24 note at the end of these Notes): blocked.** The owner split ZOD-FND-003: its Android half is verified (findings: [`docs/spikes/ZOD-FND-003-swiss-ephemeris-ffi.md`](../../spikes/ZOD-FND-003-swiss-ephemeris-ffi.md)) and its iOS half is pending (no macOS access; no spending allowed). The specification (R-7, ARCH-6) requires both platforms, so this task stays blocked until a real iOS computation is verified. Its status, scope and acceptance criteria are unchanged. The findings record the Android build setup, the 16 KB alignment check and the provisional native-assets decision.

- **iOS split (2026-11-24, owner decision):** the iOS and Xcode build requirements moved to [ZOD-IOS-009](../ios/tasks/ZOD-IOS-009-finalize-and-verify-the-ios-release-build-pipeline.md). ZOD-FND-003 is Done for its Android and shared scope, so this task's Android and shared work is no longer blocked by the iOS half. The 16 KB alignment check, recorded as a manual check in the FND-003 review minors, is still this task's to script.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Release Preparation" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
