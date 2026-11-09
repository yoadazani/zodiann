# ZOD-DAT-007 - Implement last-screen-state persistence (resume on relaunch)

## Metadata

- **ID:** ZOD-DAT-007
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Persist each screen's last state so relaunching the app returns the user to where they left off, per DATA-2 and NAV-5.

## Implementation Details

- Wheel screen: last-viewed time and drag mode.
- Square screen: last mode/anchor/size (independent of any named saved square).
- On relaunch, the last-active route (per NAV-5/T-UI-1) and that screen's last state both restore.

## Design Reference

No direct design reference applies — behavioral persistence layered on already-built screens.

## Acceptance Criteria

- [ ] T-UI-1's "reopening the app returns to the last screen" portion passes.
- [ ] The wheel/square's last-viewed state (not just the route) is restored, not reset to defaults.

## Dependencies

- [ZOD-WHL-025](../zodiac-wheel/ZOD-WHL-025-implement-responsive-wheel-screen-layout-desktop-tablet-phone.md) — Implement responsive wheel-screen layout (desktop/tablet/phone)
- [ZOD-SQR-020](../gann-square/ZOD-SQR-020-implement-responsive-square-screen-layout-desktop-tablet-portrait.md) — Implement responsive square-screen layout (desktop/tablet-portrait/tablet-landscape/phone)
- [ZOD-FND-006](../foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md) — Local storage infrastructure: `shared_preferences` + SQLite (drift) schema v1
- [ZOD-NAV-003](../navigation/ZOD-NAV-003-wire-drawer-navigation-to-go-router-routes.md) — Wire drawer navigation to `go_router` routes

## Specification References

- DATA-2
- NAV-5
- T-UI-1

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
