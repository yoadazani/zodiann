# ZOD-IOS-009 - Finalize and verify the iOS release build pipeline

## Metadata

- **ID:** ZOD-IOS-009
- **Category:** iOS (`ios/tasks/`)
- **Parent task:** [ZOD-REL-002](../../release-preparation/ZOD-REL-002-finalize-and-verify-the-native-build-pipeline-cmake-xcode-native.md) (the iOS and Xcode clauses)
- **Phase:** Phase 4
- **Priority:** Critical
- **Status:** Not Started (blocked: needs macOS and Xcode; see Notes)
- **Scope:** MVP

## Description

Harden the iOS side of the spike build into a reproducible, documented release build, including the packaged ephemeris data files. The Android and shared pipeline stays in ZOD-REL-002.

## Implementation Details

Moved from ZOD-REL-002:

- Confirm the iOS build toolchain decision (Xcode vs. native assets, confirmed in [ZOD-IOS-001](ZOD-IOS-001-verify-the-swiss-ephemeris-and-astronomy-engine-ffi-bindings-on-ios.md)) works in a clean CI release-build environment, not just a developer machine.
- Verify the final iOS app size with the data-file range chosen in [ZOD-FND-011](../../foundations-architecture/ZOD-FND-011-decide-and-document-the-ephemeris-data-file-coverage-range.md).

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] A clean CI machine can produce an iOS release build with no manual developer-machine-specific steps. *(ZOD-REL-002 criterion 1, iOS clause: "…for both platforms…")*
- [ ] The final iOS app size is documented and acceptable for store submission. *(ZOD-REL-002 criterion 2, iOS size. The Android size stays in REL-002.)*

## Dependencies

- [ZOD-REL-002](../../release-preparation/ZOD-REL-002-finalize-and-verify-the-native-build-pipeline-cmake-xcode-native.md) — Android and shared half
- [ZOD-IOS-001](ZOD-IOS-001-verify-the-swiss-ephemeris-and-astronomy-engine-ffi-bindings-on-ios.md) — the iOS binding and the confirmed toolchain decision
- [ZOD-IOS-008](ZOD-IOS-008-define-and-document-the-minimum-supported-ios-version.md) — the deployment target
- [ZOD-FND-011](../../foundations-architecture/ZOD-FND-011-decide-and-document-the-ephemeris-data-file-coverage-range.md) — the data-file range

## Specification References

- ARCH-6
- R-7

## Notes

- **Blocked: macOS access.** A clean CI iOS build needs a macOS runner. GitHub's standard macOS runners are free for public repositories according to GitHub's billing documentation read on 2026-11-20 (findings section 8); using one is a new owner decision, not taken. Owner constraint 2026-11-20: no spending.

---

*Part of the [Zodiann development task breakdown](../../TASKS.md). iOS-specific tasks live in `docs/development/ios/tasks/`; see [`../../README.md`](../../README.md) and the iOS section of [`../../TASKS.md`](../../TASKS.md).*
