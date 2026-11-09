# ZOD-SET-005 - Build the "Your data" panel (export/import backup, delete all data)

## Metadata

- **ID:** ZOD-SET-005
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 4
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the backup export/import rows and the destructive delete-all-data action with its confirmation dialog.

## Implementation Details

- Export backup: one JSON file with settings and saved squares (DATA-3, DATA-9); Import backup: replaces settings and adds the squares from the file.
- Delete all data: red label/button, opens the confirmation dialog ([ZOD-UI-013](../shared-ui-design-system/ZOD-UI-013-implement-the-dialog-component.md)) before executing (DATA-10).

## Design Reference

`design-reference/zodiann/screens/04-settings_desktop_en_dark.png` "Your data" panel; `design-reference/zodiann/screens/04-settings_delete-dialog_desktop_en_dark.png` (the exact confirmation dialog to reuse via [ZOD-UI-013](../shared-ui-design-system/ZOD-UI-013-implement-the-dialog-component.md)).

## Acceptance Criteria

- [ ] Export produces a single versioned JSON file (ZOD-DAT-008).
- [ ] Import replaces settings and adds (not replaces) saved squares from the file (ZOD-DAT-008).
- [ ] Delete-all-data requires confirmation via the dialog before any data is removed.

## Dependencies

- [ZOD-SET-001](../settings-persistence/ZOD-SET-001-build-the-settings-screen-panel-layout.md) — Build the Settings screen panel layout
- [ZOD-UI-013](../shared-ui-design-system/ZOD-UI-013-implement-the-dialog-component.md) — Implement the dialog component

## Specification References

- DATA-3
- DATA-9
- DATA-10
- MASTER.md §9

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
