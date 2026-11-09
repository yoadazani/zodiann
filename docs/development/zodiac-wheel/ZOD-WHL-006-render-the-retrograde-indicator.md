# ZOD-WHL-006 - Render the retrograde indicator (℞)

## Metadata

- **ID:** ZOD-WHL-006
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Mark a backward-moving body with ℞ next to its degree label on the wheel.

## Implementation Details

- ℞ rendered in `asp-hard` color (MASTER.md §2.3), next to the degree number, only for bodies whose speed is negative ([ZOD-EPH-005](../computation-engine/ZOD-EPH-005-implement-retrograde-detection-and-position-formatting.md)).
- The node never gets this mark on the wheel (it has its own constant "mean" semantics, shown only in the positions table, not as ℞ on the wheel face) — WH-5 explicitly excludes it here.
- Append U+FE0E to the ℞ glyph per the typography spec ([ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md)) so it never renders as emoji.

## Design Reference

`design-reference/zodiann/screens/01-zodiac-wheel_desktop_en_dark.png` (visible ℞ marks next to Jupiter, Venus, Saturn, Neptune in the sample data) for exact placement and color.

## Acceptance Criteria

- [ ] ℞ appears only on bodies with negative speed.
- [ ] ℞ never appears next to the node on the wheel face.
- [ ] Color matches `asp-hard` token exactly.

## Dependencies

- [ZOD-WHL-004](../zodiac-wheel/ZOD-WHL-004-render-body-markers-glyph-degree-label-connector-true-position-dot.md) — Render body markers (glyph, degree label, connector, true-position dot)
- [ZOD-EPH-005](../computation-engine/ZOD-EPH-005-implement-retrograde-detection-and-position-formatting.md) — Implement retrograde detection and position formatting

## Specification References

- WH-5
- MASTER.md §2.3

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
