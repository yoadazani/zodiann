# ZOD-UI-006 - Implement the segmented control component

## Metadata

- **ID:** ZOD-UI-006
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the segmented control used for mode switches (drag mode, square mode, size presets, step size, language, theme, etc.), including its "planned/disabled option" state.

## Implementation Details

- `bg-raised` track with 3px inset; selected thumb is `surface-3` with an inset 1px `accent-line` ring, icon/text at full `text` strength when selected.
- A planned-but-unavailable option (e.g., Sidereal zodiac) renders at 40% opacity and is non-interactive.
- Must stretch full-width on phone (per breakpoint rules, MASTER.md §6) and wrap into a reasonable width on desktop/tablet.

## Design Reference

`design-reference/zodiann/MASTER.md` §10 "Segmented control"; `design-reference/zodiann/components/components_dark.png`/`_light.png` ("Segmented, mode" row shows Dates/Date and time selected states, plus Tropical/Sidereal(planned) showing the disabled-option treatment).

## Acceptance Criteria

- [ ] Selected/unselected/disabled-planned states match the component sheet pixel-for-pixel.
- [ ] On a phone-width layout the control stretches to fill its row (per MASTER.md §6).
- [ ] The disabled "planned" option cannot be selected by tap, mouse, or keyboard.

## Dependencies

- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)
- [ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) — Implement the typography scale
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens

## Specification References

- MASTER.md §10 "Segmented control"
- MASTER.md §6 "Breakpoints"
- D19

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
