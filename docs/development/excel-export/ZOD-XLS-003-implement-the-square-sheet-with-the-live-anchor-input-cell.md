# ZOD-XLS-003 - Implement the "Square" sheet with the live Anchor input cell

## Metadata

- **ID:** ZOD-XLS-003
- **Category:** [Excel Export](../README.md#excel-export) (`excel-export/`)
- **Phase:** Phase 3
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the visible Square sheet: the center cell as a validated, named `Anchor` input, every other cell as a formula derived from it and the Helper sheet's `k`.

## Implementation Details

- Center cell: defined name `Anchor`, visually distinguished formatting, a "Change here" cell note, and input validation matching the mode (number in numbers mode; date in dates mode; date+time in date-and-time mode) — a wrong-type entry is rejected with a message (EX-8, feeds T-EX-6).
- Every other cell's formula, per mode: Numbers `=Anchor + k`; Dates `=Anchor + k` (Excel's date-as-day-count makes this work directly); Date and time `=Anchor + k * StepHours / 24`.
- `StepHours` is a separate named parameter cell (default 4) in date-and-time mode; changing it recalculates every cell (EX-12).
- Moving the anchor updates every cell, color, and the today mark at once, with no macro (EX-10).
- Header above the square: mode, size, anchor. Legend below it (mirrors [ZOD-SQR-018](../gann-square/ZOD-SQR-018-build-the-squares-legend.md)'s on-screen legend).

## Design Reference

`design-reference/zodiann/screens/02-square-of-nine_*` for the visual layout this sheet reproduces (EX-1: "identical to the screen"); `design-reference/zodiann/MASTER.md` §2.2 for the exact highlight/center/today colors to replicate via conditional formatting ([ZOD-XLS-004](../excel-export/ZOD-XLS-004-implement-conditional-formatting-for-highlights-center-and-today.md)).

## Acceptance Criteria

- [ ] T-EX-1 passes: changing the anchor in dates mode updates every cell to match what the app shows for that anchor.
- [ ] T-EX-2 passes: changing a numbers-mode anchor from 1 to 100 makes every cell `100 + k`, with colors/angles unchanged (per EX-11's "geometry is a property of position, not value" rule).
- [ ] T-EX-3 passes: changing `StepHours` from 4 to 6 updates every cell and the today mark.
- [ ] T-EX-6 passes: entering text in a date-mode anchor cell is rejected with a message, square stays intact.

## Dependencies

- [ZOD-XLS-002](../excel-export/ZOD-XLS-002-implement-the-gann-spiral-helper-sheet-hidden.md) — Implement the Gann spiral "Helper" sheet (hidden)

## Specification References

- EX-8
- EX-9
- EX-10
- EX-11
- EX-12
- T-EX-1
- T-EX-2
- T-EX-3
- T-EX-6

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Excel Export" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
