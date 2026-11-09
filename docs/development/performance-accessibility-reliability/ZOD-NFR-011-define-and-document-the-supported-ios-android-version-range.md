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
- Verify this range is compatible with the FFI/native-build approach proven in [ZOD-FND-003](../foundations-architecture/ZOD-FND-003-spike-swiss-ephemeris-ffi-binding-on-android-and-ios.md).

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] A documented minimum iOS and Android version exists and is referenced by `pubspec.yaml`/platform manifests.

## Dependencies

- [ZOD-FND-001](../foundations-architecture/ZOD-FND-001-set-up-the-melos-monorepo-workspace.md) — Set up the Melos monorepo workspace
- [ZOD-FND-003](../foundations-architecture/ZOD-FND-003-spike-swiss-ephemeris-ffi-binding-on-android-and-ios.md) — Spike: Swiss Ephemeris FFI binding on Android and iOS

## Specification References

- NFR-C1

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Performance, Accessibility & Reliability" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
