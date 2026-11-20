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

- [ ] A clean CI machine can produce a release build for both platforms with no manual developer-machine-specific steps.
- [ ] Final app size is documented and acceptable for store submission.

## Dependencies

- [ZOD-FND-003](../foundations-architecture/ZOD-FND-003-spike-swiss-ephemeris-ffi-binding-on-android-and-ios.md) — Spike: Swiss Ephemeris FFI binding on Android and iOS
- [ZOD-FND-011](../foundations-architecture/ZOD-FND-011-decide-and-document-the-ephemeris-data-file-coverage-range.md) — Decide and document the ephemeris data-file coverage range

## Specification References

- ARCH-6
- R-7

## Notes

- **From ZOD-FND-003 (2026-11-20): blocked.** The owner split ZOD-FND-003: its Android half is verified (findings: [`docs/spikes/ZOD-FND-003-swiss-ephemeris-ffi.md`](../../spikes/ZOD-FND-003-swiss-ephemeris-ffi.md)) and its iOS half is pending (no macOS access; no spending allowed). The specification (R-7, ARCH-6) requires both platforms, so this task stays blocked until a real iOS computation is verified. Its status, scope and acceptance criteria are unchanged. The findings record the Android build setup, the 16 KB alignment check and the provisional native-assets decision.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Release Preparation" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
