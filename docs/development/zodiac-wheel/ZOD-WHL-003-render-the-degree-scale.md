# ZOD-WHL-003 - Render the degree scale

## Metadata

- **ID:** ZOD-WHL-003
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Draw the per-degree tick marks and the 10/20-degree numeric labels inside the sign band.

## Implementation Details

- Tick lengths: 1° → 5px, 5° → 9px, 10° → 14px, all in `text-2`, drawn inward from the band (MASTER.md §7.2 "Degree ticks" row).
- Numeric labels at 10° and 20° within each sign (never 0 or 30, which are the sign boundary), 22px inset desktop / 14px compact, 9.5px text size desktop.
- Must use tabular figures ([ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md)) so the two-digit numbers align consistently around the ring.

## Design Reference

`design-reference/zodiann/screens/01-zodiac-wheel_desktop_en_dark.png` (visible "10"/"20" labels and tick gradation around the ring); `design-reference/zodiann/MASTER.md` §7.2 "Degree ticks" and "Degree numbers" rows.

## Acceptance Criteria

- [ ] Tick length varies correctly at 1°/5°/10° intervals all the way around the ring.
- [ ] "10" and "20" labels appear at the correct position within every sign, never at 0.
- [ ] Matches the reference screenshot's tick density and label placement.

## Dependencies

- [ZOD-WHL-002](../zodiac-wheel/ZOD-WHL-002-render-the-zodiac-sign-ring.md) — Render the zodiac sign ring

## Specification References

- WH-2
- MASTER.md §7.2

## Notes

Degree-number radius and size (ZOD-WHL-001 plan decision D7, `docs/plans/ZOD-WHL-001-wheel-canvas-proportions.md`, 2026-11-17; not `DESIGN_DECISIONS.md` design decision D7): the design (`kit.js` `wheelSVG`, from which the PNGs are rendered) places the numbers at `rSignIn − 26` (kit units), not MASTER §7.2's "22 px inside the band", and the "14px compact" above is the compact **font size** (desktop 9.5), not an inset. The radius comes from `WheelProportions` (ZOD-WHL-001).

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
