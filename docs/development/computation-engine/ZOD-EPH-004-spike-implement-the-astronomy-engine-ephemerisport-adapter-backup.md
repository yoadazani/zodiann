# ZOD-EPH-004 - Spike + implement the astronomy-engine `EphemerisPort` adapter (backup/oracle)

## Metadata

- **ID:** ZOD-EPH-004
- **Category:** [Computation Engine](../README.md#computation-engine) (`computation-engine/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Implement the backup position source (astronomy-engine, C version via FFI) used both as a runtime fallback and as an independent test oracle.

## Implementation Details

- Same FFI-binding process as [ZOD-FND-003](../foundations-architecture/ZOD-FND-003-spike-swiss-ephemeris-ffi-binding-on-android-and-ios.md), applied to the astronomy-engine C library.
- Implement `EphemerisPort` for the ten bodies at arcminute-level accuracy; the node is computed by formula ([ZOD-EPH-001](../computation-engine/ZOD-EPH-001-implement-the-mean-ascending-lunar-node-formula.md)), since astronomy-engine doesn't provide it per the spec's data-sources table.
- Wire as the automatic fallback when the Swiss Ephemeris FFI binding is unavailable (ARCH-4: swapping is a single injection).

## Design Reference

No direct design reference applies — pure computation / native binding.

## Acceptance Criteria

- [ ] ACC-2 passes: same reference-date set as T-EPH-1, within 1 arcminute of JPL Horizons.
- [ ] Swapping from Swiss Ephemeris to this backup requires only a DI override, no feature-code changes.
- [ ] Node longitude from this path still uses the ZOD-EPH-001 formula, not an astronomy-engine-derived value.

## Dependencies

- [ZOD-FND-002](../foundations-architecture/ZOD-FND-002-define-the-ephemerisport-interface-contract.md) — Define the `EphemerisPort` interface contract
- [ZOD-EPH-001](../computation-engine/ZOD-EPH-001-implement-the-mean-ascending-lunar-node-formula.md) — Implement the mean ascending lunar node formula

## Specification References

- "Data sources, in order of priority" (astronomy-engine row)
- ACC-2
- ARCH-4

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Computation Engine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
