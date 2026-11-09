# ZOD-DAT-005 - Implement "Open" (load a saved square into the Square screen)

## Metadata

- **ID:** ZOD-DAT-005
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 3
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Implement the action that navigates to the Square screen and restores its state from a saved `SquareConfig`.

## Implementation Details

- Restores mode, anchor (with its saved time-zone offset per DATA-4), size, spiral direction/rotation, and highlight rules exactly.

## Design Reference

No new visual element — this reuses the already-specified Square screen (`gann-square/`) populated from stored state.

## Acceptance Criteria

- [ ] Opening a saved square reproduces an identical square to what was saved, including after a time-zone or DST change since saving (DATA-4).

## Dependencies

- [ZOD-DAT-001](../settings-persistence/ZOD-DAT-001-build-the-saved-squares-list-screen.md) — Build the Saved squares list screen
- [ZOD-SQR-001](../gann-square/ZOD-SQR-001-build-the-mode-switcher-with-state-preservation.md) — Build the mode switcher with state preservation
- [ZOD-NAV-003](../navigation/ZOD-NAV-003-wire-drawer-navigation-to-go-router-routes.md) — Wire drawer navigation to `go_router` routes

## Specification References

- UC10
- DATA-4

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
