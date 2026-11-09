# ZOD-TST-006 - Author the Astrolog cross-check (ACC-3)

## Metadata

- **ID:** ZOD-TST-006
- **Category:** [Testing & QA](../README.md#testing-qa) (`testing-qa/`)
- **Phase:** Phase 1
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Compare the app's output against Astrolog under identical settings (geocentric, tropical, same node type), requiring any gap above one arcsecond to be explained.

## Implementation Details

- Produce an Astrolog-generated reference set under matched settings.
- Any discrepancy beyond 1 arcsecond must be investigated and documented (not silently accepted) before this test is considered passing.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] Comparison fixture exists and runs in CI.
- [ ] Any gap beyond the 1-arcsecond threshold has a written explanation attached (comment or linked doc), not a loosened tolerance.

## Dependencies

- [ZOD-EPH-002](../computation-engine/ZOD-EPH-002-implement-the-swiss-ephemeris-ephemerisport-adapter-data-file-mode.md) — Implement the Swiss Ephemeris `EphemerisPort` adapter (data-file mode)
- [ZOD-TST-001](../testing-qa/ZOD-TST-001-build-the-jpl-horizons-reference-dataset-t-eph-1-acc-1.md) — Build the JPL Horizons reference dataset (T-EPH-1 / ACC-1)

## Specification References

- ACC-3

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
