# ZOD-XLS-016 - Localize the Excel export (sheet names, headers, notes, direction)

## Metadata

- **ID:** ZOD-XLS-016
- **Category:** [Excel Export](../README.md#excel-export) (`excel-export/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Write all user-facing export text in the app's language at export time, while keeping formulas and defined names in fixed, locale-independent English.

## Implementation Details

- Sheet names, column headers, and notes are written in the app language at export time (e.g., "Square" sheet stays "Square" in English; translate per L-15).
- Sheet reading direction (RTL/LTR) is set by the export language (L-16) — **this is distinct from the Square sheet's own LTR-always grid ([ZOD-SQR-016](../gann-square/ZOD-SQR-016-enforce-ltr-always-rendering-of-the-square.md)/SQ-21)**, which stays LTR regardless; only the surrounding sheet chrome (Cell list, Details) follows language direction.
- Defined names (`Anchor`, `StepHours`) stay in English in both languages, so formulas remain byte-identical and functional in any Excel locale (EX-17 equivalent / L-17).

## Design Reference

No direct design reference applies to file content; translated string sourcing follows the ARB-file pattern from `localization/` (ZOD-L10-001).

## Acceptance Criteria

- [ ] A Hebrew-language export has translated sheet names/headers/notes, RTL sheet direction, but formulas and defined names unchanged from the English export.
- [ ] The underlying formula syntax is verified identical byte-for-byte between an English and a Hebrew export of the same square (only labels/direction differ).

## Dependencies

- [ZOD-XLS-003](../excel-export/ZOD-XLS-003-implement-the-square-sheet-with-the-live-anchor-input-cell.md) — Implement the "Square" sheet with the live Anchor input cell
- [ZOD-XLS-005](../excel-export/ZOD-XLS-005-implement-the-cell-list-sheet.md) — Implement the "Cell list" sheet
- [ZOD-XLS-006](../excel-export/ZOD-XLS-006-implement-the-details-sheet.md) — Implement the "Details" sheet
- ZOD-L10-001

## Specification References

- L-15
- L-16
- L-17

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Excel Export" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
