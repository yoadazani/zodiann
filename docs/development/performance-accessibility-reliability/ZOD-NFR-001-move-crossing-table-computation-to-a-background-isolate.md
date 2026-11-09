# ZOD-NFR-001 - Move crossing-table computation to a background isolate

## Metadata

- **ID:** ZOD-NFR-001
- **Category:** [Performance, Accessibility & Reliability](../README.md#performance-accessibility-reliability) (`performance-accessibility-reliability/`)
- **Phase:** Phase 2
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Run [ZOD-CRS-004](../computation-engine/ZOD-CRS-004-implement-the-degree-crossing-query-api-range-body-filter-product.md)'s query inside an `Isolate.run`, so dragging/playback never stalls while a long-range crossing table computes (ARCH-1).

## Implementation Details

- Wrap the isolate-safe query API from [ZOD-CRS-004](../computation-engine/ZOD-CRS-004-implement-the-degree-crossing-query-api-range-body-filter-product.md) in `Isolate.run`, passing only sendable data in/out.
- Surface progress to the UI (consumed by [ZOD-UI-011](../shared-ui-design-system/ZOD-UI-011-implement-the-toast-feedback-component-export-status-progress-with.md)'s progress toast) and support cancellation via the toast's Stop action.

## Design Reference

No direct design reference applies to the mechanism; the resulting UI is [ZOD-UI-011](../shared-ui-design-system/ZOD-UI-011-implement-the-toast-feedback-component-export-status-progress-with.md) (progress toast with Stop).

## Acceptance Criteria

- [ ] NFR-P3 passes: computing the maximum-range crossing table does not block the interface; a drag gesture performed in parallel stays smooth.
- [ ] Stop actually cancels the isolate computation, not just hides the toast.

## Dependencies

- [ZOD-CRS-004](../computation-engine/ZOD-CRS-004-implement-the-degree-crossing-query-api-range-body-filter-product.md) — Implement the degree-crossing query API (range, body filter, product limits)
- [ZOD-UI-011](../shared-ui-design-system/ZOD-UI-011-implement-the-toast-feedback-component-export-status-progress-with.md) — Implement the toast/feedback component (export status, progress with Stop)

## Specification References

- ARCH-1
- NFR-P3

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Performance, Accessibility & Reliability" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
