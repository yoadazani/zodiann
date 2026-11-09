# ZOD-XLS-009 - Meet the export performance budget (≤3s at 61×61, non-blocking)

## Metadata

- **ID:** ZOD-XLS-009
- **Category:** [Excel Export](../README.md#excel-export) (`excel-export/`)
- **Phase:** Phase 3
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Ensure generating the maximum-size export completes within the spec's time budget without freezing the interface.

## Implementation Details

- Run the XML-generation/ZIP-packing work off the UI thread (isolate, consistent with ARCH-1's general rule for heavy computation).
- Profile the full pipeline (Helper sheet + Square + Cell list + Details + ZIP packaging) at 61×61/3,721 cells.

## Design Reference

No direct design reference applies to the computation; the resulting UI (disabled button, progress toast) is [ZOD-XLS-010](../excel-export/ZOD-XLS-010-build-the-export-status-ui-disabled-button-toast-states.md).

## Acceptance Criteria

- [ ] EX-5 passes: 61×61 export completes within 3 seconds on a mid-range device.
- [ ] The UI thread remains responsive (no dropped frames) during the export.

## Dependencies

- [ZOD-XLS-003](../excel-export/ZOD-XLS-003-implement-the-square-sheet-with-the-live-anchor-input-cell.md) — Implement the "Square" sheet with the live Anchor input cell
- [ZOD-XLS-005](../excel-export/ZOD-XLS-005-implement-the-cell-list-sheet.md) — Implement the "Cell list" sheet
- [ZOD-XLS-006](../excel-export/ZOD-XLS-006-implement-the-details-sheet.md) — Implement the "Details" sheet
- [ZOD-XLS-007](../excel-export/ZOD-XLS-007-implement-cached-values-recalculate-on-open-flag.md) — Implement cached values + recalculate-on-open flag

## Specification References

- EX-5

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Excel Export" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
