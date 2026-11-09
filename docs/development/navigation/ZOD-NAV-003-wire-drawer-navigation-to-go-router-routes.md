# ZOD-NAV-003 - Wire drawer navigation to `go_router` routes

## Metadata

- **ID:** ZOD-NAV-003
- **Category:** [Navigation & App Shell](../README.md#navigation) (`navigation/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Connect the drawer item taps and the hamburger button to the routing scaffold from [ZOD-FND-014](../foundations-architecture/ZOD-FND-014-set-up-go-router-navigation-scaffold.md), completing the "one screen at a time" navigation model.

## Implementation Details

- Tapping a drawer item navigates to its route, closes the drawer, and marks that item active.
- A deep link to `#square` (or any route) opens that screen directly on cold start (NAV-5).
- An unknown route falls back to the wheel screen (already stubbed in [ZOD-FND-014](../foundations-architecture/ZOD-FND-014-set-up-go-router-navigation-scaffold.md); wire real screens once they exist).
- Switching screens always scrolls the new screen to the top and stops any running wheel-playback timer (NAV-4, WH-12) — this must hold even when navigating away mid-playback.

## Design Reference

No direct design reference applies to the routing wiring itself; the resulting navigated-to screens are the five screens covered in their own sections.

## Acceptance Criteria

- [ ] T-UI-1 passes: drawer navigation reaches the right screen, app relaunch returns to the last screen, a deep link opens the requested screen directly.
- [ ] Starting wheel playback, then navigating to Settings, stops playback (verified by returning to the wheel and confirming it isn't still advancing).
- [ ] Every screen switch resets scroll position to the top.

## Dependencies

- [ZOD-NAV-002](../navigation/ZOD-NAV-002-implement-the-side-navigation-drawer.md) — Implement the side navigation drawer
- [ZOD-FND-014](../foundations-architecture/ZOD-FND-014-set-up-go-router-navigation-scaffold.md) — Set up `go_router` navigation scaffold

## Specification References

- NAV-4
- NAV-5
- WH-12
- T-UI-1

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Navigation & App Shell" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
