# ZOD-NFR-010 - Audit reduced-motion compliance across every animation (NFR-X6)

## Metadata

- **ID:** ZOD-NFR-010
- **Category:** [Performance, Accessibility & Reliability](../README.md#performance-accessibility-reliability) (`performance-accessibility-reliability/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Confirm every animated behavior in the app — not just the two explicitly spec'd ones (wheel snap, playback) — degrades per the system's reduced-motion preference.

## Implementation Details

- Audit: wheel snap-to-body ([ZOD-WHL-019](../zodiac-wheel/ZOD-WHL-019-implement-tap-row-to-snap-wheel-animation.md)), drawer open/close transitions ([ZOD-NAV-002](../navigation/ZOD-NAV-002-implement-the-side-navigation-drawer.md)), segment-change crossfades, hover transitions, playback stepping ([ZOD-WHL-017](../zodiac-wheel/ZOD-WHL-017-build-automatic-playback-play-pause.md)).
- Per MASTER.md §12: every animation becomes an instant change under reduced motion; playback still steps (just without inter-step animation) — these are two different outcomes, don't collapse them into one rule.

## Design Reference

`design-reference/zodiann/MASTER.md` §12 "Motion" (the authoritative "reduced motion" row and the explicit "no decorative or ambient motion" rule).

## Acceptance Criteria

- [ ] NFR-X6 passes for every animated UI element in the app, verified with the OS reduced-motion setting enabled.
- [ ] Playback specifically continues to step at 110ms under reduced motion (not pause), per MASTER.md §12.

## Dependencies

- [ZOD-WHL-017](../zodiac-wheel/ZOD-WHL-017-build-automatic-playback-play-pause.md) — Build automatic playback (play/pause)
- [ZOD-WHL-019](../zodiac-wheel/ZOD-WHL-019-implement-tap-row-to-snap-wheel-animation.md) — Implement tap-row-to-snap wheel animation
- [ZOD-NAV-002](../navigation/ZOD-NAV-002-implement-the-side-navigation-drawer.md) — Implement the side navigation drawer
- [ZOD-UI-006](../shared-ui-design-system/ZOD-UI-006-implement-the-segmented-control-component.md) — Implement the segmented control component

## Specification References

- NFR-X6
- MASTER.md §12

## Notes

- **Button hover (ZOD-UI-004):** `ZodiannButton` animates hover (brightness 1 → 1.12) over 150 ms (`ZodiannStates.hoverDuration`, `Curves.ease`) and is instant when `MediaQuery.disableAnimationsOf` is true; covered by `button_behavior_test.dart`. Press is instant.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Performance, Accessibility & Reliability" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
