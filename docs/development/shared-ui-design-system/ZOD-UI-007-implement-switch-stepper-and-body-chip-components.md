# ZOD-UI-007 - Implement switch, stepper, and body-chip components

## Metadata

- **ID:** ZOD-UI-007
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Build three smaller selection controls used in Settings and the wheel's body filter.

## Implementation Details

- Switch: 40×24, used for Reduced motion override, etc.
- Orb stepper: 36px high, `− value +` layout, used for aspect-orb editing ([ZOD-ASP-002](../computation-engine/ZOD-ASP-002-implement-aspect-orb-configuration-data-flow.md)).
- Body chips: toggleable, `accent-soft` fill + `accent-line` border when on, used for "Visible bodies" selection in Settings and degree-table body filter styling cues.

## Design Reference

`design-reference/zodiann/MASTER.md` §10 "Others"; `design-reference/zodiann/components/components_dark.png`/`_light.png` ("Others" row: switch, orb stepper, body chips, radio list) and `screens/04-settings_desktop_en_dark.png` (orb steppers, body chips in context).

## Acceptance Criteria

- [ ] All three controls match the component sheet in both themes.
- [ ] Orb stepper respects any min/max orb bounds defined once D-1 is resolved (ZOD-ASP-002).
- [ ] Body chips reflect on/off state accessibly (not color-only — see ZOD-NFR-010).

## Dependencies

- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)
- [ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) — Implement the typography scale
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens

## Specification References

- MASTER.md §10 "Others"

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
