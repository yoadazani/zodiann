# ZOD-TST-015 - Author the Excel export test suite (T-EX-1 through T-EX-6)

## Metadata

- **ID:** ZOD-TST-015
- **Category:** [Testing & QA](../README.md#testing-qa) (`testing-qa/`)
- **Phase:** Phase 3
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Dedicated, consolidated test suite for the six named Excel-export scenarios, each already an acceptance criterion on its owning ZOD-XLS task — this task is the trackable suite and the cross-app recalculation harness they share.

## Implementation Details

- Build a reusable test harness that can open a generated xlsx, trigger recalculation (via a headless LibreOffice invocation or an equivalent recalculation engine), and read back cell values — this is the shared infrastructure T-EX-1 through T-EX-5 all need.
- T-EX-1 ([ZOD-XLS-003](../excel-export/ZOD-XLS-003-implement-the-square-sheet-with-the-live-anchor-input-cell.md)), T-EX-2 ([ZOD-XLS-003](../excel-export/ZOD-XLS-003-implement-the-square-sheet-with-the-live-anchor-input-cell.md)), T-EX-3 ([ZOD-XLS-003](../excel-export/ZOD-XLS-003-implement-the-square-sheet-with-the-live-anchor-input-cell.md)), T-EX-4 ([ZOD-XLS-002](../excel-export/ZOD-XLS-002-implement-the-gann-spiral-helper-sheet-hidden.md)/004, both 9×9 and 61×61), T-EX-5 ([ZOD-XLS-007](../excel-export/ZOD-XLS-007-implement-cached-values-recalculate-on-open-flag.md), opens clean in all three apps), T-EX-6 ([ZOD-XLS-003](../excel-export/ZOD-XLS-003-implement-the-square-sheet-with-the-live-anchor-input-cell.md), wrong-type anchor rejected).

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] A headless recalculation harness exists and is reused by all six test cases.
- [ ] All six named scenarios pass and are wired into CI.

## Dependencies

- [ZOD-XLS-002](../excel-export/ZOD-XLS-002-implement-the-gann-spiral-helper-sheet-hidden.md) — Implement the Gann spiral "Helper" sheet (hidden)
- [ZOD-XLS-003](../excel-export/ZOD-XLS-003-implement-the-square-sheet-with-the-live-anchor-input-cell.md) — Implement the "Square" sheet with the live Anchor input cell
- [ZOD-XLS-004](../excel-export/ZOD-XLS-004-implement-conditional-formatting-for-highlights-center-and-today.md) — Implement conditional formatting for highlights, center, and today
- [ZOD-XLS-007](../excel-export/ZOD-XLS-007-implement-cached-values-recalculate-on-open-flag.md) — Implement cached values + recalculate-on-open flag

## Specification References

- T-EX-1
- T-EX-2
- T-EX-3
- T-EX-4
- T-EX-5
- T-EX-6

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
