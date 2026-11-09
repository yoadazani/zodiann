# ZOD-DAT-003 - Implement inline rename

## Metadata

- **ID:** ZOD-DAT-003
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 3
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Implement the inline rename interaction: the name becomes a focused input with a primary Save button replacing the row's normal actions.

## Implementation Details

- Tapping the pencil icon turns the name into a focused text field ([ZOD-UI-005](../shared-ui-design-system/ZOD-UI-005-implement-the-input-field-component.md)) with a primary "Save" button in place of the row's usual Open/rename/delete icons.

## Design Reference

`design-reference/zodiann/screens/03-saved-squares_desktop_en_dark.png` (the "Spring equinox 2026" row shown mid-rename, with the focused input and primary Save button).

## Acceptance Criteria

- [ ] Tapping rename matches the reference screenshot's in-place editing treatment exactly.
- [ ] Saving the new name updates the stored `SquareConfig` and exits edit mode.

## Dependencies

- [ZOD-DAT-001](../settings-persistence/ZOD-DAT-001-build-the-saved-squares-list-screen.md) — Build the Saved squares list screen
- [ZOD-UI-005](../shared-ui-design-system/ZOD-UI-005-implement-the-input-field-component.md) — Implement the input/field component
- [ZOD-UI-004](../shared-ui-design-system/ZOD-UI-004-implement-the-button-components-primary-secondary-accent-outline-quiet.md) — Implement the button components (primary, secondary, accent-outline, quiet, danger) and their states

## Specification References

- UC10
- MASTER.md §9

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
