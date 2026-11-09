# ZOD-EXT-004 - Sidereal zodiac with ayanamsa choice

## Metadata

- **ID:** ZOD-EXT-004
- **Category:** [Optional Extensions](../README.md#optional-extensions) (`optional-extensions/`)
- **Phase:** Phase 5
- **Priority:** Low
- **Status:** Not Started
- **Scope:** Optional Extension

## Description

Implement the sidereal zodiac as an alternative to tropical, with a choice of ayanamsa, unlocking the currently-disabled Settings toggle.

## Implementation Details

Requires a new longitude-offset computation layer (ayanamsa subtraction) applied after the tropical position is computed; D-5's proposed default is explicitly "tropical only," so this entire task is contingent on that decision being revisited.

## Design Reference

`design-reference/zodiann/screens/04-settings_desktop_en_dark.png` "Zodiac" Tropical/Sidereal(planned) toggle — already shows the disabled target state (DESIGN_DECISIONS D19).

## Acceptance Criteria

- [ ] Selecting Sidereal with a chosen ayanamsa produces correctly offset positions, verified against a reference source.

## Dependencies

- [ZOD-EPH-002](../computation-engine/ZOD-EPH-002-implement-the-swiss-ephemeris-ephemerisport-adapter-data-file-mode.md) — Implement the Swiss Ephemeris `EphemerisPort` adapter (data-file mode)
- [ZOD-SET-006](../settings-persistence/ZOD-SET-006-build-the-wheel-and-computation-panel.md) — Build the "Wheel and computation" panel

## Specification References

- "Planned extensions to the wheel"
- D-5
- DESIGN_DECISIONS.md D19

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Optional Extensions" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
