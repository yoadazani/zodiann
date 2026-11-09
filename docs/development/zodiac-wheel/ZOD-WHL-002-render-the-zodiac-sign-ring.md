# ZOD-WHL-002 - Render the zodiac sign ring

## Metadata

- **ID:** ZOD-WHL-002
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Draw the outer ring of 12 signs, each a 30° arc from Aries to Pisces, with glyph, element color, and tint.

## Implementation Details

- 12 equal 30° sectors in fixed zodiacal order; each sector gets an element-colored tint (fire/earth/air/water, per MASTER.md §2.3) at 11% opacity desktop (per the §7.2 sign-band row), a 30° separator line in `line`, and an `accent-line` rim.
- Sign glyph centered in the band, colored by element, 21px desktop / 30px compact.
- This exact placement never mirrors under RTL (geometric rule, L-6) — signs always run in the same rotational order regardless of app language.

## Design Reference

`design-reference/zodiann/screens/01-zodiac-wheel_desktop_en_dark.png` (outer ring with glyphs and element tints) and the `_he_` variant to confirm the ring itself is pixel-identical despite the surrounding UI mirroring; `design-reference/zodiann/MASTER.md` §7.2 "Sign band" row and "Sign glyphs" bullet; `design-reference/zodiann/MASTER.md` §2.3 for exact element colors.

## Acceptance Criteria

- [ ] All 12 signs render in correct zodiacal order with correct element color and glyph.
- [ ] Tint opacity and rim match the design reference (11% dark / 9% light per §2.3).
- [ ] The ring is pixel-identical between the English and Hebrew screenshots (L-6 verified).

## Dependencies

- [ZOD-WHL-001](../zodiac-wheel/ZOD-WHL-001-build-the-wheel-canvas-and-proportion-system.md) — Build the wheel canvas and proportion system
- [ZOD-FND-009](../foundations-architecture/ZOD-FND-009-integrate-the-33-icon-set-as-svg-assets.md) — Integrate the 33-icon set as SVG assets

## Specification References

- WH-1
- L-6
- MASTER.md §7.2, §2.3

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
