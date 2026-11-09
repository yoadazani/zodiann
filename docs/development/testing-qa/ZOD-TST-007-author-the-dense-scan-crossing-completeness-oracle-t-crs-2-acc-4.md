# ZOD-TST-007 - Author the dense-scan crossing-completeness oracle (T-CRS-2 / ACC-4)

## Metadata

- **ID:** ZOD-TST-007
- **Category:** [Testing & QA](../README.md#testing-qa) (`testing-qa/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the very-small-step brute-force scan (test-only, never shipped as the production method) used to verify the real solver never misses or invents a crossing — directly targeting R-1's named risk.

## Implementation Details

- Implement a naive fixed-step scanner (fine enough to not itself miss a double-crossing near a station) as a test utility, explicitly isolated from production code so it can never accidentally become the shipped algorithm (the spec explicitly forbids that: "a fixed time-step scan is not the primary method").
- Run for every body, including during a known retrograde period, and diff the oracle's crossing count/times against [ZOD-CRS-004](../computation-engine/ZOD-CRS-004-implement-the-degree-crossing-query-api-range-body-filter-product.md)'s real output.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] T-CRS-2 passes: no missing or extra crossing for a fast body (e.g., Moon) and a retrograde body, across the full tested range.
- [ ] ACC-4 passes for every one of the ten bodies.
- [ ] The oracle scanner lives only in test code, never imported by production code paths.

## Dependencies

- [ZOD-CRS-004](../computation-engine/ZOD-CRS-004-implement-the-degree-crossing-query-api-range-body-filter-product.md) — Implement the degree-crossing query API (range, body filter, product limits)

## Specification References

- T-CRS-2
- ACC-4
- R-1

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
