# ZOD-TST-003 - Author the retrograde-marking regression test (T-EPH-3)

## Metadata

- **ID:** ZOD-TST-003
- **Category:** [Testing & QA](../README.md#testing-qa) (`testing-qa/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Verify retrograde marking against a known, published Venus or Mercury retrograde window.

## Implementation Details

- Source a published retrograde start/end date pair (e.g., a well-documented Mercury retrograde) as the fixture.
- Assert direct/retrograde/direct transitions land on the correct sides of the known boundary dates.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] Test fails if retrograde detection logic (ZOD-EPH-005) is broken or inverted.
- [ ] Covers at least one full retrograde cycle (direct → retrograde → direct).

## Dependencies

- [ZOD-EPH-005](../computation-engine/ZOD-EPH-005-implement-retrograde-detection-and-position-formatting.md) — Implement retrograde detection and position formatting

## Specification References

- T-EPH-3

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
