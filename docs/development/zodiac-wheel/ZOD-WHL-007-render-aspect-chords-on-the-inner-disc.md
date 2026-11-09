# ZOD-WHL-007 - Render aspect chords on the inner disc

## Metadata

- **ID:** ZOD-WHL-007
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Draw a line between each pair of bodies (excluding the node) whose angle falls within an aspect's orb, colored by aspect type.

## Implementation Details

- Consume `[ZOD-ASP-001](../computation-engine/ZOD-ASP-001-implement-aspect-detection-between-body-pairs.md)`'s detection results; draw each as a 1.3px line at 90% opacity between the two bodies' **true** positions on the inner disc (not the spread/displayed positions).
- Color: conjunction amber, sextile/trine turquoise, square/opposition red (`AspectColors` tokens).
- Node is excluded (enforced upstream in [ZOD-ASP-001](../computation-engine/ZOD-ASP-001-implement-aspect-detection-between-body-pairs.md), but verify no chord ever touches the node marker here either).

## Design Reference

`design-reference/zodiann/screens/01-zodiac-wheel_desktop_en_dark.png` (visible amber/turquoise/red chords crossing the inner disc in the sample chart); `design-reference/zodiann/MASTER.md` §7.2 "Aspect chords" row.

## Acceptance Criteria

- [ ] Chords render only between true positions, matching ZOD-ASP-001's output exactly (one chord per detected aspect, correct color).
- [ ] No chord ever originates from or terminates at the node.
- [ ] T-ASP-1's boundary cases are visually verifiable (a chord appears/disappears exactly at the orb boundary).

## Dependencies

- [ZOD-WHL-004](../zodiac-wheel/ZOD-WHL-004-render-body-markers-glyph-degree-label-connector-true-position-dot.md) — Render body markers (glyph, degree label, connector, true-position dot)
- [ZOD-ASP-001](../computation-engine/ZOD-ASP-001-implement-aspect-detection-between-body-pairs.md) — Implement aspect detection between body pairs

## Specification References

- WH-6
- MASTER.md §7.2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
