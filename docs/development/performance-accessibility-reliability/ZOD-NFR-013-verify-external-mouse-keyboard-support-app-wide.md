# ZOD-NFR-013 - Verify external mouse/keyboard support app-wide

## Metadata

- **ID:** ZOD-NFR-013
- **Category:** [Performance, Accessibility & Reliability](../README.md#performance-accessibility-reliability) (`performance-accessibility-reliability/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Confirm every touch interaction in the app also has a working mouse/keyboard equivalent, beyond the wheel/square-specific keyboard tasks already built.

## Implementation Details

- Sweep every button, segmented control, table row, and dialog for correct focus order, Enter/Space activation, and mouse hover/click behavior.

## Design Reference

No direct design reference applies — verifies already-built components (`shared-ui-design-system/`) for an input modality beyond touch.

## Acceptance Criteria

- [ ] NFR-C3 passes: every interactive element is reachable and operable via keyboard and mouse alone, with no touch-only dead ends.

## Dependencies

- [ZOD-UI-004](../shared-ui-design-system/ZOD-UI-004-implement-the-button-components-primary-secondary-accent-outline-quiet.md) through [ZOD-UI-014](../shared-ui-design-system/ZOD-UI-014-implement-the-hairline-panel-component.md)
- [ZOD-WHL-012](../zodiac-wheel/ZOD-WHL-012-implement-external-keyboard-controls-for-the-wheel.md) — Implement external-keyboard controls for the wheel
- [ZOD-SQR-011](../gann-square/ZOD-SQR-011-implement-keyboard-cell-selection-navigation.md) — Implement keyboard cell-selection navigation

## Specification References

- NFR-C3

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Performance, Accessibility & Reliability" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
