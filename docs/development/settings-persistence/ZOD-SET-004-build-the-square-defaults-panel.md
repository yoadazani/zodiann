# ZOD-SET-004 - Build the Square defaults panel

## Metadata

- **ID:** ZOD-SET-004
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the default-mode, default-size, and date-and-time step-hours controls that seed a newly opened Square screen.

## Implementation Details

- Default mode: Numbers/Dates/Date and time segmented control.
- Default size: 9×9/13×13/17×17/21×21 segmented control.
- Step in date-and-time mode: read/edit row, default 4 hours (feeds `StepHours` default in [ZOD-GAN-003](../computation-engine/ZOD-GAN-003-implement-gann-date-number-mapping-per-mode.md)/[ZOD-XLS-003](../excel-export/ZOD-XLS-003-implement-the-square-sheet-with-the-live-anchor-input-cell.md)).

## Design Reference

`design-reference/zodiann/screens/04-settings_desktop_en_dark.png` "Square defaults" panel.

## Acceptance Criteria

- [ ] Opening the Square screen fresh uses these defaults.
- [ ] Changing step hours here changes the default `StepHours` for new squares, not existing saved ones.

## Dependencies

- [ZOD-SET-001](../settings-persistence/ZOD-SET-001-build-the-settings-screen-panel-layout.md) — Build the Settings screen panel layout
- [ZOD-UI-006](../shared-ui-design-system/ZOD-UI-006-implement-the-segmented-control-component.md) — Implement the segmented control component
- [ZOD-SQR-001](../gann-square/ZOD-SQR-001-build-the-mode-switcher-with-state-preservation.md) — Build the mode switcher with state preservation

## Specification References

- SQ-1 through SQ-10 (defaults)
- MASTER.md §9

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
