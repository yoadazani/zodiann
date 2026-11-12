# ZOD-TST-002 - Author the mean-node formula exactness test (T-EPH-2)

## Metadata

- **ID:** ZOD-TST-002
- **Category:** [Testing & QA](../README.md#testing-qa) (`testing-qa/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Done
- **Scope:** MVP

## Description

Dedicated test verifying [ZOD-EPH-001](../computation-engine/ZOD-EPH-001-implement-the-mean-ascending-lunar-node-formula.md)'s node formula matches the spec's closed form exactly (within the defined accuracy range) on the same date set as T-EPH-1. **This task defines that shared date set** (a versioned fixture of ≥50 UTC instants across 1900–2100, matching ACC-1's shape), and [ZOD-TST-001](ZOD-TST-001-build-the-jpl-horizons-reference-dataset-t-eph-1-acc-1.md) reuses it. See Notes.

## Implementation Details

- Compute `Ω` independently (e.g., via a second, hand-written implementation of the same formula in the test file) and compare against the production implementation's output, to catch a transcription bug in the production code, not just re-validate the same formula against itself.
- **The reference implementation must be separate:** expected values must never be computed by calling the production helpers (`meanAscendingNodeAt` / `MeanAscendingNodeFormula`) or reusing their constants.
- **Prove that coefficient changes are detected:** temporarily alter each production coefficient in turn (`125.04452`, then `1934.136261`), confirm the T-EPH-2 suite fails, restore it, and record the result.
- **Accuracy bound:** compare the production output against the full Meeus mean-node formula (with its T², T³ and T⁴ terms) over ±100 years around 2000-01-01 12:00 UTC, and assert that the deviation is within the spec's ~0.01°.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [x] Expected values come from a separately implemented reference formula in the test. The production helpers are never called to compute them.
- [x] Test fails if the formula's coefficients (`125.04452`, `1934.136261`) are altered in the production code. This is verified by temporarily altering each coefficient and observing the failure.
- [x] Passes within the documented ~0.01° accuracy bound against the full Meeus mean-node formula over ±100 years around 2000-01-01 12:00 UTC.

## Dependencies

- [ZOD-EPH-001](../computation-engine/ZOD-EPH-001-implement-the-mean-ascending-lunar-node-formula.md) — Implement the mean ascending lunar node formula

## Specification References

- T-EPH-2

## Notes

- 2026-11-12 (product-owner decision): this task owns the dedicated T-EPH-2 verification of the node formula implemented in ZOD-EPH-001, whose own criterion was amended to point here. It **depends on ZOD-EPH-001** (and not the reverse) and is planned and delivered separately.
- 2026-11-12 (product-owner decision): T-EPH-1's dataset (ZOD-TST-001) is blocked behind ZOD-EPH-002 and ZOD-FND-003. So instead of waiting for it, **this task defines the shared reference date set**: a versioned JSON fixture of ≥50 UTC instants across 1900–2100, including year boundaries and the J2000 epoch, matching ACC-1's shape. ZOD-TST-001 reuses these instants for its JPL Horizons queries. ZOD-TST-001 is **not** a dependency of this task.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
