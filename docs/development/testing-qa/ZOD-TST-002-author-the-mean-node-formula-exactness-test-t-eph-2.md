# ZOD-TST-002 - Author the mean-node formula exactness test (T-EPH-2)

## Metadata

- **ID:** ZOD-TST-002
- **Category:** [Testing & QA](../README.md#testing-qa) (`testing-qa/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Dedicated test verifying [ZOD-EPH-001](../computation-engine/ZOD-EPH-001-implement-the-mean-ascending-lunar-node-formula.md)'s node formula matches the spec's closed form exactly (within the defined accuracy range) on the same date set as T-EPH-1.

## Implementation Details

- Compute `Ω` independently (e.g., via a second, hand-written implementation of the same formula in the test file) and compare against the production implementation's output, to catch a transcription bug in the production code, not just re-validate the same formula against itself.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] Test fails if the formula's coefficients (`125.04452`, `1934.136261`) are altered in the production code.
- [ ] Passes within the documented ~0.01° accuracy bound.

## Dependencies

- [ZOD-EPH-001](../computation-engine/ZOD-EPH-001-implement-the-mean-ascending-lunar-node-formula.md) — Implement the mean ascending lunar node formula

## Specification References

- T-EPH-2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
