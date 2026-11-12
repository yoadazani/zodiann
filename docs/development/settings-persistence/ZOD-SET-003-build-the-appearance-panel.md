# ZOD-SET-003 - Build the Appearance panel

## Metadata

- **ID:** ZOD-SET-003
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 4
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Build theme selection and the reduced-motion status row.

## Implementation Details

- Theme: System / Dark / Light segmented control.
- Reduced motion: read-only row stating "Follows the system setting" (the app does not override the OS-level accessibility preference, per NFR-X6).

## Design Reference

`design-reference/zodiann/screens/04-settings_desktop_en_dark.png` "Appearance" panel.

## Acceptance Criteria

- [ ] Switching theme updates the whole app immediately, no restart.
- [ ] Theme choice persists across app restarts (ZOD-FND-006).

## Dependencies

- [ZOD-SET-001](../settings-persistence/ZOD-SET-001-build-the-settings-screen-panel-layout.md) — Build the Settings screen panel layout
- [ZOD-UI-006](../shared-ui-design-system/ZOD-UI-006-implement-the-segmented-control-component.md) — Implement the segmented control component
- [ZOD-FND-006](../foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md) — Local storage infrastructure: `shared_preferences` + SQLite (drift) schema v1

## Specification References

- NFR-X6
- MASTER.md §9

## Notes

`themeModeProvider` (`apps/astro_mobile/lib/src/theme/theme_mode_provider.dart`, ZOD-FND-013) already switches the running app's theme mode (default: system). It is an app-level placeholder, not a contract for feature packages: this task decides where the picker's provider contract lives, and ZOD-SET-007 / ZOD-FND-006 persist the choice.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
