# ZOD-FND-003 - Spike: Swiss Ephemeris FFI binding on Android and iOS

## Metadata

- **ID:** ZOD-FND-003
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

De-risk the single biggest technical unknown (R-7) before any feature work starts: prove that the Swiss Ephemeris C library can be bound via Dart FFI, built via the Flutter toolchain, and packaged with its data files, on both target platforms.

## Implementation Details

- Vendor the Swiss Ephemeris C source into `native/swisseph/`.
- Generate Dart bindings with `ffigen`.
- Build via CMake (Android) and Xcode (iOS), or native assets if stable enough at the time of implementation (ARCH-6).
- Run one real computation (e.g., Sun longitude on a known date) on a physical or emulated device of each platform and compare against a known-good value.
- Decide and document how the ephemeris data files are packaged as app assets and loaded at runtime (flat files vs. compressed bundle).
- Record build-time, binary-size, and licensing findings for [ZOD-REL-003](../release-preparation/ZOD-REL-003-finalize-store-distribution-and-swiss-ephemeris-licensing-path.md).

## Design Reference

No direct design reference applies — native build spike.

## Acceptance Criteria

- [ ] A single FFI call returns a correct longitude on both an Android and an iOS build.
- [ ] Data files are packaged and readable from the app sandbox on both platforms.
- [ ] Spike findings (build setup, gotchas, size) are written up for the team/agent picking up ZOD-EPH-002.
- [ ] A decision is recorded on native assets vs. CMake/Xcode for the production build.

## Dependencies

- [ZOD-FND-001](../foundations-architecture/ZOD-FND-001-set-up-the-melos-monorepo-workspace.md) — Set up the Melos monorepo workspace

## Specification References

- ARCH-6
- R-7
- "Running Swiss Ephemeris in Flutter" (Decisions and implications)

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
