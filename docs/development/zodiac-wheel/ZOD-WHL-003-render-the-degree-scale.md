# ZOD-WHL-003 - Render the degree scale

## Metadata

- **ID:** ZOD-WHL-003
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** High
- **Status:** Done (see Notes)
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

- [x] Tick length varies correctly at 1°/5°/10° intervals all the way around the ring. (348 ticks, 288 / 36 / 24 by class, none at multiples of 30°; closed-form endpoints for both tables at three pointers; tick tips measured within 0.5 unit of 5 / 9 / 14 against Chrome and within 1.25 units on the designer's PNGs)
- [x] "10" and "20" labels appear at the correct position within every sign, never at 0. (24 labels, pixel-compared against "10" / "20" and against "0", "30" and the other number; the measured label radius is within 1 unit of the kit's 224 / 214)
- [x] Matches the reference screenshot's tick density and label placement. (four Chrome references: mean difference 0.75–1.30 per channel, label centroids within 1.08 px; the designer's PNGs: label centroids within 1.55 units of the reference, English vs Hebrew 0.22; see Notes P1)

## Dependencies

- [ZOD-WHL-002](../zodiac-wheel/ZOD-WHL-002-render-the-zodiac-sign-ring.md) — Render the zodiac sign ring

## Specification References

- WH-2
- MASTER.md §7.2

## Notes

Degree-number radius and size (ZOD-WHL-001 plan decision D7, `docs/plans/ZOD-WHL-001-wheel-canvas-proportions.md`, 2026-11-17; not `DESIGN_DECISIONS.md` design decision D7): the design (`kit.js` `wheelSVG`, from which the PNGs are rendered) places the numbers at `rSignIn − 26` (kit units), not MASTER §7.2's "22 px inside the band", and the "14px compact" above is the compact **font size** (desktop 9.5), not an inset. The radius comes from `WheelProportions` (ZOD-WHL-001).

- **From ZOD-WHL-002 (2026-11-19):** the 30° marks are WHL-002's separators (they run from the outer rim to `signBandInner − 18` units, `WheelProportions.signSeparatorInner`): draw **no tick at multiples of 30°**, as the kit does (`kit.js:318`). The band's rims and the halo belong to `SignRingLayer`; the ticks start at `signBandInner` (`tickInnerEdge`) and run inward.

- **From ZOD-WHL-003 (2026-11-19, product-owner decision P1):** MASTER §7.2 and this task say all ticks are `text-2`; the kit (`kit.css:304-307`), which renders the design PNGs, draws the 1° and 5° ticks in `text-3` at 0.8 / 1 px and the 10° ticks in `text-2` at 1.2 px, with the labels in `text-3`. The layer follows the kit; MASTER and the criteria above are not edited. The label text role is `WheelPaintContext.labelStyle` (the `micro` role), from which ZOD-WHL-004 can derive its body-degree label with `copyWith(fontSize, fontWeight)`. Connectors start at `rTick - 1` (`kit.js:334`), across the tick zone.
---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
