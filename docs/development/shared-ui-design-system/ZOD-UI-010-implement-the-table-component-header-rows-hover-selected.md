# ZOD-UI-010 - Implement the table component (header, rows, hover, selected)

## Metadata

- **ID:** ZOD-UI-010
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the shared table shell used by the positions table and the degree-crossings table.

## Implementation Details

- Header: 12/500 in `text-3`, sentence case.
- Rows: 44px high with a `line-soft` divider.
- Hover: `surface-2` fill. Selected: `accent-soft` fill with a 3px `accent` edge on the start side (logical "start," flips under RTL).

## Design Reference

`design-reference/zodiann/MASTER.md` §10 "Tables"; `design-reference/zodiann/screens/01-zodiac-wheel_desktop_en_dark.png` (Positions table showing the selected Sun row with its start-edge accent bar) and the Hebrew variant to confirm the edge flips correctly.

## Acceptance Criteria

- [ ] Header, row, hover, and selected states match the screenshots in both themes.
- [ ] The selected-row accent edge renders on the correct logical side in both LTR and RTL.

## Dependencies

- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)
- [ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) — Implement the typography scale
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens

## Specification References

- MASTER.md §10 "Tables"
- L-4

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
