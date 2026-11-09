# ZOD-TST-008 - Author the crossing-solver accuracy and boundary tests (T-CRS-1, T-CRS-3)

## Metadata

- **ID:** ZOD-TST-008
- **Category:** [Testing & QA](../README.md#testing-qa) (`testing-qa/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Dedicated test suite for the solver's precision (T-CRS-1) and the 359.9999°→0° wraparound (T-CRS-3), run as standalone unit tests distinct from the end-to-end ACC/T-CRS-2 suites.

## Implementation Details

- T-CRS-1: for a sample of found crossings across multiple bodies/degrees, assert longitude-at-crossing-moment is within the CRS-A3 tolerance (0.01 arcseconds) of the target degree.
- T-CRS-3: specifically construct a crossing right at the 359.9999→0 boundary and assert the reported degree is exactly 0, never 360 or negative.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] T-CRS-1 and T-CRS-3 both exist as named, independently runnable tests.
- [ ] T-CRS-3's boundary case is constructed deliberately (not hoped to occur incidentally in other test data).

## Dependencies

- [ZOD-CRS-002](../computation-engine/ZOD-CRS-002-implement-the-per-segment-crossing-solver-bisection-brent-newton.md) — Implement the per-segment crossing solver (bisection/Brent + Newton refinement)

## Specification References

- T-CRS-1
- T-CRS-3
- CRS-A3
- CRS-A5

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
