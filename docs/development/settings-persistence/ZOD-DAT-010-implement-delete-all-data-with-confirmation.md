# ZOD-DAT-010 - Implement "Delete all data" with confirmation

## Metadata

- **ID:** ZOD-DAT-010
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Implement the destructive action that clears every setting and saved square from the device, gated by the shared confirmation dialog.

## Implementation Details

- Confirmed action clears `shared_preferences` and the drift database entirely, then resets the app to first-launch defaults (language detection re-runs, per L-2).

## Design Reference

`design-reference/zodiann/screens/04-settings_delete-dialog_desktop_en_dark.png` (the exact dialog to use).

## Acceptance Criteria

- [ ] Confirmed deletion clears all settings and saved squares; the app behaves as a fresh install afterward.
- [ ] Canceling the dialog leaves all data untouched.

## Dependencies

- [ZOD-SET-005](../settings-persistence/ZOD-SET-005-build-the-your-data-panel-export-import-backup-delete-all-data.md) — Build the "Your data" panel (export/import backup, delete all data)
- [ZOD-UI-013](../shared-ui-design-system/ZOD-UI-013-implement-the-dialog-component.md) — Implement the dialog component
- [ZOD-FND-006](../foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md) — Local storage infrastructure: `shared_preferences` + SQLite (drift) schema v1

## Specification References

- DATA-10

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
