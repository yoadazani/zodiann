# ZOD-TST-005 - Author the astronomy-engine backup comparison suite (ACC-2)

## Metadata

- **ID:** ZOD-TST-005
- **Category:** [Testing & QA](../README.md#testing-qa) (`testing-qa/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Run the same T-EPH-1 reference set against the astronomy-engine adapter, at the looser arcminute tolerance, to catch a fault in the backup source.

## Implementation Details

- Reuses [ZOD-TST-001](../testing-qa/ZOD-TST-001-build-the-jpl-horizons-reference-dataset-t-eph-1-acc-1.md)'s fixture, swapping the `EphemerisPort` implementation under test to [ZOD-EPH-004](../computation-engine/ZOD-EPH-004-spike-implement-the-astronomy-engine-ephemerisport-adapter-backup.md)'s adapter.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] Every body in the fixture is within 1 arcminute of the JPL Horizons reference using the astronomy-engine adapter.

## Dependencies

- [ZOD-EPH-004](../computation-engine/ZOD-EPH-004-spike-implement-the-astronomy-engine-ephemerisport-adapter-backup.md) — Spike + implement the astronomy-engine `EphemerisPort` adapter (backup/oracle)
- [ZOD-TST-001](../testing-qa/ZOD-TST-001-build-the-jpl-horizons-reference-dataset-t-eph-1-acc-1.md) — Build the JPL Horizons reference dataset (T-EPH-1 / ACC-1)

## Specification References

- ACC-2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
