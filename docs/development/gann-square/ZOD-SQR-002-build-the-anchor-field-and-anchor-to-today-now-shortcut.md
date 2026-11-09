# ZOD-SQR-002 - Build the anchor field and "Anchor to today/now" shortcut

## Metadata

- **ID:** ZOD-SQR-002
- **Category:** [Gann Square of Nine](../README.md#gann-square) (`gann-square/`)
- **Phase:** Phase 3
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the mode-dependent anchor input (hidden in numbers mode) and its shortcut button.

## Implementation Details

- Dates mode: date field, "Anchor to today" button. Date-and-time mode: date+time-to-the-minute field, "Anchor to now" button. Numbers mode: no anchor field at all (center is always 1) — per DESIGN_DECISIONS D15.
- Default anchor: today at 00:00.
- Shortcut button sets the field to the current moment (matching field precision for the mode).

## Design Reference

`design-reference/zodiann/screens/02-square-of-nine_dates_desktop_en_dark.png` "Anchor" field + "Anchor to today" button; `design-reference/zodiann/DESIGN_DECISIONS.md` D15 for the numbers-mode-hides-anchor rule (explicitly does **not** resolve the related open Excel numeric-anchor question, which stays open per §6).

## Acceptance Criteria

- [ ] Anchor field and shortcut button are hidden entirely in numbers mode.
- [ ] Default anchor on first open is today at 00:00.
- [ ] Shortcut button correctly sets today/now depending on mode.

## Dependencies

- [ZOD-UI-005](../shared-ui-design-system/ZOD-UI-005-implement-the-input-field-component.md) — Implement the input/field component
- [ZOD-UI-004](../shared-ui-design-system/ZOD-UI-004-implement-the-button-components-primary-secondary-accent-outline-quiet.md) — Implement the button components (primary, secondary, accent-outline, quiet, danger) and their states
- [ZOD-SQR-001](../gann-square/ZOD-SQR-001-build-the-mode-switcher-with-state-preservation.md) — Build the mode switcher with state preservation

## Specification References

- SQ-5
- DESIGN_DECISIONS.md D15

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Gann Square of Nine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
