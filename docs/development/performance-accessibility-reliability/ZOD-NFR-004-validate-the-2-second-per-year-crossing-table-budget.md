# ZOD-NFR-004 - Validate the 2-second-per-year crossing-table budget

## Metadata

- **ID:** ZOD-NFR-004
- **Category:** [Performance, Accessibility & Reliability](../README.md#performance-accessibility-reliability) (`performance-accessibility-reliability/`)
- **Phase:** Phase 2
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Verify the degree-crossing table for one planet over one year computes in under two seconds on a mid-range phone, per the product's stated success criterion.

## Implementation Details

- Benchmark [ZOD-CRS-004](../computation-engine/ZOD-CRS-004-implement-the-degree-crossing-query-api-range-body-filter-product.md)'s query for a single body over a 1-year range on representative mid-range hardware (or an equivalent emulator profile).
- If the budget isn't met, profile [ZOD-CRS-001](../computation-engine/ZOD-CRS-001-implement-segment-splitting-at-stationary-points.md)/002 for the bottleneck (likely segment-splitting sample density) before optimizing.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] A single-body, one-year crossing query completes in under 2 seconds on the target mid-range profile.

## Dependencies

- [ZOD-CRS-004](../computation-engine/ZOD-CRS-004-implement-the-degree-crossing-query-api-range-body-filter-product.md) — Implement the degree-crossing query API (range, body filter, product limits)
- [ZOD-NFR-001](../performance-accessibility-reliability/ZOD-NFR-001-move-crossing-table-computation-to-a-background-isolate.md) — Move crossing-table computation to a background isolate

## Specification References

- "Success criteria (measurable targets)" (2-second budget)

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Performance, Accessibility & Reliability" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
