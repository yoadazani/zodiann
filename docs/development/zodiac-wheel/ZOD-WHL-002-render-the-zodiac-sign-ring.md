# ZOD-WHL-002 - Render the zodiac sign ring

## Metadata

- **ID:** ZOD-WHL-002
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** Critical
- **Status:** Done (see Notes)
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

- [x] All 12 signs render in correct zodiacal order with correct element color and glyph. (literal element table + kit.js second source; per-sign glyph-crop identity; pixel fidelity to Chrome in 4 table × theme cases)
- [x] Tint opacity and rim match the design reference (11% dark / 9% light per §2.3). (read as 10% dark / 9% light, see Notes T1; rim and halo matched to Chrome within the calibrated ceilings)
- [x] The ring is pixel-identical between the English and Hebrew screenshots (L-6 verified). (the app's own en and he renders are byte-identical; the designer PNGs are equal within 1 per channel over the band, see Notes T4)

## Dependencies

- [ZOD-WHL-001](../zodiac-wheel/ZOD-WHL-001-build-the-wheel-canvas-and-proportion-system.md) — Build the wheel canvas and proportion system
- [ZOD-FND-009](../foundations-architecture/ZOD-FND-009-integrate-the-33-icon-set-as-svg-assets.md) — Integrate the 33-icon set as SVG assets

## Specification References

- WH-1
- L-6
- MASTER.md §7.2, §2.3

## Notes

- **From ZOD-L10-007 (2026-11-14):** iterate `ZodiacSign.values` (zodiacal order from Aries, `index * 30°`). `ZodiannGlyphs.signs` is in the same order.

- **From ZOD-WHL-002 (2026-11-19):** the ring is `SignRingLayer` (`packages/feature_wheel/lib/src/canvas/sign_ring_layer.dart`), plan [`docs/plans/ZOD-WHL-002-zodiac-sign-ring.md`](../../plans/ZOD-WHL-002-zodiac-sign-ring.md). Product-owner decisions:
  - **T1, tint:** drawn at `ZodiacColors.signTintOpacity` (10 % dark, 9 % light), which is what `kit.css`, MASTER §2.3 and the reference PNGs use. MASTER §7.2's "11 %" and this file's "11 %" are not edited (the NAV-002 / UI-009 precedent: the kit wins over MASTER's prose).
  - **T2, rims and grid:** `SignRingLayer` draws the sign band's two rims **and the halo** (one kit statement, `kit.js:315`). `ProportionGridLayer` left the default layers and is opt-in scaffolding (its body rings at 0.64 R and 0.547 R have no kit counterpart). The inner-disc fill (kit `.inner`) goes to **ZOD-WHL-004**.
  - **T3, separators:** each 30° separator runs from the outer rim to `signBandInner − 18` units (the kit's `rTick − 18`), across the tick zone, so it is the 30° mark.
  - **T4, criterion 3:** the designer's own English / Hebrew PNGs differ by at most 1 per channel (on the Libra separator), so that comparison is "equal within 1 per channel" over the band, separator rays and halo (`test/design/wheel_ring_png_test.dart`); the app's own renders are byte-identical.
---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
