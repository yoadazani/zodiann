# ZOD-XLS-005 - Implement the "Cell list" sheet

## Metadata

- **ID:** ZOD-XLS-005
- **Category:** [Excel Export](../README.md#excel-export) (`excel-export/`)
- **Phase:** Phase 3
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the row-per-cell sheet with live formulas for square/root/ring/angle/direction/highlight, filtering, sorting, and RTL support.

## Implementation Details

- Columns: number, square (live `=n^2`), square root (live `=SQRT(n)`), ring, angle, direction, highlight, and the cell's position in the Square sheet (a cross-sheet reference, not a duplicated static value, per EX-14).
- Date modes add date and weekday columns; hour mode additionally adds a time column.
- Frozen header row, AutoFilter enabled, sortable.
- Sheet direction (RTL/LTR) is set by the export language (L-16), independent of the formulas themselves (which stay standard English syntax so they work in any Excel locale, per L-16).

## Design Reference

No visual design reference in `design-reference/` (this is a data sheet, not a screen mockup) — structure and content are fully specified textually in EX-2 and Appendix E.

## Acceptance Criteria

- [ ] Square and root columns are live formulas, not cached static numbers (verified by changing the Anchor and confirming this sheet updates too).
- [ ] Header row stays frozen while scrolling; filter/sort both function in Excel.
- [ ] A Hebrew-language export has this sheet laid out right-to-left.

## Dependencies

- [ZOD-XLS-003](../excel-export/ZOD-XLS-003-implement-the-square-sheet-with-the-live-anchor-input-cell.md) — Implement the "Square" sheet with the live Anchor input cell
- [ZOD-XLS-002](../excel-export/ZOD-XLS-002-implement-the-gann-spiral-helper-sheet-hidden.md) — Implement the Gann spiral "Helper" sheet (hidden)

## Specification References

- EX-2
- EX-14
- L-16

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Excel Export" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
