# ZOD-L10-005 - Verify never-mirrored exceptions stay unmirrored

## Metadata

- **ID:** ZOD-L10-005
- **Category:** [Localization](../README.md#localization) (`localization/`)
- **Phase:** Phase 4
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Explicitly test the geometric/astronomical elements that must stay identical in both languages: the wheel drawing, the Gann spiral/square, and numbers.

## Implementation Details

- Pixel-diff the wheel's canvas region and the square's canvas region between an `_en_` and `_he_` screenshot of the same state — they must be identical; only surrounding chrome differs.
- Verify numeric values never reverse digit order under RTL (a common bidi bug).

## Design Reference

`design-reference/zodiann/screens/01-zodiac-wheel_desktop_{en,he}_dark.png` and `02-square-of-nine_dates_desktop_{en,he}_dark.png` as the exact pixel-identity reference pairs.

## Acceptance Criteria

- [ ] A pixel-diff test confirms the wheel canvas and square canvas regions are identical between EN and HE builds of the same app state.
- [ ] No numeric string ever reverses digit order under RTL.

## Dependencies

- [ZOD-WHL-001](../zodiac-wheel/ZOD-WHL-001-build-the-wheel-canvas-and-proportion-system.md) — Build the wheel canvas and proportion system
- [ZOD-SQR-016](../gann-square/ZOD-SQR-016-enforce-ltr-always-rendering-of-the-square.md) — Enforce LTR-always rendering of the square
- ZOD-L10-004

## Specification References

- L-6
- L-14
- MASTER.md §13

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Localization" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
