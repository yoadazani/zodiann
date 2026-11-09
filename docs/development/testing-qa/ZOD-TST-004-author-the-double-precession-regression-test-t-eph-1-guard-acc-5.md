# ZOD-TST-004 - Author the double-precession regression test (T-EPH-1 guard / ACC-5)

## Metadata

- **ID:** ZOD-TST-004
- **Category:** [Testing & QA](../README.md#testing-qa) (`testing-qa/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

The single most emphasized regression test in the spec: catch a reintroduced extra precession correction, which "shifts all positions by a few tenths of a degree."

## Implementation Details

- This is explicitly called out as mandatory and must remain in the suite permanently (ACC-5: "The regression test for the double precession correction (T-EPH-1) remains mandatory").
- Construct the test so it would clearly fail (by a detectable, non-trivial margin) if someone mistakenly adds a precession step on top of the library's already-tropical-of-date output — not just rely on the general 1-arcsecond tolerance incidentally catching it.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] Deliberately reintroducing a precession correction into a test double of the computation causes this test to fail clearly, not marginally.
- [ ] This test is marked in the suite as permanent/non-removable (comment or tag), per ACC-5's explicit "remains mandatory" instruction.

## Dependencies

- [ZOD-EPH-002](../computation-engine/ZOD-EPH-002-implement-the-swiss-ephemeris-ephemerisport-adapter-data-file-mode.md) — Implement the Swiss Ephemeris `EphemerisPort` adapter (data-file mode)
- [ZOD-TST-001](../testing-qa/ZOD-TST-001-build-the-jpl-horizons-reference-dataset-t-eph-1-acc-1.md) — Build the JPL Horizons reference dataset (T-EPH-1 / ACC-1)

## Specification References

- NFR-A1
- ACC-5
- T-EPH-1

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
