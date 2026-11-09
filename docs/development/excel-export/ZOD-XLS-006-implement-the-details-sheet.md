# ZOD-XLS-006 - Implement the "Details" sheet

## Metadata

- **ID:** ZOD-XLS-006
- **Category:** [Excel Export](../README.md#excel-export) (`excel-export/`)
- **Phase:** Phase 3
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the metadata sheet: mode, size, anchor, today's cell and position, spiral direction, angle-measurement explanation, and creation date.

## Implementation Details

- Static-at-export-time content (not live formulas) per EX-3, except where explicitly noted otherwise is needed — confirm with EX-3's literal field list: mode, size, anchor date, the cell of today and its position in the Square sheet, spiral direction, how the angle is measured, creation date.

## Design Reference

No direct design reference in `design-reference/` — structure fully specified in EX-3 and Appendix E.

## Acceptance Criteria

- [ ] All fields listed in EX-3 are present with correct values for the exported square.
- [ ] Sheet order is Square, Cell list, Details — exactly as Appendix E specifies.

## Dependencies

- [ZOD-XLS-003](../excel-export/ZOD-XLS-003-implement-the-square-sheet-with-the-live-anchor-input-cell.md) — Implement the "Square" sheet with the live Anchor input cell

## Specification References

- EX-3
- Appendix E

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Excel Export" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
