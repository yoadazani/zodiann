# ZOD-UI-013 - Implement the dialog component

## Metadata

- **ID:** ZOD-UI-013
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the modal dialog shell used for delete confirmation, save-square naming, and any other confirm/cancel flow.

## Implementation Details

- 420px wide, 16px radius, 20/600 title, actions aligned to the end.
- Must trap focus while open and restore focus to the triggering control on close (accessibility parity with the drawer's NFR-X3 requirement).

## Design Reference

`design-reference/zodiann/MASTER.md` §10 "Dialog"; `design-reference/zodiann/screens/04-settings_delete-dialog_desktop_en_dark.png` (the one fully mocked dialog instance — use it as the literal reference for spacing, button placement, and copy tone).

## Acceptance Criteria

- [ ] Dialog matches `04-settings_delete-dialog_*` pixel-for-pixel in both themes.
- [ ] Focus is trapped inside the dialog while open and returns to the trigger on close.
- [ ] Escape/backdrop-tap closes the dialog without taking the destructive action.

## Dependencies

- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)
- [ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) — Implement the typography scale
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens
- [ZOD-UI-004](../shared-ui-design-system/ZOD-UI-004-implement-the-button-components-primary-secondary-accent-outline-quiet.md) — Implement the button components (primary, secondary, accent-outline, quiet, danger) and their states

## Specification References

- DATA-10
- MASTER.md §10 "Dialog"
- NFR-X3 (focus parity)

## Notes

- **Floating layer (ZOD-UI-003):** use `ZodiannElevation.floating` (the theme extension) for the shadow, plus `floatingOutline` (1 px `line`) painted *outside* the box, e.g. as `BoxShadow(color: side.color, spreadRadius: side.width)` after `floating`. The outline applies in both themes (product-owner decision, 2026-11-13).

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
