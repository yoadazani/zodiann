# ZOD-WHL-017 - Build automatic playback (play/pause)

## Metadata

- **ID:** ZOD-WHL-017
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the play button that automatically steps time forward at a fixed interval until stopped.

## Implementation Details

- 48px `accent` disc play button; becomes an `accent` ring with a pause glyph while playing.
- Steps at one step-size unit every 110ms, with no easing between steps (MASTER.md §12 "Motion").
- Stops automatically when the user navigates to another screen (WH-12, implemented jointly with [ZOD-NAV-003](../navigation/ZOD-NAV-003-wire-drawer-navigation-to-go-router-routes.md)).
- Under reduced motion (NFR-X6), playback still steps at the same cadence — only the *animation* between states is removed, not the stepping itself (per MASTER.md §12's explicit callout).

## Design Reference

`design-reference/zodiann/screens/01-zodiac-wheel_desktop_en_dark.png` (play button, idle state); `design-reference/zodiann/MASTER.md` §7.3 "Transport" and §12 "Motion" (110ms step cadence, reduced-motion behavior).

## Acceptance Criteria

- [ ] Playback advances exactly one step every 110ms while active.
- [ ] Navigating away from the wheel screen stops playback (verified jointly with ZOD-NAV-003/T-UI test).
- [ ] With reduced motion enabled, playback still steps at 110ms but without inter-step animation.

## Dependencies

- [ZOD-WHL-015](../zodiac-wheel/ZOD-WHL-015-build-the-time-panel-step-size-segmented-control.md) — Build the Time panel: step-size segmented control
- [ZOD-WHL-016](../zodiac-wheel/ZOD-WHL-016-build-the-time-panel-back-forward-step-buttons.md) — Build the Time panel: back/forward step buttons
- [ZOD-NAV-003](../navigation/ZOD-NAV-003-wire-drawer-navigation-to-go-router-routes.md) — Wire drawer navigation to `go_router` routes

## Specification References

- WH-11
- WH-12
- NFR-X6
- MASTER.md §7.3, §12

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
