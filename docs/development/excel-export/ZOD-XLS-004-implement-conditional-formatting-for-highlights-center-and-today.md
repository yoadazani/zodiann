# ZOD-XLS-004 - Implement conditional formatting for highlights, center, and today

## Metadata

- **ID:** ZOD-XLS-004
- **Category:** [Excel Export](../README.md#excel-export) (`excel-export/`)
- **Phase:** Phase 3
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Apply the same visual highlight rules the app uses, as live conditional-formatting rules referencing the Helper sheet, plus the amber center border and the live "today" comparison.

## Implementation Details

- Blue/yellow/gray fills driven by the Helper sheet's Blue/Yellow/Gray formulas (EX-14) — never a static, anchor-dependent color.
- Center: amber border, always on the Anchor cell regardless of its value.
- Today: `=INT(CellValue) = INT(NOW())` in dates mode; `=AND(NOW() >= CellValue, NOW() < CellValue + StepHours/24)` in date-and-time mode — recalculates live, so the mark moves with the anchor (EX-13).

## Design Reference

`design-reference/zodiann/MASTER.md` §2.2 color tokens (same fills as the app, though Excel's conditional-formatting palette is a fixed approximation of the token hex values, not a live theme).

## Acceptance Criteria

- [ ] T-EX-4 passes across 9×9 and 61×61: after Excel recalculation, every cell's highlight type matches the app's.
- [ ] Opening the file and changing the system date causes the today mark to move on next recalculation, without editing any cell.
- [ ] Today formulas use only the EX-16-allowed function set.

## Dependencies

- [ZOD-XLS-003](../excel-export/ZOD-XLS-003-implement-the-square-sheet-with-the-live-anchor-input-cell.md) — Implement the "Square" sheet with the live Anchor input cell
- [ZOD-XLS-002](../excel-export/ZOD-XLS-002-implement-the-gann-spiral-helper-sheet-hidden.md) — Implement the Gann spiral "Helper" sheet (hidden)

## Specification References

- EX-1
- EX-13
- EX-14
- T-EX-4

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Excel Export" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
