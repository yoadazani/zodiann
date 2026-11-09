# ZOD-WHL-004 - Render body markers (glyph, degree label, connector, true-position dot)

## Metadata

- **ID:** ZOD-WHL-004
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Draw each of the 11 bodies (10 bodies + node) with its fixed glyph/color, its whole-degree-within-sign label, a connector line to its true position, and a dot marking that true position on the inner circle.

## Implementation Details

- Body glyph disc: 0.64R desktop (disc radius 14, glyph 17px) / 0.60R compact (disc radius 21, glyph 27px).
- Degree label: whole degree number within the sign, 0.547R desktop (11.5/600 text) / 0.467R compact (19px).
- Connector: 1px line in the body's own color at 75% opacity, from the body's **true** degree position on the scale to its **displayed** disc position (distinct when display-spread, [ZOD-WHL-005](../zodiac-wheel/ZOD-WHL-005-implement-the-body-display-spread-collision-avoidance-algorithm.md), has moved the disc).
- True-position dot: on the inner disc (0.453R desktop / 0.373R compact), radius 3.2 desktop / 4.5 compact.
- Body is never identified by color alone — glyph is always drawn (MASTER.md §2.3 rule, feeds NFR-X4/accessibility).

## Design Reference

`design-reference/zodiann/screens/01-zodiac-wheel_desktop_en_dark.png` (all 11 body markers with glyph discs, degree labels, connectors, and dots visible — e.g., Sun/Mercury/Moon cluster near the top, Mars/Jupiter cluster at the right); `design-reference/zodiann/MASTER.md` §7.2 full body-marker row table and §2.3 body color table.

## Acceptance Criteria

- [ ] All 11 bodies render with correct glyph, color, degree label, connector, and dot.
- [ ] Connector line correctly links true position to displayed (possibly spread) position.
- [ ] No body relies on color alone for identification — glyph is always legible.

## Dependencies

- [ZOD-WHL-001](../zodiac-wheel/ZOD-WHL-001-build-the-wheel-canvas-and-proportion-system.md) — Build the wheel canvas and proportion system
- [ZOD-EPH-005](../computation-engine/ZOD-EPH-005-implement-retrograde-detection-and-position-formatting.md) — Implement retrograde detection and position formatting

## Specification References

- WH-3
- MASTER.md §7.2, §2.3
- NFR-X4

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
