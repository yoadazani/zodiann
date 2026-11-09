# ZOD-CRS-002 - Implement the per-segment crossing solver (bisection/Brent + Newton refinement)

## Metadata

- **ID:** ZOD-CRS-002
- **Category:** [Computation Engine](../README.md#computation-engine) (`computation-engine/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Within a single monotonic segment (from [ZOD-CRS-001](../computation-engine/ZOD-CRS-001-implement-segment-splitting-at-stationary-points.md)), find the exact moment longitude equals a target whole degree, to the required precision.

## Implementation Details

- Initial estimate: linear interpolation of the moment a whole degree is crossed within the segment.
- Refine up to three times: `t ← t − (l(t) − d) ÷ v`, where `v` is the instantaneous rate measured over one minute.
- Use a guaranteed-convergent bracketed method (bisection or Brent) within the segment, down to 0.01 arcseconds of longitude (CRS-A3).
- A fixed time-step scan must **not** be the primary method — it's only used as the independent oracle in tests (T-CRS-2).
- Display the resulting moment to the second (CRS-A5).
- Explicitly handle the 359.9999° → 0° wraparound: the degree of a body is `floor(longitude)`, and crossing from 359.9999 into the next whole revolution returns degree `0`, never `360` or a negative value (CRS-A5, T-CRS-3).

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] T-CRS-1 passes: longitude at every reported crossing moment is within the defined tolerance of the requested degree.
- [ ] T-CRS-3 passes: a crossing at the 359.9999→0 boundary reports degree 0.
- [ ] Convergence is to 0.01 arcseconds (CRS-A3), independent of the initial step size used by ZOD-CRS-001.

## Dependencies

- [ZOD-CRS-001](../computation-engine/ZOD-CRS-001-implement-segment-splitting-at-stationary-points.md) — Implement segment splitting at stationary points

## Specification References

- "Degree crossings" (refinement formula)
- CRS-A1 to CRS-A5
- T-CRS-1
- T-CRS-3

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Computation Engine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
