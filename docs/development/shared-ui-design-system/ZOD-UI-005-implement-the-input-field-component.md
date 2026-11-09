# ZOD-UI-005 - Implement the input/field component

## Metadata

- **ID:** ZOD-UI-005
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the text/date/number input used throughout (anchor field, time field, cells field, etc.) with its label, leading icon, and state treatments.

## Implementation Details

- Label above the field, 12/500 in `text-2`; field 40px high on `bg-raised` with a `line` border; optional leading icon in `text-3`.
- Focus: `accent` border + 3px `accent-soft` halo. Error: `danger` border + halo, with a message under the field explaining how to fix the value (NFR-R2). Disabled: 45% opacity.

## Design Reference

`design-reference/zodiann/MASTER.md` §10 "Inputs"; `design-reference/zodiann/components/components_dark.png`/`_light.png` "Inputs and selectors" section (shows default, focused, and error states for the Anchor and Cells fields specifically).

## Acceptance Criteria

- [ ] Default/focus/error/disabled states match the component sheet.
- [ ] Error state always renders an explanatory message, never color alone (NFR-X4 principle applied to forms).
- [ ] Invalid input (e.g., text in a date field) triggers the error state rather than crashing (NFR-R2).

## Dependencies

- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)
- [ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) — Implement the typography scale
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens

## Specification References

- MASTER.md §10 "Inputs"
- NFR-R2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
