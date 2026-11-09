# ZOD-CRS-001 - Implement segment splitting at stationary points

## Metadata

- **ID:** ZOD-CRS-001
- **Category:** [Computation Engine](../README.md#computation-engine) (`computation-engine/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Split a search range into segments where the longitude speed doesn't change sign, so each segment has at most one crossing per degree and a double crossing near a station is never missed (R-1).

## Implementation Details

- Walk the range at a step small enough that no body moves more than 0.7° per step (per the spec's chosen step bound).
- Detect sign changes in speed between samples; bisect/refine to locate the stationary point precisely (CRS-A4) and store it.
- When the instantaneous rate is close to zero, sample more densely around that point (explicit mitigation for R-1 called out in "Degree crossings").
- Output: an ordered list of segments, each monotonic in longitude, plus the list of stationary points found (needed for CRS-A4 and T-CRS-2 double-crossing tests).

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] For a known retrograde body/period, the solver finds all three crossings of a degree the body passes three times (direct, then backward, then direct again).
- [ ] Stationary points are stored and retrievable (not just used internally and discarded).
- [ ] No segment contains an internal speed-sign change.

## Dependencies

- [ZOD-EPH-002](../computation-engine/ZOD-EPH-002-implement-the-swiss-ephemeris-ephemerisport-adapter-data-file-mode.md) — Implement the Swiss Ephemeris `EphemerisPort` adapter (data-file mode)

## Specification References

- "Degree crossings" (segment splitting)
- CRS-A2
- CRS-A4
- R-1

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Computation Engine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
