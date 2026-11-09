# ZOD-L10-003 - Implement the in-app language override

## Metadata

- **ID:** ZOD-L10-003
- **Category:** [Localization](../README.md#localization) (`localization/`)
- **Phase:** Phase 4
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Let Settings override the device language, applied immediately with no restart, persisted in `UserSettings`.

## Implementation Details

- Wires into [ZOD-SET-002](../settings-persistence/ZOD-SET-002-build-the-language-and-region-panel.md)'s language segmented control.
- Changing it must re-render every currently visible screen immediately — verify this holds even mid-interaction (e.g., while the wheel is mid-drag, though an edge case, should not crash).

## Design Reference

`design-reference/zodiann/screens/04-settings_desktop_en_dark.png` "Language" control.

## Acceptance Criteria

- [ ] Switching language updates the entire visible UI with no restart.
- [ ] Choice persists across app restarts.

## Dependencies

- ZOD-L10-002
- [ZOD-SET-002](../settings-persistence/ZOD-SET-002-build-the-language-and-region-panel.md) — Build the Language and region panel
- [ZOD-FND-006](../foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md) — Local storage infrastructure: `shared_preferences` + SQLite (drift) schema v1

## Specification References

- L-3

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Localization" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
