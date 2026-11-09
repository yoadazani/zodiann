# ZOD-XLS-010 - Build the export status UI (disabled button + toast states)

## Metadata

- **ID:** ZOD-XLS-010
- **Category:** [Excel Export](../README.md#excel-export) (`excel-export/`)
- **Phase:** Phase 3
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Wire the Export button's disabled-during-export state and the four toast states to the real export pipeline.

## Implementation Details

- Button disables for the export's duration; toast cycles through preparing (progress bar) → saved (with Share action) / canceled / error (cause + remedy), per EX-6.
- Reuses [ZOD-UI-011](../shared-ui-design-system/ZOD-UI-011-implement-the-toast-feedback-component-export-status-progress-with.md)'s toast component.

## Design Reference

`design-reference/zodiann/components/components_dark.png` "Feedback" section (the exact four export-toast strings/layouts to reuse).

## Acceptance Criteria

- [ ] T-UI-5 passes: tapping Export offers saving a file, and the saved file opens in Excel with the three sheets.
- [ ] Button is non-interactive while export is in progress.
- [ ] All four toast states are reachable (success, cancel, error at minimum via simulated failure).

## Dependencies

- [ZOD-XLS-009](../excel-export/ZOD-XLS-009-meet-the-export-performance-budget-3s-at-61-61-non-blocking.md) — Meet the export performance budget (≤3s at 61×61, non-blocking)
- [ZOD-UI-011](../shared-ui-design-system/ZOD-UI-011-implement-the-toast-feedback-component-export-status-progress-with.md) — Implement the toast/feedback component (export status, progress with Stop)

## Specification References

- EX-6
- T-UI-5

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Excel Export" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
