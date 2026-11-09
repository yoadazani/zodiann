# ZOD-CRS-004 - Implement the degree-crossing query API (range, body filter, product limits)

## Metadata

- **ID:** ZOD-CRS-004
- **Category:** [Computation Engine](../README.md#computation-engine) (`computation-engine/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Expose the public entry point the wheel screen calls: "for this body (or all bodies), find every crossing of every whole degree in this date range," with the spec's hard limits enforced in the core (not just the UI).

## Implementation Details

- Accept: one body or "all" (Moon excluded from "all" per WH-20 — enforced here, not just filtered in the UI, so a background computation never wastes time on a Moon-in-"all" case), a date range up to 3,660 days, an optional sign/degree-within-sign filter.
- Internally: for "all," run [ZOD-CRS-001](../computation-engine/ZOD-CRS-001-implement-segment-splitting-at-stationary-points.md)/002/003 once per included body per requested degree(s), merging results sorted by time.
- Cap returned rows at 2,500 but also return the true total count (for the UI's "43 crossings" counter) — capping must not silently distort the count shown to the user.
- Designed to run inside an `Isolate` (actual isolate wiring is [ZOD-NFR-001](../performance-accessibility-reliability/ZOD-NFR-001-move-crossing-table-computation-to-a-background-isolate.md), but this API must be isolate-safe: no closures over non-sendable state).

## Design Reference

No direct design reference applies — this is the core API consumed by `design-reference/zodiann/screens/01-zodiac-wheel_*` "Degree crossings" panel, built in [ZOD-WHL-022](../zodiac-wheel/ZOD-WHL-022-implement-tap-crossing-row-to-navigate-interaction.md) onward.

## Acceptance Criteria

- [ ] Requesting "all" never computes the Moon.
- [ ] A query spanning the full 3,660-day limit returns within the 2-second-per-year budget scaled appropriately (performance verified in ZOD-NFR-003/004).
- [ ] The row cap (2,500) and the true total are both correctly reported for a query that exceeds the cap.
- [ ] T-CRS-2 passes using this API end-to-end against the small-step-scan oracle.

## Dependencies

- [ZOD-CRS-001](../computation-engine/ZOD-CRS-001-implement-segment-splitting-at-stationary-points.md) — Implement segment splitting at stationary points
- [ZOD-CRS-002](../computation-engine/ZOD-CRS-002-implement-the-per-segment-crossing-solver-bisection-brent-newton.md) — Implement the per-segment crossing solver (bisection/Brent + Newton refinement)
- [ZOD-CRS-003](../computation-engine/ZOD-CRS-003-implement-the-retrograde-mark-on-crossing-results.md) — Implement the retrograde mark on crossing results

## Specification References

- WH-16
- WH-17
- WH-20
- "Product limits" (Degree crossings section)

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Computation Engine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
