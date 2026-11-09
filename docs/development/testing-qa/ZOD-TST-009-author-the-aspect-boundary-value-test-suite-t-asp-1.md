# ZOD-TST-009 - Author the aspect boundary-value test suite (T-ASP-1)

## Metadata

- **ID:** ZOD-TST-009
- **Category:** [Testing & QA](../README.md#testing-qa) (`testing-qa/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Dedicated test asserting every row of the aspects table is tested exactly at its orb boundary and just outside it, per the spec's explicit per-row requirement.

## Implementation Details

- For each of the five aspects (conjunction/sextile/square/trine/opposition), construct a body pair exactly at `angle ± orb` (should detect) and at `angle ± orb + ε` (should not detect).
- Must be parameterized/looped per row so adding a future aspect type to the table automatically gets this coverage (per "every row in the aspects table in this document requires a test").

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] All five aspects have both an in-bounds and an out-of-bounds boundary case tested.
- [ ] Test structure makes it obvious a new aspect-table row needs a corresponding case added.

## Dependencies

- [ZOD-ASP-001](../computation-engine/ZOD-ASP-001-implement-aspect-detection-between-body-pairs.md) — Implement aspect detection between body pairs

## Specification References

- T-ASP-1

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
