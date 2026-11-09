# ZOD-DAT-008 - Implement backup export/import (single JSON file)

## Metadata

- **ID:** ZOD-DAT-008
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Implement the manual, user-initiated backup/restore flow as a single versioned JSON file containing all settings and saved squares.

## Implementation Details

- Export: serialize `UserSettings` + all `SquareConfig`s (with their `HighlightRule`s) + a version field, share via the OS share sheet (reuses [ZOD-XLS-011](../excel-export/ZOD-XLS-011-implement-share-sheet-integration-temp-storage-system-share.md)'s share pattern).
- Import: parse the file, validate its version field, **replace** settings and **add** (not overwrite) saved squares from the file — per DATA-9's "manual transfer and backup only" framing, this is explicitly a proposal awaiting approval, not a locked requirement.
- Respect the 100-saved-squares cap ([ZOD-DAT-006](../settings-persistence/ZOD-DAT-006-implement-the-100-saved-squares-cap-and-live-counter.md)) during import; show a clear message if the import would exceed it.

## Design Reference

`design-reference/zodiann/screens/04-settings_desktop_en_dark.png` "Export"/"Import" buttons in "Your data" panel.

## Acceptance Criteria

- [ ] Exported JSON round-trips through import on the same or a different device, reproducing identical settings and squares.
- [ ] Import never silently exceeds the 100-square cap.
- [ ] Importing a file with an incompatible/missing version field is rejected with a clear message, not a crash.

## Dependencies

- [ZOD-FND-012](../foundations-architecture/ZOD-FND-012-define-usersettings-squareconfig-highlightrule-crossing-dart-data.md) — Define `UserSettings`, `SquareConfig`, `HighlightRule`, `Crossing` Dart data classes
- [ZOD-DAT-006](../settings-persistence/ZOD-DAT-006-implement-the-100-saved-squares-cap-and-live-counter.md) — Implement the 100-saved-squares cap and live counter
- [ZOD-SET-005](../settings-persistence/ZOD-SET-005-build-the-your-data-panel-export-import-backup-delete-all-data.md) — Build the "Your data" panel (export/import backup, delete all data)

## Specification References

- DATA-3
- DATA-9

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
