# ZOD-EPH-002 - Implement the Swiss Ephemeris `EphemerisPort` adapter (data-file mode)

## Metadata

- **ID:** ZOD-EPH-002
- **Category:** [Computation Engine](../README.md#computation-engine) (`computation-engine/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Implement the primary position source: Swiss Ephemeris with packaged JPL-based data files, via the FFI binding proven in [ZOD-FND-003](../foundations-architecture/ZOD-FND-003-spike-swiss-ephemeris-ffi-binding-on-android-and-ios.md).

## Implementation Details

- Implement `EphemerisPort` for all ten bodies (`sun`…`pluto`); the node uses [ZOD-EPH-001](../computation-engine/ZOD-EPH-001-implement-the-mean-ascending-lunar-node-formula.md), not this adapter.
- Fixed, documented computation settings (must match exactly): geocentric viewpoint; apparent position (light time, aberration, light deflection, nutation); ecliptic and equinox of date (tropical), **no extra precession correction**; local time converted to UTC then to terrestrial time via ΔT.
- Return longitude speed (degrees/day) directly from the ephemeris, not derived by finite-differencing two calls (CRS-A1).
- Detect and surface "requested date outside packaged file coverage" as a typed error (uses [ZOD-FND-011](../foundations-architecture/ZOD-FND-011-decide-and-document-the-ephemeris-data-file-coverage-range.md)'s chosen range), rather than silently returning an inaccurate value (R-2).
- Package/propagate a ΔT-forecast warning for dates far in the future (ΔT for the future is a forecast; Moon accuracy drops) — expose this as a flag the UI can turn into a banner (feeds ZOD-NFR banner work).

## Design Reference

No direct design reference applies — pure computation.

## Acceptance Criteria

- [ ] T-EPH-1 passes: Sun and Moon longitude within 1 arcsecond of JPL Horizons/Swiss Ephemeris reference data on 10+ dates.
- [ ] Requesting a date outside the packaged range returns the typed "out of range" error, not a silently wrong value.
- [ ] No code path applies an additional precession correction on top of the library's tropical-of-date output (guarded by the regression test T-EPH-1/ACC-5).
- [ ] Longitude speed is read from the ephemeris, never finite-differenced.

## Dependencies

- [ZOD-FND-002](../foundations-architecture/ZOD-FND-002-define-the-ephemerisport-interface-contract.md) — Define the `EphemerisPort` interface contract
- [ZOD-FND-003](../foundations-architecture/ZOD-FND-003-spike-swiss-ephemeris-ffi-binding-on-android-and-ios.md) — Spike: Swiss Ephemeris FFI binding on Android and iOS
- [ZOD-FND-011](../foundations-architecture/ZOD-FND-011-decide-and-document-the-ephemeris-data-file-coverage-range.md) — Decide and document the ephemeris data-file coverage range

## Specification References

- "Planet position"
- "Computation settings that must be fixed and documented"
- CRS-A1
- NFR-A1
- R-2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Computation Engine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
