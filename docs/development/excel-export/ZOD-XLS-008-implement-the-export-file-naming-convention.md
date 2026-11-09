# ZOD-XLS-008 - Implement the export file-naming convention

## Metadata

- **ID:** ZOD-XLS-008
- **Category:** [Excel Export](../README.md#excel-export) (`excel-export/`)
- **Phase:** Phase 3
- **Priority:** Low
- **Status:** Not Started
- **Scope:** MVP

## Description

Name the generated file per the mode and size, matching the spec's example exactly.

## Implementation Details

- Pattern: `gann-square-of-nine_<mode>_<size>.xlsx`, e.g., `gann-square-of-nine_dates_43x43.xlsx`.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] File name matches the pattern for all three modes and a range of sizes, including custom sizes.

## Dependencies

- [ZOD-XLS-003](../excel-export/ZOD-XLS-003-implement-the-square-sheet-with-the-live-anchor-input-cell.md) — Implement the "Square" sheet with the live Anchor input cell

## Specification References

- EX-4

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Excel Export" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
