# ZOD-DAT-004 - Implement delete (with confirmation)

## Metadata

- **ID:** ZOD-DAT-004
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 3
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Implement the delete action on a saved square, gated by the shared confirmation dialog.

## Implementation Details

- Trash icon opens the confirmation dialog ([ZOD-UI-013](../shared-ui-design-system/ZOD-UI-013-implement-the-dialog-component.md)); confirming removes the `SquareConfig` from storage and the list.

## Design Reference

`design-reference/zodiann/screens/03-saved-squares_desktop_en_dark.png` (trash icon in each row); dialog follows the same pattern as `04-settings_delete-dialog_desktop_en_dark.png`.

## Acceptance Criteria

- [ ] Deleting requires confirmation; canceling leaves the square untouched.
- [ ] Confirmed delete removes the square from both the list and persistent storage.

## Dependencies

- [ZOD-DAT-001](../settings-persistence/ZOD-DAT-001-build-the-saved-squares-list-screen.md) — Build the Saved squares list screen
- [ZOD-UI-013](../shared-ui-design-system/ZOD-UI-013-implement-the-dialog-component.md) — Implement the dialog component

## Specification References

- UC10

## Notes

- **From ZOD-UI-013 (2026-11-23):** open it with `showZodiannDialog<T>(context, builder: ...)` returning a `ZodiannDialog(title:, message:, actions:)`; the caller localizes every string and builds the `ZodiannButton`s. Escape, a scrim tap and the back button complete the future with `null` and run no callback, so treat only an explicit value (the confirm button pops `true`) as consent. Put `autofocus: true` on Cancel for a destructive confirmation. There is **no re-entry guard**: disable the trigger while the future is pending, or a second tap stacks a second dialog.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
