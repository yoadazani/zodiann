# ZOD-XLS-014 - Implement Square of Nine "Cell list" CSV export

## Metadata

- **ID:** ZOD-XLS-014
- **Category:** [Excel Export](../README.md#excel-export) (`excel-export/`)
- **Phase:** Phase 3
- **Priority:** Low
- **Status:** Not Started
- **Scope:** MVP

## Description

Export the cell-list data alone (no formulas, no formatting) as a plain CSV, for users who just want the raw data.

## Implementation Details

- Same columns as [ZOD-XLS-005](../excel-export/ZOD-XLS-005-implement-the-cell-list-sheet.md)'s Cell list sheet, flattened to static CSV values (CSV has no live formulas, so values are computed once at export time).

## Design Reference

No direct design reference applies — CSV is a secondary, data-only export alongside the full xlsx.

## Acceptance Criteria

- [ ] CSV opens cleanly in a spreadsheet app with correct column headers and values matching the on-screen cell list for that square.

## Dependencies

- [ZOD-XLS-005](../excel-export/ZOD-XLS-005-implement-the-cell-list-sheet.md) — Implement the "Cell list" sheet

## Specification References

- "Other formats" table (Square of Nine CSV row)

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Excel Export" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
