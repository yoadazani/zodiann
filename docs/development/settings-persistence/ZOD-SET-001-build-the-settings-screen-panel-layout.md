# ZOD-SET-001 - Build the Settings screen panel layout

## Metadata

- **ID:** ZOD-SET-001
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 4
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Assemble the Settings screen's panel grid and per-row layout convention (label+hint at the start, control at the end, long controls stacking below).

## Implementation Details

- Two columns on desktop (Language and region / Appearance / Square defaults / Your data on the start column; Wheel and computation on the end column); one column on tablet and phone.
- Row convention: label + hint at the start side, control at the end side; long controls (body chips, orb steppers, ephemeris radios) stack below the label instead of squeezing into the row.

## Design Reference

`design-reference/zodiann/screens/04-settings_desktop_en_dark.png` (full two-column layout); `design-reference/zodiann/responsive/tablet/settings_tablet_*` for the single-column breakpoint; `design-reference/zodiann/MASTER.md` §9 "Settings".

## Acceptance Criteria

- [ ] Panel grouping and column count match the breakpoint-specific screenshots.
- [ ] Long controls stack below their label rather than overflowing the row, matching the reference layout.

## Dependencies

- [ZOD-UI-014](../shared-ui-design-system/ZOD-UI-014-implement-the-hairline-panel-component.md) — Implement the hairline panel component
- [ZOD-NAV-003](../navigation/ZOD-NAV-003-wire-drawer-navigation-to-go-router-routes.md) — Wire drawer navigation to `go_router` routes

## Specification References

- MASTER.md §9

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
