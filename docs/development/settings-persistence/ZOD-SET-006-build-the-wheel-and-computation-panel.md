# ZOD-SET-006 - Build the "Wheel and computation" panel

## Metadata

- **ID:** ZOD-SET-006
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 3
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the visible-bodies chips, aspect-orb steppers, lunar-node toggle, ephemeris-source radio list, zodiac toggle, and viewpoint toggle.

## Implementation Details

- Visible bodies: chip toggles for all 11 bodies ([ZOD-UI-007](../shared-ui-design-system/ZOD-UI-007-implement-switch-stepper-and-body-chip-components.md)), controls which rows/markers show on the wheel.
- Aspect orbs: five steppers ([ZOD-UI-007](../shared-ui-design-system/ZOD-UI-007-implement-switch-stepper-and-body-chip-components.md)), wired to [ZOD-ASP-002](../computation-engine/ZOD-ASP-002-implement-aspect-orb-configuration-data-flow.md) — editable or read-only depending on D-1's resolution.
- Lunar node: Mean/True toggle (True remains out-of-scope functionally per D-3's proposed default, but the control exists per the mockup — confirm with D-3's resolution whether True should be disabled/hidden or left as a genuinely working toggle).
- Ephemeris source: radio list ([ZOD-UI-008](../shared-ui-design-system/ZOD-UI-008-implement-the-radio-list-component-ephemeris-source-selector.md)) — Swiss Ephemeris data files (Recommended) / Swiss Ephemeris built-in (Moshier) / astronomy-engine (Backup), wired to [ZOD-EPH-002](../computation-engine/ZOD-EPH-002-implement-the-swiss-ephemeris-ephemerisport-adapter-data-file-mode.md)/003/004 via DI (ARCH-4).
- Zodiac: Tropical / Sidereal(planned, disabled) toggle — Sidereal shown at 40% opacity, non-interactive (D19, flagged needing approval on whether to show it at all).
- Viewpoint: Geocentric / Topocentric toggle, with the explanatory hint "Topocentric mainly affects the Moon, by up to about a degree."

## Design Reference

`design-reference/zodiann/screens/04-settings_desktop_en_dark.png` "Wheel and computation" panel (every control listed above is visible with exact copy and layout); `design-reference/zodiann/DESIGN_DECISIONS.md` D18, D19.

## Acceptance Criteria

- [ ] Toggling a body chip immediately shows/hides that body on the wheel.
- [ ] Selecting a different ephemeris source swaps the active `EphemerisPort` via DI with no other code change (ARCH-4).
- [ ] Sidereal option is visibly disabled/planned per D19, pending final approval on whether it should be shown at all.

## Dependencies

- [ZOD-SET-001](../settings-persistence/ZOD-SET-001-build-the-settings-screen-panel-layout.md) — Build the Settings screen panel layout
- [ZOD-UI-007](../shared-ui-design-system/ZOD-UI-007-implement-switch-stepper-and-body-chip-components.md) — Implement switch, stepper, and body-chip components
- [ZOD-UI-008](../shared-ui-design-system/ZOD-UI-008-implement-the-radio-list-component-ephemeris-source-selector.md) — Implement the radio-list component (ephemeris source selector)
- [ZOD-EPH-002](../computation-engine/ZOD-EPH-002-implement-the-swiss-ephemeris-ephemerisport-adapter-data-file-mode.md) — Implement the Swiss Ephemeris `EphemerisPort` adapter (data-file mode)
- [ZOD-EPH-003](../computation-engine/ZOD-EPH-003-implement-the-swiss-ephemeris-built-in-moshier-fallback-mode.md) — Implement the Swiss Ephemeris built-in (Moshier) fallback mode
- [ZOD-EPH-004](../computation-engine/ZOD-EPH-004-spike-implement-the-astronomy-engine-ephemerisport-adapter-backup.md) — Spike + implement the astronomy-engine `EphemerisPort` adapter (backup/oracle)

## Specification References

- D-3
- D19
- D18
- MASTER.md §9

## Notes

- This task touches an item flagged **needing approval** in `design-reference/zodiann/DESIGN_DECISIONS.md` — confirm the interpretation above with the product owner before implementing.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
