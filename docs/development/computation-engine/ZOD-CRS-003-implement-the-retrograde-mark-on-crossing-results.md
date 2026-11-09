# ZOD-CRS-003 - Implement the retrograde mark on crossing results

## Metadata

- **ID:** ZOD-CRS-003
- **Category:** [Computation Engine](../README.md#computation-engine) (`computation-engine/`)
- **Phase:** Phase 1
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Tag each found crossing with whether the body was moving backward at that moment.

## Implementation Details

- Determine the mark by the sign of the difference in the step (i.e., which direction the segment from [ZOD-CRS-001](../computation-engine/ZOD-CRS-001-implement-segment-splitting-at-stationary-points.md) was moving), not a fresh speed lookup.
- Populate the `Crossing.retrograde` field from the data model ([ZOD-FND-012](../foundations-architecture/ZOD-FND-012-define-usersettings-squareconfig-highlightrule-crossing-dart-data.md)).

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] A crossing found inside a backward-moving segment is marked retrograde; one in a forward segment is not.
- [ ] Covered by T-CRS-2 (no crossing is missing or mismarked across a retrograde period).

## Dependencies

- [ZOD-CRS-001](../computation-engine/ZOD-CRS-001-implement-segment-splitting-at-stationary-points.md) — Implement segment splitting at stationary points
- [ZOD-CRS-002](../computation-engine/ZOD-CRS-002-implement-the-per-segment-crossing-solver-bisection-brent-newton.md) — Implement the per-segment crossing solver (bisection/Brent + Newton refinement)

## Specification References

- "The retrograde mark is determined by the sign of the difference in the step"

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Computation Engine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
