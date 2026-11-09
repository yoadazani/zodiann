# ZOD-XLS-007 - Implement cached values + recalculate-on-open flag

## Metadata

- **ID:** ZOD-XLS-007
- **Category:** [Excel Export](../README.md#excel-export) (`excel-export/`)
- **Phase:** Phase 3
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Ensure every formula cell also carries a computed cached value at generation time, so the file previews correctly in apps that don't calculate, while still being flagged to recalculate when properly opened.

## Implementation Details

- Write both the formula string and its computed result into every formula cell's XML (standard OOXML `<f>`/`<v>` pair).
- Set the workbook's `fullCalcOnLoad` (or equivalent) flag so Excel/LibreOffice/Google Sheets recalculate on open rather than trusting stale cached values forever.

## Design Reference

No direct design reference applies — file-format correctness requirement.

## Acceptance Criteria

- [ ] T-EX-5 passes: file opens in Excel, LibreOffice, and Google Sheets with no errors; recalculation leaves all cached values unchanged (i.e., they were already correct).
- [ ] A naive preview tool that doesn't execute formulas still shows correct-looking values from the cache.

## Dependencies

- [ZOD-XLS-003](../excel-export/ZOD-XLS-003-implement-the-square-sheet-with-the-live-anchor-input-cell.md) — Implement the "Square" sheet with the live Anchor input cell
- [ZOD-XLS-004](../excel-export/ZOD-XLS-004-implement-conditional-formatting-for-highlights-center-and-today.md) — Implement conditional formatting for highlights, center, and today
- [ZOD-XLS-005](../excel-export/ZOD-XLS-005-implement-the-cell-list-sheet.md) — Implement the "Cell list" sheet

## Specification References

- EX-15
- T-EX-5

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Excel Export" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
